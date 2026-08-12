-- Gym Leader reward replacement for Gamble Mode. Badges remain vanilla;
-- leaders award themed cases while regional challengers share the same
-- replay-safe queue without inheriting Gym pools or Gym Leader dialogue.
local GymCases = {}

GymCases.KEY = "gym_case_queue"
GymCases.NEXT_KEY = "gym_case_next_id"

local function mon(species, level, tier, weight, label)
  return { kind = "pokemon", species = species, level = level,
    tier = tier or "pokemon", weight = weight or 100, label = label }
end

local function item(id, tier, weight, quantity, label)
  return { kind = "item", id = id, quantity = quantity or 1,
    tier = tier or "rare", weight = weight or 100, label = label }
end

-- Pools are deliberately local to each badge. No species or item is repeated
-- within a pool, and the reel builder below prevents adjacent duplicate cards.
GymCases.GYMS = {
  BOULDERBADGE = {
    order = 1, leader = "BROCK", theme = "ROCK",
    dialogue = "That was a solid\nvictory.\fEvery battle is a\nlesson, {PLAYER}.\fYou earned a\nROCK CASE.\fGive it a spin and\nlearn what luck\nhas in store.\fGood luck!",
    rewards = {
      mon("GEODUDE", 14), mon("ONIX", 14), mon("RHYHORN", 15),
      mon("OMANYTE", 15, "rare", 55), item("TM_BIDE", "gold", 120),
      item("TM_ROCK_SLIDE"), item("TM_DIG"), item("MOON_STONE", "epic", 50),
      item("X_DEFEND", "common", 150), item("SUPER_POTION", "common", 150),
    },
  },
  CASCADEBADGE = {
    order = 2, leader = "MISTY", theme = "WATER",
    dialogue = "You really made\na splash!\fI like a trainer\nwho surprises me.\fYou earned a\nWATER CASE.\fGive it a spin.\nLet's see if luck\nlikes you too!\fGood luck!",
    rewards = {
      mon("PSYDUCK", 21), mon("POLIWAG", 21), mon("STARYU", 22),
      mon("HORSEA", 22), mon("LAPRAS", 23, "epic", 35),
      item("TM_BUBBLEBEAM", "gold", 120), item("TM_WATER_GUN"),
      item("TM_ICE_BEAM", "epic", 50), item("WATER_STONE", "rare", 80),
      item("SUPER_POTION", "common", 150),
    },
  },
  THUNDERBADGE = {
    order = 3, leader = "SURGE", theme = "ELECTRIC",
    dialogue = "Outstanding work,\nsoldier!\fYou earned an\nELECTRIC CASE.\fStep up and spin\nfor your prize.\fThat's an order!\nGood luck!",
    rewards = {
      mon("PIKACHU", 25), mon("MAGNEMITE", 25), mon("VOLTORB", 25),
      mon("ELECTABUZZ", 26, "rare", 60), mon("JOLTEON", 27, "epic", 35),
      item("TM_THUNDERBOLT", "gold", 120), item("TM_THUNDER", "epic", 55),
      item("TM_THUNDER_WAVE"), item("THUNDER_STONE", "rare", 80),
      item("X_SPEED", "common", 150),
    },
  },
  RAINBOWBADGE = {
    order = 4, leader = "ERIKA", theme = "GRASS",
    dialogue = "What a lovely\nbattle.\fYou earned a\nGARDEN CASE.\fGive it a gentle\nspin.\fMay good fortune\nbloom for you.",
    rewards = {
      mon("ODDISH", 31), mon("BELLSPROUT", 31), mon("EXEGGCUTE", 32),
      mon("TANGELA", 33, "rare", 60), mon("PARAS", 31),
      item("TM_MEGA_DRAIN", "gold", 120), item("TM_SOLARBEAM", "epic", 55),
      item("TM_DOUBLE_TEAM"), item("LEAF_STONE", "rare", 80),
      item("FULL_HEAL", "common", 150),
    },
  },
  SOULBADGE = {
    order = 5, leader = "KOGA", theme = "VENOM",
    dialogue = "Your skill pierced\nevery illusion.\fYou earned a\nVENOM CASE.\fSpin without fear.\nFortune favors\ndiscipline.\fGood luck.",
    rewards = {
      mon("KOFFING", 40), mon("GRIMER", 40), mon("VENONAT", 41),
      mon("SCYTHER", 42, "epic", 45), mon("PINSIR", 42, "epic", 45),
      item("TM_TOXIC", "gold", 120), item("TM_RAGE"), item("TM_REST"),
      item("FULL_HEAL", "common", 150), item("MAX_REVIVE", "rare", 70),
    },
  },
  MARSHBADGE = {
    order = 6, leader = "SABRINA", theme = "PSYCHIC",
    dialogue = "I did foresee\nyour victory...\fBut even I cannot\nread pure chance.\fThis PSYCHIC CASE\nis yours.\fSpin it, and reveal\nyour fate.\fGood luck.",
    rewards = {
      mon("ABRA", 42), mon("DROWZEE", 42), mon("MR_MIME", 43, "rare", 60),
      mon("JYNX", 43, "rare", 60), mon("SLOWPOKE", 42),
      item("TM_PSYWAVE", "gold", 120), item("TM_PSYCHIC_M", "epic", 55),
      item("TM_TELEPORT"), item("PP_UP", "rare", 80),
      item("MAX_REVIVE", "rare", 70),
    },
  },
  VOLCANOBADGE = {
    order = 7, leader = "BLAINE", theme = "FIRE",
    dialogue = "Hah! A blazing\nvictory!\fYou earned a\nVOLCANO CASE.\fFinal question:\nwhat prize is\ninside?\fSpin it and find\nout! Good luck!",
    rewards = {
      mon("GROWLITHE", 47), mon("PONYTA", 47), mon("MAGMAR", 48, "rare", 60),
      mon("VULPIX", 47), mon("CHARMANDER", 45, "epic", 40),
      item("TM_FIRE_BLAST", "gold", 120), item("FIRE_STONE", "rare", 80),
      item("TM_REFLECT"), item("TM_SUBSTITUTE", "epic", 55),
      item("RARE_CANDY", "rare", 70),
    },
  },
  EARTHBADGE = {
    order = 8, leader = "GIOVANNI", theme = "EARTH",
    dialogue = "You have earned\nthis victory.\fI do not hand out\ncommon trinkets.\fTake this EARTH\nCASE and spin it.\fLet chance decide\nwhat power you\nleave with.",
    rewards = {
      mon("DUGTRIO", 52), mon("PERSIAN", 52), mon("KANGASKHAN", 53, "rare", 60),
      mon("RHYDON", 54, "epic", 45), mon("TAUROS", 53, "epic", 45),
      item("TM_EARTHQUAKE", "gold", 120), item("TM_FISSURE", "epic", 55),
      item("TM_DIG"), item("TM_TRI_ATTACK", "rare", 80),
      item("MASTER_BALL", "gold", 4),
    },
  },
}

