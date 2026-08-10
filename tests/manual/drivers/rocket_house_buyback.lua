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
  local home = bucket.gamble_campaign.house
  home.status, home.bailoutClaimed, home.buybackPaid =
    "BUYBACK_PAID", true, true
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  game.save.defeatedTrainers = game.save.defeatedTrainers or {}
  game.save.defeatedTrainers[exports.house_world.challengeSaveId()] = nil
  exports.house_world.sync(game, exports.house)

  U.teleport(game, "REDS_HOUSE_1F", 4, 4, "right")
  U.wait(180)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v06/buyback"
  U.shot(game, shotDir .. "/rocket-house-challenge.png")
  U.tap(game, "a")
  U.wait(180)
  U.shot(game, shotDir .. "/rocket-house-challenge-dialogue.png")
  U.log("Deed paid; advance the Rocket dialogue to test the restoration battle.")
  U.log("Lose once if practical, retry, win, exit/re-enter, and verify full restoration.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
