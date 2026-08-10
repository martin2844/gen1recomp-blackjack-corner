-- Drives the real 30,000-coin deed confirmation through NO and YES.

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
  bucket.gamble_campaign.house = {
    status = "ROCKET_OWNED", bailoutClaimed = true,
    buybackPaid = false, rocketBattleWon = false,
  }
  game.save.inventory = { COIN_CASE = 1 }
  game.save.coins, game.save.money = 30000, 0

  U.teleport(game, "BLACKJACK_LOUNGE", 17, 12, "right")
  U.tap(game, "a")
  U.wait(240); U.tap(game, "a")
  U.wait(240); U.tap(game, "a")
  U.wait(15)

  local function openChoice(tag)
    U.tap(game, "down") -- TAKE 500 -> BUYBACK 30000
    U.tap(game, "a")
    U.wait(180)
    assert(U.shot(game, shotDir .. "/" .. tag .. "-deed-page.png"))
    U.tap(game, "a")
    U.wait(180)
    assert(getmetatable(game.stack:top()) == ChoiceBox,
      "buyback warning did not end in a YES/NO choice")
    assert(U.shot(game, shotDir .. "/" .. tag .. "-battle-choice.png"))
  end

  openChoice("buyback-no")
  U.tap(game, "b"); U.wait(30)
  assert(game.save.coins == 30000)
  assert(api.house.snapshot(game).status == "ROCKET_OWNED")
  U.log("PASS", "BUY-02", "real NO left deed and coins unchanged")

  openChoice("buyback-yes")
  U.tap(game, "a"); U.wait(40)
  assert(game.save.coins == 0)
  assert(api.house.snapshot(game).status == "BUYBACK_PAID")
  assert(U.shot(game, shotDir .. "/buyback-accepted.png"))
  U.log("PASS", "BUY-03", "real YES deducted exactly 30000")
end
