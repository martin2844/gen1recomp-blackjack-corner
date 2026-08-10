-- Runs the real title/Oak flow and verifies the v0.6 Gamble Mode fork.
-- Set GAMBLE_CHOICE=yes or no and use a fresh POKEPORT_IDENTITY.

return function(game)
  local U = dofile("tests/drivers/util.lua")
  local choice = (os.getenv("GAMBLE_CHOICE") or "yes"):lower()
  assert(choice == "yes" or choice == "no", "GAMBLE_CHOICE must be yes or no")
  local expected = choice == "yes"
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local ChoiceBox = require("src.ui.ChoiceBox")
  local Screens = require("src.ui.Screens")

  local function pass(id, note)
    U.log("PASS", id, note or "")
  end

  U.wait(5)
  U.tap(game, "start") -- intro movie -> title
  U.wait(10)
  U.tap(game, "a") -- title -> main menu
  U.wait(5)
  U.tap(game, "a") -- NEW GAME on a clean identity

  local answered = false
  for _ = 1, 1800 do
    local top = game.stack:top()
    if getmetatable(top) == ChoiceBox and not answered then
      assert(U.shot(game, shotDir .. "/oak-gamble-mode-choice.png"))
      -- The prompt intentionally defaults to NO, so YES requires one move.
      if expected then U.tap(game, "up") end
      U.tap(game, "a")
      answered = true
      U.wait(20)
    elseif answered and game.overworld and top == game.overworld then
      break
    else
      U.tap(game, "a")
      U.wait(2)
    end
  end

  assert(answered, "Oak Gamble Mode prompt was never shown")
  assert(game.overworld and game.stack:top() == game.overworld,
    "Oak intro did not reach the overworld")

  local loader = assert(game.mods, "mod loader is unavailable")
  local exports = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = assert(loader.modSave.blackjack_corner,
    "blackjack_corner save bucket is missing after NEW GAME")
  assert(bucket.gamble_mode == expected, "Oak choice was not persisted")

  if not expected then
    assert(bucket.gamble_campaign == nil, "NO initialized a Gamble campaign")
    assert(exports.credit.snapshot(game) == nil, "NO exposed Rocket Credit")
    assert(exports.house.snapshot(game) == nil, "NO exposed the house quest")
    U.teleport(game, "PALLET_CASINO", 10, 11, "up")
    assert(U.shot(game, shotDir .. "/base-mode-pallet-casino.png"))
    pass("BASE-01", "NO keeps Gamble campaign systems disabled")
    return
  end

  assert((game.save.inventory or {}).COIN_CASE == 1,
    "YES did not grant exactly one Coin Case")
  assert((tonumber(game.save.coins) or 0) == 100,
    "YES did not grant exactly 100 starting coins")
  assert(bucket.gamble_campaign ~= nil, "YES did not initialize campaign state")

  -- Exercise the actual starter screen, including the paid re-spin branch.
  game.save.money = 3000
  game.save.party = {}
  game.save.flags = game.save.flags or {}
  game.save.flags.EVENT_GOT_STARTER = nil
  game.save.flags.EVENT_OAK_ASKED_TO_CHOOSE_MON = true
  U.teleport(game, "OAKS_LAB", 6, 4, "up")
  Screens.push(game, "BlackjackCornerStarterRoulette", {})
  U.wait(90)
  assert(U.shot(game, shotDir .. "/starter-roulette-spin.png"))
  U.wait(160)
  local screen = game.stack:top()
  assert(screen and screen.phase == "offer", "starter roulette did not reach its offer")
  local first = screen.playerStarter
  assert(U.shot(game, shotDir .. "/starter-roulette-offer.png"))
  U.tap(game, "right")
  U.tap(game, "a")
  assert(game.save.money == 2000, "starter re-spin did not cost exactly 1000")
  U.wait(250)
  screen = game.stack:top()
  assert(screen and screen.phase == "offer", "paid starter re-spin did not settle")
  assert(U.shot(game, shotDir .. "/starter-roulette-respin-offer.png"))
  U.tap(game, "a")
  assert(screen.phase == "result", "KEEP did not accept the roulette starter")
  assert(#game.save.party == 1 and game.save.flags.EVENT_GOT_STARTER,
    "accepted roulette starter was not added to the party")
  assert(bucket.roulette_player_starter == game.save.party[1].species,
    "player roulette result was not persisted")
  assert(bucket.roulette_rival_starter
      and bucket.roulette_rival_starter ~= bucket.roulette_player_starter,
    "rival roulette result was missing or duplicated the player result")
  assert(first ~= nil, "first roulette offer was missing")
  assert(U.shot(game, shotDir .. "/starter-roulette-accepted.png"))
  pass("FRESH-01", "YES grants campaign, Coin Case, 100 coins and roulette starters")
end
