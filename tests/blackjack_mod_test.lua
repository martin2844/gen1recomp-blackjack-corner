package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Stats = require("src.pokemon.Stats")
local Pokemon = require("src.pokemon.Pokemon")
local SlotMachine = require("src.ui.SlotMachine")
local Runtime = require("src.mods.Runtime")
local HeadlessFs = assert(loadfile(
  "mods/blackjack_corner/tests/support/headless_fs.lua"))()
local CasinoCatalog = assert(loadfile(
  "mods/blackjack_corner/tests/support/casino_catalog.lua"))()
local CoinCase = assert(loadfile("mods/blackjack_corner/other/coin_case.lua"))()

local data = CasinoCatalog.seed(T.fixtures.fresh())
local lobby = {}
for key, value in pairs(data.tilesets[T.fixtures.ids.tileset]) do lobby[key] = value end
lobby.id = "LOBBY"
local lobbySeed = lobby.blocks[1]
for index = #lobby.blocks + 1, 79 do
  lobby.blocks[index] = {}
  for tile, value in ipairs(lobbySeed) do lobby.blocks[index][tile] = value end
end
data.tilesets.LOBBY = lobby
data.tilesets.OVERWORLD = lobby
local facility = {}
for key, value in pairs(lobby) do facility[key] = value end
facility.id = "FACILITY"
facility.blocks = {}
for index = 1, 128 do
  local source = lobby.blocks[((index - 1) % #lobby.blocks) + 1]
  facility.blocks[index] = {}
  for tile, value in ipairs(source) do facility.blocks[index][tile] = value end
end
data.tilesets.FACILITY = facility
local gym = {}
for key, value in pairs(facility) do gym[key] = value end
gym.id = "GYM"
data.tilesets.GYM = gym
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
    -- Simulate another content mod claiming the old hard-coded patron slot.
    { index = 13, name = "COMPAT_GAMECORNER_GUEST", movement = "STAY", range = "DOWN",
      sprite = "SPRITE_FIXTURE", text = "TEXT_GAMECORNER_GAMBLER", x = 2, y = 2 },
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
local regionalFixtures = {
  { "VIRIDIAN_CITY", "VIRIDIAN_SCHOOL_HOUSE", 3, 21, 15 },
  { "PEWTER_CITY", "PEWTER_SPEECH_HOUSE", 6, 7, 29 },
  { "CERULEAN_CITY", "CERULEAN_BADGE_HOUSE", 9, 9, 11, 10 },
  { "VERMILION_CITY", "VERMILION_PIDGEY_HOUSE", 5, 23, 19 },
  { "LAVENDER_TOWN", "LAVENDER_CUBONE_HOUSE", 5, 3, 13 },
  { "FUCHSIA_CITY", "FUCHSIA_MEETING_ROOM", 7, 22, 13 },
  { "SAFFRON_CITY", "SAFFRON_PIDGEY_HOUSE", 4, 13, 11 },
  { "CINNABAR_ISLAND", "CINNABAR_LAB_TRADE_ROOM", 3, 6, 9 },
}
local regionalSignTexts = {
  VIRIDIAN_CITY = "TEXT_VIRIDIANCITY_SIGN",
  PEWTER_CITY = "TEXT_PEWTERCITY_SIGN",
  CERULEAN_CITY = "TEXT_CERULEANCITY_SIGN",
  VERMILION_CITY = "TEXT_VERMILIONCITY_SIGN",
  LAVENDER_TOWN = "TEXT_LAVENDERTOWN_SIGN",
  FUCHSIA_CITY = "TEXT_FUCHSIACITY_SIGN1",
  SAFFRON_CITY = "TEXT_SAFFRONCITY_SIGN",
  CINNABAR_ISLAND = "TEXT_CINNABARISLAND_SIGN",
}
for fixtureIndex, fixture in ipairs(regionalFixtures) do
  local exteriorId, interiorId, warpIndex, wx, wy, alternate = unpack(fixture)
  local exteriorBlocks = {}
  for index = 1, 360 do exteriorBlocks[index] = 1 end
  local warps = {}
  for index = 1, math.max(warpIndex, alternate or 0) do
    warps[index] = { x = index, y = 1, destMap = "FIXTURE_MAP", destWarp = 1 }
  end
  local exteriorDestination = exteriorId == "CINNABAR_ISLAND"
    and "CINNABAR_LAB" or interiorId
  warps[warpIndex] = {
    x = wx, y = wy, destMap = exteriorDestination, destWarp = 1,
  }
  if alternate then
    warps[alternate] = { x = wx, y = wy - 2, destMap = interiorId, destWarp = 1 }
  end
  data.maps[exteriorId] = {
    id = exteriorId, label = exteriorId, index = 200 + fixtureIndex,
    tileset = "OVERWORLD", width = 20, height = 18,
    blocks = exteriorBlocks, borderBlock = 1, connections = {},
    signs = { { x = 1, y = 2, text = regionalSignTexts[exteriorId] } },
    warps = warps, objects = {},
  }
  local interiorObjects = {}
  if interiorId == "CINNABAR_LAB_TRADE_ROOM" then
    interiorObjects[1] = { index = 1, name = "CINNABARLABTRADEROOM_SUPER_NERD",
      movement = "STAY", range = "DOWN", sprite = "SPRITE_FIXTURE",
      text = "TEXT_CINNABARLABTRADEROOM_SUPER_NERD", x = 3, y = 2 }
  end
  local regionalHouseBlocks = {}
  for index = 1, 16 do regionalHouseBlocks[index] = 15 end
  local interiorDestination = interiorId == "CINNABAR_LAB_TRADE_ROOM"
    and "CINNABAR_LAB" or "LAST_MAP"
  local interiorDestWarp = interiorId == "CINNABAR_LAB_TRADE_ROOM"
    and 3 or warpIndex
  data.maps[interiorId] = {
    id = interiorId,
    label = interiorId == "CINNABAR_LAB_TRADE_ROOM"
      and "CinnabarLabTradeRoom" or interiorId,
    index = 220 + fixtureIndex, tileset = "LOBBY", width = 4, height = 4,
    blocks = regionalHouseBlocks, borderBlock = 15, connections = {}, signs = {},
    warps = { { x = 2, y = 7, destMap = interiorDestination,
        destWarp = interiorDestWarp },
      { x = 3, y = 7, destMap = interiorDestination,
        destWarp = interiorDestWarp } },
    objects = interiorObjects,
  }
end
data.maps.CINNABAR_LAB = {
  id = "CINNABAR_LAB", label = "CinnabarLab", index = 240,
  tileset = "LOBBY", width = 5, height = 5,
  blocks = {}, borderBlock = 15, connections = {}, signs = {}, objects = {},
  warps = {
    { x = 2, y = 9, destMap = "CINNABAR_ISLAND", destWarp = 3 },
    { x = 3, y = 9, destMap = "CINNABAR_ISLAND", destWarp = 3 },
    { x = 8, y = 3, destMap = "CINNABAR_LAB_TRADE_ROOM", destWarp = 1 },
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
    { index = 1, name = "OAKSLAB_CHARMANDER_POKE_BALL", sprite = "SPRITE_POKE_BALL",
      text = "TEXT_OAKSLAB_CHARMANDER_POKE_BALL", x = 6, y = 3 },
    { index = 2, name = "OAKSLAB_SQUIRTLE_POKE_BALL", sprite = "SPRITE_POKE_BALL",
      text = "TEXT_OAKSLAB_SQUIRTLE_POKE_BALL", x = 7, y = 3 },
    { index = 3, name = "OAKSLAB_BULBASAUR_POKE_BALL", sprite = "SPRITE_POKE_BALL",
      text = "TEXT_OAKSLAB_BULBASAUR_POKE_BALL", x = 8, y = 3 },
  },
}

local run = T.sdk.loadMod("mods/blackjack_corner", {
  data = data,
  dev = true,
  fs = HeadlessFs.new({ "mods/blackjack_corner" }),
})
T.eq(#run.errors, 0, "blackjack mod loads cleanly")
T.eq(run.data.constants.coinCap, 1000000,
  "the mod expands the native Coin Case limit to one million")

local api = run.loader.exports.blackjack_corner
T.check(api and api.rules and api.holdem_rules and api.holdem_view and api.catalog and api.view
    and api.buyCoins and api.coinOffers and api.cashOutCoins
    and api.cashOutOffers and api.pawn and api.pawnPokemon
    and api.pawnQuote
    and api.redeemPokemon and api.pawnLedger and api.crash_rules
    and api.flappy_rules and api.case_rules and api.giveCaseReward
    and api.horse_rules and api.plinko_rules and api.roulette_rules
    and api.roulette_view
    and api.gamble and api.gym_cases and api.campaign_state
    and api.reputation_rules and api.reputation
    and api.credit_rules and api.credit and api.credit_world
    and api.house and api.house_world and api.arena_rules and api.arena
    and api.arena_security
    and api.arena_world and api.arena_story and api.story_world
    and api.settings,
  "games, prizes, coin exchange, pawning, and arcade rules are exported")
T.check(api.roulette_view.RESULT_BUTTON_Y
    + api.roulette_view.RESULT_BUTTON_HEIGHT <= api.roulette_view.FRAME_CONTENT_BOTTOM,
  "the starter result button stays fully inside the visible frame")

do
  T.eq(#api.city_casinos.locations, 8,
    "eight regional branches join the existing Pallet and Celadon casinos")
  for _, location in ipairs(api.city_casinos.locations) do
    local interior = run.data.maps[location.interior]
    T.eq(interior.width, 6, location.city .. " casino has the compact native layout")
    T.eq(interior.height, 5, location.city .. " casino has enough vertical room")
    T.eq(#interior.blocks, 30, location.city .. " casino block grid is complete")
    local hasBlackjack, hasHoldem, hasSpecial = false, false, false
    local indices = {}
    for _, object in ipairs(interior.objects or {}) do
      T.check(not indices[object.index], location.city .. " casino object indices are unique")
      indices[object.index] = true
      hasBlackjack = hasBlackjack or object.text == "TEXT_CITY_CASINO_BLACKJACK"
      hasHoldem = hasHoldem or object.text == "TEXT_CITY_CASINO_HOLDEM"
      hasSpecial = hasSpecial or object.text == "TEXT_CITY_CASINO_SPECIAL"
    end
    T.check(hasBlackjack and hasHoldem and hasSpecial,
      location.city .. " offers both card tables and a local game")
    local signed, original = 0, false
    for _, sign in ipairs(run.data.maps[location.exterior].signs or {}) do
      if sign.text == "TEXT_REGIONAL_CASINO_SIGN" then signed = signed + 1 end
      original = original or sign.text == location.sign.text
    end
    T.eq(signed, 1, location.city .. " repurposes one visible city placard")
    T.check(not original, location.city .. " does not leave a duplicate city sign")
  end
  local cinnabar = run.data.maps.CINNABAR_LAB_TRADE_ROOM
  local keptScientist = false
  for _, object in ipairs(cinnabar.objects) do
    keptScientist = keptScientist
      or object.name == "CINNABARLABTRADEROOM_SUPER_NERD"
  end
  T.check(keptScientist and cinnabar.label == "CinnabarLabTradeRoom",
    "Cinnabar's casino branch preserves its native Lab interaction surface")
  T.eq(run.data.maps.CINNABAR_ISLAND.warps[3].destMap, "CINNABAR_LAB",
    "Cinnabar keeps its ordinary Lab entrance instead of inventing a direct door")
  T.eq(run.data.maps.CINNABAR_LAB.warps[3].destMap,
    "CINNABAR_LAB_TRADE_ROOM",
    "Cinnabar Casino remains reachable through the native Lab trade-room door")
  T.eq(cinnabar.warps[1].destMap, "CINNABAR_LAB",
    "Cinnabar Casino exits back into the Lab instead of skipping outdoors")
  T.eq(cinnabar.warps[1].destWarp, 3,
    "Cinnabar Casino preserves the native trade-room return door")

  local Data = require("src.core.Data")
  local MapScripts = require("src.script.MapScripts")
  local previousScripts = Data.map_scripts
  Data.map_scripts = run.data.map_scripts
  MapScripts.invalidate("VIRIDIAN_SCHOOL_HOUSE")
  local schoolScript = MapScripts.get("VIRIDIAN_SCHOOL_HOUSE")
  T.check(schoolScript and schoolScript.onInteract({}, {}, 3, 0),
    "Viridian Casino consumes the old invisible blackboard interaction")
  T.check(schoolScript.onInteract({}, {}, 3, 4),
    "Viridian Casino consumes the old invisible notebook interaction")
  T.check(not schoolScript.onInteract({}, {}, 2, 4),
    "Viridian Casino leaves unrelated interaction cells available to other mods")
  Data.map_scripts = previousScripts
  MapScripts.invalidate("VIRIDIAN_SCHOOL_HOUSE")

  T.eq(run.data.trainers.OPP_CASE_ACE_M.basePic, "OPP_COOLTRAINER_M",
    "imported catalogs retain the real CASE ACE trainer portrait")
  T.eq(run.data.trainers.OPP_CASE_ACE_M.parties[1][1].species, "MANKEY",
    "imported catalogs retain the authored CASE ACE teams")

  local leaderCaps = { 14, 21, 24, 29, 43, 43, 47, 50 }
  T.eq(#api.case_challengers.locations, 8,
    "one optional case challenger is staged beyond every Gym")
  for index, location in ipairs(api.case_challengers.locations) do
    local party = api.case_challengers.parties[location.party]
    local minimum = 100
    for _, pokemon in ipairs(party) do minimum = math.min(minimum, pokemon.level) end
    T.check(minimum > leaderCaps[index],
      location.key .. " challenger is stronger than the nearest Gym Leader")
    local found
    for _, object in ipairs(run.data.maps[location.map].objects or {}) do
      if object.name == location.objectName then found = object; break end
    end
    T.check(found and found.hidden and found.trainerClass == location.trainer,
      location.key .. " challenger is staged as an optional Gamble Mode fight")
    for _, branch in ipairs(api.city_casinos.locations) do
      if location.map == branch.exterior then
        T.check(location.x ~= branch.sign.x or location.y ~= branch.sign.y,
          location.key .. " challenger does not occupy its casino sign")
      end
    end
  end
end

do
  local steps = { { id = "oak_welcome", kind = "say" } }
  local built = Runtime.call("intro.oak_speech.build", function(rows) return rows end,
    steps, {})
  T.eq(built[1].id, "blackjack_corner_gamble_mode",
    "new games ask about Gamble Mode before Oak appears")
  T.eq(built[2].id, "oak_welcome",
    "Oak's first appearance follows the campaign choice")
  T.eq(built[1].kind, "yesno", "Gamble Mode is an explicit yes-or-no choice")
  T.eq(built[1].pic, nil, "the campaign choice does not reveal Oak early")
  T.check(built[1].defaultNo, "ordinary rules remain the safe default")

  run.loader.modOptions.blackjack_corner = { gamble_default = "on" }
  local preferred = Runtime.call("intro.oak_speech.build",
    function(rows) return rows end, { { id = "oak_welcome", kind = "say" } }, {})
  T.check(not preferred[1].defaultNo,
    "the persistent setting can preselect Gamble Mode for a new campaign")
  run.loader.modOptions.blackjack_corner = {}

  -- Nuzlocke 2's default World Building listener opens an Oak flavor box
  -- from intro.oak_speech.finished. The engine emits that event before it
  -- pops OakSpeech, so an uncoordinated listener makes Oak pop the new box
  -- and leaves the completed opaque speech screen white forever.
  local introOverlay = { pages = { { "OAK FLAVOR" } } }
  local introStack = { states = {} }
  function introStack:top() return self.states[#self.states] end
  local introDone = false
  local compatSpeech = {
    onDone = function() introDone = true end,
  }
  local compatGame = {
    mods = { mods = { nuzlocke = { enabled = true } } },
    stack = introStack,
  }
  compatSpeech.game = compatGame
  introStack.states = { compatSpeech, introOverlay }
  Runtime.emit("intro.oak_speech.finished", { speech = compatSpeech })
  T.eq(introStack:top(), compatSpeech,
    "Nuzlocke's post-intro flavor is deferred until Oak can pop itself")
  table.remove(introStack.states)
  compatSpeech.onDone()
  T.check(introDone, "the original Oak completion callback still runs")
  T.eq(introStack:top(), introOverlay,
    "the deferred Nuzlocke flavor resumes after Oak exits")

  run.data.text._OaksLabOakChooseMonText =
    "OAK: There are 3\nPOKEMON here!"
  run.data.text._OaksLabOakBePatientText =
    "OAK: Be patient!\nYou can have one too!"
  local originalOakChoice = run.data.text._OaksLabOakChooseMonText
  local originalOakRival = run.data.text._OaksLabOakBePatientText
  local introGame = { data = run.data, save = { inventory = {}, coins = 0 } }
  local originalStarterTexts = {}
  for index, object in ipairs(run.data.maps.OAKS_LAB.objects) do
    originalStarterTexts[index] = object.text
  end
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
    T.eq(object.text, "TEXT_BLACKJACK_CORNER_STARTER_ROULETTE",
      "Gamble Mode moves starter interaction off the Randomizer-owned ball handler")
  end
  local rouletteHandler
  for _, contribution in ipairs(
      run.loader.content.map_scripts:chain("OAKS_LAB")) do
    rouletteHandler = rouletteHandler or (contribution.talk
      and contribution.talk.TEXT_BLACKJACK_CORNER_STARTER_ROULETTE)
  end
  T.check(type(rouletteHandler) == "function",
    "the isolated roulette text binding has a matching map handler")
  Runtime.emit("game.ready", { game = introGame })
  T.eq(run.data.maps.OAKS_LAB.objects[1].text,
    "TEXT_BLACKJACK_CORNER_STARTER_ROULETTE",
    "Gamble Mode keeps its isolated roulette handler after late boot listeners")
  local Game = require("src.core.Game")
  local oldData, oldSave, oldOverworld = Game.data, Game.save, Game.overworld
  local coldReload
  Game.data, Game.save = run.data, introGame.save
  Game.overworld = {
    map = { id = "OAKS_LAB" },
    reloadMap = function(_, mapId, reason) coldReload = { mapId, reason } end,
  }
  run.data.maps.OAKS_LAB.objects[1].sprite = "SPRITE_POKE_BALL"
  run.data.maps.OAKS_LAB.objects[1].text = originalStarterTexts[1]
  Runtime.emit("save.loaded", { save = {
    player = { map = "OAKS_LAB" },
  } })
  T.eq(run.data.maps.OAKS_LAB.objects[1].text,
    "TEXT_BLACKJACK_CORNER_STARTER_ROULETTE",
    "cold CONTINUE restores Gamble Mode's private roulette interaction")
  T.check(coldReload and coldReload[1] == "OAKS_LAB"
      and coldReload[2] == "gamble-starter-sync",
    "cold CONTINUE rebuilds Oak's live Lab objects after roulette reconciliation")
  Game.data, Game.save, Game.overworld = oldData, oldSave, oldOverworld
  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = false, speech = { game = introGame },
  })
  for index, object in ipairs(run.data.maps.OAKS_LAB.objects) do
    T.eq(object.sprite, "SPRITE_POKE_BALL",
      "declining Gamble Mode restores Oak's ordinary gift-ball art")
    T.eq(object.text, originalStarterTexts[index],
      "declining Gamble Mode returns starter interaction to the Randomizer-compatible ball handler")
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
  local forcedGymReward = {
    kind = "item", id = "TM_BUBBLEBEAM", quantity = 1,
    label = "TM BUBBLEBEAM", tier = "gold", weight = 120,
  }
  api.gym_cases.onChosen(api.gym_cases.queue()[1], forcedGymReward)
  Game.stack.pushed[1].caseData.reward = forcedGymReward
  for index = 1, 19 do Game.save.inventory["GYM_FILLER_" .. index] = 1 end
  local gymCase = Game.stack.pushed[1]
  gymCase:update(0)
  T.eq(gymCase.phase, "spinning", "the queued Gym Case auto-opens once")
  gymCase:settle()
  T.check(gymCase.claimSaved, "a full Bag preserves the exact Gym Case claim")
  T.eq(#api.gym_cases.queue(), 1,
    "a failed Gym Case delivery remains in the persistent queue")
  local pressed = {}
  Game.input = { wasPressed = function(_, key) return pressed[key] == true end }
  pressed.a = true
  gymCase:update(0)
  T.eq(#Game.stack.pushed, 0,
    "a failed Gym Case delivery does not invent a leader reaction")
  pressed.a = false
  local chosen = api.gym_cases.queue()[1].reward.id
  for index = 1, 19 do Game.save.inventory["GYM_FILLER_" .. index] = nil end
  local retry = run.data.screens.BlackjackCornerGymCase.new(Game, {
    caseData = api.gym_cases.queue()[1], autoOpen = true, oneShot = true,
  })
  Game.stack:push(retry)
  retry:update(0)
  T.eq(retry.winner.id, chosen, "a Gym Case retry keeps the exact selected prize")
  retry:settle()
  T.eq(#api.gym_cases.queue(), 0, "a delivered Gym Case leaves the queue")
  T.eq(Game.save.inventory[chosen], 1, "the retried Gym Case reaches the Bag")
  pressed.a = true
  retry:update(0)
  local reaction = Game.stack:top()
  T.check(reaction and reaction.pages and not reaction.screenId,
    "acknowledging a delivered Gym Case opens the leader's reaction")
  local reactionText = {}
  for _, page in ipairs(reaction.pages or {}) do
    for _, line in ipairs(page) do reactionText[#reactionText + 1] = line end
  end
  reactionText = table.concat(reactionText, " ")
  T.check(reactionText:find("MISTY", 1, true)
      and reactionText:find("BUBBLEBEAM", 1, true),
    "Misty reacts to the exact delivered Gym Case prize")
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
    T.check(speech:find("CASE", 1, true)
        and speech:lower():find("spin", 1, true),
      expected.leader .. " clearly tells the player to spin a themed case")
  end
end

do
  local tierMarkers = {
    common = "SAFE PULL", pokemon = "SOLID PULL", rare = "RARE PULL",
    epic = "EPIC PULL", gold = "JACKPOT",
  }
  local total = 0
  for badge, definition in pairs(api.gym_cases.definitions) do
    local reactions = {}
    for _, reward in ipairs(definition.rewards) do
      total = total + 1
      local reaction = api.gym_cases.rewardDialogue({ badge = badge }, reward)
      local normalized = reaction and reaction:gsub("%s+", " ") or ""
      local identity = reward.id or reward.species
      T.check(reaction and reaction:find(definition.leader, 1, true),
        definition.leader .. " comments on " .. tostring(identity))
      T.check(normalized:find(tierMarkers[reward.tier], 1, true),
        tostring(identity) .. " gets a rarity-aware reaction")
      T.check(not reactions[reaction],
        definition.leader .. " has unique copy for " .. tostring(identity))
      for markedPage in (reaction .. "\f"):gmatch("(.-)\f") do
        local _, lineBreaks = markedPage:gsub("\n", "")
        T.check(lineBreaks <= 1,
          tostring(identity) .. " reaction uses at most two authored lines per page")
        for line in (markedPage .. "\n"):gmatch("(.-)\n") do
          T.check(#line <= 18,
            tostring(identity) .. " reaction fits the native text width")
        end
      end
      reactions[reaction] = true
    end
  end
  T.eq(total, 80, "all eight leaders cover all ten themed case prizes")
  local horsea = api.gym_cases.rewardDialogue({ badge = "CASCADEBADGE" }, {
    kind = "pokemon", species = "HORSEA", tier = "pokemon",
  })
  T.check(horsea and horsea:find("mid", 1, true),
    "Misty gives HORSEA the requested affectionate roast")
  local bubblebeam = api.gym_cases.rewardDialogue({ badge = "CASCADEBADGE" }, {
    kind = "item", id = "TM_BUBBLEBEAM", tier = "gold",
  })
  T.check(bubblebeam and bubblebeam:find("WATER POKEMON", 1, true),
    "Misty still teaches the classic BUBBLEBEAM lesson on the jackpot pull")
  local legacy = api.gym_cases.rewardDialogue({ badge = "CASCADEBADGE" }, {
    kind = "pokemon", species = "NIDORAN_F", label = "NIDORAN F",
    tier = "pokemon",
  })
  local normalizedLegacy = legacy and legacy:gsub("%s+", " ") or ""
  T.check(normalizedLegacy:find("MISTY", 1, true)
      and normalizedLegacy:find("NIDORAN F", 1, true)
      and normalizedLegacy:find("SOLID PULL", 1, true),
    "a pending pre-theme Gym Case still gets an exact rarity-aware reaction")
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
  local trainerChain = run.loader.hooks.chains["trainer.party"] or {}
  local blackjackPriority
  for _, entry in ipairs(trainerChain) do
    if entry.owner == "blackjack_corner" then blackjackPriority = entry.priority end
  end
  T.check((blackjackPriority or 0) > 0,
    "the roulette rival projection runs after the Randomizer's trainer projection")
  local stopTrainerFixture = run.loader.hooks:wrap("trainer.party",
    function(next, trainerClass, partyIndex, party)
      local out = next(trainerClass, partyIndex, party)
      local copy = {}
      for index, slot in ipairs(out) do
        copy[index] = {}
        for key, value in pairs(slot) do copy[index][key] = value end
      end
      if copy[#copy] then copy[#copy].species = "FIXMON_C" end
      return copy
    end, 0, "pokemon_randomizer_fixture")
  local stopEncounterFixture = run.loader.hooks:wrap("encounter.species",
    function(next, encounter, context)
      next(encounter, context)
      return "FIXMON_B"
    end, 0, "pokemon_randomizer_fixture")
  local ordinaryParty = Runtime.call("trainer.party",
    function(_, _, party) return party end,
    "OPP_BUG_CATCHER", 1, { { species = "FIXMON_A", level = 5 } })
  T.eq(ordinaryParty[1].species, "FIXMON_C",
    "Gamble Mode leaves the Randomizer's ordinary trainer parties intact")
  T.eq(Runtime.call("encounter.species", function(encounter) return encounter end,
    "FIXMON_A", { mapId = "ROUTE_1" }), "FIXMON_B",
    "Gamble Mode leaves the Randomizer's wild encounters intact")
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
  stopTrainerFixture()
  stopEncounterFixture()
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
  local indices, names = {}, {}
  for _, object in ipairs(run.data.maps.GAME_CORNER.objects) do
    T.check(not indices[object.index],
      "Game Corner additions allocate collision-free object indices")
    indices[object.index], names[object.name] = true, object
  end
  T.check(names.CASINO_DEBTOR.index > names.COMPAT_GAMECORNER_GUEST.index,
    "new patrons allocate after objects contributed by earlier content mods")
end

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
  T.eq(#lounge.warps, 3,
    "the revealed stairwell has a reciprocal route into the VIP lobby")
  for piece = 1, 4 do
    local terminal = objects[("ARENA_STATUS_TERMINAL_%02d"):format(piece)]
    T.check(terminal ~= nil,
      "the native Rocket status terminal covers piece " .. piece)
  end
  T.eq(objects.ARENA_STATUS_TERMINAL_03.text, "TEXT_ARENA_TERMINAL",
    "the terminal can scan status from its left approach")
  T.eq(objects.ARENA_STATUS_TERMINAL_04.text, "TEXT_ARENA_TERMINAL",
    "the terminal can scan status from its right approach")
  T.eq(lounge.blocks[52], 67,
    "the terminal covers Celadon's complete native secret-stair block")
  T.eq(objects.ARENA_STAIR, nil,
    "the native secret staircase needs no artificial object sprite")
  T.eq(lounge.warps[3].x, 3,
    "the arena route enters through the native secret-stair cell")
  T.eq(lounge.warps[3].y, 10,
    "the arena route triggers on the visible staircase rather than below it")
end

do
  local lobby, pit = run.data.maps.ROCKET_ARENA_LOBBY,
    run.data.maps.ROCKET_BATTLE_ARENA
  T.check(lobby and pit, "the two underground casino floors are registered")
  T.eq(lobby.tileset, "LOBBY",
    "B1 uses the unmodified Celadon Game Corner tileset")
  T.eq(pit.tileset, "GYM",
    "B2 uses the unmodified Elite Four gym tileset")
  T.check(run.data.tilesets.ROCKET_VIP_LOBBY == nil,
    "the underground casino does not register a derived tileset")
  T.eq(lobby.label, "RocketCasinoB1F", "the first room is identified as B1")
  T.eq(pit.label, "RocketCasinoB2F", "the arena is identified as B2")
  T.eq(#lobby.warps, 3,
    "B1 has a two-cell stair exit and a physical B2 door route")
  T.eq(lobby.warps[1].destMap, "ROCKET_BATTLE_ARENA",
    "walking through B1's guarded door enters B2")
  T.eq(pit.warps[1].destMap, "ROCKET_ARENA_LOBBY",
    "walking through B2's exit returns to B1 security")

  local function inspect(map, tileset)
    local byName, indices = {}, {}
    T.eq(#map.blocks, map.width * map.height,
      map.id .. " fills its complete block grid")
    for _, block in ipairs(map.blocks) do
      T.check(block >= 0 and block < #tileset.blocks,
        map.id .. " references only blocks from its stock ROM tileset")
    end
    for _, row in ipairs(map.objects or {}) do
      byName[row.name] = row
      T.check(not indices[row.index], map.id .. " object indices remain unique")
      indices[row.index] = true
      T.check(row.x >= 0 and row.x < map.width * 2
          and row.y >= 0 and row.y < map.height * 2,
        row.name .. " stays inside " .. map.id)
      T.check(not tostring(row.sprite or ""):find("SPRITE_ARENA_", 1, true),
        row.name .. " uses a native ROM object sprite")
    end
    return byName
  end
  local lobbyObjects = inspect(lobby, run.data.tilesets.LOBBY)
  local pitObjects = inspect(pit, run.data.tilesets.GYM)

  T.eq(lobby.blocks[1], 15, "B1 opens with the native Game Corner wall")
  T.eq(lobby.blocks[5], 12, "B1's north route begins with a native door")
  T.eq(lobby.blocks[6], 13, "B1's north route keeps its native door pair")
  T.eq(lobby.blocks[54], 57, "B1's left slot bank uses native cabinets")
  T.eq(lobby.blocks[57], 57, "B1 mirrors its native cabinets on the right")
  T.eq(lobby.blocks[74], 56, "B1 finishes the left cabinet bank natively")
  T.eq(lobby.blocks[77], 56, "B1 finishes the right cabinet bank natively")
  T.eq(lobby.blocks[31], 29, "B1 uses a native roulette-table top")
  T.eq(lobby.blocks[35], 32, "B1 preserves the open central promenade")
  T.eq(lobby.blocks[85], 40, "B1 exits through a native LOBBY doorway")
  T.eq(lobby.blocks[86], 41, "B1's south doorway has its native companion")

  T.eq(pit.blocks[1], 33, "B2 begins with a native Elite Four wall")
  T.eq(pit.blocks[5], 36, "B2's north dais uses the native League barrier")
  T.eq(pit.blocks[23], 5, "B2's upper islands replace Lorelei ice with League flooring")
  T.eq(pit.blocks[33], 50, "B2's left island keeps its statue on solid flooring")
  T.eq(pit.blocks[38], 49, "B2 mirrors the right island statue on solid flooring")
  T.eq(pit.blocks[64], 5, "B2 closes the central stage without an ice pocket")
  T.eq(pit.blocks[85], 5, "B2's return aisle uses native League flooring")

  local vipSlots = run.data.field.slotMachines
    and run.data.field.slotMachines.ROCKET_ARENA_LOBBY or {}
  T.eq(#vipSlots, 6,
    "B1 registers six playable native slot-machine seats")
  local expectedSlots = {
    ["7,10"] = true, ["7,12"] = true, ["7,14"] = true,
    ["12,10"] = true, ["12,12"] = true, ["12,14"] = true,
  }
  for _, slot in ipairs(vipSlots) do
    T.check(slot.state == "ok" and expectedSlots[slot.x .. "," .. slot.y],
      "each B1 slot event matches a native cabinet cell")
  end

  T.check(lobbyObjects.ARENA_DOORMAN and lobbyObjects.ARENA_DOORMAN_WING,
    "two permanent Rocket staff members flank the B1 pit entrance")
  T.eq(lobbyObjects.ARENA_RETURN_CLERK, nil,
    "the retired party-custody clerk is not staged behind the counter")
  T.eq(lobbyObjects.ARENA_DOORMAN.text, "TEXT_ARENA_GREETER",
    "B1's first Rocket welcomes the player instead of duplicating custody")
  T.eq(lobbyObjects.ARENA_DOORMAN_WING.text, "TEXT_ARENA_DOORMAN",
    "B1's second Rocket guards the physical pit door")
  for _, name in ipairs({ "ARENA_CASHIER", "ARENA_HOSTESS" }) do
    T.eq(lobbyObjects[name].y, 4,
      "B1 counter staff stands behind, not on, the native counter: " .. name)
  end
  T.eq(lobbyObjects.ARENA_DOORMAN.x, 7,
    "B1's left Rocket is inset toward the central aisle")
  T.eq(lobbyObjects.ARENA_DOORMAN_WING.x, 12,
    "B1's right Rocket mirrors the inset left guard")
  T.eq(lobbyObjects.ARENA_DOORMAN.y, 2,
    "B1's left Rocket works from the upper reception counter")
  T.eq(lobbyObjects.ARENA_DOORMAN_WING.y, 2,
    "B1's right Rocket works from the upper reception counter")
  T.eq(lobbyObjects.ARENA_CASHIER.x, 4,
    "B1's cashier is centered behind the left counter")
  T.eq(lobbyObjects.ARENA_HOSTESS.x, 15,
    "B1's hostess mirrors the cashier behind the right counter")
  T.check(pitObjects.ARENA_BOOKIE ~= nil,
    "the native B2 floor retains the arena bookie")
  local function objectBlock(map, object)
    return map.blocks[math.floor(object.y / 2) * map.width
      + math.floor(object.x / 2) + 1]
  end
  for index = 1, 8 do
    local fan = pitObjects["ARENA_FAN_" .. index]
    T.check(fan ~= nil,
      "the native B2 floor includes fan voice " .. index)
    local block = objectBlock(pit, fan)
    T.check(block == 5 or block == 24,
      "B2 fan " .. index .. " stands on a native floor block instead of Lorelei ice")
  end
end

do
  local function collector(mapId, name)
    local map = run.data.maps[mapId]
    if not map then return nil end
    for _, object in ipairs(map.objects or {}) do
      if object.name == name then return object end
    end
  end
  local palletCollector = collector("PALLET_TOWN", "PALLETTOWN_ROCKET_COLLECTOR")
  local celadonCollector = collector("CELADON_CITY", "CELADONCITY_ROCKET_COLLECTOR")
  local cinnabarHandler = collector("CINNABAR_LAB_METRONOME_ROOM",
    "BLACKJACK_CORNER_CINNABAR_HANDLER")
  local mansionResearcher = collector("POKEMON_MANSION_B1F",
    "BLACKJACK_CORNER_MANSION_RESEARCHER")
  local giovanni = collector("ROCKET_BATTLE_ARENA",
    "BLACKJACK_CORNER_GIOVANNI")
  T.check(palletCollector and palletCollector.hidden,
    "Pallet's Rocket collector remains hidden until a default")
  T.check(celadonCollector and celadonCollector.hidden,
    "Celadon's Rocket collector remains hidden until a default")
  T.check(palletCollector.index > 3 and celadonCollector.index > 8,
    "collector additions preserve existing map object indices")
  local hasStoryMaps = run.data.maps.CINNABAR_LAB_METRONOME_ROOM
    and run.data.maps.POKEMON_MANSION_B1F
  T.check(not hasStoryMaps or (cinnabarHandler and cinnabarHandler.hidden
      and mansionResearcher and mansionResearcher.hidden),
    "final-stage contacts remain absent before the Cinnabar lead")
  T.check(not hasStoryMaps
      or (cinnabarHandler.index > 2 and mansionResearcher.index > 8),
    "story contacts allocate indices after every native map object")
  T.check(giovanni and giovanni.hidden and giovanni.index > 9,
    "Giovanni is staged after the native Arena cast and remains hidden")
end

do
  local oldItems = {}
  for badge, definition in pairs(api.gym_cases.definitions) do
    local identities = {}
    for _, reward in ipairs(definition.rewards) do
      local key = reward.kind .. ":" .. tostring(reward.id or reward.species)
      T.check(not identities[key], definition.leader .. " has no duplicate case slot")
      identities[key] = true
      if reward.kind == "item" and not run.data.items[reward.id] then
        oldItems[reward.id] = false
        run.data.items[reward.id] = { id = reward.id, name = reward.id }
      end
    end
    local rows = api.gym_cases.pool({ data = run.data }, { badge = badge })
    T.eq(#rows, 10, definition.leader .. " exposes all ten themed prizes")
    if badge == "BOULDERBADGE" then
      local species = {}
      for _, row in ipairs(rows) do
        if row.species then species[row.species] = true end
      end
      T.check(species.GEODUDE and species.ONIX and species.RHYHORN,
        "Brock's pool is visibly Rock themed")
      T.check(not species.NIDORAN_M and not species.NIDORAN_F,
        "Gym Cases no longer contain filler Nidorans")
    end
  end
  local rules = assert(loadfile("mods/blackjack_corner/other/gamble/gym_cases.lua"))()
    .rules(api.case_rules)
  local misty = api.gym_cases.pool({ data = run.data }, { badge = "CASCADEBADGE" })
  local strip = rules.strip(misty, misty[1], function() return 1 end)
  for index = 2, #strip do
    local function key(row) return row.kind .. ":" .. tostring(row.id or row.species) end
    T.check(key(strip[index]) ~= key(strip[index - 1]),
      "the themed reel never shows the same prize in adjacent slots")
  end
  for id, value in pairs(oldItems) do if value == false then run.data.items[id] = nil end end
end

do
  local Game = require("src.core.Game")
  local Data = require("src.core.Data")
  local MapScripts = require("src.script.MapScripts")
  local oldData, oldSave, oldStack, oldOverworld =
    Game.data, Game.save, Game.stack, Game.overworld
  local oldMapScripts = Data.map_scripts
  local location = api.case_challengers.locations[1]
  Game.data = run.data
  Data.map_scripts = run.data.map_scripts
  Game.save = { coins = 100, flags = {}, inventory = { [location.badge] = 1 },
    defeatedTrainers = {}, objectToggles = {}, party = {}, boxes = {},
    currentBox = 1, player = { name = "RED" } }
  Game.stack = { pushed = {}, push = function(self, screen)
    self.pushed[#self.pushed + 1] = screen
  end, pop = function(self) return table.remove(self.pushed) end,
    top = function(self) return self.pushed[#self.pushed] end }
  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = true, speech = { game = Game },
  })
  api.case_challengers.sync(Game, location.map)
  T.check(Game.save.objectToggles[location.map][location.objectName],
    "a regional challenger appears after the matching badge")
  Game.save.defeatedTrainers[api.case_challengers.saveId(location)] = true
  MapScripts.get(location.map).onVictory(Game, {})
  T.eq(#api.gym_cases.queue(), 1,
    "beating a regional challenger queues exactly one case")
  local challengerCase = api.gym_cases.queue()[1]
  T.eq(challengerCase.kind, "case_ace",
    "CASE ACE wins are tagged separately from Gym Leader rewards")
  T.eq(api.gym_cases.rewardDialogue(challengerCase, {
      kind = "pokemon", species = "GEODUDE", label = "GEODUDE",
      tier = "pokemon",
    }), nil,
    "CASE ACE prizes never inherit the matching Gym Leader's reaction")
  local temporaryItems = {}
  for _, reward in ipairs(api.case_challengers.rewards) do
    if reward.kind == "item" and not run.data.items[reward.id] then
      temporaryItems[reward.id] = true
      run.data.items[reward.id] = { id = reward.id, name = reward.id }
    end
  end
  local acePool = api.case_challengers.pool({ data = run.data }, challengerCase)
  T.eq(#acePool, #api.case_challengers.rewards,
    "CASE ACE cases expose their complete independent reward pool")
  local aceKinds, aceSpecies = {}, {}
  local totalWeight = 0
  for _, reward in ipairs(acePool) do
    aceKinds[reward.kind], totalWeight = true, totalWeight + reward.weight
    if reward.species then aceSpecies[reward.species] = true end
  end
  T.check(aceKinds.pokemon and aceKinds.item
      and aceSpecies.ABRA and aceSpecies.GROWLITHE and aceSpecies.MAGNEMITE,
    "the ACE pool mixes Pokemon and items across unrelated types")
  local firstRoll = api.case_rules.choose(acePool, function() return 1 end)
  local lastRoll = api.case_rules.choose(acePool, function() return totalWeight end)
  T.check((firstRoll.id or firstRoll.species) ~= (lastRoll.id or lastRoll.species),
    "different ACE rolls can select different rewards")
  local aceReaction = api.case_challengers.rewardDialogue(challengerCase, firstRoll)
  T.check(aceReaction and aceReaction:find("CASE ACE", 1, true)
      and not aceReaction:find("BROCK", 1, true),
    "the CASE ACE reacts in its own voice instead of borrowing the Gym Leader")
  for id in pairs(temporaryItems) do run.data.items[id] = nil end
  local rewardText = Game.stack:top()
  T.check(rewardText and rewardText.pages,
    "the challenger presents the case reward in the overworld")
  rewardText.onDone()
  local aceScreen = Game.stack:top()
  T.eq(aceScreen.screenId, "BlackjackCornerGymCase",
    "acknowledging the challenger reward opens its independent reel")
  T.eq(aceScreen.title, "ACE CASE",
    "the challenger reel is labeled separately from a Gym Case")
  aceScreen:update(0)
  local aceWinnerKey = aceScreen.winner.id or aceScreen.winner.species
  local validAceWinner = false
  for _, reward in ipairs(acePool) do
    validAceWinner = validAceWinner
      or (reward.id or reward.species) == aceWinnerKey
  end
  T.check(validAceWinner,
    "the live CASE ACE screen chooses from the independent mixed pool")
  MapScripts.get(location.map).onVictory(Game, {})
  T.eq(#api.gym_cases.queue(), 1,
    "replayed victory hooks cannot duplicate a challenger case")
  api.gym_cases.onDelivered(api.gym_cases.queue()[1])
  Game.save.defeatedTrainers[api.case_challengers.saveId(location)] = nil
  api.case_challengers.sync(Game, location.map)
  T.check(Game.save.defeatedTrainers[api.case_challengers.saveId(location)],
    "the stable CASE ACE award repairs a shifted runtime object index")
  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = false, speech = { game = Game },
  })
  T.check(not Game.save.objectToggles[location.map][location.objectName],
    "regional challengers disappear when Gamble Mode is disabled")

  Runtime.emit("intro.oak_speech.answered", {
    saveKey = "gamble_mode", value = true, speech = { game = Game },
  })
  Game.save.objectToggles[location.map][location.objectName] = nil
  local reloaded
  Game.overworld = {
    map = { id = location.map },
    reloadMap = function(_, mapId, reason)
      if reason == "case-challenger-sync" then
        reloaded = { mapId, reason }
      end
    end,
  }
  Runtime.emit("save.loaded", { save = {
    player = { map = location.map },
  } })
  T.check(Game.save.objectToggles[location.map][location.objectName],
    "CONTINUE applies a badge-earned CASE ACE toggle to the loaded save")
  T.check(reloaded and reloaded[1] == location.map
      and reloaded[2] == "case-challenger-sync",
    "CONTINUE rebuilds a live CASE ACE city after reconciling its toggle")
  reloaded = nil
  Game.overworld.map.id = "PALLET_TOWN"
  Runtime.emit("save.loaded", { save = {
    player = { map = "PALLET_TOWN" },
  } })
  T.eq(reloaded, nil,
    "CONTINUE does not rebuild maps that cannot contain a CASE ACE")
  Data.map_scripts = oldMapScripts
  Game.data, Game.save, Game.stack, Game.overworld =
    oldData, oldSave, oldStack, oldOverworld
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
  T.eq(api.view.suitSignature("C", true), "010/111/010",
    "corner clubs keep the compact cross silhouette")
  T.eq(api.view.suitSignature("S", true), "010/111/101",
    "corner spades keep their proven pointed split-body silhouette")
  T.eq(api.view.suitSignature("S", true), "010/111/101",
    "compact spades preserve a pointed crown and split lower lobes")
  T.check(api.view.suitSignature("C", true)
      ~= api.view.suitSignature("S", true),
    "compact club and spade pips are not pixel-identical")
  T.eq(api.view.pipSignature("C"), "010/111/010",
    "numeric clubs use the compact cross pip from the preferred layout")
  T.eq(api.view.pipSignature("S"), "010/101/111/010",
    "numeric spades use the former pointed club pip")
  T.eq(api.view.suitSignature("C", false),
    "0000011100000/0000111110000/0001111111000/0001111111000/0000111110000/0111001001110/1111101011111/1111111111111/0111101011110/0011001001100/0000011100000/0000011100000/0001111111000",
    "ace clubs use three notched lobes, a short stem, and a flared base")
  T.eq(api.view.suitSignature("S", false),
    "00000100000/00001110000/00011111000/00111111100/01111111110/11111111111/11111111111/11111111111/11110101111/01100100110/00000100000/00001110000",
    "ace spades keep a detailed pointed crown, lower lobes, and narrow stem")
  T.check(api.view.suitSignature("C", false)
      ~= api.view.suitSignature("S", false),
    "large club and spade emblems remain distinguishable")
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

local noInput = { wasPressed = function() return false end }

local function withStack(game)
  game.input = noInput
  game.stack = { items = {} }
  function game.stack:push(screen) self.items[#self.items + 1] = screen end
  function game.stack:pop() return table.remove(self.items) end
  function game.stack:top() return self.items[#self.items] end
  return game
end

local function clearPawnLedger()
  local ledger = api.pawnLedger()
  for index = #ledger, 1, -1 do table.remove(ledger, index) end
end

local function fixtureMon(species, level)
  return Pokemon.new(run.data, species or "FIXMON_A", level or 20,
    function() return 8 end)
end

do
  local options = run.loader.modOptions.blackjack_corner or {}
  run.loader.modOptions.blackjack_corner = options
  local function stackGame()
    local game = withStack(gameWith(10000))
    game.save.inventory.COIN_CASE = 1
    return game
  end

  options.shiny_upgrades = false
  local game = stackGame()
  local prizes = run.data.screens.BlackjackCornerPokemonPrizes.new(game, {})
  prizes.onChoose(prizes.items[1])
  T.eq(#game.stack:top().items, 2,
    "disabling shiny upgrades leaves NORMAL and CANCEL prize actions")
  T.eq(game.stack:top().items[1].label:sub(1, 6), "NORMAL",
    "the ordinary Pokemon prize remains available without shiny upgrades")

  options.shiny_upgrades = true
  game = stackGame()
  prizes = run.data.screens.BlackjackCornerPokemonPrizes.new(game, {})
  prizes.onChoose(prizes.items[1])
  T.eq(#game.stack:top().items, 3,
    "enabling shiny upgrades restores NORMAL, SHINY, and CANCEL actions")
  T.eq(game.stack:top().items[2].label:sub(1, 5), "SHINY",
    "the paid shiny prize action is restored")

  game = stackGame()
  game.save.money = 5000
  local cityClerk
  for _, contribution in ipairs(
      run.loader.content.map_scripts:chain("VIRIDIAN_SCHOOL_HOUSE")) do
    cityClerk = cityClerk or (contribution.talk
      and contribution.talk.TEXT_CITY_CASINO_CLERK)
  end
  T.check(type(cityClerk) == "function",
    "regional casinos expose their shared clerk interaction")
  local function clerkFor(mapId, textId)
    for _, contribution in ipairs(run.loader.content.map_scripts:chain(mapId)) do
      if contribution.talk and contribution.talk[textId] then
        return contribution.talk[textId]
      end
    end
  end
  T.eq(clerkFor("PALLET_CASINO", "TEXT_PALLET_CASINO_CLERK"), cityClerk,
    "Pallet shares the regional early-redemption counter")
  T.eq(clerkFor("GAME_CORNER", "TEXT_GAMECORNER_CLERK1"), cityClerk,
    "Celadon's coin desk shares redemption while its full Prize Room remains")
  cityClerk(game, nil, nil)
  local counter = game.stack:top()
  T.eq(counter.items[1].label, "BUY COINS",
    "every city casino clerk still sells coins")
  T.eq(counter.items[2].label, "CASH OUT",
    "every city casino clerk converts coins back into money")
  T.eq(counter.items[3].label, "REDEEM POKEMON",
    "every city casino clerk offers early Pokemon redemption")

  local cashGame = stackGame()
  cashGame.save.coins, cashGame.save.money = 100, 0
  cityClerk(cashGame, nil, nil)
  local cashCounter = cashGame.stack:pop()
  cashCounter.items[2].onSelect()
  local cashIntro = cashGame.stack:pop()
  T.check(cashIntro and type(cashIntro.onDone) == "function",
    "the clerk explains the cash-out rate before listing bundles")
  cashIntro.onDone()
  local cashList = cashGame.stack:top()
  T.eq(cashList.title, "CASH OUT",
    "the wired clerk action opens the cash-out list")
  cashList.onChoose(cashList.items[1])
  T.eq(cashGame.save.coins, 50,
    "the clerk UI deducts the selected cash-out bundle")
  T.eq(cashGame.save.money, 1000,
    "the clerk UI credits the matching ordinary-money payout")

  game.stack:pop()
  counter.items[3].onSelect()
  local localPrizes = game.stack:top()
  T.check(#localPrizes.items > 0 and #localPrizes.items < #prizes.items,
    "regional counters use a useful but limited Pokemon prize selection")

  local redeemGame = stackGame()
  redeemGame.save.inventory.COIN_CASE = 1
  local redeemList = run.data.screens.BlackjackCornerPokemonPrizes.new(redeemGame, {})
  redeemGame.stack:push(redeemList)
  redeemList.onChoose(redeemList.items[1])
  local choice = redeemGame.stack:pop()
  choice.items[1].onSelect()
  local received = redeemGame.stack:top()
  T.check(received and type(received.onDone) == "function",
    "a redeemed Pokemon result continues into the nickname handoff")
  redeemGame.stack:pop()
  received.onDone()
  T.check(redeemGame.stack:top() and redeemGame.stack:top().choice,
    "redeemed Pokemon offer the native-style nickname question")

  local loungeTalk
  for _, contribution in ipairs(
      run.loader.content.map_scripts:chain("BLACKJACK_LOUNGE")) do
    loungeTalk = loungeTalk or (contribution.talk
      and contribution.talk.TEXT_BLACKJACK_TABLE)
  end
  T.check(type(loungeTalk) == "function",
    "the settings integration reaches a real casino table handler")
  options.table_intros = false
  game = stackGame()
  loungeTalk(game, nil, nil)
  T.eq(game.stack:top().screenId, "BlackjackCornerTable",
    "disabling table intros opens an ordinary game directly")
  options.table_intros = true
  game = stackGame()
  loungeTalk(game, nil, nil)
  T.check(game.stack:top().pages and not game.stack:top().screenId,
    "enabling table intros keeps the rules card before an ordinary game")

  options.reveal_speed = "fast"
  game = stackGame()
  local case = run.data.screens.BlackjackCornerPrizeCase.new(game, {})
  case.phase, case.elapsed, case.duration = "spinning", 0, 2
  case:update(1 / 60)
  T.check(case.elapsed > 0.02,
    "the reveal-speed setting reaches a real reel animation")

  run.loader.modOptions.blackjack_corner = {}
end

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
  local game = gameWith(1300, 0)
  game.save.inventory.COIN_CASE = 1
  local offers = api.cashOutOffers(game)
  T.eq(#offers, 5, "cash-out offers useful bundles plus the exact maximum")
  T.eq(offers[1].amount, 50, "cash-out preserves the original 50-coin bundle")
  T.eq(offers[4].amount, 1000, "cash-out offers a bulk thousand-coin shortcut")
  T.eq(offers[5].amount, 1300, "cash-out MAX uses every complete bundle")
  T.eq(offers[5].payout, 26000, "cash-out MAX uses the symmetric exchange rate")
  local ok, _, payout = api.cashOutCoins(game, 500)
  T.check(ok, "casino coins can be cashed out for ordinary money")
  T.eq(payout, 10000, "five hundred coins pay ten thousand money")
  T.eq(game.save.coins, 800, "cash-out deducts the selected casino coins")
  T.eq(game.save.money, 10000, "cash-out credits the full ordinary-money payout")
end

do
  local game = gameWith(100, 998999)
  game.save.inventory.COIN_CASE = 1
  local offers = api.cashOutOffers(game)
  T.eq(#offers, 1, "wallet capacity trims cash-out to one complete bundle")
  T.eq(offers[1].amount, 50, "the capacity-limited offer spends only fifty coins")
  local ok = api.cashOutCoins(game, offers[1].amount)
  T.check(ok, "cash-out can reach the native money cap exactly")
  T.eq(game.save.money, 999999, "cash-out never crosses the native money cap")
  T.eq(game.save.coins, 50, "capacity-limited cash-out leaves unused coins intact")
  T.eq(#api.cashOutOffers(game), 0, "a full wallet has no misleading cash-out offer")
end

do
  local game = gameWith(100, 999000)
  game.save.inventory.COIN_CASE = 1
  T.eq(#api.cashOutOffers(game), 0,
    "cash-out refuses wallet space smaller than one full payout")
  local ok = api.cashOutCoins(game, 50)
  T.check(not ok, "cash-out refuses a payout that would overflow the wallet")
  T.eq(game.save.money, 999000, "overflow refusal leaves ordinary money unchanged")
  T.eq(game.save.coins, 100, "overflow refusal leaves casino coins unchanged")

  ok = api.cashOutCoins(game, 25)
  T.check(not ok, "cash-out refuses partial exchange bundles")
  T.eq(game.save.coins, 100, "partial-bundle refusal remains atomic")

  game.save.inventory.COIN_CASE = nil
  game.save.money = 0
  ok = api.cashOutCoins(game, 50)
  T.check(not ok, "cash-out still requires a Coin Case")
  T.eq(game.save.money, 0, "missing-Coin-Case refusal gives no money")
  T.eq(game.save.coins, 100, "missing-Coin-Case refusal takes no coins")
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
  local game = gameWith(250, 5000)
  game.save.inventory.COIN_CASE = 1
  local ok = api.house.pawnHome(game)
  T.check(ok, "the integrated campaign can pawn the home at any balance")
  T.eq(game.save.coins, 10250, "the integrated house pawn adds exactly ten thousand")
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
  local game = withStack(gameWith(100, 3000))
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
  T.check(game.stack:top() and game.stack:top().choice,
    "roulette starters offer the native-style nickname question")
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

  local pokemonGame = withStack(gameWith(0))
  pokemonGame.save.inventory.COIN_CASE = 1
  local ok, message, destination = api.giveCaseReward(pokemonGame, {
    kind = "pokemon", species = "FIXMON_A", level = 20, label = "FIXMON A",
  })
  T.check(ok, "case Pokemon rewards use safe party and PC delivery")
  T.eq(#pokemonGame.save.party, 1, "a case Pokemon reaches an open party slot")
  T.eq(message, "FIXMON A", "the case result names the Pokemon reward")
  T.eq(destination, "party", "the delivery result identifies the party destination")
  local nicknamePrompt = pokemonGame.stack:top()
  T.check(nicknamePrompt and nicknamePrompt.choice,
    "case Pokemon offer the native-style nickname question")
  nicknamePrompt.choice(true)
  local naming = pokemonGame.stack:top()
  naming.onDone("JACKPOT")
  T.eq(pokemonGame.save.party[1].nickname, "JACKPOT",
    "the shared prize nickname handoff writes the chosen name")

  local boxGame = withStack(gameWith(0))
  for _ = 1, 6 do boxGame.save.party[#boxGame.save.party + 1] = fixtureMon() end
  ok, _, destination = api.giveCaseReward(boxGame, {
    kind = "pokemon", species = "FIXMON_A", level = 20, label = "BOX TEST",
  })
  T.check(ok and destination == "BOX 1",
    "case Pokemon can enter the nickname flow after PC delivery")
  boxGame.stack:top().choice(true)
  boxGame.stack:top().onDone("BOXJACK")
  T.eq(boxGame.save.boxes[1][1].nickname, "BOXJACK",
    "a nickname edits the exact Pokemon deposited in the PC")

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
  for _, gameId in ipairs({ "blackjack", "holdem", "crash", "tube_flyer",
      "prize_case", "horse_racing", "plinko" }) do
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

  local blackjackReturned = snapshot.byGame.blackjack.returned
  game = prepared(999990)
  blackjack = run.data.screens.BlackjackCornerTable.new(game, {})
  blackjack.reputationRound = api.reputation.beginRound("blackjack", 10)
  blackjack.round = { state = "done", result = "win", payout = 25, bet = 10 }
  blackjack:recordRound()
  T.eq(game.save.coins, 1000000,
    "Blackjack credits only the payout that fits in the Coin Case")
  T.eq(api.reputation.snapshot(game).byGame.blackjack.returned,
    blackjackReturned + 10,
    "Blackjack statistics record the payout actually delivered")

  local holdemReturned = snapshot.byGame.holdem.returned
  game = prepared(999990)
  holdem = run.data.screens.BlackjackCornerHoldemTable.new(game, {})
  holdem.reputationRound = api.reputation.beginRound("holdem", 10)
  holdem.round = { state = "done", result = "win", payout = 40 }
  holdem:recordRound()
  T.eq(game.save.coins, 1000000,
    "Hold'em credits only the payout that fits in the Coin Case")
  T.eq(api.reputation.snapshot(game).byGame.holdem.returned,
    holdemReturned + 10,
    "Hold'em statistics record the payout actually delivered")

  game = prepared()
  blackjack = run.data.screens.BlackjackCornerTable.new(game, {})
  blackjack:deal()
  game.stack = { top = function() return blackjack end }
  T.eq(Runtime.call("save.write", function() return true end, game), false,
    "saving is vetoed while an instant table round cannot be resumed")
  blackjack.round.state, blackjack.round.result = "done", "loss"
  blackjack.round.payout = 0
  blackjack:recordRound()
  T.eq(Runtime.call("save.write", function() return true end, game), true,
    "saving resumes after the instant table round settles")

  game = prepared()
  tube = run.data.screens.BlackjackCornerTubeFlyer.new(game, {})
  tube:start()
  game.stack = { top = function() return tube end }
  T.eq(Runtime.call("save.write", function() return true end, game), false,
    "saving is vetoed while an animated arcade round cannot be resumed")
  tube:finish()
  T.eq(Runtime.call("save.write", function() return true end, game), true,
    "saving resumes after the animated arcade round settles")

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
  local stressState = {
    rank = "REGULAR", rankLabel = "REGULAR", points = 999999,
    nextRank = api.reputation_rules.RANKS[3], badges = 2,
    wins = 999999, losses = 123456, draws = 87654,
    lifetimeWagered = 999999999, currentLossStreak = 999999,
    favoriteGame = { label = "TUBE FLYER" }, pendingRewardCoins = 999999,
  }
  local statusModel = status:viewModel(stressState)
  local Font = require("src.render.Font")
  T.eq(statusModel.wins, "999K",
    "the High Roller panel abbreviates late-game win counts")
  T.eq(statusModel.wagered, "999M",
    "the High Roller panel abbreviates late-game wager totals")
  T.check(Font.width(statusModel.wins) <= 32
      and Font.width(statusModel.losses) <= 32
      and Font.width(statusModel.draws) <= 32,
    "record counters remain inside their reserved status columns")
  T.check(Font.width(statusModel.favorite) <= 80,
    "favorite game names fit their dedicated status row")
  local endingModel = status:viewModel(stressState, {
    ending = { choice = "CHAMPION", rewardPending = 15000 },
  })
  T.check(endingModel.ending == "CHAMPION" and endingModel.hasEndingBank,
    "the High Roller panel exposes the permanent champion title and reward bank")
  T.eq(endingModel.endingBank, "15K",
    "the champion reward uses the panel's bounded value formatting")
  status.snapshot, status.rankUp = stressState, nil
  status.story = { ending = { choice = "CHAMPION", rewardPending = 15000 } }
  status:draw()
  T.check(true,
    "the High Roller status panel renders large values without an engine error")

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
