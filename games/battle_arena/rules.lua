-- Pure match generation, posted odds, and a compact Gen I-inspired battle
-- simulation for the Underground Arena. The player never supplies a Pokemon:
-- every fighter is an immutable house roster entry.
local Arena = {}

Arena.BETS = { 50, 100, 500, 1000, 5000, 10000 }
Arena.MAX_TURNS = 32
Arena.ACTION_TIME = 0.72
Arena.INTRO_TIME = 1.2
Arena.RESULT_TIME = 0.8

Arena.TIERS = {
  { id = "STREET", label = "STREET", reputation = 0 },
  { id = "ELITE", label = "ELITE", reputation = 250 },
  { id = "RARE", label = "RARE", reputation = 900 },
}

Arena.FIGHTERS = {
  { species = "RATICATE", level = 34, tier = 1,
    moves = { "HYPER_FANG", "QUICK_ATTACK", "SUPER_FANG", "BITE" } },
  { species = "ARBOK", level = 36, tier = 1,
    moves = { "ACID", "BITE", "WRAP", "STRENGTH" } },
  { species = "SANDSLASH", level = 36, tier = 1,
    moves = { "SLASH", "DIG", "EARTHQUAKE", "SWIFT" } },
  { species = "PRIMEAPE", level = 36, tier = 1,
    moves = { "KARATE_CHOP", "LOW_KICK", "THRASH", "ROCK_SLIDE" } },
  { species = "DODRIO", level = 36, tier = 1,
    moves = { "TRI_ATTACK", "DRILL_PECK", "FURY_ATTACK", "BODY_SLAM" } },
  { species = "DEWGONG", level = 36, tier = 1,
    moves = { "AURORA_BEAM", "SURF", "HEADBUTT", "ICE_BEAM" } },

  { species = "NIDOKING", level = 44, tier = 2,
    moves = { "EARTHQUAKE", "THUNDER", "MEGA_PUNCH", "ROCK_SLIDE" } },
  { species = "NIDOQUEEN", level = 44, tier = 2,
    moves = { "BODY_SLAM", "EARTHQUAKE", "BLIZZARD", "DOUBLE_KICK" } },
  { species = "SCYTHER", level = 45, tier = 2,
    moves = { "SLASH", "WING_ATTACK", "QUICK_ATTACK", "SWIFT" } },
  { species = "PINSIR", level = 45, tier = 2,
    moves = { "STRENGTH", "SLASH", "SEISMIC_TOSS", "VICEGRIP" } },
  { species = "TAUROS", level = 45, tier = 2,
    moves = { "BODY_SLAM", "EARTHQUAKE", "BLIZZARD", "HYPER_BEAM" } },
  { species = "KANGASKHAN", level = 45, tier = 2,
    moves = { "COMET_PUNCH", "DIZZY_PUNCH", "SURF", "EARTHQUAKE" } },

  { species = "LAPRAS", level = 52, tier = 3,
    moves = { "SURF", "ICE_BEAM", "BODY_SLAM", "THUNDERBOLT" } },
  { species = "SNORLAX", level = 52, tier = 3,
    moves = { "BODY_SLAM", "HYPER_BEAM", "EARTHQUAKE", "ROCK_SLIDE" } },
  { species = "AERODACTYL", level = 52, tier = 3,
    moves = { "FLY", "BITE", "TAKE_DOWN", "HYPER_BEAM" } },
  { species = "GYARADOS", level = 52, tier = 3,
    moves = { "SURF", "HYDRO_PUMP", "BITE", "HYPER_BEAM" } },
  { species = "DRAGONITE", level = 55, tier = 3,
    moves = { "SLAM", "ICE_BEAM", "THUNDERBOLT", "HYPER_BEAM" } },
  { species = "ALAKAZAM", level = 52, tier = 3,
    moves = { "PSYCHIC_M", "PSYBEAM", "SEISMIC_TOSS", "TRI_ATTACK" } },
}

local SPECIAL = {
  FIRE = true, WATER = true, GRASS = true, ELECTRIC = true,
  ICE = true, PSYCHIC_TYPE = true, DRAGON = true,
}

local function clamp(value, low, high)
  return math.max(low, math.min(high, value))
end

local function rngInt(random, maximum)
  local value = random and random(maximum) or math.random(maximum)
  return clamp(math.floor(tonumber(value) or 1), 1, maximum)
end

local function stat(base, level, hp)
  local value = math.floor(((base + 10) * 2) * level / 100)
  return value + (hp and level + 10 or 5)
end

