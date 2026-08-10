return function(game)
  local U = dofile("tests/drivers/util.lua")
  U.wait(10)
  local loader = assert(game.mods, "mod loader is unavailable")
  assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode, bucket.gamble_campaign = false, nil
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = math.max(1,
    tonumber(game.save.inventory.COIN_CASE) or 0)
  game.save.coins = math.max(500, tonumber(game.save.coins) or 0)

  U.teleport(game, "PALLET_CASINO", 10, 11, "up")
  local shotDir = os.getenv("SHOT_DIR") or "/tmp/blackjack-corner-v05/mode-off"
  U.shot(game, shotDir .. "/base-casino.png")
  U.log("Base Casino mode prepared. HIGH ROLLER must be absent from Start.")
  U.log("Games, prizes, pawn, and coin exchange must remain playable.")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
