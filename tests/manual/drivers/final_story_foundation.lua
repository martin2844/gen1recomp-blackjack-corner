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

  bucket.gamble_mode, bucket.gamble_campaign = false, nil
  assert(api.arena_story.snapshot(game) == nil)
  U.log("PASS", "STORY-02", "base mode exposed no campaign story")

  local migrated = api.campaign_state.sanitize({
    schema = 4,
    reputation = { points = 777, rank = "HIGH_ROLLER" },
    arena = { stairsRevealed = true, matchesPlayed = 9 },
    debt = { principal = 321, fees = 45, status = "ACTIVE" },
    house = { status = "ROCKET_OWNED", bailoutClaimed = true },
  })
  assert(migrated.schema == api.campaign_state.SCHEMA)
  assert(migrated.reputation.points == 777
    and migrated.arena.matchesPlayed == 9)
  assert(migrated.debt.principal == 321
    and migrated.house.status == "ROCKET_OWNED")
  U.log("PASS", "STORY-01", "schema-four campaign migrated additively")

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

  local added, _, reason = api.arena_story.discover(game,
    api.arena_story.CLUES.FRAME)
  assert(not added and reason == "ALREADY FOUND")
  U.log("PASS", "STORY-04", "repeat painting did not duplicate its clue")

  local handlerVisible, researcherVisible = api.story_world.sync(game,
    api.arena_story)
  assert(not handlerVisible and not researcherVisible)
  U.log("PASS", "CIN-01", "Cinnabar contacts stayed hidden before the lead")

  campaign = loader.modSave.blackjack_corner.gamble_campaign
  added, _, reason = api.arena_story.discover(game,
    api.arena_story.CLUES.MANIFEST)
  assert(not added and reason == "NOT READY")
  U.log("PASS", "STORY-05", "manifest stayed locked before three matches")
  campaign = loader.modSave.blackjack_corner.gamble_campaign
  campaign.arena.matchesPlayed = 3
  assert(api.arena_story.discover(game, api.arena_story.CLUES.MANIFEST))
  U.log("PASS", "STORY-06", "three matches revealed the manifest")
  campaign = loader.modSave.blackjack_corner.gamble_campaign
  added, _, reason = api.arena_story.discover(game,
    api.arena_story.CLUES.CHART)
  assert(not added and reason == "NOT READY")
  U.log("PASS", "STORY-07", "Fuji chart stayed locked before six matches")
  campaign = loader.modSave.blackjack_corner.gamble_campaign
  campaign.arena.matchesPlayed = 6
  assert(api.arena_story.discover(game, api.arena_story.CLUES.CHART))
  state = api.arena_story.snapshot(game)
  assert(state.clueCount == 3 and state.stage == api.arena_story.STAGES.LEAD)
  U.log("PASS", "STORY-08", "six matches completed the Cinnabar lead")

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

  local PaletteFX = require("src.render.PaletteFX")
  local paletteBefore = PaletteFX.mode
  game:keypressed("2")
  U.wait(45)
  assert(PaletteFX.mode ~= paletteBefore)
  assert(U.shot(game, shotDir .. "/story-palette-cycle.png"))
  U.log("PASS", "STORY-11", "story world remained readable after palette cycle")

  U.teleport(game, "CINNABAR_LAB_METRONOME_ROOM", 5, 6, "up")
  U.wait(20)
  U.log("PASS", "CIN-02", "native Lab handler was reachable after the lead")
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
  U.log("PASS", "CIN-04", "native Mansion researcher was reachable")
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-mansion-researcher.png"))
  for _ = 1, 12 do U.tap(game, "a"); U.wait(3) end
  state = api.arena_story.snapshot(game)
  assert(state.stage == api.arena_story.STAGES.INVITATION)
  assert(state.clues[api.arena_story.CLUES.MANSION_LOG])
  U.log("PASS", "CIN-05", "Mansion log authenticated the invitation")

  added, _, reason = api.arena_story.discover(game,
    api.arena_story.CLUES.MANSION_LOG)
  assert(not added and reason == "ALREADY FOUND")
  assert(game:writeSave(), "Cinnabar story save failed")
  local cinnabarDisk = assert(SaveData.load(game.save.version))
  game:restoreSave(cinnabarDisk)
  state = api.arena_story.snapshot(game)
  assert(state.stage == api.arena_story.STAGES.INVITATION
    and state.cinnabarClueCount == 2)
  U.log("PASS", "CIN-06", "repeat contact and disk reload stayed idempotent")
  local stableCampaign = loader.modSave.blackjack_corner.gamble_campaign
  assert(stableCampaign.debt.status == "CLEAR"
    and stableCampaign.house.status == "FAMILY_HOME")
  U.log("PASS", "CIN-07", "investigation preserved debt and house state")

  game.save.coins = 50000
  local coinsBeforePosting = game.save.coins
  local exhibition = assert(api.arena.current(game))
  assert(exhibition.kind == "EXHIBITION")
  assert(game.save.coins == coinsBeforePosting)
  U.log("PASS", "EXH-01", "Series 3 replaced the ordinary unpaid posting")
  assert(exhibition.match.fighters[1].species == "DRAGONITE"
    and exhibition.match.fighters[1].level == 62)
  assert(exhibition.match.fighters[2].species == "MEWTWO"
    and exhibition.match.fighters[2].level == 65)
  assert(exhibition.match.winner and exhibition.match.actions)
  U.log("PASS", "EXH-02", "fighter pair, odds, result, and actions were committed")

  local lostId = exhibition.match.id
  local recordedLoss, lossState = api.arena_story.settleExhibition(game,
    lostId, false)
  assert(recordedLoss and lossState.stage == api.arena_story.STAGES.INVITATION)
  assert(api.arena.resetPosted())
  exhibition = assert(api.arena.current(game))
  assert(exhibition.kind == "EXHIBITION"
    and exhibition.match.id > lostId)
  assert(exhibition.match.fighters[1].species == "DRAGONITE"
    and exhibition.match.fighters[2].species == "MEWTWO")
  U.log("PASS", "EXH-06", "loss kept the fixed exhibition retryable")

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
  assert(game:writeSave(), "paid exhibition save failed")
  local exhibitionDisk = assert(SaveData.load(game.save.version))
  local diskPending = assert(exhibitionDisk.modData.blackjack_corner
    .gamble_campaign.arena.pending)
  assert(diskPending.match.id == committedId
    and diskPending.selected == committedWinner)
  U.log("PASS", "EXH-03", "paid Series 3 ticket reached disk before animation")
  for _ = 1, 6000 do
    U.wait(1)
    if screen.phase == "result" then break end
  end
  assert(screen.phase == "result" and screen.pending.won)
  assert(screen.pending.match.id == committedId)
  assert(U.shot(game, shotDir .. "/story-exhibition-result.png"))
  state = api.arena_story.snapshot(game)
  assert(state.stage == api.arena_story.STAGES.CHOICE)
  assert(state.exhibition.attempts == 2 and state.exhibition.wins == 1)
  U.log("PASS", "EXH-04", "Series 3 win committed Giovanni's audience")

  local repeated = api.arena_story.settleExhibition(game, committedId, true)
  assert(not repeated)
  U.log("PASS", "EXH-07", "Series 3 settlement could not duplicate")

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
  U.log("PASS", "END-01", "Giovanni presented EXPOSE, CHAMPION, and LEAVE")
  if expected == api.arena_story.ENDINGS.EXPOSE then
    assert(api.credit.borrow(game), "pre-ending Rocket loan failed")
  else
    game.save.coins = 990000
  end
  local coinsBeforeChoice = game.save.coins
  if expected == api.arena_story.ENDINGS.CHAMPION then
    U.tap(game, "down")
    U.wait(5)
  end
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-giovanni-consequence.png"))
  U.log("PASS", "END-02", "branch consequence appeared before confirmation")

  local function waitForChoiceBox()
    for _ = 1, 16 do
      local top = game.stack:top()
      if top and top.onChoose then return top end
      U.tap(game, "a")
      U.wait(120)
    end
    error("ending confirmation did not appear")
  end

  assert(waitForChoiceBox())
  U.tap(game, "b")
  U.wait(30)
  state = api.arena_story.snapshot(game)
  assert(state.ending.choice == nil)
  local reopened = game.stack:top()
  assert(reopened and reopened.items and #reopened.items == 3)
  U.log("PASS", "END-04", "NO preserved the full ending choice")

  if expected == api.arena_story.ENDINGS.CHAMPION then
    U.tap(game, "down")
    U.wait(5)
  end
  U.tap(game, "a")
  U.wait(120)
  assert(waitForChoiceBox())
  U.tap(game, "a")
  U.wait(30)
  for _ = 1, 120 do
    state = api.arena_story.snapshot(game)
    if state.ending.choice then break end
    U.wait(1)
  end
  state = api.arena_story.snapshot(game)
  assert(state.ending.choice == expected)
  local expectedStage = expected == api.arena_story.ENDINGS.EXPOSE
    and api.arena_story.STAGES.EXPOSED or api.arena_story.STAGES.CHAMPION
  assert(state.stage == expectedStage)
  assert(U.shot(game, shotDir .. "/story-giovanni-ending.png"))
  U.log("PASS", "END-03", expected .. " committed after consequence copy")

  if expected == api.arena_story.ENDINGS.CHAMPION then
    assert(game.save.coins == 1000000)
    assert(state.ending.rewardPending == 15000
      and not state.ending.rewardClaimed)
    assert(api.credit.snapshot(game).newLoansAllowed)
    local endingBox = game.stack:top()
    assert(endingBox and endingBox.pages and #endingBox.pages >= 4)
    while endingBox.pageIndex < #endingBox.pages do
      while not endingBox.waiting do U.wait(1) end
      U.tap(game, "a")
      U.wait(2)
    end
    while not endingBox.done do U.wait(1) end
    assert(U.shot(game, shotDir .. "/story-ending-reward.png"))
    game.save.coins = 900000
    local credited, pending = api.arena_story.deliverEndingReward(game)
    assert(credited == 15000 and pending == 0 and game.save.coins == 915000)
    local afterReward = game.save.coins
    credited = api.arena_story.deliverEndingReward(game)
    assert(credited == 0 and game.save.coins == afterReward)
    U.log("PASS", "END-07", "CHAMPION reward banked at cap and settled once")
  else
    assert(game.save.coins == coinsBeforeChoice)
    local creditState = api.credit.snapshot(game)
    assert(not creditState.newLoansAllowed and creditState.total > 0)
    assert(api.credit.repayCoins(game, creditState.total))
    assert(api.credit.snapshot(game).total == 0)
    local borrowed, reason = api.credit.borrow(game)
    assert(not borrowed and reason:find("CLOSED", 1, true))
    U.log("PASS", "END-06", "EXPOSE blocked new credit but allowed repayment")
  end
  assert(api.credit.luxuryAllowed(game))

  for _ = 1, 10 do U.tap(game, "a"); U.wait(3) end
  assert(game:writeSave(), "ending save failed")
  local endingDisk = assert(SaveData.load(game.save.version))
  game:restoreSave(endingDisk)
  state = api.arena_story.snapshot(game)
  assert(state.ending.choice == expected and state.stage == expectedStage)
  local otherEnding = expected == api.arena_story.ENDINGS.EXPOSE
    and api.arena_story.ENDINGS.CHAMPION or api.arena_story.ENDINGS.EXPOSE
  local switched = api.arena_story.chooseEnding(game, otherEnding)
  assert(not switched and api.arena_story.snapshot(game).ending.choice == expected)
  U.teleport(game, api.arena_world.ARENA, 10, 7, "up")
  U.wait(20)
  U.tap(game, "a")
  U.wait(120)
  assert(U.shot(game, shotDir .. "/story-ending-repeat.png"))
  U.log("PASS", "END-05", "ending survived reload and refused the other branch")

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

  local function talkToNamedNpc(mapId, name, dx, dy, facing, filename)
    U.teleport(game, mapId, 1, 1, "down")
    local npc
    for _, candidate in ipairs(game.overworld.npcs or {}) do
      if candidate.def and candidate.def.name == name then npc = candidate break end
    end
    assert(npc, "missing ending-reactive NPC " .. name)
    npc.frozen = true
    local player = game.overworld.player
    player.cellX, player.cellY = npc.cellX + dx, npc.cellY + dy
    player.px, player.py = player.cellX * 16, player.cellY * 16
    player.facing, player.moving = facing, false
    U.tap(game, "a")
    U.wait(120)
    assert(game.stack:top() and game.stack:top().pages,
      name .. " did not open ending dialogue")
    assert(U.shot(game, shotDir .. "/" .. filename))
  end

  talkToNamedNpc(api.arena_world.ARENA, "ARENA_FAN_7",
    1, 0, "left", "story-ending-b2.png")
  talkToNamedNpc("CINNABAR_LAB_METRONOME_ROOM",
    "BLACKJACK_CORNER_CINNABAR_HANDLER", 0, 1, "up",
    "story-ending-cinnabar.png")
  talkToNamedNpc("PALLET_CASINO", "PALLET_CASINO_LOSER",
    -1, 0, "right", "story-ending-pallet.png")
  talkToNamedNpc("GAME_CORNER", "CASINO_DEBTOR",
    -1, 0, "right", "story-ending-celadon.png")

  local finalCampaign = loader.modSave.blackjack_corner.gamble_campaign
  finalCampaign.house.status = "ROCKET_OWNED"
  finalCampaign.house.bailoutClaimed = true
  api.reputation.ensure()
  api.house_world.sync(game, api.house)
  talkToNamedNpc("REDS_HOUSE_1F", api.house_world.TENANT,
    -1, 0, "right", "story-ending-house.png")
  assert(api.arena_story.snapshot(game).ending.choice == expected)
  U.log("PASS", "END-08", "ending reacted across every campaign region")

  assert(game:writeSave(), "ending world save failed")
  local finalDisk = assert(SaveData.load(game.save.version))
  game:restoreSave(finalDisk)
  assert(api.arena_story.snapshot(game).ending.choice == expected)
  assert(api.arena.access(game))
  assert(api.credit.luxuryAllowed(game))
  assert(api.house.snapshot(game).status == "ROCKET_OWNED")
  U.log("PASS", "END-09", "ending world, access, and services survived reload")
end