local function statsFor(def, level)
  local base = assert(def and def.baseStats, "arena fighter has no base stats")
  return {
    hp = stat(base.hp, level, true),
    attack = stat(base.attack, level), defense = stat(base.defense, level),
    speed = stat(base.speed, level), special = stat(base.special, level),
  }
end

local function matchup(data, attackType, defenderTypes)
  local value = 10
  for _, defender in ipairs(defenderTypes or {}) do
    local one = 10
    for _, row in ipairs(data.type_chart and data.type_chart.matchups or {}) do
      if row.attacker == attackType and row.defender == defender then
        one = tonumber(row.multiplier) or 10
        break
      end
    end
    value = math.floor(value * one / 10)
  end
  return value
end

local function moveModel(data, fighter, moveId, defender)
  local move = data.moves and data.moves[moveId]
  if not move or (tonumber(move.power) or 0) <= 0 then return nil end
  local ownTypes = fighter.types or {}
  local stab = (ownTypes[1] == move.type or ownTypes[2] == move.type) and 15 or 10
  local typeX10 = matchup(data, move.type, defender.types)
  local attack = SPECIAL[move.type] and fighter.stats.special or fighter.stats.attack
  local defense = SPECIAL[move.type] and defender.stats.special or defender.stats.defense
  local base = math.floor((math.floor(2 * fighter.level / 5) + 2)
    * move.power * attack / math.max(1, defense) / 50) + 2
  local expected = base * stab * typeX10 * (tonumber(move.accuracy) or 100)
    / 10000
  return {
    id = moveId, name = move.name or moveId, power = move.power,
    accuracy = tonumber(move.accuracy) or 100, type = move.type,
    typeX10 = typeX10, stab = stab, base = math.max(1, base),
    expected = expected,
  }
end

