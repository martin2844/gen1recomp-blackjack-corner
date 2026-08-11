local State = {}

State.KEY = "gamble_campaign"
State.SCHEMA = 9
State.CHAMPION_REWARD = 25000

local VALID_RANKS = {
  ROOKIE = true, REGULAR = true, HIGH_ROLLER = true,
  VIP = true, KINGPIN = true,
}

State.STORY_CLUES = {
  FRAME = "CINNABAR_FRAME",
  MANIFEST = "CAGE_MANIFEST",
  CHART = "FUJI_CHART",
  LAB_ARCHIVE = "LAB_ARCHIVE",
  MANSION_LOG = "MANSION_LOG",
}
State.STORY_STAGES = {
  RUMORS = "ARENA_RUMORS",
  LEAD = "CINNABAR_LEAD",
  INVESTIGATION = "CINNABAR_INVESTIGATION",
  INVITATION = "EXHIBITION_INVITATION",
  CHOICE = "GIOVANNI_CHOICE",
  EXPOSED = "ROCKET_EXPOSED",
  CHAMPION = "HOUSE_CHAMPION",
}
State.STORY_ENDINGS = {
  EXPOSE = "EXPOSE",
  CHAMPION = "CHAMPION",
}

local VALID_STORY_CLUES, VALID_STORY_STAGES = {}, {}
for _, id in pairs(State.STORY_CLUES) do VALID_STORY_CLUES[id] = true end
for _, id in pairs(State.STORY_STAGES) do VALID_STORY_STAGES[id] = true end
local STORY_STAGE_ORDER = {
  [State.STORY_STAGES.RUMORS] = 1,
  [State.STORY_STAGES.LEAD] = 2,
  [State.STORY_STAGES.INVESTIGATION] = 3,
  [State.STORY_STAGES.INVITATION] = 4,
  [State.STORY_STAGES.CHOICE] = 5,
  [State.STORY_STAGES.EXPOSED] = 6,
  [State.STORY_STAGES.CHAMPION] = 6,
}

local function number(value, fallback, minimum)
  value = tonumber(value)
  if not value or value ~= value or value == math.huge or value == -math.huge then
    return fallback
  end
  value = math.floor(value)
  return math.max(minimum or 0, value)
end

local function tableOrEmpty(value)
  return type(value) == "table" and value or {}
end

local function deepCopy(value, seen)
  if type(value) ~= "table" then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local out = {}
  seen[value] = out
  for key, item in pairs(value) do
    out[deepCopy(key, seen)] = deepCopy(item, seen)
  end
  return out
end

local function ensureTable(parent, key)
  if type(parent[key]) ~= "table" then parent[key] = {} end
  return parent[key]
end

local function sanitizeGameRows(value)
  local out = {}
  for gameId, row in pairs(tableOrEmpty(value)) do
    if type(gameId) == "string" and type(row) == "table" then
      local clean = deepCopy(row)
      clean.played = number(row.played, 0)
      clean.wins = number(row.wins, 0)
      clean.losses = number(row.losses, 0)
      clean.draws = number(row.draws, 0)
      clean.wagered = number(row.wagered, 0)
      clean.returned = number(row.returned, 0)
      out[gameId] = clean
    end
  end
  return out
end

local function sanitizePending(value)
  local out = {}
  for token, row in pairs(tableOrEmpty(value)) do
    if type(token) == "string" and type(row) == "table"
        and type(row.gameId) == "string" then
      local clean = deepCopy(row)
      clean.gameId = row.gameId
      clean.stake = number(row.stake, 0)
      clean.rankAtStart = VALID_RANKS[row.rankAtStart] and row.rankAtStart or nil
      out[token] = clean
    end
  end
  return out
end

