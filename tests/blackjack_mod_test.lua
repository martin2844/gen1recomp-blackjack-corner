package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Stats = require("src.pokemon.Stats")
local Pokemon = require("src.pokemon.Pokemon")
local SlotMachine = require("src.ui.SlotMachine")
local Runtime = require("src.mods.Runtime")
local CoinCase = assert(loadfile("mods/blackjack_corner/other/coin_case.lua"))()

local data = T.fixtures.fresh()
local lobby = {}
for key, value in pairs(data.tilesets[T.fixtures.ids.tileset]) do lobby[key] = value end
lobby.id = "LOBBY"
data.tilesets.LOBBY = lobby
data.tilesets.OVERWORLD = lobby
local blocks = {}
for i = 1, 90 do blocks[i] = 31 end
data.maps.GAME_CORNER = {
  id = "GAME_CORNER", label = "GameCorner", index = 135,
  tileset = "LOBBY", width = 10, height = 9,
  blocks = blocks, borderBlock = 15, connections = {}, signs = {},
  warps = {
    { x = 15, y = 17, destMap = "LAST_MAP", destWarp = 8 },
    { x = 16, y = 17, destMap = "LAST_MAP", destWarp = 8 },
    { x = 17, y = 4, destMap = "FIXTURE_MAP", destWarp = 2 },
  },
  objects = {
    { index = 7, name = "GAMECORNER_GYM_GUIDE", movement = "STAY", range = "LEFT",
      sprite = "SPRITE_FIXTURE", text = "TEXT_GAMECORNER_GYM_GUIDE", x = 8, y = 14 },
    { index = 8, name = "GAMECORNER_GAMBLER", movement = "STAY", range = "RIGHT",
      sprite = "SPRITE_FIXTURE", text = "TEXT_GAMECORNER_GAMBLER", x = 11, y = 15 },
  },
}
local palletBlocks = {}
for i = 1, 90 do palletBlocks[i] = 1 end
palletBlocks[73] = 0x1d -- the real Pallet pond directly below the new facade
palletBlocks[74] = 0x1e
palletBlocks[83] = 0x65
palletBlocks[84] = 0x64
data.maps.PALLET_TOWN = {
  id = "PALLET_TOWN", label = "PalletTown", index = 0,
  tileset = "OVERWORLD", width = 10, height = 9,
  blocks = palletBlocks, borderBlock = 11, connections = {}, signs = {},
  warps = {
    { x = 5, y = 5, destMap = "FIXTURE_MAP", destWarp = 1 },
    { x = 13, y = 5, destMap = "FIXTURE_MAP", destWarp = 1 },
    { x = 12, y = 11, destMap = "FIXTURE_MAP", destWarp = 1 },
  },
  objects = {
    { index = 3, name = "PALLETTOWN_FISHER", movement = "WALK",
      range = "ANY_DIR", sprite = "SPRITE_FISHER",
      text = "TEXT_PALLETTOWN_FISHER", x = 11, y = 14 },
  },
}
local celadonBlocks = {}
for i = 1, 450 do celadonBlocks[i] = 1 end
data.maps.CELADON_CITY = {
  id = "CELADON_CITY", label = "CeladonCity", index = 6,
  tileset = "OVERWORLD", width = 25, height = 18,
  blocks = celadonBlocks, borderBlock = 11, connections = {}, signs = {},
  warps = {}, objects = {
    { index = 8, name = "CELADONCITY_ROCKET1", movement = "WALK",
      range = "LEFT_RIGHT", sprite = "SPRITE_ROCKET",
      text = "TEXT_CELADONCITY_ROCKET1", x = 32, y = 29 },
  },
}
local houseBlocks = {}
for i = 1, 16 do houseBlocks[i] = 15 end
data.maps.REDS_HOUSE_1F = {
  id = "REDS_HOUSE_1F", label = "RedsHouse1F", index = 37,
  tileset = "LOBBY", width = 4, height = 4,
  blocks = houseBlocks, borderBlock = 10, connections = {}, signs = {},
  warps = {
    { x = 2, y = 7, destMap = "PALLET_TOWN", destWarp = 1 },
    { x = 3, y = 7, destMap = "PALLET_TOWN", destWarp = 1 },
    { x = 7, y = 1, destMap = "REDS_HOUSE_2F", destWarp = 1 },
  },
  objects = {
    { index = 1, name = "REDSHOUSE1F_MOM", movement = "STAY",
      range = "LEFT", sprite = "SPRITE_MOM", text = "TEXT_REDSHOUSE1F_MOM",
      x = 5, y = 4 },
  },
}
data.maps.REDS_HOUSE_2F = {
  id = "REDS_HOUSE_2F", label = "RedsHouse2F", index = 38,
  tileset = "LOBBY", width = 4, height = 4,
  blocks = houseBlocks, borderBlock = 10, connections = {}, signs = {},
  warps = { { x = 7, y = 1, destMap = "REDS_HOUSE_1F", destWarp = 3 } },
  objects = {},
}
data.maps.OAKS_LAB = {
  id = "OAKS_LAB", label = "OaksLab", index = 40,
  tileset = "LOBBY", width = 5, height = 5,
  blocks = {}, borderBlock = 15, connections = {}, signs = {}, warps = {},
  objects = {
    { index = 1, name = "OAKSLAB_CHARMANDER_POKE_BALL", sprite = "SPRITE_POKE_BALL" },
    { index = 2, name = "OAKSLAB_SQUIRTLE_POKE_BALL", sprite = "SPRITE_POKE_BALL" },
    { index = 3, name = "OAKSLAB_BULBASAUR_POKE_BALL", sprite = "SPRITE_POKE_BALL" },
  },
}

local run = T.sdk.loadMod("mods/blackjack_corner", { data = data, dev = true })
T.eq(#run.errors, 0, "blackjack mod loads cleanly")
T.eq(run.data.constants.coinCap, 1000000,
  "the mod expands the native Coin Case limit to one million")

local api = run.loader.exports.blackjack_corner
T.check(api and api.rules and api.holdem_rules and api.holdem_view and api.catalog and api.view
    and api.buyCoins and api.coinOffers and api.pawn and api.pawnPokemon
    and api.pawnQuote
    and api.redeemPokemon and api.pawnLedger and api.crash_rules
    and api.flappy_rules and api.case_rules and api.giveCaseReward
    and api.horse_rules and api.plinko_rules and api.roulette_rules
    and api.roulette_view
    and api.gamble and api.gym_cases and api.campaign_state
    and api.reputation_rules and api.reputation
    and api.credit_rules and api.credit and api.credit_world
    and api.house and api.house_world,
  "games, prizes, coin exchange, pawning, and arcade rules are exported")
T.check(api.roulette_view.RESULT_BUTTON_Y
    + api.roulette_view.RESULT_BUTTON_HEIGHT <= api.roulette_view.FRAME_CONTENT_BOTTOM,
  "the starter result button stays fully inside the visible frame")

do
  local steps = { { id = "oak_welcome", kind = "say" } }
  local built = Runtime.call("intro.oak_speech.build", function(rows) return rows end,
    steps, {})
  T.eq(built[2].id, "blackjack_corner_gamble_mode",
    "new games ask about Gamble Mode during Oak's introduction")
  T.eq(built[2].kind, "yesno", "Gamble Mode is an explicit yes-or-no choice")
  T.check(built[2].defaultNo, "ordinary rules remain the safe default")

  run.data.text._OaksLabOakChooseMonText =
    "OAK: There are 3\nPOKEMON here!"
  run.data.text._OaksLabOakBePatientText =
    "OAK: Be patient!\nYou can have one too!"
  local originalOakChoice = run.data.text._OaksLabOakChooseMonText
  local originalOakRival = run.data.text._OaksLabOakBePatientText
  local introGame = { data = run.data, save = { inventory = {}, coins = 0 } }
  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = true, speech = { game = introGame },
  })
  T.eq(introGame.save.inventory.COIN_CASE, 1,
    "Gamble Mode starts the player with a Coin Case")
  T.eq(introGame.save.coins, 100,
    "Gamble Mode supplies a small starting stake")
  T.check(not run.data.text._OaksLabOakChooseMonText:find("3\nPOK", 1, true),
    "Gamble Mode removes Oak's three-Pokemon choice speech")
  T.check(run.data.text._OaksLabOakChooseMonText:find("Gamble", 1, true) ~= nil,
    "Gamble Mode makes Oak pitch the starter roulette")
  T.check(run.data.text._OaksLabOakBePatientText:find("gamble", 1, true) ~= nil,
    "Oak explicitly encourages the rival to gamble too")
  for index, object in ipairs(run.data.maps.OAKS_LAB.objects) do
    T.eq(object.sprite, ("SPRITE_STARTER_ROULETTE_%02d"):format(index),
      "Oak's three gift balls become one roulette cabinet")
  end
  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = false, speech = { game = introGame },
  })
  for _, object in ipairs(run.data.maps.OAKS_LAB.objects) do
    T.eq(object.sprite, "SPRITE_POKE_BALL",
      "declining Gamble Mode restores Oak's ordinary gift-ball art")
  end
  T.eq(run.data.text._OaksLabOakChooseMonText, originalOakChoice,
    "declining Gamble Mode restores Oak's ordinary starter speech")
  T.eq(run.data.text._OaksLabOakBePatientText, originalOakRival,
    "declining Gamble Mode restores Oak's ordinary rival speech")
end

