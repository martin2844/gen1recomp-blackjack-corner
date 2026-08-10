-- Exercises the house challenge through one real loss and one real win.

return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Pokemon = require("src.pokemon.Pokemon")
  local SaveData = require("src.core.SaveData")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local loader = assert(game.mods)
  local api = assert(loader.exports.blackjack_corner)
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  bucket.gamble_campaign.house = {
    status = "BUYBACK_PAID", bailoutClaimed = true,
    buybackPaid = true, rocketBattleWon = false,
  }
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  game.save.defeatedTrainers = game.save.defeatedTrainers or {}
  local challengeId = assert(api.house_world.challengeSaveId())
  game.save.defeatedTrainers[challengeId] = nil
  api.house_world.sync(game, api.house)

  local function pass(id, note) U.log("PASS", id, note or "") end
  local function fightUntilFinished(expectWin)
    local sawBattle = false
    for frame = 1, 5000 do
      local top = game.stack:top()
      if top and top.phase then
        sawBattle = true
        if top.phase == "menu" then top.menuIndex = 1
        elseif top.phase == "moveSelect" then top.moveIndex = 1 end
        U.tap(game, "a")
      else
        U.tap(game, "a")
      end
      U.wait(2)
      if sawBattle then
        local won = game.save.defeatedTrainers[challengeId] == true
        if expectWin and won and api.house.snapshot(game).status == "RESTORED" then break end
        if not expectWin and not won and game.stack:top() == game.overworld
            and frame > 180 then break end
      end
    end
    assert(sawBattle, "house challenger never started a battle")
  end

  -- The level-2, one-HP Rattata deterministically loses to the Rocket party.
  local weak = Pokemon.new(game.data, "RATTATA", 2)
  weak.hp = 1
  game.save.party = { weak }
  U.teleport(game, "REDS_HOUSE_1F", 4, 4, "right")
  U.wait(10); assert(U.shot(game, shotDir .. "/battle-challenger-before-loss.png"))
  U.tap(game, "a")
  fightUntilFinished(false)
  assert(not game.save.defeatedTrainers[challengeId], "loss marked challenger defeated")
  assert(api.house.snapshot(game).status == "BUYBACK_PAID",
    "loss changed the paid-deed state")
  pass("BATTLE-02", "real loss returned without consuming the challenge")

  assert(game:writeSave())
  local disk = assert(SaveData.load(game.save.version))
  assert(disk.modData.blackjack_corner.gamble_campaign.house.status == "BUYBACK_PAID")
  game:restoreSave(disk)
  bucket = loader.modSave.blackjack_corner
  assert(api.house.snapshot(game).status == "BUYBACK_PAID")
  assert(not game.save.defeatedTrainers[challengeId])
  pass("BATTLE-03", "loss remained retryable after real save/reload")

  local tank = Pokemon.new(game.data, "MEWTWO", 100)
  tank.moves = {
    { id = "PSYCHIC_M", pp = 99 }, { id = "THUNDERBOLT", pp = 99 },
    { id = "ICE_BEAM", pp = 99 }, { id = "EARTHQUAKE", pp = 99 },
  }
  game.save.party = { tank }
  api.house_world.sync(game, api.house)
  U.teleport(game, "REDS_HOUSE_1F", 4, 4, "right")
  U.wait(10); assert(U.shot(game, shotDir .. "/battle-challenger-retry.png"))
  U.tap(game, "a")
  fightUntilFinished(true)
  assert(game.save.defeatedTrainers[challengeId], "win was not persisted")
  assert(api.house.snapshot(game).status == "RESTORED", "win did not restore house")
  U.wait(20); assert(U.shot(game, shotDir .. "/battle-restoration-message.png"))
  pass("BATTLE-04", "real win completed the one-time restoration")
end