local function sanitizeStrings(value, limit, valid)
  local out = {}
  for _, item in ipairs(tableOrEmpty(value)) do
    if type(item) == "string" and (not valid or valid[item])
        and #out < (limit or 128) then
      out[#out + 1] = item
    end
  end
  return out
end

local function sanitizeBooleanMap(value, valid)
  local out = {}
  for key, item in pairs(tableOrEmpty(value)) do
    if type(key) == "string" and item == true and (not valid or valid[key]) then
      out[key] = true
    end
  end
  return out
end

local function sanitizeDiscoveries(value)
  local out, legacy = {}, {}
  for key, item in pairs(tableOrEmpty(value)) do
    if VALID_RANKS[key] and type(item) == "table" then
      out[key] = sanitizeBooleanMap(item)
    elseif type(key) == "string" and item == true then
      -- Early v0.5 development saves used one flat discovery map. Treat those
      -- entries as ROOKIE discoveries so later ranks receive their own bonus.
      legacy[key] = true
    end
  end
  if next(legacy) then
    out.ROOKIE = out.ROOKIE or {}
    for gameId in pairs(legacy) do out.ROOKIE[gameId] = true end
  end
  return out
end

local function sanitizeArenaPending(value)
  if type(value) ~= "table" or not ({ POSTED = true, BET = true,
      RESULT = true })[value.status] then return nil end
  local match = value.match
  if type(match) ~= "table" or type(match.fighters) ~= "table"
      or type(match.fighters[1]) ~= "table"
      or type(match.fighters[2]) ~= "table" then return nil end
  local out = deepCopy(value)
  out.match.id = number(match.id, 0)
  if out.match.id < 1 then return nil end
  out.match.tier = ({ STREET = true, ELITE = true, RARE = true,
      EXHIBITION = true })[match.tier]
    and match.tier or "STREET"
  out.match.kind = match.kind == "EXHIBITION" and "EXHIBITION" or "STANDARD"
  out.match.reward = type(match.reward) == "string" and match.reward or nil
  out.kind = value.kind == "EXHIBITION" and "EXHIBITION" or out.match.kind
  for index = 1, 2 do
    local fighter = out.match.fighters[index]
    if type(fighter.species) ~= "string" or fighter.species == "" then return nil end
    fighter.name = type(fighter.name) == "string" and fighter.name or fighter.species
    fighter.level = number(fighter.level, 1, 1)
    fighter.maxHP = number(fighter.maxHP, 1, 1)
    fighter.hp = fighter.maxHP
    if type(fighter.stats) ~= "table" or type(fighter.moves) ~= "table" then
      return nil
    end
  end
  if type(match.odds) ~= "table" then return nil end
  out.match.odds = { number(match.odds[1], 0), number(match.odds[2], 0) }
  if out.match.odds[1] < 100 or out.match.odds[2] < 100 then return nil end
  out.match.winner = number(match.winner, 0)
  if out.match.winner < 1 or out.match.winner > 2 then return nil end
  local actions = {}
  for _, source in ipairs(type(match.actions) == "table" and match.actions or {}) do
    if type(source) == "table" and #actions < 128 then
      local action = deepCopy(source)
      action.attacker, action.defender = number(source.attacker, 0),
        number(source.defender, 0)
      action.damage, action.defenderHP = number(source.damage, 0),
        number(source.defenderHP, 0)
      action.move = type(source.move) == "string" and source.move or "ATTACK"
      if action.attacker >= 1 and action.attacker <= 2
          and action.defender >= 1 and action.defender <= 2
          and action.attacker ~= action.defender then actions[#actions + 1] = action end
    end
  end
  out.match.actions = actions
  if #actions == 0 then return nil end
  if out.status ~= "POSTED" then
    out.selected = number(value.selected, 0)
    out.stake = number(value.stake, 0)
    if out.selected < 1 or out.selected > 2 or out.stake < 1
        or type(value.roundToken) ~= "string" then return nil end
  end
  if out.status == "RESULT" then
    out.payout = number(value.payout, 0)
    out.won = value.won == true
  end
  return out
end

local function sanitizeHeldParty(value)
  local party = {}
  for _, pokemon in ipairs(tableOrEmpty(value)) do
    if type(pokemon) == "table" and type(pokemon.species) == "string"
        and pokemon.species ~= "" and #party < 6 then
      party[#party + 1] = deepCopy(pokemon)
    end
  end
  return #party > 0 and party or nil
end

function State.defaults()
  return {
    schema = State.SCHEMA,
    reputation = {
      points = 0,
      rank = "ROOKIE",
      lifetimeWagered = 0,
      completedGames = 0,
      wins = 0,
      losses = 0,
      draws = 0,
      currentLossStreak = 0,
      bestLossStreak = 0,
      byGame = {},
      discoveredGames = {},
      rankRewardsClaimed = {},
      pendingRewardCoins = 0,
      pendingRankUps = {},
      pendingRounds = {},
      settledRounds = {},
      nextRoundId = 0,
    },
    -- Reserved now so later releases can migrate additively.
    debt = {
      principal = 0, fees = 0, status = "CLEAR", dueBadge = 0,
      lastBadgeFee = 0, loansTaken = 0, totalRepaid = 0,
      collectorsTriggered = {},
    },
    house = {
      status = "FAMILY_HOME", bailoutClaimed = false,
      buybackPaid = false, rocketBattleWon = false,
    },
    arena = {
      unlocked = false,
      stairsRevealed = false,
      heldParty = nil,
      securityExit = false,
      reputation = 0,
      matchesPlayed = 0,
      wins = 0,
      losses = 0,
      lifetimeWagered = 0,
      lifetimeReturned = 0,
      nextMatchId = 0,
      pending = nil,
      history = {},
    },
    story = {
      stage = State.STORY_STAGES.RUMORS,
      clues = {},
      exhibition = {
        attempts = 0, wins = 0, lastMatchId = 0,
      },
      ending = {
        choice = nil, rewardPending = 0, rewardClaimed = false,
      },
    },
  }
end

State.MIGRATIONS = {
  [1] = function(value)
    ensureTable(value, "reputation")
    ensureTable(value, "debt")
    ensureTable(value, "house")
    ensureTable(value, "arena")
  end,
  [2] = function(value)
    local debt = ensureTable(value, "debt")
    local legacyBalance = number(debt.balance, 0)
    if debt.principal == nil and legacyBalance > 0 then
      debt.principal = legacyBalance
    end
    debt.balance = nil
    debt.defaults = nil
    local house = ensureTable(value, "house")
    if house.status == nil then
      house.status = house.repossessed and "ROCKET_OWNED"
        or house.boughtBack and "RESTORED" or "FAMILY_HOME"
    end
    house.repossessed = nil
    house.boughtBack = nil
  end,
  [3] = function(value)
    -- v0.7 owns the arena record that earlier releases reserved. Keep the
    -- reserved unlock/reputation values and add the match ledger around them.
    local arena = ensureTable(value, "arena")
    if arena.matchesPlayed == nil then arena.matchesPlayed = 0 end
    if arena.wins == nil then arena.wins = 0 end
    if arena.losses == nil then arena.losses = 0 end
    if arena.lifetimeWagered == nil then arena.lifetimeWagered = 0 end
    if arena.lifetimeReturned == nil then arena.lifetimeReturned = 0 end
    if arena.nextMatchId == nil then arena.nextMatchId = 0 end
    if type(arena.history) ~= "table" then arena.history = {} end
  end,
  [4] = function(value)
    local arena = ensureTable(value, "arena")
    if arena.stairsRevealed == nil then arena.stairsRevealed = false end
    if arena.securityExit == nil then arena.securityExit = false end
  end,
  [5] = function(value)
    local story = ensureTable(value, "story")
    if story.stage == nil then story.stage = State.STORY_STAGES.RUMORS end
    if type(story.clues) ~= "table" then story.clues = {} end
  end,
  [6] = function(value)
    local story = ensureTable(value, "story")
    if story.stage == nil then story.stage = State.STORY_STAGES.RUMORS end
    if type(story.clues) ~= "table" then story.clues = {} end
  end,
  [7] = function(value)
    local story = ensureTable(value, "story")
    ensureTable(story, "exhibition")
  end,
  [8] = function(value)
    local story = ensureTable(value, "story")
    ensureTable(story, "ending")
  end,
  [9] = function(value)
    local story = ensureTable(value, "story")
    local ending = ensureTable(story, "ending")
    local champion = ending.choice == State.STORY_ENDINGS.CHAMPION
      or story.stage == State.STORY_STAGES.CHAMPION
    if ending.rewardPending == nil then
      ending.rewardPending = champion and State.CHAMPION_REWARD or 0
    end
    if ending.rewardClaimed == nil then
      ending.rewardClaimed = not champion
    end
  end,
}

function State.migrate(value)
  local out = deepCopy(tableOrEmpty(value))
  local schema = number(out.schema, 0)
  if schema > State.SCHEMA then
    -- A newer build owns this schema. Preserve it and every unknown field;
    -- sanitation below only repairs fields this build understands.
    return out, false, "FUTURE SCHEMA"
  end
  for target = schema + 1, State.SCHEMA do
    local migration = assert(State.MIGRATIONS[target],
      "missing Gamble campaign migration " .. tostring(target))
    migration(out)
    out.schema = target
  end
  return out, schema < State.SCHEMA
end

function State.sanitize(value)
  local out = State.migrate(value)
  local savedSchema = number(out.schema, State.SCHEMA)
  local rep = ensureTable(out, "reputation")
  local debt = ensureTable(out, "debt")
  local house = ensureTable(out, "house")
  local arena = ensureTable(out, "arena")
  local story = ensureTable(out, "story")
  local exhibition = ensureTable(story, "exhibition")
  local ending = ensureTable(story, "ending")

  out.schema = savedSchema > State.SCHEMA and savedSchema or State.SCHEMA
  rep.points = number(rep.points, 0)
  rep.rank = VALID_RANKS[rep.rank] and rep.rank or "ROOKIE"
  rep.lifetimeWagered = number(rep.lifetimeWagered, 0)
  rep.completedGames = number(rep.completedGames, 0)
  rep.wins = number(rep.wins, 0)
  rep.losses = number(rep.losses, 0)
  rep.draws = number(rep.draws, 0)
  rep.currentLossStreak = number(rep.currentLossStreak, 0)
  rep.bestLossStreak = number(rep.bestLossStreak, 0)
  rep.byGame = sanitizeGameRows(rep.byGame)
  rep.discoveredGames = sanitizeDiscoveries(rep.discoveredGames)
  rep.rankRewardsClaimed = sanitizeBooleanMap(rep.rankRewardsClaimed, VALID_RANKS)
  rep.pendingRewardCoins = number(rep.pendingRewardCoins, 0)
  rep.pendingRankUps = sanitizeStrings(rep.pendingRankUps, 8, VALID_RANKS)
  rep.pendingRounds = sanitizePending(rep.pendingRounds)
  rep.settledRounds = sanitizeStrings(rep.settledRounds, 128)
  rep.nextRoundId = number(rep.nextRoundId, 0)
  debt.principal = number(debt.principal, 0)
  debt.fees = number(debt.fees, 0)
  debt.status = ({ CLEAR = true, ACTIVE = true, DEFAULT = true })[debt.status]
    and debt.status or (debt.principal + debt.fees > 0 and "ACTIVE" or "CLEAR")
  debt.dueBadge = number(debt.dueBadge, 0)
  debt.lastBadgeFee = number(debt.lastBadgeFee, 0)
  debt.loansTaken = number(debt.loansTaken, 0)
  debt.totalRepaid = number(debt.totalRepaid, 0)
  debt.collectorsTriggered = sanitizeBooleanMap(debt.collectorsTriggered)
  house.status = ({ FAMILY_HOME = true, ROCKET_OWNED = true,
    BUYBACK_PAID = true, RESTORED = true })[house.status]
    and house.status or "FAMILY_HOME"
  house.bailoutClaimed = house.bailoutClaimed == true
  house.buybackPaid = house.buybackPaid == true
  house.rocketBattleWon = house.rocketBattleWon == true
  -- Repair relational state so a partially written or hand-edited campaign
  -- can never expose a battle that cannot complete or a repeat bailout.
  if house.rocketBattleWon or house.status == "RESTORED" then
    house.status = "RESTORED"
    house.bailoutClaimed, house.buybackPaid, house.rocketBattleWon = true, true, true
  elseif house.buybackPaid or house.status == "BUYBACK_PAID" then
    house.status = "BUYBACK_PAID"
    house.bailoutClaimed, house.buybackPaid = true, true
  elseif house.status == "ROCKET_OWNED" then
    house.bailoutClaimed = true
  end
  arena.unlocked = arena.unlocked == true
  arena.stairsRevealed = arena.stairsRevealed == true
  arena.heldParty = sanitizeHeldParty(arena.heldParty)
  arena.securityExit = arena.securityExit == true
  arena.reputation = number(arena.reputation, 0)
  arena.matchesPlayed = number(arena.matchesPlayed, 0)
  arena.wins = number(arena.wins, 0)
  arena.losses = number(arena.losses, 0)
  arena.lifetimeWagered = number(arena.lifetimeWagered, 0)
  arena.lifetimeReturned = number(arena.lifetimeReturned, 0)
  arena.nextMatchId = number(arena.nextMatchId, 0)
  arena.pending = sanitizeArenaPending(arena.pending)
  local history = {}
  for _, row in ipairs(tableOrEmpty(arena.history)) do
    if type(row) == "table" and #history < 12 then
      history[#history + 1] = deepCopy(row)
    end
  end
  arena.history = history
  if savedSchema <= State.SCHEMA or type(story.stage) ~= "string" then
    story.stage = VALID_STORY_STAGES[story.stage]
      and story.stage or State.STORY_STAGES.RUMORS
  end
  local clueAllowlist
  if savedSchema <= State.SCHEMA then clueAllowlist = VALID_STORY_CLUES end
  story.clues = sanitizeBooleanMap(story.clues, clueAllowlist)
  exhibition.attempts = number(exhibition.attempts, 0)
  exhibition.wins = number(exhibition.wins, 0)
  exhibition.lastMatchId = number(exhibition.lastMatchId, 0)
  if exhibition.wins > exhibition.attempts then
    exhibition.attempts = exhibition.wins
  end
  ending.choice = ({ EXPOSE = true, CHAMPION = true })[ending.choice]
    and ending.choice or nil
  ending.rewardPending = number(ending.rewardPending, 0)
  ending.rewardClaimed = ending.rewardClaimed == true
  if savedSchema <= State.SCHEMA or VALID_STORY_STAGES[story.stage] then
    local arenaFound = 0
    for _, id in ipairs({ State.STORY_CLUES.FRAME,
        State.STORY_CLUES.MANIFEST, State.STORY_CLUES.CHART }) do
      if story.clues[id] then arenaFound = arenaFound + 1 end
    end
    if arenaFound == 3 and story.stage == State.STORY_STAGES.RUMORS then
      story.stage = State.STORY_STAGES.LEAD
    end
    local order = STORY_STAGE_ORDER[story.stage] or 1
    if order >= STORY_STAGE_ORDER[State.STORY_STAGES.INVESTIGATION] then
      story.clues[State.STORY_CLUES.LAB_ARCHIVE] = true
    end
    if story.clues[State.STORY_CLUES.LAB_ARCHIVE]
        and order < STORY_STAGE_ORDER[State.STORY_STAGES.INVESTIGATION] then
      story.stage = State.STORY_STAGES.INVESTIGATION
      order = STORY_STAGE_ORDER[story.stage]
    end
    if story.clues[State.STORY_CLUES.MANSION_LOG]
        and order < STORY_STAGE_ORDER[State.STORY_STAGES.INVESTIGATION] then
      story.stage = State.STORY_STAGES.INVESTIGATION
      story.clues[State.STORY_CLUES.LAB_ARCHIVE] = true
      order = STORY_STAGE_ORDER[story.stage]
    end
    if order >= STORY_STAGE_ORDER[State.STORY_STAGES.INVITATION]
        or (story.clues[State.STORY_CLUES.LAB_ARCHIVE]
          and story.clues[State.STORY_CLUES.MANSION_LOG]) then
      if order < STORY_STAGE_ORDER[State.STORY_STAGES.INVITATION] then
        story.stage = State.STORY_STAGES.INVITATION
        order = STORY_STAGE_ORDER[story.stage]
      end
      story.clues[State.STORY_CLUES.LAB_ARCHIVE] = true
      story.clues[State.STORY_CLUES.MANSION_LOG] = true
    end
    if exhibition.wins > 0
        and order < STORY_STAGE_ORDER[State.STORY_STAGES.CHOICE] then
      story.stage = State.STORY_STAGES.CHOICE
      order = STORY_STAGE_ORDER[story.stage]
    end
    if story.stage == State.STORY_STAGES.EXPOSED then
      ending.choice = State.STORY_ENDINGS.EXPOSE
    elseif story.stage == State.STORY_STAGES.CHAMPION then
      ending.choice = State.STORY_ENDINGS.CHAMPION
    elseif ending.choice == State.STORY_ENDINGS.EXPOSE then
      story.stage = State.STORY_STAGES.EXPOSED
    elseif ending.choice == State.STORY_ENDINGS.CHAMPION then
      story.stage = State.STORY_STAGES.CHAMPION
    end
    if ending.choice and exhibition.wins == 0 then
      exhibition.wins = 1
      exhibition.attempts = math.max(exhibition.attempts, 1)
    end
    if ending.choice == State.STORY_ENDINGS.CHAMPION then
      if not ending.rewardClaimed and ending.rewardPending == 0 then
        ending.rewardPending = State.CHAMPION_REWARD
      end
    elseif ending.choice == State.STORY_ENDINGS.EXPOSE then
      ending.rewardPending, ending.rewardClaimed = 0, true
    end
  end
  return out
end

State.copy = deepCopy

function State.new(mod, active)
  local api = {}

  function api.load(create)
    if not active() then return nil end
    local saved = mod.save:get(State.KEY)
    if saved == nil and not create then return nil end
    local value = State.sanitize(saved)
    mod.save:set(State.KEY, value)
    return value
  end

  function api.save(value)
    if not active() then return false end
    mod.save:set(State.KEY, State.sanitize(value))
    return true
  end

  function api.reset()
    if not active() then return false end
    mod.save:set(State.KEY, State.defaults())
    return true
  end

  return api
end

return State