do
  local function objectsByName(mapId)
    local out, indices = {}, {}
    for _, object in ipairs(run.data.maps[mapId].objects or {}) do
      out[object.name] = object
      T.check(not indices[object.index], mapId .. " house object indices stay unique")
      indices[object.index] = true
    end
    return out
  end
  local downstairs = objectsByName("REDS_HOUSE_1F")
  local upstairs = objectsByName("REDS_HOUSE_2F")
  T.check(downstairs.REDSHOUSE1F_ROCKET_TENANT
      and downstairs.REDSHOUSE1F_ROCKET_OBSERVER,
    "the repossessed downstairs gains two Rocket occupants")
  local challenger = downstairs.REDSHOUSE1F_ROCKET_CHALLENGE
  T.check(challenger and challenger.trainerClass == "OPP_ROCKET"
      and challenger.trainerParty == 8,
    "the deed challenge uses a concrete, winnable Rocket party")
  T.check(upstairs.REDSHOUSE2F_GAMBLE_MOM
      and upstairs.REDSHOUSE2F_GAMBLE_MOM.hidden,
    "the displaced Mom is staged upstairs without affecting normal saves")
  for piece = 1, 5 do
    local name = ("REDSHOUSE1F_ROCKET_EQUIPMENT_%02d"):format(piece)
    T.check(downstairs[name] and downstairs[name].hidden,
      name .. " is staged only for Rocket ownership")
    T.check(run.data.sprites[("SPRITE_ROCKET_EQUIPMENT_%02d"):format(piece)],
      name .. " derives from imported Rocket Hideout or Silph Co art")
  end
  T.eq(api.house_world.challengeSaveId(),
    "REDS_HOUSE_1F_obj_4", "the restoration battle has a stable save identity")
end

do
  local Game = require("src.core.Game")
  local Overworld = require("src.world.OverworldController")
  local oldData, oldSave, oldStack = Game.data, Game.save, Game.stack
  Game.data = run.data
  local oldBubblebeam = Game.data.items.TM_BUBBLEBEAM
  Game.data.items.TM_BUBBLEBEAM = { name = "TM BUBBLEBEAM" }
  Game.save = {
    coins = 0, flags = {}, inventory = {}, defeatedTrainers = {},
    player = { name = "RED" }, party = {}, boxes = {}, currentBox = 1,
  }
  Game.stack = { pushed = {}, push = function(self, screen)
    self.pushed[#self.pushed + 1] = screen
  end, pop = function(self)
    return table.remove(self.pushed)
  end, top = function(self)
    return self.pushed[#self.pushed]
  end }
  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = true, speech = { game = Game },
  })
  local vanilla = Overworld._blackjackCornerGymCases.vanilla
  local gameUpvalue, oldOverworldGame
  for index = 1, 20 do
    local name, value = debug.getupvalue(vanilla, index)
    if not name then break end
    if name == "Game" then
      gameUpvalue, oldOverworldGame = index, value
      debug.setupvalue(vanilla, index, Game)
      break
    end
  end
  T.check(gameUpvalue ~= nil, "the gym reward integration reaches the live game state")
  local victoryDone = false
  local overworld = { runVictoryHook = function() victoryDone = true end }
  Overworld.checkVictoryRewards(overworld, "OPP_MISTY", 1)
  T.eq(Game.save.inventory.CASCADEBADGE, 1,
    "Gamble Mode keeps the gym leader's badge reward")
  T.eq(Game.save.inventory.TM_BUBBLEBEAM, nil,
    "Gamble Mode suppresses the gym leader's direct TM reward")
  T.check(victoryDone, "the ordinary post-victory script still runs")
  T.eq(#api.gym_cases.queue(), 1,
    "the suppressed gym TM becomes one persistent prize case")
  local leaderSpeech = Game.stack.pushed[1]
  T.check(leaderSpeech and leaderSpeech.pages and not leaderSpeech.screenId,
    "the leader speaks over the gym scene before the Gym Case opens")
  T.eq(#Game.stack.pushed, 1,
    "the opaque Gym Case does not sit behind the leader's dialogue")
  Game.stack:pop()
  leaderSpeech.onDone()
  T.eq(Game.stack.pushed[1].screenId, "BlackjackCornerGymCase",
    "finishing the leader's speech opens the Gym Case")
  for index = 1, 19 do Game.save.inventory["GYM_FILLER_" .. index] = 1 end
  local gymCase = Game.stack.pushed[1]
  gymCase:update(0)
  T.eq(gymCase.phase, "spinning", "the queued Gym Case auto-opens once")
  gymCase:settle()
  T.check(gymCase.claimSaved, "a full Bag preserves the exact Gym Case claim")
  T.eq(#api.gym_cases.queue(), 1,
    "a failed Gym Case delivery remains in the persistent queue")
  local chosen = api.gym_cases.queue()[1].reward.id
  for index = 1, 19 do Game.save.inventory["GYM_FILLER_" .. index] = nil end
  local retry = run.data.screens.BlackjackCornerGymCase.new(Game, {
    caseData = api.gym_cases.queue()[1], autoOpen = true, oneShot = true,
  })
  retry:update(0)
  T.eq(retry.winner.id, chosen, "a Gym Case retry keeps the exact selected prize")
  retry:settle()
  T.eq(#api.gym_cases.queue(), 0, "a delivered Gym Case leaves the queue")
  T.eq(Game.save.inventory[chosen], 1, "the retried Gym Case reaches the Bag")
  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = false, speech = { game = Game },
  })
  Game.save = {
    coins = 0, flags = {}, inventory = {}, defeatedTrainers = {},
    player = { name = "RED" }, party = {}, boxes = {}, currentBox = 1,
  }
  Game.stack = { pushed = {}, push = function(self, screen)
    self.pushed[#self.pushed + 1] = screen
  end, pop = function(self)
    return table.remove(self.pushed)
  end, top = function(self)
    return self.pushed[#self.pushed]
  end }
  victoryDone = false
  Overworld.checkVictoryRewards(overworld, "OPP_MISTY", 1)
  T.eq(Game.save.inventory.TM_BUBBLEBEAM, 1,
    "declining Gamble Mode restores the leader's direct TM reward")
  T.eq(#api.gym_cases.queue(), 0,
    "ordinary Gym progression does not enqueue a mystery case")
  T.check(victoryDone, "ordinary Gym progression still runs its victory hook")
  debug.setupvalue(vanilla, gameUpvalue, oldOverworldGame)
  Game.data.items.TM_BUBBLEBEAM = oldBubblebeam
  Game.data, Game.save, Game.stack = oldData, oldSave, oldStack
end

do
  local voices = {
    BOULDERBADGE = { leader = "BROCK", marker = "lesson" },
    CASCADEBADGE = { leader = "MISTY", marker = "splash" },
    THUNDERBADGE = { leader = "SURGE", marker = "order" },
    RAINBOWBADGE = { leader = "ERIKA", marker = "bloom" },
    SOULBADGE = { leader = "KOGA", marker = "discipline" },
    MARSHBADGE = { leader = "SABRINA", marker = "foresee" },
    VOLCANOBADGE = { leader = "BLAINE", marker = "question" },
    EARTHBADGE = { leader = "GIOVANNI", marker = "power" },
  }
  for badge, expected in pairs(voices) do
    local speech = api.gym_cases.leaderDialogue(badge)
    T.check(speech and speech:find(expected.marker, 1, true),
      expected.leader .. " gives the Gym Case pitch in character")
    T.check(not speech:find("TM", 1, true),
      expected.leader .. " no longer explains a direct TM reward")
    T.check(speech:find("GYM CASE", 1, true)
        and speech:lower():find("spin", 1, true),
      expected.leader .. " clearly tells the player to spin a Gym Case")
  end
end

do
  local Game = require("src.core.Game")
  local oldData, oldSave = Game.data, Game.save
  local oldMagikarp, oldAbra = run.data.pokemon.MAGIKARP, run.data.pokemon.ABRA
  local oldTackle, oldConfusion = run.data.moves.TACKLE, run.data.moves.CONFUSION
  local function starterDef(source, name)
    local out = {}
    for key, value in pairs(source) do out[key] = value end
    out.name, out.evolutions = name, {}
    return out
  end
  run.data.pokemon.MAGIKARP = starterDef(run.data.pokemon.FIXMON_A, "MAGIKARP")
  run.data.pokemon.ABRA = starterDef(run.data.pokemon.FIXMON_A, "ABRA")
  run.data.moves.TACKLE = run.data.moves.FIX_CUT
  run.data.moves.CONFUSION = run.data.moves.FIX_CUT
  local game = {
    data = run.data,
    save = { coins = 0, inventory = {}, party = {}, flags = {},
      pokedex = { seen = {}, owned = {} }, player = { name = "RED", id = 1 } },
  }
  Game.data, Game.save = run.data, game.save
  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = true, speech = { game = game },
  })
  local ok = api.gamble.complete(game, "MAGIKARP", "ABRA")
  T.check(ok, "a risky Magikarp roulette roll is still deliverable")
  T.eq(game.save.party[1].moves[#game.save.party[1].moves].id, "TACKLE",
    "a level-five Magikarp starter receives its anti-softlock attack")
  local rivalParty = Runtime.call("trainer.party", function(_, _, party) return party end,
    "OPP_RIVAL1", 1, { { species = "FIXMON_A", level = 5 } })
  T.eq(rivalParty[1].species, "ABRA",
    "the rival's separately rolled species replaces the vanilla starter")
  T.eq(rivalParty[1].moves[1], "CONFUSION",
    "a risky rival roll receives the same anti-softlock treatment")
  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = false, speech = { game = game },
  })
  Game.data, Game.save = oldData, oldSave
  run.data.pokemon.MAGIKARP, run.data.pokemon.ABRA = oldMagikarp, oldAbra
  run.data.moves.TACKLE, run.data.moves.CONFUSION = oldTackle, oldConfusion
