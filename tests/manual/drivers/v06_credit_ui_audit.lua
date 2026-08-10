-- Drives the real Rookie loan confirmation and statement screens.

return function(game)
  local U = dofile("tests/drivers/util.lua")
  local ChoiceBox = require("src.ui.ChoiceBox")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local loader = assert(game.mods)
  local api = assert(loader.exports.blackjack_corner)
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  game.save.inventory = { COIN_CASE = 1 }
  game.save.coins, game.save.money = 100, 3000

  U.teleport(game, "BLACKJACK_LOUNGE", 17, 12, "right")
  U.tap(game, "a")
  U.wait(240); U.tap(game, "a")
  U.wait(240); U.tap(game, "a")
  U.wait(15)
  assert(U.shot(game, shotDir .. "/credit-clean-menu.png"))
  U.tap(game, "a") -- TAKE 500
  U.wait(180)
  assert(U.shot(game, shotDir .. "/credit-offer-page.png"))
  U.tap(game, "a")
  U.wait(180)
  assert(getmetatable(game.stack:top()) == ChoiceBox,
    "loan offer did not end in a YES/NO choice")
  assert(U.shot(game, shotDir .. "/credit-offer-choice.png"))
  U.tap(game, "a")
  U.wait(180)
  assert(U.shot(game, shotDir .. "/credit-accepted-page-1.png"))
  U.tap(game, "a"); U.wait(180)
  assert(U.shot(game, shotDir .. "/credit-accepted-page-2.png"))
  U.tap(game, "a"); U.wait(20)

  local debt = api.credit.snapshot(game)
  assert(game.save.coins == 600 and debt.principal == 500
    and debt.fees == 100 and debt.total == 600 and debt.dueBadge == 1)
  -- Active menu: PAY COINS, PAY MONEY, PAWN TO PAY, STATEMENT.
  U.tap(game, "down"); U.tap(game, "down"); U.tap(game, "down"); U.tap(game, "a")
  for page = 1, 3 do
    U.wait(180)
    assert(U.shot(game, shotDir .. "/credit-statement-page-" .. page .. ".png"))
    if page < 3 then U.tap(game, "a") end
  end
  U.log("PASS", "CREDIT-01", "real offer and statement show principal, fee, total and due badge")
end
