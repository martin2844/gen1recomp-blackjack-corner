local State = {}

State.KEY = "gamble_campaign"
State.SCHEMA = 2

local VALID_RANKS = {
  ROOKIE = true, REGULAR = true, HIGH_ROLLER = true,
  VIP = true, KINGPIN = true,
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
    arena = { unlocked = false, reputation = 0 },
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
  arena.unlocked = arena.unlocked == true
  arena.reputation = number(arena.reputation, 0)
  return out
end

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
