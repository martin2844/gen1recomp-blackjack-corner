-- Captures the High Roller panel at the reported mid-game state and at a
-- deliberately extreme late-game state. The second checkpoint protects every
-- fixed status column from growing counters and a banked rank reward.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  U.wait(10)

  local loader = assert(game.mods, "mod loader is unavailable")
  local api = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true

  local campaign = api.campaign_state.defaults()
  local rep = campaign.reputation
  rep.points, rep.rank = 112, "REGULAR"
  rep.wins, rep.losses, rep.draws = 10, 5, 0
  rep.lifetimeWagered, rep.currentLossStreak = 1360, 1
  rep.rankRewardsClaimed.REGULAR = true
  rep.byGame.crash = {
    played = 8, wins = 5, losses = 3, draws = 0,
    wagered = 1360, returned = 1200,
  }
  bucket.gamble_campaign = campaign
  game.save.inventory = { COIN_CASE = 1, BOULDERBADGE = 1 }
  game.save.coins = 1000

  local stress = os.getenv("STATUS_STRESS") == "1"
  if stress then
    rep.points = 999999
    rep.wins, rep.losses, rep.draws = 999999, 123456, 87654
    rep.lifetimeWagered, rep.currentLossStreak = 999999999, 999999
    rep.pendingRewardCoins = 999999
    rep.byGame.tube_flyer = {
      played = 999999, wins = 500000, losses = 499999, draws = 0,
      wagered = 999999999, returned = 999999999,
    }
    game.save.inventory.CASCADEBADGE = 1
    game.save.coins = 1000000
  end

  U.teleport(game, "PALLET_CASINO", 10, 11, "up")
  U.wait(60)
  require("src.ui.Screens").push(game, "BlackjackCornerHighRoller")
  -- POKEPORT_SPEED can consume several driver frames per actual render.
  -- Leave enough rendered frames for the native palette and full panel.
  U.wait(30)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-status-ui"
  local filename = stress and "high-roller-large-values.png"
    or "high-roller-112-rep.png"
  assert(U.shot(game, shotDir .. "/" .. filename))

  U.log("High Roller status UI captured:", filename)
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
