-- Prepares a fresh Gamble Mode casino visit, captures a baseline, and then
-- yields forever so the tester can supervise the UI with normal controls.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  U.wait(10)

  local loader = assert(game.mods, "mod loader is unavailable")
  local exports = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  assert(exports.gamble, "Gamble Mode export is unavailable")

  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true
  bucket.gamble_campaign = nil

  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = math.max(1,
    tonumber(game.save.inventory.COIN_CASE) or 0)
  game.save.coins = math.max(500, tonumber(game.save.coins) or 0)

  U.teleport(game, "PALLET_CASINO", 10, 11, "up")
  exports.reputation.ensure()
  require("src.ui.Screens").push(game, "BlackjackCornerHighRoller")
  U.wait(5)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v05/fresh"
  U.shot(game, shotDir .. "/high-roller-fresh.png")

  U.log("Fresh Gamble Mode save prepared in PALLET CASINO.")
  U.log("The High Roller panel is open. Press B, then play each game.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
