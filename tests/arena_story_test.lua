package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function loadModule(relative)
  return assert(loadfile("mods/blackjack_corner/" .. relative))()
end

local State = loadModule("other/gamble/state.lua")
local StoryFactory = loadModule("other/gamble/arena_story.lua")
local StoryWorld = loadModule("other/gamble/story_world.lua")(
  loadModule("other/world_helpers.lua"))

local enabled = true
local saved = { gamble_campaign = State.defaults() }
local mod = { save = {
  get = function(_, key) return saved[key] end,
  set = function(_, key, value) saved[key] = value end,
} }
local story = StoryFactory(mod, {
  state = State, active = function() return enabled end,
})
local game = { save = { objectToggles = {} } }

local snapshot = story.snapshot(game)
T.eq(snapshot.stage, story.STAGES.RUMORS,
  "a fresh campaign begins with Arena rumors")
T.eq(snapshot.clueCount, 0, "a fresh campaign has no discovered clue")
T.eq(snapshot.clueTarget, 3, "the Cinnabar lead requires three records")

local ok, state, reason = story.discover(game, story.CLUES.FRAME)
T.check(not ok and reason == "ARENA LOCKED",
  "story clues cannot be injected before the Arena route opens")
T.eq(state.clueCount, 0, "a locked clue attempt changes nothing")

saved.gamble_campaign.arena.stairsRevealed = true
ok, state, reason = story.discover(game, story.CLUES.FRAME)
T.check(ok and reason == "CLUE FOUND", "the concealed frame yields the first clue")
T.eq(state.clueCount, 1, "the first clue is counted exactly once")
ok, state, reason = story.discover(game, story.CLUES.FRAME)
T.check(not ok and reason == "ALREADY FOUND",
  "re-reading a clue cannot duplicate story progress")
T.eq(state.clueCount, 1, "a repeated clue keeps the same count")

ok, state, reason = story.discover(game, story.CLUES.MANIFEST)
T.check(not ok and reason == "NOT READY",
  "the cage manifest waits for three Arena matches")
saved.gamble_campaign.arena.matchesPlayed = 3
ok, state = story.discover(game, story.CLUES.MANIFEST)
T.check(ok, "three Arena matches reveal the cage manifest")
T.eq(state.clueCount, 2, "the second record advances the trail")

ok, state, reason = story.discover(game, story.CLUES.CHART)
T.check(not ok and reason == "NOT READY",
  "the Fuji chart waits for six Arena matches")
saved.gamble_campaign.arena.matchesPlayed = 6
ok, state, reason = story.discover(game, story.CLUES.CHART)
T.check(ok and reason == "LEAD COMPLETE",
  "the third record completes the Cinnabar lead")
T.eq(state.stage, story.STAGES.LEAD,
  "three records advance the campaign to Cinnabar")
T.eq(state.clueCount, 3, "the completed trail persists all three clues")
local handlerVisible, researcherVisible = StoryWorld.sync(game, story)
T.check(handlerVisible and not researcherVisible,
  "the Cinnabar handler appears when the Arena lead is complete")

ok, state, reason = story.discover(game, story.CLUES.MANSION_LOG)
T.check(not ok and reason == "WRONG STAGE",
  "the Mansion record cannot skip the Cinnabar handler")
ok, state, reason = story.beginCinnabar(game)
T.check(ok and reason == "INVESTIGATION STARTED",
  "the Cinnabar handler begins the investigation exactly once")
T.eq(state.stage, story.STAGES.INVESTIGATION,
  "the handler advances the lead into an active investigation")
T.eq(state.cinnabarClueCount, 1,
  "the handler supplies the authenticated Lab archive")
T.check(state.clues[story.CLUES.LAB_ARCHIVE],
  "the Lab archive is persisted as the first Cinnabar record")
handlerVisible, researcherVisible = StoryWorld.sync(game, story)
T.check(handlerVisible and researcherVisible,
  "the Mansion researcher appears only after handler contact")
ok, state, reason = story.beginCinnabar(game)
T.check(not ok and reason == "ALREADY CONTACTED",
  "the handler cannot restart an active investigation")

