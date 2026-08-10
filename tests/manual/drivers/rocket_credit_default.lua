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
  local debt = bucket.gamble_campaign.debt
  debt.principal, debt.fees = 500, 100
  debt.status, debt.dueBadge, debt.lastBadgeFee = "DEFAULT", 1, 1
  debt.loansTaken = 1
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  game.save.coins, game.save.money = 100, 3000
  game.save.party = game.save.party or {}
  while #game.save.party < 2 do
    assert(exports.giveCaseReward(game, {
      kind = "pokemon", species = "RATTATA", level = 5, label = "RATTATA",
    }))
  end
  exports.credit_world.sync(game, exports.credit)

  U.teleport(game, "PALLET_TOWN", 8, 14, "left")
  U.wait(180)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v06/default"
  U.shot(game, shotDir .. "/pallet-rocket-collector.png")
  U.teleport(game, "BLACKJACK_LOUNGE", 17, 12, "right")
  U.tap(game, "a")
  U.wait(240)
  U.tap(game, "a")
  U.wait(240)
  U.tap(game, "a")
  U.wait(10)
  U.shot(game, shotDir .. "/default-broker-menu.png")
  U.tap(game, "down")
  U.tap(game, "down")
  U.tap(game, "a")
  U.wait(10)
  U.shot(game, shotDir .. "/pawn-to-pay-appraisals.png")
  U.log("Rocket Credit default prepared: 500 principal + 100 fee.")
  U.log("Talk to the collector, verify luxury Prize Cases/counters are frozen,")
  U.log("then repay or use PAWN & PAY in the Celadon Lounge and revisit Pallet.")
  U.log("Essential travel, healing, casino games, clerk, and pawn redemption must work.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
