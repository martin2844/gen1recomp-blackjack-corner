return function(game)
  local U = dofile("tests/drivers/util.lua")
  U.wait(10)
  local loader = assert(game.mods, "mod loader is unavailable")
  local exports = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true
  local state = exports.campaign_state.defaults()
  state.reputation.points = 100
  state.reputation.rank = "REGULAR"
  state.reputation.rankRewardsClaimed.REGULAR = true
  state.reputation.pendingRankUps = { "REGULAR" }
  bucket.gamble_campaign = state
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE, game.save.inventory.BOULDERBADGE = 1, 1
  game.save.coins = math.max(750, tonumber(game.save.coins) or 0)

  U.teleport(game, "BLACKJACK_LOUNGE", 10, 11, "up")
  require("src.ui.Screens").push(game, "BlackjackCornerHighRoller")
  U.wait(5)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v05/rank-up"
  U.shot(game, shotDir .. "/regular-rank-up.png")
  U.log("REGULAR rank-up presentation prepared; it must appear only once.")
  U.log("Close and reopen HIGH ROLLER to verify the banner does not repeat.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