end
T.check(run.data.screens.BlackjackCornerTable ~= nil, "blackjack screen is registered")
T.check(run.data.screens.BlackjackCornerHoldemTable ~= nil, "holdem screen is registered")
T.check(run.data.screens.BlackjackCornerPokemonPrizes ~= nil,
  "Pokemon prize screen is registered")
T.check(run.data.screens.BlackjackCornerItemPrizes ~= nil,
  "item prize screen is registered")
T.check(run.data.screens.BlackjackCornerCrash ~= nil, "crash screen is registered")
T.check(run.data.screens.BlackjackCornerTubeFlyer ~= nil,
  "tube flyer screen is registered")
T.check(run.data.screens.BlackjackCornerPrizeCase ~= nil,
  "prize case screen is registered")
T.check(run.data.screens.BlackjackCornerHorseRacing ~= nil,
  "animated horse racing screen is registered")
T.check(run.data.screens.BlackjackCornerPlinko ~= nil,
  "Plinko screen is registered")
T.check(run.data.screens.BlackjackCornerStarterRoulette ~= nil,
  "starter roulette screen is registered")
T.check(run.data.screens.BlackjackCornerGymCase ~= nil,
  "Gym Case screen is registered")
T.check(run.data.screens.BlackjackCornerHighRoller ~= nil,
  "Gamble Mode registers its High Roller status screen")
T.check(run.data.maps.BLACKJACK_LOUNGE ~= nil,
  "blackjack has a dedicated lounge map")
T.check(run.data.maps.PALLET_CASINO ~= nil,
  "Pallet Town has a dedicated mini-casino map")
T.eq(run.data.maps.PALLET_TOWN.warps[4].destMap, "PALLET_CASINO",
  "the new Pallet casino facade has a working entrance")
T.eq(run.data.maps.PALLET_TOWN.blocks[63], 0x3a,
  "the Pallet casino facade uses a visible door block")
T.eq(run.data.maps.PALLET_TOWN.blocks[73], 0x01,
  "the Pallet casino door has a dry walkable landing below it")
T.eq(run.data.maps.PALLET_TOWN.blocks[74], 0x01,
  "the Pallet casino forecourt clears the complete old pond edge")
T.eq(run.data.maps.PALLET_TOWN.blocks[83], 0x1d,
  "the Pallet pond moves its bordered upper-left corner down one row")
T.eq(run.data.maps.PALLET_TOWN.blocks[84], 0x1e,
  "the Pallet pond moves its bordered upper-right corner down one row")
T.eq(#run.data.field.hiddenCoins.PALLET_CASINO, 3,
  "the Pallet casino hides three one-time coin pickups")

