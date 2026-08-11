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
  for _, badge in ipairs(api.reputation_rules.BADGES) do
    game.save.inventory[badge] = 1
  end
  for _, rankRow in ipairs(api.reputation_rules.RANKS) do
    campaign.reputation.rankRewardsClaimed[rankRow.id] = true
  end
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

  game.save.coins = 50000
  local exhibition = assert(api.arena.current(game))
  assert(exhibition.kind == "EXHIBITION")
  local committedId = exhibition.match.id
  local committedWinner = exhibition.match.winner
  U.teleport(game, api.arena_world.ARENA, 9, 4, "up")
  U.wait(20)
  U.tap(game, "a")
  U.wait(120)
  local screen
  for _ = 1, 5 do
    local top = game.stack:top()
    if top and top.pending then screen = top break end
    U.tap(game, "a")
    U.wait(120)
  end
  assert(screen and screen.pending and screen.pending.kind == "EXHIBITION")
  assert(screen.pending.match.id == committedId)
  assert(U.shot(game, shotDir .. "/story-exhibition-card.png"))
  if committedWinner == 2 then U.tap(game, "down"); U.wait(5) end
  U.tap(game, "a")
  U.wait(20)
  assert(U.shot(game, shotDir .. "/story-exhibition-intro.png"))
  for _ = 1, 6000 do
    U.wait(1)
    if screen.phase == "result" then break end
  end
  assert(screen.phase == "result" and screen.pending.won)
  assert(screen.pending.match.id == committedId)
  assert(U.shot(game, shotDir .. "/story-exhibition-result.png"))
  state = api.arena_story.snapshot(game)
  assert(state.stage == api.arena_story.STAGES.CHOICE)
  assert(state.exhibition.attempts == 1 and state.exhibition.wins == 1)
  U.log("PASS", "EXH-04", "Series 3 win committed Giovanni's audience")

  U.tap(game, "b")
  U.wait(60)
  U.teleport(game, api.arena_world.ARENA, 10, 7, "up")
  U.wait(30)
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-giovanni-summoned.png"))
  U.log("PASS", "EXH-05", "Giovanni appeared physically after the win")

  local menu
  for _ = 1, 8 do
    local top = game.stack:top()
    if top and top.items then menu = top break end
    U.tap(game, "a")
    U.wait(120)
  end
  assert(menu and #menu.items == 3)
  assert(U.shot(game, shotDir .. "/story-giovanni-choice.png"))
  local GameVersion = require("src.core.GameVersion")
  local expected = GameVersion.isBlue() and api.arena_story.ENDINGS.CHAMPION
    or api.arena_story.ENDINGS.EXPOSE
  local coinsBeforeChoice = game.save.coins
  if expected == api.arena_story.ENDINGS.CHAMPION then
    U.tap(game, "down")
    U.wait(5)
  end
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-giovanni-consequence.png"))
  for _ = 1, 12 do
    state = api.arena_story.snapshot(game)
    if state.ending.choice then break end
    U.tap(game, "a")
    U.wait(120)
  end
  state = api.arena_story.snapshot(game)
  assert(state.ending.choice == expected)
  local expectedStage = expected == api.arena_story.ENDINGS.EXPOSE
    and api.arena_story.STAGES.EXPOSED or api.arena_story.STAGES.CHAMPION
  assert(state.stage == expectedStage)
  assert(U.shot(game, shotDir .. "/story-giovanni-ending.png"))
  U.log("PASS", "END-03", expected .. " committed after consequence copy")

  if expected == api.arena_story.ENDINGS.CHAMPION then
    assert(game.save.coins == coinsBeforeChoice
      + api.arena_story.CHAMPION_REWARD)
    assert(state.ending.rewardPending == 0 and state.ending.rewardClaimed)
    assert(api.credit.snapshot(game).newLoansAllowed)
    local endingBox = game.stack:top()
    assert(endingBox and endingBox.pages and #endingBox.pages >= 3)
    while endingBox.pageIndex < #endingBox.pages do
      while not endingBox.waiting do U.wait(1) end
      U.tap(game, "a")
      U.wait(2)
    end
    while not endingBox.done do U.wait(1) end
    assert(U.shot(game, shotDir .. "/story-ending-reward.png"))
    U.log("PASS", "END-04", "CHAMPION reward credited exactly once")
  else
    assert(game.save.coins == coinsBeforeChoice)
    assert(not api.credit.snapshot(game).newLoansAllowed)
    local borrowed, reason = api.credit.borrow(game)
    assert(not borrowed and reason:find("CLOSED", 1, true))
    U.log("PASS", "END-04", "EXPOSE closed new Rocket credit")
  end
  assert(api.credit.luxuryAllowed(game))

  for _ = 1, 10 do U.tap(game, "a"); U.wait(3) end
  while api.reputation.consumeRankUp() do end
  require("src.ui.Screens").push(game, "BlackjackCornerHighRoller")
  U.wait(40)
  assert(U.shot(game, shotDir .. "/story-ending-status.png"))
  U.tap(game, "b")
  U.wait(30)

  U.teleport(game, api.arena_world.LOBBY, 7, 3, "up")
  U.wait(20)
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-ending-world.png"))
  U.log("PASS", "END-05", "ending changed status and world dialogue")
end
