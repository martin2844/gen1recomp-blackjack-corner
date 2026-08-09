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
  game.save.coins, game.save.money = 100, 3000

  U.teleport(game, "BLACKJACK_LOUNGE", 17, 12, "right")
  U.tap(game, "a")
  U.wait(240)
  U.tap(game, "a") -- advance to the second greeting page
  U.wait(240)
  U.tap(game, "a") -- acknowledge the greeting and open the credit menu
  U.wait(10)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v06/credit"
  U.shot(game, shotDir .. "/rocket-credit-menu.png")
  U.log("Rocket Credit prepared with a clean Rookie account.")
  U.log("Take the 500-coin loan, inspect the statement, then repay both ways.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
