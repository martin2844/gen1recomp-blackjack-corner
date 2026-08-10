return function(game)
  local U = dofile("tests/drivers/util.lua")
  U.wait(10)
  local loader = assert(game.mods, "mod loader is unavailable")
  local exports = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true
  bucket.gamble_campaign = exports.campaign_state.defaults()
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  game.save.coins, game.save.money = 0, 0
  exports.house_world.sync(game, exports.house)

  U.teleport(game, "BLACKJACK_LOUNGE", 17, 12, "right")
  U.tap(game, "a")
  U.wait(240)
  U.tap(game, "a")
  U.wait(240)
  U.tap(game, "a")
  U.wait(10)
  U.tap(game, "down")
  U.wait(5)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v06/bailout"
  U.shot(game, shotDir .. "/last-resort-menu.png")
  U.tap(game, "a")
  U.wait(180)
  U.shot(game, shotDir .. "/last-resort-confirmation.png")
  U.log("Zero money / zero coins prepared with LAST RESORT highlighted.")
  U.log("Test NO first, then YES. Verify exactly 10000 coins and one-time use.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
