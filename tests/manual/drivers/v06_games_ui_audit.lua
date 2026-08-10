-- Plays one real round of every non-luxury game while Rocket Credit is in
-- DEFAULT, proving the freeze is scoped to prize purchases only.

return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Screens = require("src.ui.Screens")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local loader = assert(game.mods)
  local api = assert(loader.exports.blackjack_corner)
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  bucket.gamble_campaign.debt = {
    principal = 500, fees = 100, status = "DEFAULT", dueBadge = 1,
    lastBadgeFee = 1, loansTaken = 1, totalRepaid = 0,
    collectorsTriggered = {},
  }
  game.save.inventory = { COIN_CASE = 1, BOULDERBADGE = 1 }
  game.save.coins, game.save.money = 50000, 50000

  local function open(id)
    U.teleport(game, "PALLET_CASINO", 10, 11, "up")
    Screens.push(game, id, {})
    U.wait(10)
    return game.stack:top()
  end
  local function awaitResult(screen, limit)
    for _ = 1, limit or 600 do
      if screen.phase == "result" or screen.phase == "crashed"
          or screen.phase == "cashed" then return end
      U.wait(1)
    end
    error("game never reached a result: " .. tostring(screen.phase))
  end
  local function done(id, screen)
    assert(U.shot(game, shotDir .. "/" .. id .. "-result.png"))
    U.log("PASS", id, "real round reached " .. tostring(screen.phase))
  end

  local screen = open("BlackjackCornerTable")
  U.tap(game, "a"); U.wait(20); U.tap(game, "b"); awaitResult(screen)
  done("blackjack", screen)

  screen = open("BlackjackCornerHoldemTable")
  U.tap(game, "a"); U.wait(10); U.tap(game, "right"); U.tap(game, "a")
  -- The mod intentionally keeps Hold'em progressive after a preflop bet:
  -- check the flop and river to reach showdown.
  U.wait(10); U.tap(game, "a"); U.wait(10); U.tap(game, "a")
  awaitResult(screen); done("holdem", screen)

  screen = open("BlackjackCornerCrash")
  U.tap(game, "a"); U.wait(8)
  if screen.phase == "running" then U.tap(game, "a") end
  awaitResult(screen); done("crash", screen)

  screen = open("BlackjackCornerTubeFlyer")
  U.tap(game, "a"); awaitResult(screen, 900); done("tube-flyer", screen)

  screen = open("BlackjackCornerHorseRacing")
  U.tap(game, "a"); awaitResult(screen, 900); done("horse-racing", screen)

  screen = open("BlackjackCornerPlinko")
  U.tap(game, "a"); awaitResult(screen, 900); done("plinko", screen)

  local rep = api.reputation.snapshot(game)
  for _, id in ipairs({ "blackjack", "holdem", "crash", "tube_flyer",
      "horse_racing", "plinko" }) do
    assert(rep.byGame[id] and rep.byGame[id].played >= 1,
      id .. " did not settle its real round")
  end
  assert(api.credit.snapshot(game).status == "DEFAULT")
  U.log("PASS", "FREEZE-03", "all six non-luxury games settled during DEFAULT")
end
