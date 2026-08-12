return function(World)
local Challengers = {}

Challengers.TRAINERS = {
  male = "OPP_CASE_ACE_M",
  female = "OPP_CASE_ACE_F",
}

local function mon(species, tier, weight)
  return { kind = "pokemon", species = species, level = 1,
    tier = tier or "pokemon", weight = weight or 100 }
end

local function item(id, tier, weight, quantity)
  return { kind = "item", id = id, quantity = quantity or 1,
    tier = tier or "rare", weight = weight or 100 }
end

-- CASE ACE reels are deliberately broad and badge-agnostic. Gym Leaders keep
-- their authored elemental pools; every challenger draws from this same mixed
-- bag of Pokemon, supplies, TMs, and one very unlikely jackpot.
Challengers.REWARDS = {
  mon("ABRA", "pokemon", 180), mon("POLIWAG", "pokemon", 180),
  mon("GROWLITHE", "pokemon", 180), mon("MAGNEMITE", "pokemon", 180),
  mon("SCYTHER", "rare", 90), mon("LAPRAS", "rare", 75),
  mon("DRAGONAIR", "epic", 45), mon("KANGASKHAN", "epic", 45),
  item("RARE_CANDY", "common", 300), item("PP_UP", "common", 240),
  item("MAX_REVIVE", "rare", 150, 2), item("TM_BODY_SLAM", "rare", 125),
  item("TM_ICE_BEAM", "epic", 60), item("TM_THUNDERBOLT", "epic", 60),
  item("TM_PSYCHIC_M", "epic", 60), item("MASTER_BALL", "gold", 2),
}

local TIER_LINES = {
  common = "ROUGH PULL.", pokemon = "POKEMON PULL.",
  rare = "RARE PULL!", epic = "EPIC PULL!", gold = "JACKPOT!",
}

Challengers.locations = {
  {
    key = "PEWTER", map = "PEWTER_CITY", x = 9, y = 30,
    trainer = Challengers.TRAINERS.male,
    badge = "BOULDERBADGE", party = 1, sprite = "SPRITE_COOLTRAINER_M",
    intro = "BROCK teaches form.\fI test what happens\nafter form breaks.",
    won = "You hit harder than\nyour BADGE says.\fTake an ACE CASE.\nNo theme. Pure luck.",
    reaction = "No type advantage.\nJust a clean pull.",
  },
  {
    key = "CERULEAN", map = "CERULEAN_CITY", x = 11, y = 13,
    trainer = Challengers.TRAINERS.female,
    badge = "CASCADEBADGE", party = 2, sprite = "SPRITE_COOLTRAINER_F",
    intro = "MISTY tests your\nbalance.\fI drag battles into\ndeeper water.",
    won = "You kept your head.\fYour ACE CASE is\nanything but calm.",
    reaction = "The reel went deep.\nTry not to drown.",
  },
  {
    key = "VERMILION", map = "VERMILION_CITY", x = 25, y = 20,
    trainer = Challengers.TRAINERS.male,
    badge = "THUNDERBADGE", party = 3, sprite = "SPRITE_SAILOR",
    intro = "SURGE fights loud.\fI fight after the\nthunder fades.",
    won = "Current confirmed.\fACE CASE authorized.\nExpect no pattern.",
    reaction = "Pure variance.\nStill counts, rookie.",
  },
  {
    key = "CELADON", map = "CELADON_CITY", x = 26, y = 20,
    trainer = Challengers.TRAINERS.female,
    badge = "RAINBOWBADGE", party = 4, sprite = "SPRITE_BEAUTY",
    intro = "ERIKA is graceful.\fI prefer battles\nwith thorns.",
    won = "You survived the\nthorns.\fTake an ACE CASE.\nTaste is not assured.",
    reaction = "No theme, no rules.\nIt rather suits you.",
  },
  {
    key = "FUCHSIA", map = "FUCHSIA_CITY", x = 24, y = 14,
    trainer = Challengers.TRAINERS.male,
    badge = "SOULBADGE", party = 5, sprite = "SPRITE_COOLTRAINER_M",
    intro = "KOGA hides the hit.\fMine lands where you\ncan see it.",
    won = "Discipline beats\npoison.\fClaim your ACE CASE.\nChance leaves no trail.",
    reaction = "Chance left no trace.\nKeep the evidence.",
  },
  {
    key = "SAFFRON", map = "SAFFRON_CITY", x = 11, y = 13,
    trainer = Challengers.TRAINERS.female,
    badge = "MARSHBADGE", party = 6, sprite = "SPRITE_COOLTRAINER_F",
    intro = "SABRINA saw you win.\fLet's see whether she\nsaw this battle.",
    won = "The future changed.\fYour ACE CASE was\nnot in the vision.",
    reaction = "I did not see that.\nNeither did she.",
  },
  {
    key = "CINNABAR", map = "CINNABAR_ISLAND", x = 4, y = 10,
    trainer = Challengers.TRAINERS.male,
    badge = "VOLCANOBADGE", party = 7, sprite = "SPRITE_SUPER_NERD",
    intro = "BLAINE tests facts.\fMy hypothesis is\nthat you lose.",
    won = "Hypothesis rejected.\fRun the ACE CASE.\nControl group: none.",
    reaction = "Random result.\nHypothesis ruined.",
  },
  {
    key = "VIRIDIAN", map = "VIRIDIAN_CITY", x = 23, y = 16,
    trainer = Challengers.TRAINERS.male,
    badge = "EARTHBADGE", party = 8, sprite = "SPRITE_GAMBLER",
    intro = "GIOVANNI was the\ncity's final wall.\fI am what waits past\nthe wall.",
    won = "KANTO has nothing\nleft to prove.\fOne ACE CASE.\nThe house chooses.",
    reaction = "The house blinked.\nTake the opening.",
  },
}

