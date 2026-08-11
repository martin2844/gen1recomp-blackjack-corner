-- Drives the complete PAWN HOUSE confirmation through NO and YES.

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
  game.save.coins, game.save.money = 250, 5000

  local function openBrokerMenu()
    U.teleport(game, "BLACKJACK_LOUNGE", 17, 12, "right")
    U.tap(game, "a")
    U.wait(240); U.tap(game, "a")
    U.wait(240); U.tap(game, "a")
    U.wait(15)
  end
  local function openPawnChoice(tag)
    U.tap(game, "down") -- TAKE 500 -> PAWN HOUSE
    U.tap(game, "a")
    for page = 1, 4 do
      U.wait(180)
      assert(U.shot(game, shotDir .. "/" .. tag .. "-page-" .. page .. ".png"))
      if page < 4 then U.tap(game, "a") end
    end
    U.wait(20)
    assert(getmetatable(game.stack:top()) == ChoiceBox,
      "PAWN HOUSE warning did not end in a YES/NO choice")
    assert(U.shot(game, shotDir .. "/" .. tag .. "-choice.png"))
  end

  openBrokerMenu()
  openPawnChoice("pawn-house-no")
  U.tap(game, "b")
  U.wait(30)
  assert(game.save.coins == 250 and game.save.money == 5000)
  assert(api.house.snapshot(game).status == "FAMILY_HOME")
  U.log("PASS", "BAIL-04", "real NO left balances and home unchanged")

  -- The NO callback reopens the menu; choose PAWN HOUSE again.
  openPawnChoice("pawn-house-yes")
  U.tap(game, "a") -- defaults to YES
  U.wait(40)
  assert(game.save.coins == 10250 and game.save.money == 5000)
  assert(api.house.snapshot(game).status == "ROCKET_OWNED")
  assert(U.shot(game, shotDir .. "/pawn-house-accepted.png"))
  U.log("PASS", "BAIL-05", "real YES added exactly 10000 and transferred the home")
end