do
  local palletCasino = run.data.maps.PALLET_CASINO
  T.eq(palletCasino.width, 10, "Pallet Casino keeps its twenty-cell width")
  T.eq(palletCasino.height, 9, "Pallet Casino expands for two card tables")
  T.eq(#palletCasino.blocks, 90, "the expanded Pallet Casino block grid is complete")
  T.eq(palletCasino.warps[1].y, 17, "the Pallet Casino exit moves to its new bottom wall")
  local objects, indices = {}, {}
  for _, object in ipairs(palletCasino.objects) do
    objects[object.name] = object
    T.check(not indices[object.index], "Pallet Casino object indices remain unique")
    indices[object.index] = true
    T.check(object.x >= 0 and object.x < palletCasino.width * 2
        and object.y >= 0 and object.y < palletCasino.height * 2,
      object.name .. " stays inside Pallet Casino")
  end
  T.check(objects.PALLET_BLACKJACK_DEALER ~= nil,
    "Pallet Casino has a dedicated blackjack dealer")
  T.check(objects.PALLET_HOLDEM_DEALER ~= nil,
    "Pallet Casino has a dedicated Hold'em dealer")
  for _, tableId in ipairs({ "BLACKJACK", "HOLDEM" }) do
    for piece = 1, 8 do
      local name = ("PALLET_%s_TABLE_%02d"):format(tableId, piece)
      T.check(objects[name] ~= nil, name .. " is present in Pallet Casino")
      if piece > 4 then
        T.eq(objects[name].text, "TEXT_PALLET_" .. tableId .. "_TABLE",
          name .. " opens its card game from the front rail")
      end
    end
  end
  local function contributedTalk(textId)
    for _, contribution in ipairs(
        run.loader.content.map_scripts:chain("PALLET_CASINO")) do
      if contribution.talk and contribution.talk[textId] then return true end
    end
    return false
  end
  T.check(contributedTalk("TEXT_PALLET_BLACKJACK_TABLE"),
    "the Pallet blackjack table opens the blackjack screen")
  T.check(contributedTalk("TEXT_PALLET_HOLDEM_TABLE"),
    "the Pallet Hold'em table opens the poker screen")
end

do
  local lounge = run.data.maps.BLACKJACK_LOUNGE
  T.eq(lounge.width, 10, "the expanded Lounge keeps its twenty-cell width")
  T.eq(lounge.height, 9, "the Lounge gains a full lower arcade floor")
  T.eq(#lounge.blocks, 90, "the expanded Lounge has one block for every map cell")
  T.eq(lounge.warps[1].y, 17, "the Lounge exit moves to the new bottom wall")
  local objects, indices = {}, {}
  for _, object in ipairs(lounge.objects) do
    objects[object.name] = object
    T.check(not indices[object.index], "Lounge object indices remain unique")
    indices[object.index] = true
    T.check(object.x >= 0 and object.x < lounge.width * 2
        and object.y >= 0 and object.y < lounge.height * 2,
      object.name .. " stays inside the expanded Lounge")
  end
  T.eq(objects.HORSE_MACHINE_02.text, "TEXT_HORSE_RACING",
    "the Lounge includes an interactive Horse Racing terminal")
  T.eq(objects.PLINKO_MACHINE_02.text, "TEXT_PLINKO",
    "the Lounge includes an interactive Plinko terminal")
  local function contributedTalk(textId)
    for _, contribution in ipairs(
        run.loader.content.map_scripts:chain("BLACKJACK_LOUNGE")) do
      if contribution.talk and contribution.talk[textId] then return true end
    end
    return false
  end
  T.check(contributedTalk("TEXT_HORSE_RACING"),
    "the Lounge can open Horse Racing from its new terminal")
  T.check(contributedTalk("TEXT_PLINKO"),
    "the Lounge can open Plinko from its new terminal")
  T.check(objects.ROCKET_LOAN_SHARK
      and objects.ROCKET_LOAN_SHARK.text == "TEXT_ROCKET_CREDIT",
    "a Rocket loan shark occupies the lower Lounge")
  T.check(contributedTalk("TEXT_ROCKET_CREDIT"),
    "the Rocket loan shark opens the credit service")
end

do
  local function collector(mapId, name)
    for _, object in ipairs(run.data.maps[mapId].objects or {}) do
      if object.name == name then return object end
    end
  end
  local palletCollector = collector("PALLET_TOWN", "PALLETTOWN_ROCKET_COLLECTOR")
  local celadonCollector = collector("CELADON_CITY", "CELADONCITY_ROCKET_COLLECTOR")
  T.check(palletCollector and palletCollector.hidden,
    "Pallet's Rocket collector remains hidden until a default")
  T.check(celadonCollector and celadonCollector.hidden,
    "Celadon's Rocket collector remains hidden until a default")
  T.check(palletCollector.index > 3 and celadonCollector.index > 8,
    "collector additions preserve existing map object indices")
end

do
  local oldBide, oldBubble = run.data.items.TM_BIDE, run.data.items.TM_BUBBLEBEAM
  local oldNidoranM, oldNidoranF = run.data.pokemon.NIDORAN_M,
    run.data.pokemon.NIDORAN_F
  local oldPikachu = run.data.pokemon.PIKACHU
  run.data.items.TM_BIDE = { name = "TM BIDE" }
  run.data.items.TM_BUBBLEBEAM = { name = "TM BUBBLEBEAM" }
  run.data.pokemon.NIDORAN_M = { name = "NIDORAN M" }
  run.data.pokemon.NIDORAN_F = { name = "NIDORAN F" }
  run.data.pokemon.PIKACHU = { name = "PIKACHU" }
  local brockRows = api.gym_cases.pool({ data = run.data },
    { order = 1, tm = "TM_BIDE" })
  local brockTotal, brockBide = 0, nil
  for _, row in ipairs(brockRows) do
    brockTotal = brockTotal + row.weight
    if row.id == "TM_BIDE" then brockBide = row end
  end
  T.check(brockBide and brockBide.weight / brockTotal <= 0.16,
    "Bide stays below sixteen percent of Brock's Gym Case pool")
  local rows = api.gym_cases.pool({ data = run.data },
    { order = 2, tm = "TM_BUBBLEBEAM" })
  local byId, bySpecies = {}, {}
  for _, row in ipairs(rows) do
    if row.kind == "item" then byId[row.id] = row else bySpecies[row.species] = row end
  end
  T.eq(byId.TM_BUBBLEBEAM.tier, "gold",
    "the current leader's TM is the Gym Case headline reward")
  T.eq(byId.TM_BUBBLEBEAM.weight, 100,
    "the current leader's TM is featured without dominating the case")
  T.eq(byId.TM_BIDE.weight, 50,
    "an earlier Gym TM remains possible at a reduced weight")
  T.check(bySpecies.NIDORAN_M and bySpecies.PIKACHU,
    "early Gym Cases include their unlocked basic Pokemon")
  T.eq(bySpecies.BULBASAUR, nil,
    "later starter rewards remain locked at the second badge")
  run.data.items.TM_BIDE, run.data.items.TM_BUBBLEBEAM = oldBide, oldBubble
  run.data.pokemon.NIDORAN_M, run.data.pokemon.NIDORAN_F =
    oldNidoranM, oldNidoranF
  run.data.pokemon.PIKACHU = oldPikachu
end
T.eq(run.data.maps.GAME_CORNER.blocks[82], 61,
  "a double-door replaces one lower Game Corner floor block")
T.eq(run.data.maps.GAME_CORNER.blocks[75], 31,
  "the original slot-machine bank remains intact")
T.eq(#run.data.maps.GAME_CORNER.warps, 5,
  "the lounge entrance adds two reciprocal Game Corner warps")
T.eq(run.data.maps.GAME_CORNER.warps[4].destMap, "BLACKJACK_LOUNGE",
  "the first new door tile enters the lounge")
T.eq(run.data.maps.GAME_CORNER.warps[5].destWarp, 2,
  "the second new door tile preserves its side of the doorway")

local function objectNamed(mapId, name)
  for _, object in ipairs(run.data.maps[mapId].objects) do
    if object.name == name then return object end
  end
end

do
  local lounge = run.data.maps.BLACKJACK_LOUNGE
  T.eq(lounge.width, 10, "the casino lounge is twenty walk cells wide")
  T.eq(lounge.height, 9, "the casino lounge is eighteen walk cells tall")
  T.eq(lounge.palette, "SLOTS1", "the lounge inherits the Game Corner palette")
  T.eq(lounge.warps[1].destWarp, 4, "the left exit returns to the left entrance tile")
  T.eq(lounge.warps[2].destWarp, 5, "the right exit returns to the right entrance tile")
  local dealer = objectNamed("BLACKJACK_LOUNGE", "BLACKJACK_DEALER")
  T.eq(dealer.x, 4, "the blackjack dealer is centered behind the left table")
  T.eq(dealer.y, 3, "the dealer stands one row behind the lounge table")
  local holdemDealer = objectNamed("BLACKJACK_LOUNGE", "HOLDEM_DEALER")
  T.eq(holdemDealer.x, 15, "the holdem dealer is centered behind the right table")
  T.eq(holdemDealer.y, 3, "the holdem dealer stands behind its table")
  local guide = objectNamed("GAME_CORNER", "GAMECORNER_GYM_GUIDE")
  T.eq(guide.x, 8, "the original Game Corner NPC layout is preserved")
  T.eq(guide.y, 14, "the Gym Guide remains in his canonical position")
  local broker = objectNamed("GAME_CORNER", "GAMECORNER_PAWN_BROKER")
  T.check(broker ~= nil, "the shady pawn broker appears at the original counter")
  T.eq(broker.sprite, "SPRITE_ROCKET", "the broker uses a shady Rocket sprite")
  T.eq(broker.text, "TEXT_PAWN_BROKER", "the broker opens the pawn service")
  T.eq(broker.x, 8, "the broker stands behind the original counter")
  T.eq(broker.y, 6, "the broker stays in the counter row")
  for index, machine in ipairs({
    { id = "CRASH", x = 8, y = 2, text = "TEXT_CRASH_MACHINE" },
    { id = "FLAPPY", x = 10, y = 2, text = "TEXT_FLAPPY_MACHINE" },
    { id = "CASE", x = 12, y = 2, text = "TEXT_CASE_MACHINE" },
    { id = "HORSE", x = 6, y = 10, text = "TEXT_HORSE_RACING" },
    { id = "PLINKO", x = 13, y = 10, text = "TEXT_PLINKO" },
  }) do
    local top = objectNamed("BLACKJACK_LOUNGE", machine.id .. "_MACHINE_01")
    local controls = objectNamed("BLACKJACK_LOUNGE", machine.id .. "_MACHINE_02")
    T.check(top and controls, machine.id .. " has a two-tile arcade cabinet")
    T.eq(top.x, machine.x, machine.id .. " occupies its center-lounge column")
    T.eq(top.y, machine.y + 1, machine.id .. " cabinet starts on its arcade row")
    T.eq(controls.y, machine.y + 2, machine.id .. " controls face the player")
    T.eq(controls.text, machine.text, machine.id .. " opens its own minigame")
    T.check(run.data.sprites[("SPRITE_ARCADE_%s_01"):format(machine.id)] ~= nil,
      machine.id .. " has generated cabinet art")
    if index <= 3 then
      T.eq(index * 2 + 6, machine.x, machine.id .. " machines are evenly spaced")
    end
  end
  for _, tableId in ipairs({ "BLACKJACK", "HOLDEM" }) do
    for piece = 1, 8 do
      local name = ("%s_TABLE_%02d"):format(tableId, piece)
      local object = objectNamed("BLACKJACK_LOUNGE", name)
      T.check(object ~= nil, name .. " is present in the casino lounge")
      T.check(run.data.sprites[("SPRITE_%s_TABLE_%02d"):format(tableId, piece)] ~= nil,
        name .. " has a registered true-color sprite")
      if piece > 4 then
        T.eq(object.text, "TEXT_" .. tableId .. "_TABLE",
          name .. " opens its game across the front edge")
      end
    end
  end
end

do
  local fakeGame = {
    data = { constants = { coinCap = 1000000 }, field = { hiddenCoins = { TEST_MAP = {
      { x = 4, y = 5, coins = 20 },
    } } } },
    save = { coins = 9990, inventory = { COIN_CASE = 1 }, hiddenTaken = {} },
  }
  local FakeOverworld = {}
  function FakeOverworld:tryHiddenObject(fx, fy)
    fakeGame.save.hiddenTaken["TEST_MAP_" .. fx .. "_" .. fy] = true
    fakeGame.save.coins = math.min(9999, fakeGame.save.coins + 20)
    return true
  end
  CoinCase.installHiddenCoinCompatibility(1000000, FakeOverworld, fakeGame)
  FakeOverworld.tryHiddenObject({ map = { id = "TEST_MAP" } }, 4, 5)
  T.eq(fakeGame.save.coins, 10010,
    "hidden coin pickups cross the original 9999-coin boundary")

  fakeGame.save.coins, fakeGame.save.hiddenTaken = 20000, {}
  FakeOverworld.tryHiddenObject({ map = { id = "TEST_MAP" } }, 4, 5)
  T.eq(fakeGame.save.coins, 20020,
    "hidden coin pickups preserve an existing five-digit balance")

  fakeGame.data.constants.coinCap = 9999
  fakeGame.save.coins, fakeGame.save.hiddenTaken = 20000, {}
  FakeOverworld.tryHiddenObject({ map = { id = "TEST_MAP" } }, 4, 5)
  T.eq(fakeGame.save.coins, 9999,
    "the hidden-coin wrapper becomes vanilla-equivalent when the cap is restored")
end

do
  local one = api.view.cardLayout(1)
  T.eq(one[1], 70, "a single pixel card is centered")
  local crowded = api.view.cardLayout(10)
  T.check(crowded[1] >= 0 and crowded[#crowded] + 20 <= 160,
    "a crowded hand remains inside the 160-pixel canvas")
  for i = 2, #crowded do
    T.check(crowded[i] > crowded[i - 1], "overlapped cards keep a readable order")
  end
end

local function contains(rows, species)
  for _, row in ipairs(rows) do if row.species == species then return true end end
  return false
end

local red = api.catalog.pokemon("red")
local blue = api.catalog.pokemon("blue")
for _, species in ipairs({ "SANDSHREW", "VULPIX", "MEOWTH", "BELLSPROUT", "PINSIR", "MAGMAR" }) do
  T.check(contains(red, species), "Red catalogue supplies Blue-exclusive " .. species)
end
for _, species in ipairs({ "EKANS", "ODDISH", "MANKEY", "GROWLITHE", "SCYTHER", "ELECTABUZZ" }) do
  T.check(contains(blue, species), "Blue catalogue supplies Red-exclusive " .. species)
end
for _, species in ipairs({ "BULBASAUR", "CHARMANDER", "SQUIRTLE", "OMANYTE", "KABUTO", "AERODACTYL", "DRATINI" }) do
  T.check(contains(red, species) and contains(blue, species), species .. " is sold in both versions")
end

local function gameWith(coins, money)
  return {
    data = run.data,
    save = {
      coins = coins,
      money = money or 0,
      inventory = {},
      party = {},
      flags = {},
      pokedex = { seen = {}, owned = {} },
      player = { name = "RED", id = 12345 },
    },
  }
end

local function clearPawnLedger()
  local ledger = api.pawnLedger()
  for index = #ledger, 1, -1 do table.remove(ledger, index) end
end

local function fixtureMon(species, level)
  return Pokemon.new(run.data, species or "FIXMON_A", level or 20,
    function() return 8 end)
end

local noInput = { wasPressed = function() return false end }

do
  local slot = setmetatable({
    game = { data = run.data, save = { coins = 10000 }, input = noInput },
    stage = "payout", payoutRemaining = 2, payoutDisplay = 2,
    dripTimer = 7, dripFrames = 8, dripFlash = 5, flash = false,
  }, SlotMachine)
  slot:update(0)
  T.eq(slot.game.save.coins, 10001,
    "a vanilla slot payout preserves and increments a five-digit balance")
  slot.game.save.coins = 9999
  slot.dripTimer, slot.payoutRemaining = 7, 1
  slot:update(0)
  T.eq(slot.game.save.coins, 10000,
    "a vanilla slot payout crosses the original 9999-coin boundary")
  slot.game.save.coins = 1000000
  slot.dripTimer, slot.payoutRemaining = 7, 1
  slot:update(0)
  T.eq(slot.game.save.coins, 1000000,
    "the original slots respect the expanded one-million-coin ceiling")
end

do
  local game = gameWith(0, 20000)
  game.save.inventory.COIN_CASE = 1
  local offers = api.coinOffers(game)
  T.eq(#offers, 4, "the clerk offers four useful denominations at ¥20000")
  T.eq(offers[1].amount, 50, "the original 50-coin purchase remains available")
  T.eq(offers[2].amount, 250, "the clerk offers a five-pack shortcut")
  T.eq(offers[3].amount, 500, "the clerk offers a ten-pack shortcut")
  T.eq(offers[4].amount, 1000, "the clerk offers a thousand coins at once")
  local ok, _, cost = api.buyCoins(game, 500)
  T.check(ok, "a larger coin purchase succeeds")
  T.eq(cost, 10000, "larger purchases preserve the ¥1000-per-50 exchange rate")
  T.eq(game.save.money, 10000, "the larger exchange deducts its full price")
  T.eq(game.save.coins, 500, "the larger exchange adds all selected coins")
end

do
  local game = gameWith(999001, 100000)
  game.save.inventory.COIN_CASE = 1
  local offers = api.coinOffers(game)
  local maximum = offers[#offers]
  T.eq(maximum.label, "MAX 999", "MAX fills the exact remaining Coin Case space")
  T.eq(maximum.cost, 20000, "a partial final bundle keeps the standard pack price")
  local ok = api.buyCoins(game, maximum.amount)
  T.check(ok, "the calculated maximum can be purchased")
  T.eq(game.save.coins, 1000000, "MAX reaches the expanded Coin Case cap exactly")
end

do
  local game = gameWith(0, 10000)
  local ok = api.buyCoins(game, 250)
  T.check(not ok, "the larger exchange still requires a Coin Case")
  T.eq(game.save.money, 10000, "a rejected exchange takes no money")
  T.eq(game.save.coins, 0, "a rejected exchange gives no coins")
end

do
  clearPawnLedger()
  local game = gameWith(100)
  game.save.inventory.COIN_CASE = 1
  local lead = fixtureMon("FIXMON_A", 10)
  local collateral = fixtureMon("FIXMON_C", 30)
  collateral.nickname = "SHELLY"
  collateral.moves[1].pp = 1
  game.save.party = { lead, collateral }
  local ok, entry = api.pawnPokemon(game, 2)
  T.check(ok, "a non-final party Pokemon can be pawned")
  T.eq(#game.save.party, 1, "pawning removes the selected party member")
  T.eq(game.save.party[1], lead, "pawning preserves the remaining party order")
  T.eq(game.save.coins, 100 + entry.value, "the full appraised value is paid in coins")
  T.eq(entry.mon, collateral, "the exact Pokemon record is held in pawn")
  T.eq(entry.mon.moves[1].pp, 1, "moves and PP survive pawn storage")
  T.eq(entry.name, "SHELLY", "the pawn ticket preserves the nickname")
  T.eq(entry.redeem, math.ceil(entry.value * 1.3),
    "the ticket locks in a thirty-percent redemption premium")

  game.save.coins = entry.redeem + 25
  ok, entry, _, destination = api.redeemPokemon(game, 1)
  T.check(ok, "a pawned Pokemon can be redeemed")
  T.eq(destination, "party", "redemption uses an open party slot first")
  T.eq(game.save.party[2], collateral, "redemption restores the exact Pokemon")
  T.eq(game.save.coins, 25, "redemption deducts only the ticket price")
  T.eq(#api.pawnLedger(), 0, "a redeemed ticket leaves the ledger")
end

do
  clearPawnLedger()
  local bucket = run.loader.modSave.blackjack_corner
  local previousMode, previousCampaign = bucket.gamble_mode, bucket.gamble_campaign
  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  local game = gameWith(0)
  game.save.inventory.COIN_CASE = 1
  game.save.party = { fixtureMon("FIXMON_A", 10), fixtureMon("FIXMON_C", 30) }
  local ok = api.credit.borrow(game)
  T.check(ok, "the integration fixture opens a Rocket Credit account")
  local quote = api.pawnQuote(game, 2)
  local beforeDebt = api.credit.snapshot(game).total
  game.save.coins = 1000000 - math.max(0, quote.value - beforeDebt)
  local beforeCoins = game.save.coins
  T.check(beforeCoins + quote.value > 1000000,
    "the integration appraisal would overflow without direct debt routing")
  local paid
  ok, _, _, _, paid = api.credit.pawnAndRepay(game, 2, api.pawnPokemon)
  T.check(ok, "Rocket Credit can pawn a real party Pokemon into repayment")
  T.eq(paid, math.min(quote.value, beforeDebt),
    "the real pawn appraisal pays no more than the outstanding ledger")
  T.eq(game.save.coins, beforeCoins + quote.value - paid,
    "the real pawn flow leaves only appraisal surplus in the Coin Case")
  T.eq(#api.pawnLedger(), 1,
    "pawn-to-debt repayment keeps the exact Pokemon redeemable")
  T.eq(#game.save.party, 1, "pawn-to-debt removes only the chosen party member")

  local campaign = bucket.gamble_campaign
  campaign.debt.status = "DEFAULT"
  campaign.debt.principal, campaign.debt.fees = 500, 100
  campaign.debt.dueBadge = 1
  local allowed = api.credit.luxuryAllowed(game)
  T.check(not allowed, "a default activates the narrow luxury freeze")
  api.credit_world.sync(game, api.credit)
  T.check(game.save.objectToggles.PALLET_TOWN.PALLETTOWN_ROCKET_COLLECTOR,
    "a default arms Pallet's Rocket collector for the next map entry")
  T.check(game.save.objectToggles.CELADON_CITY.CELADONCITY_ROCKET_COLLECTOR,
    "a default arms Celadon's Rocket collector for the next map entry")

  game.save.coins = 100000
  local item = api.catalog.ITEMS[1]
  local coinsBefore = game.save.coins
  local message
  ok, message = api.buyItem(game, item)
  T.check(not ok and message:find("frozen", 1, true),
    "default blocks rare item redemption at the service boundary")
  T.eq(game.save.coins, coinsBefore, "a frozen luxury purchase charges nothing")
  bucket.paid_case_claim = nil
  game.input = noInput
  local case = run.data.screens.BlackjackCornerPrizeCase.new(game, {})
  case:open()
  T.eq(case.phase, "ready", "default blocks opening a new paid Prize Case")
  T.eq(game.save.coins, coinsBefore, "a frozen Prize Case charges nothing")
  bucket.paid_case_claim = {
    kind = "item", id = "NEW_CASE_ITEM", quantity = 1,
    label = "PENDING ITEM", tier = "rare",
  }
  local pending = run.data.screens.BlackjackCornerPrizeCase.new(game, {})
  pending:open()
  T.eq(pending.phase, "spinning",
    "default still permits delivery of a Prize Case paid for earlier")
  T.eq(game.save.coins, coinsBefore,
    "resuming an existing claim during default never charges twice")
  bucket.paid_case_claim = nil

  game.save.coins = 1000
  ok = api.credit.repayCoins(game, 1000)
  T.check(ok and api.credit.snapshot(game).status == "CLEAR",
    "the luxury freeze is fully recoverable through repayment")
  api.credit_world.sync(game, api.credit)
  T.check(not game.save.objectToggles.PALLET_TOWN.PALLETTOWN_ROCKET_COLLECTOR,
    "clearing debt hides Pallet's collector again")
  T.check(not game.save.objectToggles.CELADON_CITY.CELADONCITY_ROCKET_COLLECTOR,
    "clearing debt hides Celadon's collector again")
  T.check(api.credit.luxuryAllowed(game),
    "clearing debt restores paid Prize Cases and prize counters")

  bucket.gamble_mode, bucket.gamble_campaign = previousMode, previousCampaign
  clearPawnLedger()
end

do
  local bucket = run.loader.modSave.blackjack_corner
  local previousMode, previousCampaign = bucket.gamble_mode, bucket.gamble_campaign
  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  local game = gameWith(0, 0)
  game.save.inventory.COIN_CASE = 1
  local ok = api.house.claimBailout(game)
  T.check(ok, "the integrated campaign can claim the zero-balance bailout")
  T.eq(game.save.coins, 10000, "the integrated bailout pays exactly ten thousand")
  api.house_world.sync(game, api.house)
  local down = game.save.objectToggles.REDS_HOUSE_1F
  local up = game.save.objectToggles.REDS_HOUSE_2F
  T.check(not down.REDSHOUSE1F_MOM and up.REDSHOUSE2F_GAMBLE_MOM,
    "repossession moves Mom from downstairs into Red's bedroom")
  T.check(down.REDSHOUSE1F_ROCKET_TENANT
      and down.REDSHOUSE1F_ROCKET_OBSERVER,
    "repossession fills the family room with Rocket occupants")
  T.check(not down.REDSHOUSE1F_ROCKET_CHALLENGE,
    "the house battle stays hidden until the deed is paid")
  for piece = 1, 5 do
    T.check(down[("REDSHOUSE1F_ROCKET_EQUIPMENT_%02d"):format(piece)],
      "repossession reveals Rocket equipment piece " .. piece)
  end

  game.save.coins = 30050
  ok = api.house.buyBack(game)
  T.check(ok, "the integrated campaign accepts the exact deed buyback")
  T.eq(game.save.coins, 50, "the integrated buyback deducts thirty thousand")
  api.house_world.sync(game, api.house)
  down = game.save.objectToggles.REDS_HOUSE_1F
  T.check(not down.REDSHOUSE1F_ROCKET_TENANT
      and down.REDSHOUSE1F_ROCKET_CHALLENGE,
    "deed payment swaps the tenant for the Rocket challenger")

  ok = api.house.recordRocketVictory()
  T.check(ok, "the integrated Rocket victory completes the house quest")
  api.house_world.sync(game, api.house)
  down, up = game.save.objectToggles.REDS_HOUSE_1F,
    game.save.objectToggles.REDS_HOUSE_2F
  T.check(down.REDSHOUSE1F_MOM and not up.REDSHOUSE2F_GAMBLE_MOM,
    "restoration returns Mom downstairs")
  T.check(not down.REDSHOUSE1F_ROCKET_OBSERVER
      and not down.REDSHOUSE1F_ROCKET_CHALLENGE,
    "restoration removes every Rocket occupant")
  for piece = 1, 5 do
    T.check(not down[("REDSHOUSE1F_ROCKET_EQUIPMENT_%02d"):format(piece)],
      "restoration removes Rocket equipment piece " .. piece)
  end

  local function contribution(mapId, key)
    for _, row in ipairs(run.loader.content.map_scripts:chain(mapId)) do
      if row[key] then return row[key] end
    end
  end
  T.check(contribution("REDS_HOUSE_1F", "onVictory"),
    "the downstairs battle has a restoration victory hook")
  local challengeOverridden = false
  for _, row in ipairs(run.loader.content.map_scripts:chain("REDS_HOUSE_1F")) do
    if row.talk and row.talk.TEXT_REDSHOUSE1F_ROCKET_CHALLENGE then
      challengeOverridden = true
    end
  end
  T.check(not challengeOverridden,
    "the Rocket challenger stays on the engine's trainer battle path")
  local upstairsTalk
  for _, row in ipairs(run.loader.content.map_scripts:chain("REDS_HOUSE_2F")) do
    if row.talk and row.talk.TEXT_REDSHOUSE2F_GAMBLE_MOM then
      upstairsTalk = row.talk.TEXT_REDSHOUSE2F_GAMBLE_MOM
    end
  end
  T.check(upstairsTalk, "displaced Mom retains an upstairs healing interaction")

  bucket.gamble_mode, bucket.gamble_campaign = previousMode, previousCampaign
end

do
  clearPawnLedger()
  local game = gameWith(0)
  game.save.inventory.COIN_CASE = 1
  game.save.party = { fixtureMon() }
  local ok = api.pawnPokemon(game, 1)
  T.check(not ok, "the broker refuses the player's final Pokemon")
  T.eq(#game.save.party, 1, "the refused final Pokemon remains in the party")
  T.eq(game.save.coins, 0, "a refused pawn pays no coins")
end

do
  clearPawnLedger()
  local game = gameWith(1000000)
  game.save.inventory.COIN_CASE = 1
  game.save.party = { fixtureMon(), fixtureMon("FIXMON_B", 30) }
  local ok = api.pawnPokemon(game, 2)
  T.check(not ok, "a full Coin Case refuses a pawn instead of underpaying")
  T.eq(#game.save.party, 2, "a capacity failure leaves the party untouched")
  T.eq(#api.pawnLedger(), 0, "a capacity failure creates no pawn ticket")
end

do
  clearPawnLedger()
  local game = gameWith(0)
  game.save.inventory.COIN_CASE = 1
  local lead = fixtureMon("FIXMON_A", 5)
  game.save.party = { lead }
  local oldest
  for index = 1, 6 do
    local collateral = fixtureMon(index % 2 == 0 and "FIXMON_B" or "FIXMON_C", 5 + index)
    collateral.nickname = "PAWN " .. index
    game.save.party[2] = collateral
    local ok, entry, sold = api.pawnPokemon(game, 2)
    T.check(ok, "FIFO pawn " .. index .. " succeeds")
    if index == 1 then oldest = entry end
    if index < 6 then
      T.eq(sold, nil, "the first five tickets remain recoverable")
    else
      T.eq(sold, oldest, "the sixth pawn permanently sells the oldest ticket")
    end
  end
  local ledger = api.pawnLedger()
  T.eq(#ledger, 5, "the recoverable pawn ledger never exceeds five")
  T.eq(ledger[1].name, "PAWN 2", "FIFO eviction advances the oldest ticket")
  T.eq(ledger[5].name, "PAWN 6", "the newest pawn is stored last")
end

do
  clearPawnLedger()
  local game = gameWith(0)
  game.save.inventory.COIN_CASE = 1
  game.save.party = { fixtureMon(), fixtureMon("FIXMON_C", 25) }
  local ok, entry = api.pawnPokemon(game, 2)
  T.check(ok, "a Pokemon can be pawned before a PC redemption")
  while #game.save.party < 6 do game.save.party[#game.save.party + 1] = fixtureMon() end
  game.save.coins = entry.redeem
  ok, _, _, destination = api.redeemPokemon(game, 1)
  T.check(ok, "redemption succeeds when only PC storage has room")
  T.eq(destination, "BOX 1", "a full party sends the exact Pokemon to the PC")
  T.eq(game.save.boxes[1][1], entry.mon, "the PC receives the pawned record unchanged")
end

do
  clearPawnLedger()
  local game = gameWith(0)
  game.save.inventory.COIN_CASE = 1
  game.save.party = { fixtureMon(), fixtureMon("FIXMON_C", 25) }
  local ok, entry = api.pawnPokemon(game, 2)
  while #game.save.party < 6 do game.save.party[#game.save.party + 1] = fixtureMon() end
  game.save.boxes = {}
  game.save.currentBox = 1
  for box = 1, 12 do
    game.save.boxes[box] = {}
    for slot = 1, 20 do game.save.boxes[box][slot] = fixtureMon() end
  end
  game.save.coins = entry.redeem
  ok = api.redeemPokemon(game, 1)
  T.check(not ok, "redemption is refused when party and PC are both full")
  T.eq(game.save.coins, entry.redeem, "failed redemption charges no coins")
  T.eq(api.pawnLedger()[1], entry, "failed redemption keeps the pawn recoverable")
end

do
  local game = gameWith(100)
  game.input = noInput
  local screen = run.data.screens.BlackjackCornerCrash.new(game, {})
  screen:launch()
  T.eq(screen.phase, "running", "crash launches when the wager is affordable")
  T.eq(game.save.coins, 90, "crash deducts the selected ten-coin wager once")
  screen.multiplier = 2.37
  screen:cashOut()
  T.eq(screen.phase, "cashed", "crash cash-out settles before the hidden crash point")
  T.eq(screen.payout, 23, "crash credits the floored live multiplier payout")
  T.eq(game.save.coins, 113, "crash returns the payout to the Coin Case")
  screen:draw()
  T.check(true, "the crash result renders without an engine error")

  local poor = gameWith(9)
  poor.input = noInput
  local refused = run.data.screens.BlackjackCornerCrash.new(poor, {})
  refused:launch()
  T.eq(refused.phase, "bet", "an unaffordable crash wager does not launch")
  T.eq(poor.save.coins, 9, "an unaffordable crash wager takes no coins")
end

do
  local game = gameWith(20)
  game.input = noInput
  local screen = run.data.screens.BlackjackCornerTubeFlyer.new(game, {})
  screen:start()
  T.eq(screen.phase, "playing", "tube flyer starts with ten available coins")
  T.eq(game.save.coins, 10, "tube flyer charges exactly ten coins")
  screen.run.y, screen.run.velocity = 65, 0
  screen.run.tubes[1].x = api.flappy_rules.BIRD_X - api.flappy_rules.TUBE_WIDTH - 1
  screen.run.tubes[1].gapY = 68
  screen:update(0)
  T.eq(screen.run.score, 1, "the screen records a passed tube")
  T.eq(game.save.coins, 11, "each passed tube immediately pays one coin")
  screen.run.y = api.flappy_rules.TOP - 1
  screen:update(0)
  T.eq(screen.phase, "result", "a collision ends the tube flyer round")
  screen:draw()
  T.check(true, "the tube flyer result renders without an engine error")
end

do
  local game = gameWith(100)
  game.input = noInput
  local screen = run.data.screens.BlackjackCornerHorseRacing.new(game, {})
  screen:start()
  T.eq(screen.phase, "racing", "horse racing starts with an affordable ticket")
  T.eq(game.save.coins, 90, "horse racing deducts the selected wager once")
  screen.race.winner = screen.horseIndex
  screen:finish()
  T.eq(screen.phase, "result", "horse racing settles into a result screen")
  T.eq(screen.payout, 20, "the favorite pays its posted two-times return")
  T.eq(game.save.coins, 110, "a winning race ticket credits its full return")
  screen:draw()
  T.check(true, "the animated race result renders without an engine error")

  local poor = gameWith(9)
  poor.input = noInput
  local refused = run.data.screens.BlackjackCornerHorseRacing.new(poor, {})
  refused:start()
  T.eq(refused.phase, "bet", "an unaffordable race ticket is refused")
  T.eq(poor.save.coins, 9, "a refused race ticket takes no coins")

  local loserGame = gameWith(100)
  loserGame.input = noInput
  local loser = run.data.screens.BlackjackCornerHorseRacing.new(loserGame, {})
  loser:start()
  loser.race.winner = 2
  loser:finish()
  T.eq(loser.payout, 0, "a losing race ticket pays nothing")
  T.eq(loserGame.save.coins, 90, "a losing race consumes the complete wager")

  local cappedGame = gameWith(1000000)
  cappedGame.input = noInput
  local capped = run.data.screens.BlackjackCornerHorseRacing.new(cappedGame, {})
  capped.horseIndex, capped.betIndex = 4, 4
  capped:start()
  capped.race.winner = 4
  capped:finish()
  T.eq(capped.payout, 500,
    "a race payout clips to the Coin Case space freed by its wager")
  T.eq(cappedGame.save.coins, 1000000,
    "a winning long shot never overflows the million-coin cap")
end

do
  local game = gameWith(100)
  game.input = noInput
  local screen = run.data.screens.BlackjackCornerPlinko.new(game, {})
  screen:dropBall()
  T.eq(screen.phase, "dropping", "Plinko begins with an affordable drop")
  T.eq(game.save.coins, 90, "Plinko deducts the selected wager once")
  screen.drop.slot = 9
  screen:finish()
  T.eq(screen.phase, "result", "Plinko settles into a result screen")
  T.eq(screen.payout, 90, "the outside Plinko bucket pays nine times")
  T.eq(game.save.coins, 180, "Plinko credits the selected bucket payout")
  screen:draw()
  T.check(true, "the animated Plinko result renders without an engine error")

  local poor = gameWith(9)
  poor.input = noInput
  local refused = run.data.screens.BlackjackCornerPlinko.new(poor, {})
  refused:dropBall()
  T.eq(refused.phase, "bet", "an unaffordable Plinko drop is refused")
  T.eq(poor.save.coins, 9, "a refused Plinko drop takes no coins")
end

do
  local game = gameWith(100, 3000)
  game.input = noInput
  local screen = run.data.screens.BlackjackCornerStarterRoulette.new(game, {})
  screen:start()
  T.eq(screen.phase, "spinning", "the starter roulette enters its animated spin")
  T.eq(screen.strip[api.roulette_rules.WINNER_INDEX], screen.playerStarter,
    "the starter reel stops on the predetermined player roll")
  screen:settle()
  T.eq(screen.phase, "offer", "a starter spin pauses for a keep-or-reroll choice")
  T.eq(#game.save.party, 0, "the rolled starter is not awarded before acceptance")
  T.check(screen:respin(), "an affordable starter reroll begins")
  T.eq(game.save.money, 2000, "a starter reroll charges exactly one thousand")
  T.eq(screen.phase, "spinning", "a paid reroll restarts the animated reel")
  screen:settle()
  screen:accept()
  T.eq(screen.phase, "result", "accepting the final roll settles successfully")
  T.eq(#game.save.party, 1, "the rolled starter reaches the player's party")
  T.check(game.save.flags.EVENT_GOT_STARTER,
    "settling the roulette unlocks Oak's Lab exit flow")
  screen:draw()
  T.check(true, "the starter result renders without an engine error")

  local duplicate = run.data.screens.BlackjackCornerStarterRoulette.new(game, {})
  duplicate.playerStarter, duplicate.rivalStarter = "FIXMON_A", "FIXMON_B"
  duplicate:settle()
  duplicate:accept()
  T.eq(duplicate.phase, "failed", "the roulette refuses a second starter")
  T.eq(#game.save.party, 1, "a refused second spin cannot duplicate the starter")

  local poor = gameWith(100, 999)
  poor.input = noInput
  local unaffordable = run.data.screens.BlackjackCornerStarterRoulette.new(poor, {})
  unaffordable:start()
  unaffordable:settle()
  T.check(not unaffordable:respin(), "an unaffordable starter reroll is refused")
  T.eq(poor.save.money, 999, "a refused starter reroll takes no money")
  T.eq(unaffordable.phase, "offer", "a refused reroll keeps the current offer")
end

do
  local game = gameWith(1000)
  game.input = noInput
  game.save.inventory.COIN_CASE = 1
  local screen = run.data.screens.BlackjackCornerPrizeCase.new(game, {})
  T.eq(screen.duration, 3.75, "the prize reel uses the slower spin duration")
  screen:open()
  T.eq(screen.phase, "spinning", "a funded prize case starts its reel")
  T.eq(game.save.coins, 500, "opening a case charges exactly 500 coins")
  T.eq(screen.strip[api.case_rules.WINNER_INDEX], screen.winner,
    "the visible reel is locked to the selected reward")
  screen:settle()
  T.eq(screen.phase, "result", "the case settles after its reel")
  T.check(not screen.refunded, "a deliverable case prize is awarded")
  screen:draw()
  T.check(true, "the case-opening result renders without an engine error")

  local pokemonGame = gameWith(0)
  pokemonGame.save.inventory.COIN_CASE = 1
  local ok, message, destination = api.giveCaseReward(pokemonGame, {
    kind = "pokemon", species = "FIXMON_A", level = 20, label = "FIXMON A",
  })
  T.check(ok, "case Pokemon rewards use safe party and PC delivery")
  T.eq(#pokemonGame.save.party, 1, "a case Pokemon reaches an open party slot")
  T.eq(message, "FIXMON A", "the case result names the Pokemon reward")
  T.eq(destination, "party", "the delivery result identifies the party destination")

  local surfGame = gameWith(0)
  surfGame.save.inventory.COIN_CASE = 1
  ok = api.giveCaseReward(surfGame, {
    kind = "pokemon", species = "FIXMON_A", level = 20, label = "SURF TEST",
    moves = { "FIX_CUT" },
  })
  T.check(ok, "case Pokemon can carry a special prize move")
  local surfMove = surfGame.save.party[1].moves[#surfGame.save.party[1].moves]
  T.eq(surfMove.id, "FIX_CUT", "the special case move is installed on delivery")
  T.eq(surfMove.pp, run.data.moves.FIX_CUT.pp,
    "the special case move starts with full PP")

  local refundGame = gameWith(1000)
  refundGame.input = noInput
  refundGame.save.inventory.COIN_CASE = 1
  local campaignBucket = run.loader.modSave.blackjack_corner
  local previousMode = campaignBucket.gamble_mode
  campaignBucket.gamble_mode = true
  api.reputation.resetForQA()
  local refund = run.data.screens.BlackjackCornerPrizeCase.new(refundGame, {})
  refund:open()
  for index = 1, 19 do refundGame.save.inventory["FILLER_" .. index] = 1 end
  refund.winner = {
    kind = "item", id = "NEW_CASE_ITEM", quantity = 1,
    label = "NEW ITEM", tier = "rare",
  }
  campaignBucket.paid_case_claim = refund.winner
  refund:settle()
  local failedProgress = api.reputation.snapshot(refundGame)
  T.check(refund.claimSaved and not refund.refunded,
    "an undeliverable paid case saves the exact claim")
  T.eq(refundGame.save.coins, 500,
    "a saved paid-case claim cannot become a free reputation wager")
  T.eq(refundGame.save.inventory.NEW_CASE_ITEM, nil,
    "failed case delivery does not partially add the reward")
  local retry = run.data.screens.BlackjackCornerPrizeCase.new(refundGame, {})
  T.check(retry.hasSavedClaim, "a new screen detects the pending paid claim")
  retry:open()
  T.eq(retry.winner.id, "NEW_CASE_ITEM",
    "a paid claim retry preserves the immutable reward")
  T.eq(refundGame.save.coins, 500, "retrying a saved claim never charges twice")
  retry:settle()
  local retriedProgress = api.reputation.snapshot(refundGame)
  T.eq(retriedProgress.completedGames, failedProgress.completedGames,
    "retrying a paid claim cannot duplicate campaign settlement")
  T.eq(retriedProgress.points, failedProgress.points,
    "retrying a paid claim cannot duplicate reputation")
  refundGame.save.inventory.FILLER_19 = nil
  local delivered = run.data.screens.BlackjackCornerPrizeCase.new(refundGame, {})
  delivered:open()
  delivered:settle()
  T.eq(refundGame.save.inventory.NEW_CASE_ITEM, 1,
    "a saved paid claim delivers after Bag space is made")
  T.check(not run.loader.modSave.blackjack_corner.paid_case_claim,
    "successful delivery clears the persistent paid claim")
  campaignBucket.gamble_mode = previousMode
end

do
  local screen = run.data.screens.BlackjackCornerTable.new(gameWith(500), {})
  local zones = screen:sgbPalettes()
  T.eq(#zones, 1, "the blackjack screen owns one palette zone")
  T.eq(zones[1].colors, false,
    "the casino primitives bypass Game Boy shade remapping")
  T.eq(zones[1].w, 160, "the true-color zone covers the full native canvas")
  T.eq(zones[1].h, 144, "the true-color zone covers the full native height")
end

do
  local poorGame = gameWith(0)
  local poorScreen = run.data.screens.BlackjackCornerHoldemTable.new(poorGame, {})
  poorScreen:deal()
  T.eq(poorScreen.notice, "NEED 10 COINS",
    "holdem requires only the selected starting bet")
  T.eq(poorGame.save.coins, 0, "a rejected holdem deal takes no coins")
  poorScreen:draw()
  T.check(true, "holdem bet screen draws its cost explanation without an error")

  local minimumGame = gameWith(10)
  local minimumScreen = run.data.screens.BlackjackCornerHoldemTable.new(minimumGame, {})
  minimumScreen:deal()
  T.eq(minimumGame.save.coins, 0, "the minimum bankroll pays only the starting bet")
  minimumScreen:chooseAction(1)
  minimumScreen:chooseAction(1)
  T.eq(minimumScreen.round.phase, "river", "two checks reach the final decision")
  T.eq(minimumScreen:actions()[1].label, "CHECK",
    "a zero-balance player can check the river")
  T.check(not minimumScreen:actions()[2].enabled,
    "the optional river bet is disabled at zero coins")
  minimumScreen:chooseAction(1)
  T.eq(minimumScreen.phase, "result",
    "a player who started with ten coins can reach showdown")

  local tightGame = gameWith(40)
  local tightScreen = run.data.screens.BlackjackCornerHoldemTable.new(tightGame, {})
  tightScreen:deal()
  T.check(tightScreen:actions()[2].enabled,
    "an affordable early 3x bet does not require a river reserve")
  T.check(not tightScreen:actions()[3].enabled,
    "an unaffordable early 4x bet remains disabled")

  local stagedGame = gameWith(60)
  local stagedScreen = run.data.screens.BlackjackCornerHoldemTable.new(stagedGame, {})
  stagedScreen:deal()
  T.check(stagedScreen:actions()[2].enabled,
    "an affordable early 3x bet is enabled")
  stagedScreen:chooseAction(2)
  T.eq(stagedScreen.round.phase, "flop", "an affordable 3x bet reveals only the flop")
  T.check(stagedScreen:actions()[2].enabled,
    "an affordable flop 2x bet remains available")
  stagedScreen:chooseAction(2)
  T.eq(stagedScreen:actions()[1].label, "CHECK",
    "the river offers a free showdown instead of fold")
  T.check(not stagedScreen:actions()[2].enabled,
    "the optional river bet is disabled after spending the balance")
  stagedScreen:chooseAction(1)
  T.eq(stagedScreen.phase, "result", "checking the river reaches showdown")

  local game = gameWith(1000)
  local screen = run.data.screens.BlackjackCornerHoldemTable.new(game, {})
  local zones = screen:sgbPalettes()
  T.eq(zones[1].colors, false, "holdem screen also bypasses shade remapping")
  screen:deal()
  T.eq(game.save.coins, 990, "holdem posts one ten-coin starting bet")
  T.eq(screen.round.phase, "preflop", "holdem deal begins with the progressive choice")
  local actions = screen:actions()
  T.eq(actions[1].label, "CHECK", "pre-flop can check")
  T.eq(actions[2].multiplier, 3, "pre-flop offers a three-times play bet")
  T.eq(actions[3].multiplier, 4, "pre-flop offers a four-times play bet")
  screen:draw()
  T.check(true, "holdem pre-flop view draws without an engine error")
  screen:chooseAction(1)
  T.eq(screen.round.phase, "flop", "checking reveals three community cards")
  T.eq(#screen.round.board, 3, "holdem screen exposes the complete flop")
  actions = screen:actions()
  T.eq(actions[2].multiplier, 2, "flop offers the progressive two-times bet")
  screen:draw()
  screen:chooseAction(2)
  T.eq(screen.round.phase, "river", "a flop bet advances to the final betting round")
  T.eq(screen.phase, "play", "a flop bet keeps the hand open")
  screen:chooseAction(2)
  T.eq(screen.phase, "result", "the river bet advances to showdown")
  screen:draw()
  T.check(true, "holdem showdown view draws without an engine error")
end

do
  local bucket = run.loader.modSave.blackjack_corner
  bucket.gamble_mode = true
  api.reputation.resetForQA()
  local function prepared(coins)
    local game = gameWith(coins or 5000)
    game.input = noInput
    game.save.inventory.COIN_CASE = 1
    return game
  end

  local game = prepared()
  local blackjack = run.data.screens.BlackjackCornerTable.new(game, {})
  blackjack:deal()
  if not blackjack.settled then
    blackjack.round.state, blackjack.round.result = "done", "win"
    blackjack.round.payout = blackjack.round.bet * 2
    blackjack:recordRound()
  end

  game = prepared()
  local holdem = run.data.screens.BlackjackCornerHoldemTable.new(game, {})
  holdem:deal()
  holdem.round.state, holdem.round.result, holdem.round.payout = "done", "loss", 0
  holdem:recordRound()

  game = prepared()
  local crash = run.data.screens.BlackjackCornerCrash.new(game, {})
  crash:launch(); crash.multiplier = 1.0; crash:cashOut()

  game = prepared()
  local tube = run.data.screens.BlackjackCornerTubeFlyer.new(game, {})
  tube:start(); tube:finish()

  game = prepared()
  local case = run.data.screens.BlackjackCornerPrizeCase.new(game, {})
  case:open()

  game = prepared()
  local horse = run.data.screens.BlackjackCornerHorseRacing.new(game, {})
  horse:start(); horse.race.winner = horse.horseIndex; horse:finish()

  game = prepared()
  local plinko = run.data.screens.BlackjackCornerPlinko.new(game, {})
  plinko:dropBall(); plinko.drop.slot = 5; plinko:finish()

  local snapshot = api.reputation.snapshot(game)
  for gameId in pairs(api.reputation_rules.GAMES) do
    T.eq(snapshot.byGame[gameId].played, 1,
      gameId .. " screen settles one real campaign round")
  end
  T.eq(snapshot.completedGames, 7,
    "the seven casino screens share one exactly-once campaign ledger")
  T.eq(snapshot.byGame.crash.draws, 1,
    "a break-even 1.00x Crash cashout records a draw instead of a win")
  case:settle()
  T.eq(api.reputation.snapshot(game).completedGames, 7,
    "Prize Case delivery cannot duplicate its reel settlement")

  local menu = Runtime.call("ui.start_menu.items", function(_, rows) return rows end,
    game, { { label = "POKéMON" }, { label = "SAVE" }, { label = "EXIT" } })
  local highRoller
  for _, item in ipairs(menu) do
    if item.label == "HIGH ROLLER" then highRoller = item end
  end
  T.check(highRoller and type(highRoller.onSelect) == "function",
    "Gamble Mode exposes High Roller progress from the Start menu")
  local status = run.data.screens.BlackjackCornerHighRoller.new(game, {})
  status:draw()
  T.check(true, "the High Roller status panel renders without an engine error")

  local campaign = run.loader.modSave.blackjack_corner.gamble_campaign
  campaign.reputation.points = 99
  campaign.reputation.rank = "ROOKIE"
  campaign.reputation.rankRewardsClaimed = {}
  campaign.reputation.pendingRankUps = {}
  campaign.reputation.discoveredGames = {}
  game = prepared()
  game.save.inventory.BOULDERBADGE = 1
  local rankGame = run.data.screens.BlackjackCornerTable.new(game, {})
  rankGame:deal()
  if not rankGame.settled then
    rankGame.round.state, rankGame.round.result = "done", "loss"
    rankGame.round.payout = 0
    rankGame:recordRound()
  end
  T.check(rankGame.rankUpPending,
    "a real game result carries its rank-up into result acknowledgement")

  bucket.gamble_mode = false
  menu = Runtime.call("ui.start_menu.items", function(_, rows) return rows end,
    game, { { label = "SAVE" }, { label = "EXIT" } })
  for _, item in ipairs(menu) do
    T.check(item.label ~= "HIGH ROLLER",
      "base mode keeps campaign progression out of the Start menu")
  end
end

do
  local game = gameWith(9999)
  local prize = { species = "FIXMON_A", level = 20, cost = 3500 }
  local ok = api.buyPokemon(game, prize, true)
  T.check(ok, "a shiny prize can be purchased")
  T.eq(game.save.coins, 3999, "base price and shiny surcharge are deducted")
  T.eq(#game.save.party, 1, "the prize enters an available party slot")
  T.check(Stats.isShiny(game.save.party[1].dvs), "the purchased Pokemon has canonical shiny DVs")
  T.check(game.save.pokedex.owned.FIXMON_A, "the prize updates owned dex state")
end

do
  local game = gameWith(100)
  local ok = api.buyPokemon(game, { species = "FIXMON_A", level = 20, cost = 3500 }, false)
  T.check(not ok, "an unaffordable Pokemon is refused")
  T.eq(game.save.coins, 100, "a refused Pokemon does not consume coins")
  T.eq(#game.save.party, 0, "a refused Pokemon is not created")
end

do
  local game = gameWith(9999)
  local filler = { species = "FIXMON_A" }
  for _ = 1, 6 do game.save.party[#game.save.party + 1] = filler end
  game.save.boxes = {}
  game.save.currentBox = 1
  for box = 1, 12 do
    game.save.boxes[box] = {}
    for slot = 1, 20 do game.save.boxes[box][slot] = filler end
  end
  local ok = api.buyPokemon(game,
    { species = "FIXMON_A", level = 20, cost = 3500 }, true)
  T.check(not ok, "a Pokemon is refused when the party and every box are full")
  T.eq(game.save.coins, 9999, "a storage failure consumes no coins")
end

do
  local game = gameWith(9999)
  local master = { item = "MASTER_BALL", cost = 9999, once = true }
  local ok = api.buyItem(game, master)
  T.check(ok, "the Master Ball can be redeemed")
  T.eq(game.save.inventory.MASTER_BALL, 1, "the Master Ball reaches the bag")
  T.eq(game.save.coins, 0, "the ultimate prize costs 9999 coins")
  game.save.coins = 9999
  ok = api.buyItem(game, master)
  T.check(not ok, "the Master Ball cannot be redeemed twice")
  T.eq(game.save.coins, 9999, "a sold-out redemption consumes no coins")
end

run.release()
do
  run.data.constants.coinCap = 9999
  local slot = setmetatable({
    game = { data = run.data, save = { coins = 9999 }, input = noInput },
    stage = "payout", payoutRemaining = 1, payoutDisplay = 1,
    dripTimer = 7, dripFrames = 8, dripFlash = 5, flash = false,
  }, SlotMachine)
  slot:update(0)
  T.eq(slot.game.save.coins, 9999,
    "releasing the mod restores vanilla slot payout behavior")
end
T.finish("blackjack_mod")