ok, state, reason = story.discover(game, story.CLUES.MANSION_LOG)
T.check(ok and reason == "INVITATION READY",
  "the Mansion specimen log authenticates the exhibition invitation")
T.eq(state.stage, story.STAGES.INVITATION,
  "two Cinnabar records advance the campaign back toward Celadon")
T.eq(state.cinnabarClueCount, 2,
  "the complete Cinnabar investigation persists both records")
T.check(story.exhibitionAvailable(game),
  "the authenticated invitation exposes the engineered exhibition")
ok, state, reason = story.settleExhibition(game, 0, true)
T.check(not ok and reason == "INVALID MATCH",
  "story settlement rejects a missing durable Arena match id")
ok, state, reason = story.settleExhibition(game, 21, false)
T.check(ok and reason == "EXHIBITION LOST",
  "a committed exhibition loss is recorded without blocking a retry")
T.eq(state.stage, story.STAGES.INVITATION,
  "a loss keeps the exhibition invitation active")
T.eq(state.exhibition.attempts, 1,
  "the lost exhibition advances the attempt ledger exactly once")
ok, state, reason = story.settleExhibition(game, 21, false)
T.check(not ok and reason == "ALREADY SETTLED",
  "the same exhibition match cannot settle twice")
ok, state, reason = story.settleExhibition(game, 22, true)
T.check(ok and reason == "GIOVANNI SUMMONED",
  "a committed exhibition win summons Giovanni")
T.eq(state.stage, story.STAGES.CHOICE,
  "the victory advances to Giovanni's choice stage")
T.eq(state.exhibition.attempts, 2,
  "the exhibition ledger preserves both attempts")
T.eq(state.exhibition.wins, 1,
  "the exhibition ledger preserves the one victory")
handlerVisible, researcherVisible, giovanniVisible = StoryWorld.sync(game, story)
T.check(handlerVisible and not researcherVisible and giovanniVisible,
  "Giovanni replaces the Cinnabar contact after the exhibition victory")

ok, state, reason = story.discover(game, "NOT_A_REAL_CLUE")
T.check(not ok and reason == "UNKNOWN CLUE",
  "unknown story events cannot mutate the campaign")
T.eq(state.clueCount, 3, "an unknown event leaves progress untouched")

local migrated = State.sanitize({
  schema = 4,
  arena = { stairsRevealed = true, matchesPlayed = 9 },
})
T.eq(migrated.schema, 7, "schema four campaigns migrate into story state")
T.eq(migrated.story.stage, story.STAGES.RUMORS,
  "an upgraded campaign starts the rumor trail without skipping content")
T.eq(migrated.arena.matchesPlayed, 9,
  "story migration preserves prior Arena participation")

local repaired = State.sanitize({
  schema = 5,
  story = { stage = "BROKEN", clues = {
    [story.CLUES.FRAME] = true,
    [story.CLUES.MANIFEST] = true,
    [story.CLUES.CHART] = true,
  } },
})
T.eq(repaired.story.stage, story.STAGES.LEAD,
  "complete clues repair a partially written chapter transition")

local future = State.sanitize({
  schema = 8,
  story = { stage = "GIOVANNI_FINALE", clues = {
    FUTURE_DOSSIER = true,
    [story.CLUES.LAB_ARCHIVE] = true,
  } },
})
T.eq(future.schema, 8, "a future campaign schema is never downgraded")
T.eq(future.story.stage, "GIOVANNI_FINALE",
  "a future story chapter survives an older build")
T.check(future.story.clues.FUTURE_DOSSIER,
  "future clue fields survive an older build")
T.check(future.story.clues[story.CLUES.LAB_ARCHIVE],
  "known prerequisite clues cannot regress a future chapter")

T.check(story.resetForQA(), "the story service exposes a deterministic QA reset")
T.eq(story.snapshot(game).clueCount, 0, "QA reset clears only story progress")
T.eq(saved.gamble_campaign.arena.matchesPlayed, 6,
  "QA reset preserves Arena results")

enabled = false
T.eq(story.snapshot(game), nil, "base mode never exposes the Arena story")

T.finish("arena_story")
