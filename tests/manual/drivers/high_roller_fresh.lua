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
  U.log("Start a NEW GAME and answer YES to Oak's Gamble Mode prompt.")
  while bucket.gamble_mode == nil do coroutine.yield() end
  assert(bucket.gamble_mode == true, "fresh scenario requires Gamble Mode YES")
  assert((game.save.inventory or {}).COIN_CASE == 1,
    "Oak's Gamble Mode flow did not grant the Coin Case")
  assert((tonumber(game.save.coins) or 0) == 100,
    "Oak's Gamble Mode flow did not grant exactly 100 starting coins")
  assert(bucket.gamble_campaign ~= nil,
    "Oak's Gamble Mode flow did not initialize campaign state")

  U.teleport(game, "PALLET_CASINO", 10, 11, "up")
  require("src.ui.Screens").push(game, "BlackjackCornerHighRoller")
  U.wait(5)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v05/fresh"
  U.shot(game, shotDir .. "/high-roller-fresh.png")

  U.log("Fresh Gamble Mode save prepared in PALLET CASINO.")
  U.log("The High Roller panel is open. Press B, then play each game.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
