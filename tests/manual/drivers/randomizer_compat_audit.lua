-- Native compatibility gate for ciddmandude/PokemonRecompRandomizer. Run with
-- the real pokemon_randomizer mod installed and a fresh identity. It exercises
-- both new-game setup hooks, then proves that Gamble Mode owns only Oak's
-- roulette/rival projection while Randomizer still owns wild and trainer data.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local ChoiceBox = require("src.ui.ChoiceBox")
  local Runtime = require("src.mods.Runtime")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local gamble = (os.getenv("GAMBLE_CHOICE") or "yes"):lower() == "yes"

  local function pass(id, note) U.log("PASS", id, note or "") end
  local function hasOwner(name, owner)
    for _, entry in ipairs((game.mods.hooks.chains or {})[name] or {}) do
      if entry.owner == owner then return true end
    end
    return false
  end

  U.wait(5)
  U.tap(game, "start")
  U.wait(10)
  U.tap(game, "a")
  U.wait(5)
  U.tap(game, "a")

  local questions, presetChosen, seenChoices = 0, false, {}
  for _ = 1, 2400 do
    local top = game.stack:top()
    if getmetatable(top) == ChoiceBox then
      if seenChoices[top] then
        U.wait(2)
      else
      seenChoices[top] = true
      questions = questions + 1
      assert(U.shot(game, ("%s/setup-question-%d.png"):format(
        shotDir, questions)))
      if questions == 1 then
        -- TURN ON THE RANDOMIZER? defaults to NO.
        U.tap(game, "up"); U.tap(game, "a")
      elseif questions == 2 then
        -- USE A SETTINGS PRESET? defaults to YES.
        U.tap(game, "a")
      elseif questions == 3 then
        -- Blackjack Corner's GAMBLE MODE prompt defaults to NO.
        if gamble then U.tap(game, "up") end
        U.tap(game, "a")
      else
        error("unexpected new-game question " .. questions)
      end
      U.wait(20)
      end
    elseif top and top.title == "RANDOMIZER PRESET" then
      -- First preset is a supported, non-vanilla randomized run.
      U.tap(game, "a")
      presetChosen = true
      U.wait(30)
    elseif questions >= 3 and game.overworld and top == game.overworld then
      break
    else
      U.tap(game, "a")
      U.wait(2)
    end
  end

  assert(questions == 3 and presetChosen,
    "the composed Randomizer/Gamble setup flow did not complete")
  assert(game.overworld and game.stack:top() == game.overworld,
    "composed new-game setup did not reach the overworld")
  local randomSave = assert(game.mods.modSave.pokemon_randomizer,
    "Randomizer save namespace missing")
  local blackjackSave = assert(game.mods.modSave.blackjack_corner,
    "Blackjack Corner save namespace missing")
  assert(randomSave.enabled == true, "Randomizer was not enabled")
  assert(blackjackSave.gamble_mode == gamble,
    "Gamble Mode answer was not persisted")
  pass("COMPAT-SETUP", "both new-game setup hooks completed")

  assert(hasOwner("encounter.species", "pokemon_randomizer"),
    "Randomizer wild hook is missing")
  assert(hasOwner("trainer.party", "pokemon_randomizer"),
    "Randomizer trainer hook is missing")
  assert(hasOwner("trainer.party", "blackjack_corner"),
    "Blackjack rival projection is missing")

  local wildChanged = false
  for index, species in ipairs({ "RATTATA", "PIDGEY", "CATERPIE", "WEEDLE",
      "ZUBAT", "GEODUDE", "ODDISH", "ABRA" }) do
    local source = { species = species, level = 3 + index, slotIndex = index }
    local resolved = Runtime.call("encounter.species", function(value) return value end,
      source, { terrain = "grass", mapId = "ROUTE_1" })
    wildChanged = wildChanged or (resolved and resolved.species ~= species)
  end
  assert(wildChanged, "the real Randomizer did not project any sampled wild slot")

  local vanillaParty = { { species = "CATERPIE", level = 6 },
    { species = "WEEDLE", level = 7 } }
  local randomizedParty = Runtime.call("trainer.party",
    function(_, _, party) return party end,
    "OPP_BUG_CATCHER", 1, vanillaParty)
  local trainerChanged = #randomizedParty ~= #vanillaParty
  for index, slot in ipairs(randomizedParty or {}) do
    local prior = vanillaParty[index]
    trainerChanged = trainerChanged or not prior
      or slot.species ~= prior.species or slot.level ~= prior.level
  end
  assert(trainerChanged, "the real Randomizer did not project the sampled trainer")
  pass("COMPAT-RANDOMIZER", "wild encounters and ordinary trainers remain randomized")

  game.save.flags = game.save.flags or {}
  game.save.flags.EVENT_GOT_STARTER = nil
  game.save.flags.EVENT_OAK_ASKED_TO_CHOOSE_MON = true
  game.save.party = {}
  U.teleport(game, "OAKS_LAB", 6, 4, "up")

  local rouletteObjects = {}
  for _, object in ipairs(game.data.maps.OAKS_LAB.objects or {}) do
    if object.text == "TEXT_BLACKJACK_CORNER_STARTER_ROULETTE" then
      rouletteObjects[#rouletteObjects + 1] = object
    end
  end
  if not gamble then
    assert(#rouletteObjects == 0,
      "disabled Gamble Mode retained the private roulette binding")
    pass("COMPAT-VANILLA", "Randomizer keeps Oak's starter balls when Gamble Mode is off")
    love.event.quit(0)
    return
  end

  assert(#rouletteObjects >= 1,
    "Gamble Mode did not reclaim Randomizer-modified starter objects")
  local target = rouletteObjects[math.ceil(#rouletteObjects / 2)]
  U.teleport(game, "OAKS_LAB", target.x, target.y + 1, "up")
  local ow = assert(game.overworld)
  ow:interact()
  for _ = 1, 180 do
    local top = game.stack:top()
    if top and top.screenId == "BlackjackCornerStarterRoulette" then
      assert(U.shot(game, shotDir .. "/randomizer-gamble-roulette.png"))
      pass("COMPAT-ROULETTE", "Oak's real cabinet opens Blackjack Corner roulette")
      love.event.quit(0)
      return
    end
    U.tap(game, "a")
    U.wait(3)
  end
  error("Randomizer-modified Oak cabinet did not open the Gamble roulette")
end
