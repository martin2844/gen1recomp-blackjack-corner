-- Native Red/Blue audit for the regional casino network. It walks the real
-- exterior and interior warp records, opens every service through an A press,
-- checks badge-gated CASE ACE visibility, and captures the imported layouts.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Screens = require("src.ui.Screens")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local loader = assert(game.mods, "mod loader is unavailable")
  local api = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket

  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  game.save.coins = 25000
  game.save.money = 100000
  game.save.party = game.save.party or {}
  game.save.boxes = game.save.boxes or {}
  game.save.currentBox = game.save.currentBox or 1
  game.save.flags = game.save.flags or {}
  game.save.defeatedTrainers = game.save.defeatedTrainers or {}
  game.save.objectToggles = game.save.objectToggles or {}

  local passed = {}
  local function pass(id, note)
    assert(not passed[id], "duplicate case " .. id)
    passed[id] = true
    U.log("PASS", id, note or "")
  end
  local function settleMap(mapId)
    for _ = 1, 360 do
      local ow = game.overworld
      if ow and ow.map and ow.map.id == mapId and not ow.transitioning
          and not ow.player.moving then return true end
      U.wait(1)
    end
    error("did not reach " .. tostring(mapId))
  end
  local function enterWarp(mapId, warp)
    U.teleport(game, mapId, warp.x, math.max(0, warp.y - 1), "down")
    U.hold(game, "down", 35)
  end
  local function openPhysical(mapId, x, y, facing, screenId)
    local screenDef = assert(game.data.screens[screenId], "missing " .. screenId)
    local expectedMeta = getmetatable(screenDef.new(game, {}))
    U.teleport(game, mapId, x, y, facing)
    local ow = assert(game.overworld)
    local fx, fy = ow.player:facingCell()
    local npc = ow:npcAtCell(fx, fy)
    assert(npc,
      ("no casino object faced at %s %d,%d"):format(mapId, fx, fy))
    local MapScripts = require("src.script.MapScripts")
    assert(type(MapScripts.talkScript(mapId, npc.def.text)) == "function",
      ("no talk handler for %s/%s"):format(mapId, tostring(npc.def.text)))
    ow:interact()
    U.wait(2)
    -- Native text boxes reveal at the ROM cadence even when the rest of the
    -- driver is accelerated. Leave enough frames for the two-page city intro
    -- before expecting the game screen.
    for _ = 1, 160 do
      local top = game.stack:top()
      if top and getmetatable(top) == expectedMeta then return top end
      U.tap(game, "a")
      U.wait(3)
    end
    error(("%s did not open at %s %d,%d"):format(screenId, mapId, x, y))
  end
  local function closeScreen(mapId)
    U.tap(game, "b")
    U.wait(10)
    assert(game.overworld and game.overworld.map.id == mapId,
      "closing a casino screen left its branch")
  end
  local function findObject(mapId, name)
    for _, object in ipairs(game.data.maps[mapId].objects or {}) do
      if object.name == name then return object end
    end
  end

  U.wait(10)
  for index, location in ipairs(api.city_casinos.locations) do
    local exterior = assert(game.data.maps[location.exterior])
    local interior = assert(game.data.maps[location.interior])
    local source = assert(exterior.warps[location.sourceWarp])
    local signFound = false
    for _, sign in ipairs(exterior.signs or {}) do
      signFound = signFound or sign.text == "TEXT_REGIONAL_CASINO_SIGN"
    end
    assert(signFound, location.city .. " casino sign missing")

    U.teleport(game, location.exterior, source.x, math.max(0, source.y - 2), "down")
    U.wait(20)
    assert(U.shot(game, ("%s/%02d-%s-exterior.png"):format(
      shotDir, index, location.key:lower())))

    if location.key == "CINNABAR" then
      enterWarp(location.exterior, source)
      settleMap("CINNABAR_LAB")
      local labDoor = assert(game.data.maps.CINNABAR_LAB.warps[3])
      enterWarp("CINNABAR_LAB", labDoor)
    else
      enterWarp(location.exterior, source)
    end
    settleMap(location.interior)
    assert(U.shot(game, ("%s/%02d-%s-interior.png"):format(
      shotDir, index, location.key:lower())))

    openPhysical(location.interior, 2, 1, "down", "BlackjackCornerTable")
    closeScreen(location.interior)
    openPhysical(location.interior, 8, 1, "down", "BlackjackCornerHoldemTable")
    closeScreen(location.interior)
    local specialIds = {
      crash = "BlackjackCornerCrash", tube = "BlackjackCornerTubeFlyer",
      case = "BlackjackCornerPrizeCase", horse = "BlackjackCornerHorseRacing",
      plinko = "BlackjackCornerPlinko",
    }
    openPhysical(location.interior, 5, 3, "up",
      assert(specialIds[location.special]))
    closeScreen(location.interior)

    U.teleport(game, location.interior, 6, 8, "down")
    U.hold(game, "down", 35)
    local expectedExit = location.key == "CINNABAR"
      and "CINNABAR_LAB" or location.exterior
    settleMap(expectedExit)
    pass("CITY-" .. location.key,
      "sign, entrance, blackjack, holdem, local machine, and exit")

  end

  -- CASE ACE locations are keyed to Gyms, not the branch list (Lavender has a
  -- casino but no Gym; Celadon has a Gym but its flagship casino predates this
  -- compact network). Verify every real imported object and its badge toggle.
  for index, location in ipairs(api.case_challengers.locations) do
    game.save.inventory[location.badge] = 1
    api.case_challengers.sync(game, location.map)
    assert(game.save.objectToggles[location.map][location.objectName] == true,
      location.key .. " CASE ACE did not appear")
    local object = assert(findObject(location.map, location.objectName))
    assert(object.trainerClass == location.trainer
      and object.trainerParty == location.party)
    U.teleport(game, location.map, object.x,
      math.min(object.y + 2, game.data.maps[location.map].height * 2 - 1), "up")
    U.wait(15)
    assert(U.shot(game, ("%s/%02d-%s-case-ace.png"):format(
      shotDir, index, location.key:lower())))
  end
  pass("ACE-VISIBILITY", "all eight post-badge trainers appeared")

  for badge, definition in pairs(api.gym_cases.definitions) do
    local pool = api.gym_cases.pool(game, { badge = badge })
    assert(#pool == 10, definition.leader .. " themed pool is incomplete")
    local identities, pokemon, items = {}, 0, 0
    for _, reward in ipairs(pool) do
      local id = reward.kind .. ":" .. tostring(reward.id or reward.species)
      assert(not identities[id], definition.leader .. " repeats " .. id)
      identities[id] = true
      if reward.kind == "pokemon" then pokemon = pokemon + 1 else items = items + 1 end
    end
    assert(pokemon > 0 and items > 0,
      definition.leader .. " pool does not mix Pokemon and items")
  end
  pass("GYM-POOLS", "all eight imported themed pools contain ten unique prizes")

  Screens.push(game, "BlackjackCornerGymCase", {
    caseData = { id = "manual:water", badge = "CASCADEBADGE", order = 2,
      leader = "MISTY" },
    autoOpen = true, oneShot = true, title = "WATER CASE",
  })
  U.wait(90)
  assert(U.shot(game, shotDir .. "/themed-water-case.png"))
  pass("GYM-REEL", "native themed Gym Case rendered")

  U.log("CASINO NETWORK AUDIT COMPLETE")
end
