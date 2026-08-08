-- Gym Leader reward replacement for Gamble Mode. Badges remain vanilla;
-- the leader's TM becomes one persistent, animated case claim.
local GymCases = {}

GymCases.KEY = "gym_case_queue"
GymCases.GYMS = {
  BOULDERBADGE = { order = 1, leader = "BROCK" },
  CASCADEBADGE = { order = 2, leader = "MISTY" },
  THUNDERBADGE = { order = 3, leader = "SURGE" },
  RAINBOWBADGE = { order = 4, leader = "ERIKA" },
  SOULBADGE = { order = 5, leader = "KOGA" },
  MARSHBADGE = { order = 6, leader = "SABRINA" },
  VOLCANOBADGE = { order = 7, leader = "BLAINE" },
  EARTHBADGE = { order = 8, leader = "GIOVANNI" },
}

local POKEMON = {
  { species = "NIDORAN_M", level = 10, from = 1, weight = 190 },
  { species = "NIDORAN_F", level = 10, from = 1, weight = 190 },
  { species = "PIKACHU", level = 12, from = 1, weight = 170 },
  { species = "ABRA", level = 14, from = 2, weight = 150 },
  { species = "EEVEE", level = 18, from = 3, weight = 120 },
  { species = "BULBASAUR", level = 20, from = 4, weight = 90 },
  { species = "CHARMANDER", level = 20, from = 4, weight = 90 },
  { species = "SQUIRTLE", level = 20, from = 4, weight = 90 },
  { species = "OMANYTE", level = 25, from = 5, weight = 65 },
  { species = "KABUTO", level = 25, from = 5, weight = 65 },
  { species = "DRATINI", level = 25, from = 6, weight = 45 },
  { species = "AERODACTYL", level = 35, from = 7, weight = 25 },
}

local function copy(value)
  local out = {}
  for key, item in pairs(value or {}) do out[key] = item end
  return out
end

function GymCases.rules(CaseRules)
  return {
    COST = 0,
    SPIN_DURATION = CaseRules.SPIN_DURATION,
    WINNER_INDEX = CaseRules.WINNER_INDEX,
    STRIP_LENGTH = CaseRules.STRIP_LENGTH,
    CARD_STEP = CaseRules.CARD_STEP,
    REEL_STOP_OFFSET = CaseRules.REEL_STOP_OFFSET,
    choose = CaseRules.choose,
    strip = CaseRules.strip,
  }
end

function GymCases.install(mod, opts)
  local function queue()
    local value = mod.save:get(GymCases.KEY, {})
    return type(value) == "table" and value or {}
  end

  local function saveQueue(value) mod.save:set(GymCases.KEY, value) end

  local function enqueue(reward)
    local rows = queue()
    local gym = GymCases.GYMS[reward.badge]
    local entry = { id = tostring(reward.badge) .. ":" .. tostring(#rows + 1),
      badge = reward.badge, order = gym.order, leader = gym.leader, tm = reward.item }
    rows[#rows + 1] = entry
    saveQueue(rows)
    return entry
  end

  local function remove(entry)
    local rows = queue()
    for index, candidate in ipairs(rows) do
      if candidate.id == entry.id then table.remove(rows, index); break end
    end
    saveQueue(rows)
  end

  local function pool(game, entry)
    local rows = {}
    local victories = require("data.scripts.victories")
    for _, reward in pairs(victories) do
      local gym = reward.badge and GymCases.GYMS[reward.badge]
      if gym and gym.order <= entry.order and game.data.items[reward.item] then
        rows[#rows + 1] = { kind = "item", id = reward.item, quantity = 1,
          label = game.data.items[reward.item].name or reward.item,
          tier = reward.item == entry.tm and "gold" or "rare",
          weight = reward.item == entry.tm and 420 or 90 }
      end
    end
    for _, prize in ipairs(POKEMON) do
      if prize.from <= entry.order and game.data.pokemon[prize.species] then
        local row = copy(prize)
        row.kind, row.tier = "pokemon", prize.from >= 6 and "epic" or "pokemon"
        row.label = game.data.pokemon[prize.species].name or prize.species
        rows[#rows + 1] = row
      end
    end
    return rows
  end

  local function onChosen(entry, reward)
    if not entry then return end
    local rows = queue()
    for _, candidate in ipairs(rows) do
      if candidate.id == entry.id then
        candidate.reward = copy(reward)
        entry.reward = candidate.reward
        break
      end
    end
    saveQueue(rows)
  end

  local Overworld = require("src.world.OverworldController")
  local state = Overworld._blackjackCornerGymCases
  if type(state) ~= "table" then
    state = { vanilla = Overworld.checkVictoryRewards }
    Overworld._blackjackCornerGymCases = state
    function Overworld:checkVictoryRewards(trainerClass, partyIndex)
      if state.handler then return state.handler(self, trainerClass, partyIndex) end
      return state.vanilla(self, trainerClass, partyIndex)
    end
  end

  state.handler = function(ow, trainerClass, partyIndex)
    local victories = require("data.scripts.victories")
    local reward = victories[trainerClass .. "#" .. tostring(partyIndex or 1)]
    local game = require("src.core.Game")
    local enabled = game.data and game.data.screens
      and game.data.screens[opts.screenId] ~= nil
    if not enabled or not opts.active()
        or not (reward and reward.badge and GymCases.GYMS[reward.badge])
        or game.save.flags[reward.flag] then
      return state.vanilla(ow, trainerClass, partyIndex)
    end
    local entry = enqueue(reward)
    if reward.gotFlag then game.save.flags[reward.gotFlag] = true end
    mod.ui.push(game, opts.screenId, { caseData = entry, autoOpen = true,
      oneShot = true, title = "GYM CASE" })
    local item, gotFlag = reward.item, reward.gotFlag
    reward.item, reward.gotFlag = nil, nil
    local ok, result = pcall(state.vanilla, ow, trainerClass, partyIndex)
    reward.item, reward.gotFlag = item, gotFlag
    if not ok then error(result, 0) end
    return result
  end

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" or not opts.active() or #queue() == 0 then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "GYM CASE",
      onSelect = function()
        mod.ui.push(game, opts.screenId, { caseData = queue()[1], autoOpen = true,
          oneShot = true, title = "GYM CASE" })
      end,
    })
  end)

  return {
    queue = queue,
    pool = pool,
    onChosen = onChosen,
    onDelivered = remove,
  }
end

return GymCases
