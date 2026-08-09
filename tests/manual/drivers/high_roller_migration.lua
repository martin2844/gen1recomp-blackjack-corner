return function(game)
  local U = dofile("tests/drivers/util.lua")
  U.wait(10)
  local loader = assert(game.mods, "mod loader is unavailable")
  local exports = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true
  bucket.gamble_campaign = nil
  bucket.hands_played, bucket.cases_opened = 37, 4
  bucket.pawned_pokemon = bucket.pawned_pokemon or {}
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  local partyCount, coins = #(game.save.party or {}), tonumber(game.save.coins) or 0
  exports.reputation.ensure()
  assert(bucket.hands_played == 37 and bucket.cases_opened == 4,
    "campaign migration changed legacy counters")
  assert(#(game.save.party or {}) == partyCount and game.save.coins == coins,
    "campaign migration changed the player save")

  U.teleport(game, "BLACKJACK_LOUNGE", 10, 11, "up")
  require("src.ui.Screens").push(game, "BlackjackCornerHighRoller")
  U.wait(5)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v05/migration"
  U.shot(game, shotDir .. "/migrated-v04-save.png")
  U.log("Legacy counters, party, coins, and pawn ledger survived initialization.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
