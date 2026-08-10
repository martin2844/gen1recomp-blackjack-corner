local Rules = {}

Rules.GAMES = {
  blackjack = true, holdem = true, crash = true, tube_flyer = true,
  prize_case = true, horse_racing = true, plinko = true,
  arena = true,
}

Rules.GAME_ORDER = {
  "blackjack", "holdem", "crash", "tube_flyer",
  "prize_case", "horse_racing", "plinko",
  "arena",
}

Rules.GAME_LABELS = {
  blackjack = "BLACKJACK", holdem = "HOLD'EM", crash = "CRASH",
  tube_flyer = "TUBE FLYER", prize_case = "PRIZE CASE",
  horse_racing = "RACING", plinko = "PLINKO",
  arena = "ARENA",
}

Rules.RANKS = {
  { id = "ROOKIE", label = "ROOKIE", points = 0, badges = 0, reward = 0 },
  { id = "REGULAR", label = "REGULAR", points = 100, badges = 1, reward = 250 },
  { id = "HIGH_ROLLER", label = "HIGH ROLLER", points = 500, badges = 3, reward = 1000 },
  { id = "VIP", label = "VIP", points = 1500, badges = 5, reward = 5000 },
  { id = "KINGPIN", label = "KINGPIN", points = 4000, badges = 8,
    reward = 10000 },
}

Rules.BADGES = {
  "BOULDERBADGE", "CASCADEBADGE", "THUNDERBADGE", "RAINBOWBADGE",
  "SOULBADGE", "MARSHBADGE", "VOLCANOBADGE", "EARTHBADGE",
}

local function rankIndex(id)
  for index, rank in ipairs(Rules.RANKS) do
    if rank.id == id then return index end
  end
  return 1
end

function Rules.badgeCount(game)
  local inventory = game and game.save and game.save.inventory or {}
  local count = 0
  for _, badge in ipairs(Rules.BADGES) do
    if (tonumber(inventory[badge]) or 0) > 0 then count = count + 1 end
  end
  return count
end

function Rules.rankFor(points, badges)
  points, badges = math.max(0, tonumber(points) or 0),
    math.max(0, tonumber(badges) or 0)
  local selected = Rules.RANKS[1]
  for _, rank in ipairs(Rules.RANKS) do
    if not rank.deferred and points >= rank.points and badges >= rank.badges then
      selected = rank
    end
  end
  return selected
end

function Rules.nextRank(currentId)
  local rank = Rules.RANKS[rankIndex(currentId) + 1]
  return rank
end

function Rules.progress(points, badges)
  local current = Rules.rankFor(points, badges)
  local nextRank = Rules.nextRank(current.id)
  return {
    current = current,
    next = nextRank,
    points = math.max(0, math.floor(tonumber(points) or 0)),
    badges = math.max(0, math.floor(tonumber(badges) or 0)),
    blockedByArena = nextRank and nextRank.deferred == true or false,
    blockedByBadges = nextRank and points >= nextRank.points
      and badges < nextRank.badges and not nextRank.deferred or false,
  }
end

function Rules.pointsFor(stake, result, firstForGame)
  stake = math.max(0, math.floor(tonumber(stake) or 0))
  local base = math.min(30, 2 + math.floor(math.sqrt(stake) / 2))
  if result == "win" then base = base + math.max(1, math.floor(base / 2)) end
  if result == "draw" then base = base + 1 end
  if firstForGame then base = base + 10 end
  return base
end

function Rules.rankIndex(id) return rankIndex(id) end

function Rules.atLeast(id, minimum)
  return rankIndex(id) >= rankIndex(minimum)
end

return Rules
