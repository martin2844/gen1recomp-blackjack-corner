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
  bucket.gym_case_queue = bucket.gym_case_queue or {}
  if #bucket.pawned_pokemon == 0 then
    bucket.pawned_pokemon[1] = {
      mon = { species = "RATTATA", level = 7 }, value = 123,
    }
  end
  if #bucket.gym_case_queue == 0 then
    bucket.gym_case_queue[1] = {
      badge = "BOULDERBADGE", leader = "BROCK",
      reward = { kind = "item", id = "TM_BIDE", quantity = 1 },
    }
  end
  local pawnLedger, gymQueue = bucket.pawned_pokemon, bucket.gym_case_queue
  local pawnSpecies = pawnLedger[1].mon and pawnLedger[1].mon.species
  local gymBadge = gymQueue[1].badge
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  local party, coins = game.save.party or {}, tonumber(game.save.coins) or 0
  local partyCount = #party
  local firstSpecies = party[1] and party[1].species
  exports.reputation.ensure()
  assert(bucket.hands_played == 37 and bucket.cases_opened == 4,
    "campaign migration changed legacy counters")
  assert(#(game.save.party or {}) == partyCount
      and ((game.save.party or {})[1] and game.save.party[1].species) == firstSpecies
      and game.save.coins == coins,
    "campaign migration changed the player save")
  assert(bucket.pawned_pokemon == pawnLedger
      and bucket.pawned_pokemon[1].mon.species == pawnSpecies,
    "campaign migration changed the pawn ledger")
  assert(bucket.gym_case_queue == gymQueue
      and bucket.gym_case_queue[1].badge == gymBadge,
    "campaign migration changed the Gym Case queue")

  U.teleport(game, "BLACKJACK_LOUNGE", 10, 11, "up")
  require("src.ui.Screens").push(game, "BlackjackCornerHighRoller")
  U.wait(5)
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v05/migration"
  U.shot(game, shotDir .. "/migrated-v04-save.png")
  U.log("Legacy counters, party, coins, and pawn ledger survived initialization.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