local function hydrate(data, source)
  local pokemon = assert(data.pokemon and data.pokemon[source.species],
    "missing arena species " .. tostring(source.species))
  local fighter = {
    species = source.species, name = pokemon.name or source.species,
    level = source.level, tier = source.tier, types = pokemon.types or {},
  }
  fighter.stats = statsFor(pokemon, fighter.level)
  fighter.maxHP, fighter.hp = fighter.stats.hp, fighter.stats.hp
  fighter.moves = {}
  for _, moveId in ipairs(source.moves) do
    local model = moveModel(data, fighter, moveId, fighter)
    if model then fighter.moves[#fighter.moves + 1] = model end
  end
  return fighter
end

local function refreshMoves(data, fighter, defender, source)
  fighter.moves = {}
  for _, moveId in ipairs(source.moves) do
    local model = moveModel(data, fighter, moveId, defender)
    if model then fighter.moves[#fighter.moves + 1] = model end
  end
  assert(#fighter.moves > 0, "arena fighter has no damaging moves")
end

function Arena.tierFor(reputation)
  reputation = math.max(0, math.floor(tonumber(reputation) or 0))
  local selected = Arena.TIERS[1]
  for _, tier in ipairs(Arena.TIERS) do
    if reputation >= tier.reputation then selected = tier end
  end
  return selected
end

function Arena.wagerLimit(rank)
  return ({ ROOKIE = 0, REGULAR = 0, HIGH_ROLLER = 0,
    VIP = 0, KINGPIN = 10000 })[rank] or 0
end

function Arena.availableBets(rank)
  local out, limit = {}, Arena.wagerLimit(rank)
  for _, bet in ipairs(Arena.BETS) do
    if bet <= limit then out[#out + 1] = bet end
  end
  return out
end

local function combatRating(attacker, defender)
  local best, second = 1, 1
  for _, move in ipairs(attacker.moves) do
    if move.expected > best then second, best = best, move.expected
    elseif move.expected > second then second = move.expected end
  end
  local offense = best * 0.7 + second * 0.3
  local bulk = attacker.maxHP * (attacker.stats.defense + attacker.stats.special) / 2
  local tempo = 1 + attacker.stats.speed / math.max(1,
    attacker.stats.speed + defender.stats.speed) * 0.18
  return math.max(1, offense * math.sqrt(math.max(1, bulk)) * tempo)
end

function Arena.postedOdds(left, right)
  local leftRating, rightRating = combatRating(left, right), combatRating(right, left)
  local leftChance = clamp(leftRating / (leftRating + rightRating), 0.18, 0.82)
  local rightChance = 1 - leftChance
  -- Each side is priced independently with a six-percent house margin.
  local leftOdds = math.max(110, math.floor(94 / leftChance))
  local rightOdds = math.max(110, math.floor(94 / rightChance))
  return { leftOdds, rightOdds }, { leftChance, rightChance }
end

local function chooseMove(fighter, random)
  local total = 0
  for _, move in ipairs(fighter.moves) do
    total = total + math.max(1, math.floor(move.expected * 10))
  end
  local roll = rngInt(random, total)
  for _, move in ipairs(fighter.moves) do
    roll = roll - math.max(1, math.floor(move.expected * 10))
    if roll <= 0 then return move end
  end
  return fighter.moves[1]
end

local function attack(attackerIndex, fighters, random, forcedWinner, forceFinish)
  local defenderIndex = attackerIndex == 1 and 2 or 1
  local attacker, defender = fighters[attackerIndex], fighters[defenderIndex]
  local move = chooseMove(attacker, random)
  local hit = rngInt(random, 100) <= clamp(move.accuracy, 1, 100)
  local damage = 0
  if hit and move.typeX10 > 0 then
    local variance = 84 + rngInt(random, 17)
    damage = math.max(1, math.floor(move.base * move.stab * move.typeX10
      * variance / 10000))
    if forceFinish and attackerIndex == forcedWinner then damage = defender.hp end
    if defenderIndex == forcedWinner and damage >= defender.hp then
      damage = math.max(0, defender.hp - 1)
    end
    defender.hp = math.max(0, defender.hp - damage)
  end
  return {
    attacker = attackerIndex, defender = defenderIndex,
    move = move.name, damage = damage, missed = not hit,
    immune = hit and move.typeX10 == 0,
    typeX10 = move.typeX10, defenderHP = defender.hp,
    protectedWinner = defenderIndex == forcedWinner and defender.hp == 1,
  }
end

local function simulate(fighters, random, forcedWinner)
  local actions, winner, comeback = {}, nil, false
  for _ = 1, Arena.MAX_TURNS do
    local first = fighters[1].stats.speed >= fighters[2].stats.speed and 1 or 2
    if fighters[1].stats.speed == fighters[2].stats.speed and rngInt(random, 2) == 2 then
      first = 3 - first
    end
    for _, attacker in ipairs({ first, 3 - first }) do
      local action = attack(attacker, fighters, random, forcedWinner,
        comeback and attacker == forcedWinner)
      actions[#actions + 1] = action
      if action.protectedWinner then comeback = true end
      if fighters[3 - attacker].hp <= 0 then winner = attacker break end
    end
    if winner then break end
  end
  if not winner then
    winner = forcedWinner
    local loser = 3 - winner
    fighters[loser].hp = 0
    actions[#actions + 1] = {
      attacker = winner, defender = loser, move = "SUDDEN DEATH",
      damage = 0, defenderHP = 0, suddenDeath = true,
    }
  end
  return actions, winner
end

function Arena.newMatch(data, reputation, sequence, random)
  local tier = Arena.tierFor(reputation)
  local pool = {}
  local tierIndex = tier.id == "RARE" and 3 or (tier.id == "ELITE" and 2 or 1)
  for _, fighter in ipairs(Arena.FIGHTERS) do
    if fighter.tier <= tierIndex then pool[#pool + 1] = fighter end
  end
  local leftIndex = rngInt(random, #pool)
  local rightIndex = rngInt(random, #pool - 1)
  if rightIndex >= leftIndex then rightIndex = rightIndex + 1 end
  local leftSource, rightSource = pool[leftIndex], pool[rightIndex]
  local left, right = hydrate(data, leftSource), hydrate(data, rightSource)
  refreshMoves(data, left, right, leftSource)
  refreshMoves(data, right, left, rightSource)
  local odds, chances = Arena.postedOdds(left, right)
  -- The posted probability is the betting contract. Pick the result from that
  -- same model, then make the battle plan tell the selected result as a
  -- plausible fight. Keeping pricing and outcomes on one source of truth
  -- prevents deterministic matchup strength from turning favorites into a
  -- positive-EV coin farm.
  local winner = rngInt(random, 1000000)
      <= math.floor(chances[1] * 1000000 + 0.5) and 1 or 2
  local actions
  actions, winner = simulate({ left, right }, random, winner)
  left.hp, right.hp = left.maxHP, right.maxHP
  return {
    id = math.max(1, math.floor(tonumber(sequence) or 1)), tier = tier.id,
    fighters = { left, right }, odds = odds, chances = chances,
    actions = actions, winner = winner,
  }
end

function Arena.payout(stake, selected, match)
  if not match or selected ~= match.winner then return 0 end
  local odds = match.odds and match.odds[selected] or 0
  return math.floor(math.max(0, tonumber(stake) or 0) * odds / 100)
end

function Arena.formatOdds(value)
  value = math.max(0, math.floor(tonumber(value) or 0))
  return tostring(math.floor(value / 100)) .. "." .. string.format("%02d", value % 100) .. "X"
end

return Arena
