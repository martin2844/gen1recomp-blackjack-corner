-- Verifies the real PAWN TO PAY appraisal and full-ledger FIFO warning UI.

return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Pokemon = require("src.pokemon.Pokemon")
  local ChoiceBox = require("src.ui.ChoiceBox")
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
  game.save.inventory = { COIN_CASE = 1 }
  game.save.coins, game.save.money = 100, 3000
  game.save.party = {
    Pokemon.new(game.data, "RATTATA", 8),
    Pokemon.new(game.data, "PIKACHU", 18),
  }
  bucket.pawned_pokemon = {}
  for index = 1, 5 do
    local held = Pokemon.new(game.data, "PIDGEY", 5 + index)
    bucket.pawned_pokemon[index] = {
      mon = held, name = "PIDGEY " .. index,
      value = 100 + index, redeem = 130 + index,
    }
  end
  local firstName = bucket.pawned_pokemon[1].name

  U.teleport(game, "BLACKJACK_LOUNGE", 17, 12, "right")
  U.tap(game, "a")
  U.wait(240); U.tap(game, "a")
  U.wait(240); U.tap(game, "a")
  U.wait(15)
  U.tap(game, "down"); U.tap(game, "down"); U.tap(game, "a")
  U.wait(20)
  assert(U.shot(game, shotDir .. "/pawn-to-pay-appraisals.png"))
  U.tap(game, "a")
  U.wait(180)
  assert(U.shot(game, shotDir .. "/pawn-fifo-prompt.png"))
  U.tap(game, "a")
  U.wait(180)
  assert(getmetatable(game.stack:top()) == ChoiceBox,
    "full pawn ledger warning did not end in a YES/NO choice")
  assert(U.shot(game, shotDir .. "/pawn-fifo-warning-choice.png"))
  U.tap(game, "b")
  U.wait(30)
  assert(#game.save.party == 2, "cancelled pawn removed a party Pokemon")
  assert(#api.pawnLedger() == 5 and api.pawnLedger()[1].name == firstName,
    "cancelled pawn changed the FIFO ledger")
  assert(api.credit.snapshot(game).total == 600,
    "cancelled pawn changed Rocket Credit")
  U.log("PASS", "PAWN-01", "real appraisals were readable")
  U.log("PASS", "PAWN-03", "real FIFO warning cancelled without mutation")
end
