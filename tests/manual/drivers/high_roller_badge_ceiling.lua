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
  state.reputation.points = 550
  state.reputation.rank = "ROOKIE"
  bucket.gamble_campaign = state
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  for _, badge in ipairs(exports.reputation_rules.BADGES) do
    game.save.inventory[badge] = nil
  end

  U.teleport(game, "PALLET_CASINO", 10, 11, "up")
  require("src.ui.Screens").push(game, "BlackjackCornerHighRoller")
  U.wait(5)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v05/badge-lock"
  U.shot(game, shotDir .. "/badge-ceiling.png")
  U.log("550 REP is banked with no badges; rank must remain ROOKIE.")
  U.log("The panel must clearly say that one badge is required.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
