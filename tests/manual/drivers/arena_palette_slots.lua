-- Native verification for B1 palette cycling and the six usable ROM slots.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local PaletteFX = require("src.render.PaletteFX")
  local SlotMachine = require("src.ui.SlotMachine")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  U.wait(10)

  local loader = assert(game.mods, "mod loader is unavailable")
  local api = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  bucket.gamble_campaign.reputation.points = 4000
  bucket.gamble_campaign.reputation.rank = "KINGPIN"
  game.save.inventory.COIN_CASE = 1
  game.save.coins = 5000

  local function setMode(mode, file)
    PaletteFX.setMode(mode)
    game.save.options.colors = mode
    U.wait(45)
    assert(game.overworld.map.id == api.arena_world.LOBBY,
      "palette reload left casino B1")
    assert(U.shot(game, shotDir .. "/" .. file))
  end

  U.teleport(game, api.arena_world.LOBBY, 9, 9, "up")
  setMode("ogred", "00-og-hardware.png")
  game:keypressed("2")
  U.wait(45)
  assert(PaletteFX.mode == "gbc", "hotkey 2 did not advance to SGB")
  assert(U.shot(game, shotDir .. "/01-sgb.png"))
  game:keypressed("2")
  U.wait(45)
  assert(PaletteFX.mode == "redpp", "hotkey 2 did not advance to ADVANCED")
  assert(U.shot(game, shotDir .. "/02-advanced.png"))
  game:keypressed("2")
  U.wait(45)
  assert(PaletteFX.mode == "og", "hotkey 2 did not advance to OG")
  assert(U.shot(game, shotDir .. "/03-og.png"))

  -- Approach the first left bank from its inner aisle. Stock Game Corner
  -- chairs are solid, so the playable event lives on the chair cell exactly
  -- as it does in the ROM while the player stops beside it.
  U.teleport(game, api.arena_world.LOBBY, 8, 10, "left")
  U.wait(10)
  local player = game.overworld.player
  assert(player.cellX == 8 and player.cellY == 10,
    ("could not sit at native B1 slot: reached %s,%s"):format(
      tostring(player.cellX), tostring(player.cellY)))
  assert(U.shot(game, shotDir .. "/04-native-seat-position.png"))
  U.tap(game, "a")
  U.wait(15)
  local screen = game.stack:top()
  assert(getmetatable(screen) == SlotMachine and screen.screenId == "SlotMachine",
    "the native B1 cabinet did not open the SlotMachine screen")
  assert(U.shot(game, shotDir .. "/05-native-slot-ui.png"))

  U.tap(game, "b")
  U.wait(20)
  assert(getmetatable(game.stack:top()) ~= SlotMachine,
    "the native slot screen did not return control to B1")
  PaletteFX.setMode("ogred")
  game.save.options.colors = "ogred"
  U.teleport(game, api.arena_world.ARENA, 12, 10, "left")
  U.wait(45)
  assert(U.shot(game, shotDir .. "/06-b2-og-hardware.png"))
  game:keypressed("2")
  U.wait(45)
  assert(PaletteFX.mode == "gbc", "B2 did not advance to SGB with hotkey 2")
  assert(U.shot(game, shotDir .. "/07-b2-sgb.png"))

  U.log("ARENA PALETTE AND SLOT AUDIT COMPLETE")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