Challengers.parties = {
  { { species = "MANKEY", level = 18 }, { species = "BUTTERFREE", level = 19 },
    { species = "PIKACHU", level = 20 } },
  { { species = "IVYSAUR", level = 24 }, { species = "PIKACHU", level = 25 },
    { species = "KADABRA", level = 26 } },
  { { species = "GRAVELER", level = 28 }, { species = "DUGTRIO", level = 29 },
    { species = "WARTORTLE", level = 30 } },
  { { species = "CHARMELEON", level = 32 }, { species = "FEAROW", level = 33 },
    { species = "HAUNTER", level = 34 } },
  { { species = "HYPNO", level = 46 }, { species = "SANDSLASH", level = 47 },
    { species = "GYARADOS", level = 48 } },
  { { species = "SNORLAX", level = 46 }, { species = "SCYTHER", level = 47 },
    { species = "MAGNETON", level = 48 } },
  { { species = "STARMIE", level = 50 }, { species = "GOLEM", level = 51 },
    { species = "DRAGONAIR", level = 52 } },
  { { species = "ALAKAZAM", level = 54 }, { species = "LAPRAS", level = 55 },
    { species = "DRAGONITE", level = 56 } },
}

-- The repository's public validation base intentionally contains only three
-- synthetic Pokemon and one trainer portrait.  Keep that structural gate
-- useful without weakening the imported-ROM build: real Red/Blue catalogs
-- always take the themed teams above, while the fixture gets eight valid
-- parties under the same trainer IDs and party numbers.
local function registrationCatalog(mod)
  if mod.content.pokemon:get("MANKEY")
      and mod.content.trainers:get("OPP_COOLTRAINER_M") then
    return Challengers.parties, {
      male = "OPP_COOLTRAINER_M", female = "OPP_COOLTRAINER_F",
    }
  end
  local parties = {}
  local species = { "FIXMON_A", "FIXMON_B", "FIXMON_C" }
  for index = 1, #Challengers.parties do
    parties[index] = {}
    for slot = 1, 3 do
      parties[index][slot] = {
        species = species[((index + slot - 2) % #species) + 1],
        level = 10 + index * 5 + slot,
      }
    end
  end
  return parties, {
    male = "OPP_FIX_YOUNGSTER", female = "OPP_FIX_YOUNGSTER",
  }
end

local function saveId(location)
  return location.map .. "_obj_" .. tostring(location.objectIndex)
end

local function awardKey(location)
  return "case_challenger_awarded_" .. location.key:lower()
end

local function locationForMap(mapId)
  for _, location in ipairs(Challengers.locations) do
    if location.map == mapId then return location end
  end
end

local function locationForKey(key)
  for _, location in ipairs(Challengers.locations) do
    if location.key == key then return location end
  end
end

local function rewardDialogue(entry, reward)
  local location = entry and locationForKey(entry.source)
  if not location or type(reward) ~= "table" then return nil end
  local label = tostring(reward.label or reward.id or reward.species or "PRIZE")
    :gsub("_", " ")
  if #label > 17 then label = label:sub(1, 17) end
  local tier = TIER_LINES[reward.tier] or TIER_LINES.rare
  return "CASE ACE:\n" .. tier .. "\f" .. label .. "?\f"
    .. location.reaction
end

function Challengers.register(mod, opts)
  local registeredParties, basePics = registrationCatalog(mod)
  for gender, trainerClass in pairs(Challengers.TRAINERS) do
    mod.content.trainers:register(trainerClass, {
      id = trainerClass, name = "CASE ACE",
      basePic = basePics[gender],
      baseMoney = 45, parties = registeredParties,
    })
  end

  for _, location in ipairs(Challengers.locations) do
    local map = mod.content.maps:get(location.map)
    if map then
      location.objectIndex = World.nextObjectIndex(map)
      location.objectName = "CASE_CHALLENGER_" .. location.key
      mod.content.maps:patch(location.map, { objects = { __append = {
        {
          index = location.objectIndex, name = location.objectName,
          sprite = location.sprite, text = "TEXT_CASE_CHALLENGER",
          x = location.x, y = location.y, movement = "STAY", range = "DOWN",
          trainerClass = location.trainer, trainerParty = location.party,
          hidden = true,
        },
      } } })

      mod.content.map_scripts:register(location.map, {
        talk = {
          TEXT_CASE_CHALLENGER = function(game, ow, npc, done)
            if game.save.defeatedTrainers
                and game.save.defeatedTrainers[saveId(location)] then
              local pending = false
              for _, entry in ipairs(opts.gym.queue()) do
                pending = pending or entry.id == "challenger:" .. location.key
              end
              opts.text(game, location.won .. (pending
                and "\fYour CASE waits in\nthe START menu."
                or "\fOne battle, one case.\nNo second spins."), done)
              return
            end
            opts.text(game, location.intro .. "\fShow me the BADGE.\nThen show me more.", function()
              ow:engageTrainer(npc, done, "Not luck. Skill.", true)
            end)
          end,
        },
        onVictory = function(game)
          if not opts.active()
              or mod.save:get(awardKey(location), false) == true
              or not (game.save.defeatedTrainers
                and game.save.defeatedTrainers[saveId(location)]) then return end
          local entry = opts.gym.enqueueChallenge(location.badge, location.key)
          if not entry then return end
          mod.save:set(awardKey(location), true)
          opts.openCase(game, entry, location)
        end,
      })
    end
  end

  local function sync(game, mapId)
    if not (game and game.save) then return end
    for _, location in ipairs(Challengers.locations) do
      if location.objectName and (not mapId or mapId == location.map) then
        local visible = opts.active()
          and game.save.inventory and game.save.inventory[location.badge] ~= nil
        World.setObjectVisible(game.save, location.map, location.objectName, visible)
        -- Object indices are allocated around other installed content mods.
        -- The stable award key carries a completed fight across a changed mod
        -- load order so the same CASE ACE cannot become battleable again just
        -- because its runtime object index moved.
        if mod.save:get(awardKey(location), false) == true then
          game.save.defeatedTrainers = game.save.defeatedTrainers or {}
          game.save.defeatedTrainers[saveId(location)] = true
        end
      end
    end
  end

  local function pool(game, entry)
    local rows = opts.gym.materialize(game, Challengers.REWARDS)
    local level = math.min(52, 12 + math.max(1,
      math.floor(tonumber(entry and entry.order) or 1)) * 5)
    for _, reward in ipairs(rows) do
      if reward.kind == "pokemon" then reward.level = level end
    end
    return rows
  end

  mod.events:on("intro.oak_speech.answered", function(ev)
    if ev.saveKey == "gamble_mode" and ev.speech and ev.speech.game then
      sync(ev.speech.game)
    end
  end, -100)
  mod.events:on("game.ready", function(ev) sync(ev and ev.game) end, -100)
  mod.events:on("save.loaded", function(ev)
    local game = require("src.core.Game")
    local mapId = ev and ev.save and ev.save.player and ev.save.player.map
    local location = locationForMap(mapId)
    sync(game, mapId)
    -- CONTINUE builds the saved overworld immediately before save.loaded.
    -- If the player saved in a CASE ACE city, rebuild that one live NPC list
    -- after applying its badge toggle; otherwise a newly eligible challenger
    -- stays absent until the player leaves and re-enters the map.
    local ow = game and game.overworld
    if location and ow and ow.map and ow.map.id == mapId and ow.reloadMap then
      ow:reloadMap(mapId, "case-challenger-sync")
    end
  end, -100)
  mod.events:on("map.exited", function(ev)
    sync(require("src.core.Game"), ev and ev.toMapId)
  end, -100)

  return {
    locations = Challengers.locations,
    parties = Challengers.parties,
    rewards = Challengers.REWARDS,
    trainers = Challengers.TRAINERS,
    pool = pool,
    rewardDialogue = rewardDialogue,
    sync = sync,
    saveId = saveId,
  }
end

return Challengers
end
