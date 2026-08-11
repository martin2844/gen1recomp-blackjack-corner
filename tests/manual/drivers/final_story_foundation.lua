-- Native smoke for the first final-stage slice: physical frame clue, durable
-- story transition, and the completed-lead greeter dialogue.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local SaveData = require("src.core.SaveData")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local loader = assert(game.mods, "mod loader is unavailable")
  local api = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket

  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  local campaign = bucket.gamble_campaign
  campaign.reputation.points, campaign.reputation.rank = 4000, "KINGPIN"
  campaign.arena.unlocked = true
  campaign.arena.stairsRevealed = true
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  game.save.objectToggles = game.save.objectToggles or {}
  api.arena_world.sync(game, api.arena_security)

  U.teleport(game, api.arena_world.LOBBY, 2, 14, "down")
  U.wait(20)
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-frame-clue.png"))
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-frame-record.png"))
  for _ = 1, 11 do U.tap(game, "a"); U.wait(3) end
  local state = api.arena_story.snapshot(game)
  assert(state.clueCount == 1 and state.stage == api.arena_story.STAGES.RUMORS)
  U.log("PASS", "STORY-03", "physical painting awarded one clue")

  campaign = loader.modSave.blackjack_corner.gamble_campaign
  campaign.arena.matchesPlayed = 3
  assert(api.arena_story.discover(game, api.arena_story.CLUES.MANIFEST))
  campaign = loader.modSave.blackjack_corner.gamble_campaign
  campaign.arena.matchesPlayed = 6
  assert(api.arena_story.discover(game, api.arena_story.CLUES.CHART))
  state = api.arena_story.snapshot(game)
  assert(state.clueCount == 3 and state.stage == api.arena_story.STAGES.LEAD)

  assert(game:writeSave(), "story save failed")
  local disk = assert(SaveData.load(game.save.version))
  game:restoreSave(disk)
  state = api.arena_story.snapshot(game)
  assert(state.clueCount == 3 and state.stage == api.arena_story.STAGES.LEAD)
  U.log("PASS", "STORY-10", "Cinnabar lead survived a disk restore")

  U.teleport(game, api.arena_world.LOBBY, 7, 3, "up")
  U.wait(20)
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-cinnabar-greeter.png"))
  U.log("PASS", "STORY-09", "greeter reacted to the completed lead")
  for _ = 1, 8 do U.tap(game, "a"); U.wait(3) end

  U.teleport(game, "CINNABAR_LAB_METRONOME_ROOM", 5, 6, "up")
  U.wait(20)
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-cinnabar-handler.png"))
  for _ = 1, 12 do U.tap(game, "a"); U.wait(3) end
  state = api.arena_story.snapshot(game)
  assert(state.stage == api.arena_story.STAGES.INVESTIGATION)
  assert(state.clues[api.arena_story.CLUES.LAB_ARCHIVE])
  U.log("PASS", "CIN-03", "Lab handler opened the investigation")

  U.teleport(game, "POKEMON_MANSION_B1F", 15, 19, "right")
  U.wait(20)
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-mansion-researcher.png"))
  for _ = 1, 12 do U.tap(game, "a"); U.wait(3) end
  state = api.arena_story.snapshot(game)
  assert(state.stage == api.arena_story.STAGES.INVITATION)
  assert(state.clues[api.arena_story.CLUES.MANSION_LOG])
  U.log("PASS", "CIN-05", "Mansion log authenticated the invitation")
end
