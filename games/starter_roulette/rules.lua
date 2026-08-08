-- Build a balanced roulette from species that are not themselves evolutions.
local Roulette = {}

Roulette.SPIN_DURATION = 3.4
Roulette.STRIP_LENGTH = 21
Roulette.WINNER_INDEX = 17
Roulette.CARD_STEP = 52
Roulette.STOP_OFFSET = (Roulette.WINNER_INDEX - 1) * Roulette.CARD_STEP

local EXCLUDED = {
  ARTICUNO = true, ZAPDOS = true, MOLTRES = true, MEWTWO = true, MEW = true,
}

-- These two legal base-stage rolls otherwise have no damaging move at level 5
-- and can strand a new save before Poké Balls or another party member exist.
Roulette.FALLBACK_MOVES = { ABRA = "CONFUSION", MAGIKARP = "TACKLE" }

function Roulette.pool(pokemonData)
  local evolved = {}
  for _, def in pairs(pokemonData or {}) do
    for _, evolution in ipairs(def.evolutions or {}) do
      evolved[evolution.species] = true
    end
  end
  local pool = {}
  for species, def in pairs(pokemonData or {}) do
    if not evolved[species] and not EXCLUDED[species] and def.baseStats then
      pool[#pool + 1] = species
    end
  end
  table.sort(pool, function(a, b)
    local da, db = pokemonData[a], pokemonData[b]
    return (tonumber(da.dex) or 999) < (tonumber(db.dex) or 999)
      or ((tonumber(da.dex) or 999) == (tonumber(db.dex) or 999) and a < b)
  end)
  return pool
end

function Roulette.choose(pool, random, except)
  assert(#pool > 0, "starter roulette pool cannot be empty")
  random = random or function(maximum) return math.random(maximum) end
  local index = math.max(1, math.min(#pool, math.floor(random(#pool))))
  local choice = pool[index]
  if #pool > 1 and choice == except then
    choice = pool[index % #pool + 1]
  end
  return choice
end

function Roulette.strip(pool, winner, random)
  local out = {}
  for index = 1, Roulette.STRIP_LENGTH do out[index] = Roulette.choose(pool, random) end
  out[Roulette.WINNER_INDEX] = winner
  return out
end

function Roulette.evolveForLevel(pokemonData, species, level)
  local current, guard = species, 0
  while guard < 3 do
    guard = guard + 1
    local def, chosen = pokemonData[current], nil
    for _, evolution in ipairs(def and def.evolutions or {}) do
      if evolution.method == "LEVEL" and level >= (tonumber(evolution.level) or 100) then
        chosen = evolution.species
        break
      elseif not chosen and level >= 36 then
        chosen = evolution.species
      end
    end
    if not chosen or chosen == current then break end
    current = chosen
  end
  return current
end

return Roulette