local function copy(value)
  local out = {}
  for key, entry in pairs(value or {}) do out[key] = entry end
  return out
end

local function rewardKey(reward)
  return tostring(reward.kind) .. ":" .. tostring(reward.id or reward.species)
end

function GymCases.rules(CaseRules)
  local function strip(pool, winner, random)
    local rows, previous = {}, nil
    for index = 1, CaseRules.STRIP_LENGTH do
      local chosen
      if index == CaseRules.WINNER_INDEX then
        chosen = winner
      else
        local eligible = {}
        for _, reward in ipairs(pool) do
          local key = rewardKey(reward)
          if key ~= previous
              and not (index == CaseRules.WINNER_INDEX - 1
                and key == rewardKey(winner)) then
            eligible[#eligible + 1] = reward
          end
        end
        chosen = CaseRules.choose(#eligible > 0 and eligible or pool, random)
      end
      rows[index], previous = chosen, rewardKey(chosen)
    end
    return rows
  end
  return {
    COST = 0,
    SPIN_DURATION = CaseRules.SPIN_DURATION,
    WINNER_INDEX = CaseRules.WINNER_INDEX,
    STRIP_LENGTH = CaseRules.STRIP_LENGTH,
    CARD_STEP = CaseRules.CARD_STEP,
    REEL_STOP_OFFSET = CaseRules.REEL_STOP_OFFSET,
    choose = CaseRules.choose,
    strip = strip,
  }
end

function GymCases.install(mod, opts)
  local function queue()
    local value = mod.save:get(GymCases.KEY, {})
    return type(value) == "table" and value or {}
  end

  local function saveQueue(value) mod.save:set(GymCases.KEY, value) end

  local function enqueue(reward, requestedId)
    local gym = reward and GymCases.GYMS[reward.badge]
    if not gym then return nil, false end
    local rows = queue()
    if requestedId then
      for _, candidate in ipairs(rows) do
        if candidate.id == requestedId then return candidate, false end
      end
    end
    local sequence = math.max(1, math.floor(tonumber(
      mod.save:get(GymCases.NEXT_KEY, 1)) or 1))
    local id = requestedId or (tostring(reward.badge) .. ":" .. tostring(sequence))
    mod.save:set(GymCases.NEXT_KEY, sequence + 1)
    local entry = { id = id, badge = reward.badge, order = gym.order,
      leader = gym.leader, tm = reward.item, source = reward.source,
      kind = reward.kind }
    rows[#rows + 1] = entry
    saveQueue(rows)
    return entry, true
  end

  local function enqueueChallenge(badge, sourceId)
    return enqueue({ badge = badge, source = sourceId, kind = "case_ace" },
      "challenger:" .. tostring(sourceId))
  end

  -- v0.7.0-v0.7.3 challenger claims predate the explicit kind field. The
  -- stable ID keeps those pending cases on the ACE path after an upgrade.
  local function isChallenge(entry)
    return type(entry) == "table" and (entry.kind == "case_ace"
      or tostring(entry.id or ""):match("^challenger:") ~= nil)
  end

  local function remove(entry)
    local rows = queue()
    for index, candidate in ipairs(rows) do
      if candidate.id == entry.id then table.remove(rows, index); break end
    end
    saveQueue(rows)
  end

  local function materialize(game, rewards)
    local rows = {}
    for _, reward in ipairs(rewards or {}) do
      if reward.kind == "item" and game.data.items[reward.id] then
        local row = copy(reward)
        row.label = row.label or game.data.items[row.id].name or row.id
        rows[#rows + 1] = row
      elseif reward.kind == "pokemon" and game.data.pokemon[reward.species] then
        local row = copy(reward)
        row.label = row.label or game.data.pokemon[row.species].name or row.species
        rows[#rows + 1] = row
      end
    end
    return rows
  end

  local function pool(game, entry)
    if isChallenge(entry) then return {} end
    local gym = entry and GymCases.GYMS[entry.badge]
    return materialize(game, gym and gym.rewards)
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

  local function leaderDialogue(badge)
    local gym = GymCases.GYMS[badge]
    return gym and gym.dialogue or nil
  end

  local function rewardDialogue(entry, reward)
    if isChallenge(entry) then return nil end
    local gym = entry and GymCases.GYMS[entry.badge]
    if not gym or not (opts.comments and opts.comments.forReward) then return nil end
    return opts.comments.forReward({ badge = entry.badge, leader = gym.leader }, reward)
  end

  local function victoryDialogue(game, reward)
    local lines, text = {}, game.data.text or {}
    for _, label in ipairs(reward.dialogue or {}) do
      if text[label] and text[label] ~= "" then lines[#lines + 1] = text[label] end
    end
    lines[#lines + 1] = leaderDialogue(reward.badge)
      or "You earned a\nGYM CASE.\fGive it a spin.\nGood luck!"
    return table.concat(lines, "\f")
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
    local originalItem, gotFlag, dialogue = reward.item, reward.gotFlag, reward.dialogue
    reward.item, reward.gotFlag, reward.dialogue = nil, nil, {}
    local ok, result = pcall(state.vanilla, ow, trainerClass, partyIndex)
    reward.item, reward.gotFlag, reward.dialogue = originalItem, gotFlag, dialogue
    if not ok then error(result, 0) end
    game.stack:push(mod.ui.TextBox.new(game, victoryDialogue(game, reward), function()
      mod.ui.push(game, opts.screenId, { caseData = entry, autoOpen = true,
        oneShot = true, title = "GYM CASE" })
    end))
    return result
  end

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" or not opts.active() or #queue() == 0 then return out end
    local pending = queue()[1]
    local title = isChallenge(pending) and "ACE CASE" or "GYM CASE"
    return mod.ui.insertBefore(out, "SAVE", {
      label = title,
      onSelect = function()
        mod.ui.push(game, opts.screenId, { caseData = pending, autoOpen = true,
          oneShot = true, title = title })
      end,
    })
  end)

  return {
    queue = queue,
    pool = pool,
    materialize = materialize,
    definitions = GymCases.GYMS,
    enqueueChallenge = enqueueChallenge,
    isChallenge = isChallenge,
    leaderDialogue = leaderDialogue,
    rewardDialogue = rewardDialogue,
    onChosen = onChosen,
    onDelivered = remove,
  }
end

return GymCases
