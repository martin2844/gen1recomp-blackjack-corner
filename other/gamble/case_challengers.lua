return function(World)
local Challengers = {}

Challengers.TRAINERS = {
  male = "OPP_CASE_ACE_M",
  female = "OPP_CASE_ACE_F",
}
Challengers.locations = {
  {
    key = "PEWTER", map = "PEWTER_CITY", x = 9, y = 30,
    trainer = Challengers.TRAINERS.male,
    badge = "BOULDERBADGE", party = 1, sprite = "SPRITE_COOLTRAINER_M",
    intro = "BROCK teaches form.\fI test what happens\nafter form breaks.",
    won = "Solid technique.\fTake the ROCK CASE.\nYou earned the spin.",
  },
  {
    key = "CERULEAN", map = "CERULEAN_CITY", x = 11, y = 13,
    trainer = Challengers.TRAINERS.female,
    badge = "CASCADEBADGE", party = 2, sprite = "SPRITE_COOLTRAINER_F",
    intro = "MISTY tests your\nbalance.\fI drag battles into\ndeeper water.",
    won = "You kept your head.\fThis WATER CASE is\nyours.",
  },
  {
    key = "VERMILION", map = "VERMILION_CITY", x = 25, y = 20,
    trainer = Challengers.TRAINERS.male,
    badge = "THUNDERBADGE", party = 3, sprite = "SPRITE_SAILOR",
    intro = "SURGE fights loud.\fI fight after the\nthunder fades.",
    won = "Current confirmed.\fClaim this ELECTRIC\nCASE.",
  },
  {
    key = "CELADON", map = "CELADON_CITY", x = 26, y = 20,
    trainer = Challengers.TRAINERS.female,
    badge = "RAINBOWBADGE", party = 4, sprite = "SPRITE_BEAUTY",
    intro = "ERIKA is graceful.\fI prefer battles\nwith thorns.",
    won = "You survived the\nthorns.\fSpin this GARDEN\nCASE.",
  },
  {
    key = "FUCHSIA", map = "FUCHSIA_CITY", x = 24, y = 14,
    trainer = Challengers.TRAINERS.male,
    badge = "SOULBADGE", party = 5, sprite = "SPRITE_COOLTRAINER_M",
    intro = "KOGA hides the hit.\fMine lands where you\ncan see it.",
    won = "Discipline beats\npoison.\fTake the VENOM CASE.",
  },
  {
    key = "SAFFRON", map = "SAFFRON_CITY", x = 11, y = 13,
    trainer = Challengers.TRAINERS.female,
    badge = "MARSHBADGE", party = 6, sprite = "SPRITE_COOLTRAINER_F",
    intro = "SABRINA saw you win.\fLet's see whether she\nsaw this battle.",
    won = "The future changed.\fYour PSYCHIC CASE\nremains.",
  },
  {
    key = "CINNABAR", map = "CINNABAR_ISLAND", x = 4, y = 10,
    trainer = Challengers.TRAINERS.male,
    badge = "VOLCANOBADGE", party = 7, sprite = "SPRITE_SUPER_NERD",
    intro = "BLAINE tests facts.\fMy hypothesis is\nthat you lose.",
    won = "Hypothesis rejected.\fTake the VOLCANO\nCASE, colleague.",
  },
  {
    key = "VIRIDIAN", map = "VIRIDIAN_CITY", x = 23, y = 16,
    trainer = Challengers.TRAINERS.male,
    badge = "EARTHBADGE", party = 8, sprite = "SPRITE_GAMBLER",
    intro = "GIOVANNI was the\ncity's final wall.\fI am what waits past\nthe wall.",
    won = "KANTO has nothing\nleft to prove.\fSpin the EARTH CASE.",
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

local function saveId(location)
  return location.map .. "_obj_" .. tostring(location.objectIndex)
end

local function awardKey(location)
  return "case_challenger_awarded_" .. location.key:lower()
end

function Challengers.register(mod, opts)
  for gender, trainerClass in pairs(Challengers.TRAINERS) do
    mod.content.trainers:register(trainerClass, {
      id = trainerClass, name = "CASE ACE",
      basePic = gender == "female" and "OPP_COOLTRAINER_F"
        or "OPP_COOLTRAINER_M",
      baseMoney = 45, parties = Challengers.parties,
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

  mod.events:on("intro.oak_speech.answered", function(ev)
    if ev.saveKey == "gamble_mode" and ev.speech and ev.speech.game then
      sync(ev.speech.game)
    end
  end, -100)
  mod.events:on("game.ready", function(ev) sync(ev and ev.game) end, -100)
  mod.events:on("map.exited", function(ev)
    sync(require("src.core.Game"), ev and ev.toMapId)
  end, -100)

  return {
    locations = Challengers.locations,
    parties = Challengers.parties,
    trainers = Challengers.TRAINERS,
    sync = sync,
    saveId = saveId,
  }
end

return Challengers
end
