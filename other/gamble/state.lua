local State = {}

State.KEY = "gamble_campaign"
State.SCHEMA = 1

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

local function sanitizeGameRows(value)
  local out = {}
  for gameId, row in pairs(tableOrEmpty(value)) do
    if type(gameId) == "string" and type(row) == "table" then
      out[gameId] = {
        played = number(row.played, 0),
        wins = number(row.wins, 0),
        losses = number(row.losses, 0),
        draws = number(row.draws, 0),
        wagered = number(row.wagered, 0),
        returned = number(row.returned, 0),
      }
    end
  end
  return out
end

local function sanitizePending(value)
  local out = {}
  for token, row in pairs(tableOrEmpty(value)) do
    if type(token) == "string" and type(row) == "table"
        and type(row.gameId) == "string" then
      out[token] = { gameId = row.gameId, stake = number(row.stake, 0) }
    end
  end
  return out
end

local function sanitizeStrings(value, limit)
  local out = {}
  for _, item in ipairs(tableOrEmpty(value)) do
    if type(item) == "string" and #out < (limit or 128) then
      out[#out + 1] = item
    end
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
      pendingRankUps = {},
      pendingRounds = {},
      settledRounds = {},
      nextRoundId = 0,
    },
    -- Reserved now so later releases can migrate additively.
    debt = { balance = 0, defaults = 0 },
    house = { repossessed = false, boughtBack = false },
    arena = { unlocked = false, reputation = 0 },
  }
end

function State.sanitize(value)
  value = tableOrEmpty(value)
  local rep = tableOrEmpty(value.reputation)
  local debt = tableOrEmpty(value.debt)
  local house = tableOrEmpty(value.house)
  local arena = tableOrEmpty(value.arena)
  local out = State.defaults()
  out.reputation.points = number(rep.points, 0)
  out.reputation.rank = type(rep.rank) == "string" and rep.rank or "ROOKIE"
  out.reputation.lifetimeWagered = number(rep.lifetimeWagered, 0)
  out.reputation.completedGames = number(rep.completedGames, 0)
  out.reputation.wins = number(rep.wins, 0)
  out.reputation.losses = number(rep.losses, 0)
  out.reputation.draws = number(rep.draws, 0)
  out.reputation.currentLossStreak = number(rep.currentLossStreak, 0)
  out.reputation.bestLossStreak = number(rep.bestLossStreak, 0)
  out.reputation.byGame = sanitizeGameRows(rep.byGame)
  out.reputation.discoveredGames = tableOrEmpty(rep.discoveredGames)
  out.reputation.rankRewardsClaimed = tableOrEmpty(rep.rankRewardsClaimed)
  out.reputation.pendingRankUps = sanitizeStrings(rep.pendingRankUps, 8)
  out.reputation.pendingRounds = sanitizePending(rep.pendingRounds)
  out.reputation.settledRounds = sanitizeStrings(rep.settledRounds, 128)
  out.reputation.nextRoundId = number(rep.nextRoundId, 0)
  out.debt.balance = number(debt.balance, 0)
  out.debt.defaults = number(debt.defaults, 0)
  out.house.repossessed = house.repossessed == true
  out.house.boughtBack = house.boughtBack == true
  out.arena.unlocked = arena.unlocked == true
  out.arena.reputation = number(arena.reputation, 0)
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
