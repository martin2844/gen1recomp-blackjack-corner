package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function loadModule(relative)
  return assert(loadfile("mods/blackjack_corner/" .. relative))()
end

local Rules = loadModule("games/battle_arena/rules.lua")
local State = loadModule("other/gamble/state.lua")
local StoryFactory = loadModule("other/gamble/arena_story.lua")
local ServiceFactory = loadModule("games/battle_arena/service.lua")
local ScreenFactory = loadModule("games/battle_arena/screen.lua")
-- Keep the unit suite ROM-free. Imported-data validation separately checks
-- these public IDs against a real Red/Blue cache; the rules test only needs a
-- complete deterministic model with the same species and move keys.
local data = { pokemon = {}, moves = {}, type_chart = { matchups = {} } }
local allFighters = {}
for _, roster in ipairs({ Rules.FIGHTERS, Rules.EXHIBITION_FIGHTERS }) do
  for _, fighter in ipairs(roster) do allFighters[#allFighters + 1] = fighter end
end
for index, fighter in ipairs(allFighters) do
  data.pokemon[fighter.species] = {
    name = fighter.species,
    types = { "NORMAL" },
    baseStats = {
      hp = 55 + index, attack = 50 + index * 2,
      defense = 48 + index, speed = 45 + index * 2,
      special = 52 + index,
    },
  }
  for moveIndex, move in ipairs(fighter.moves) do
    data.moves[move] = data.moves[move] or {
      name = move, power = 45 + moveIndex * 10,
      accuracy = 92 + moveIndex, type = "NORMAL",
    }
  end
end

local repaired = State.sanitize({ schema = 3, arena = {
  pending = { status = "BET", match = {} },
} })
T.eq(repaired.arena.pending, nil,
  "a malformed saved match is discarded before the arena screen can crash")

local roll = 0
local function deterministic(maximum)
  roll = roll + 1
  return (roll * 7 % maximum) + 1
end

local match = Rules.newMatch(data, 0, 1, deterministic)
T.eq(match.id, 1, "the arena assigns a persistent match id")
T.eq(match.tier, "STREET", "new arena players begin on the street card")
T.check(match.fighters[1].species ~= match.fighters[2].species,
  "a fight never posts the same species on both sides")
T.check(#match.actions > 0 and match.winner >= 1 and match.winner <= 2,
  "a posted match contains a complete deterministic battle")
T.check(match.odds[1] >= 110 and match.odds[2] >= 110,
  "both fighters receive readable decimal odds")
for index = 1, 2 do
  local impliedReturn = match.chances[index] * match.odds[index] / 100
  T.check(impliedReturn <= 0.95 and impliedReturn >= 0.90,
    "posted odds include the bounded house margin")
end

-- Pricing and outcomes must remain one contract. A seeded large sample catches
-- the old failure where the displayed favorite paid as a 70% shot but the
-- independent battle simulator let it win almost every time.
local calibrationSeed = 91373
local function calibrationRandom(maximum)
  calibrationSeed = (calibrationSeed * 48271) % 2147483647
  return (calibrationSeed % maximum) + 1
end
local returned = { 0, 0 }
local underdogWins = 0
for sequence = 1, 20000 do
  local card = Rules.newMatch(data, 900, sequence, calibrationRandom)
  local favorite = card.odds[1] <= card.odds[2] and 1 or 2
  if card.winner ~= favorite then underdogWins = underdogWins + 1 end
  for side = 1, 2 do
    returned[side] = returned[side] + Rules.payout(100, side, card)
  end
end
for side = 1, 2 do
  local rtp = returned[side] / 20000 / 100
  T.check(rtp >= 0.90 and rtp <= 0.98,
    "realized arena outcomes preserve the posted house margin")
end
T.check(underdogWins > 1000,
  "seeded arena cards include meaningful underdog wins")
T.eq(Rules.payout(100, match.winner, match), match.odds[match.winner],
  "winning payout uses the exact posted price")
T.eq(Rules.payout(100, 3 - match.winner, match), 0,
  "a losing arena ticket returns nothing")
local exhibition = Rules.newExhibition(data, 77, deterministic)
T.eq(exhibition.id, 77, "the exhibition receives a durable Arena match id")
T.eq(exhibition.kind, "EXHIBITION", "the story card is explicitly classified")
T.eq(exhibition.tier, "EXHIBITION", "the story card has a dedicated visual tier")
T.eq(exhibition.fighters[1].species, "DRAGONITE",
  "Series 3 always posts its announced left fighter")
T.eq(exhibition.fighters[2].species, "MEWTWO",
  "Series 3 always posts its announced engineered opponent")
T.eq(exhibition.reward, "GIOVANNI AUDIENCE",
  "the story reward is committed with the fighter pair and result")
T.eq(Rules.tierFor(249).id, "STREET", "street card lasts through 249 arena rep")
T.eq(Rules.tierFor(250).id, "ELITE", "elite card unlocks at 250 arena rep")
T.eq(Rules.tierFor(900).id, "RARE", "rare fighters unlock at 900 arena rep")
T.eq(Rules.wagerLimit("VIP"), 0, "VIP cannot wager before final-rank access")
T.eq(Rules.wagerLimit("KINGPIN"), 10000, "Kingpin unlocks the full wager board")
for _, fighter in ipairs(allFighters) do
  T.check(data.pokemon[fighter.species] ~= nil,
    fighter.species .. " exists in the imported species data")
  for _, move in ipairs(fighter.moves) do
    T.check(data.moves[move] ~= nil,
      fighter.species .. " move " .. move .. " exists in the imported move data")
  end
end

do
  local pressed
  local input = { wasPressed = function(_, key) return key == pressed end }
  local Screen = ScreenFactory({
    mod = {}, rules = Rules, view = {}, service = {},
    play = function() end,
  })
  local screen = setmetatable({
    game = { input = input }, phase = "bet", selected = 1,
    betIndex = 1, bets = { 50, 100, 500 }, notice = "OLD NOTICE",
  }, Screen)
  local function press(key)
    pressed = key
    screen:update(0)
    pressed = nil
  end
  press("down")
  T.eq(screen.selected, 2, "down selects the other arena fighter")
  T.eq(screen.betIndex, 1, "fighter selection does not change the wager")
  press("right")
  T.eq(screen.betIndex, 2, "right increases the arena wager")
  T.eq(screen.selected, 2, "wager changes do not change the fighter")
  press("up")
  T.eq(screen.selected, 1, "up selects the other arena fighter")
  press("left")
  T.eq(screen.betIndex, 1, "left decreases the arena wager")
  press("left")
  T.eq(screen.betIndex, 3, "left wraps from the smallest arena wager")
  press("right")
  T.eq(screen.betIndex, 1, "right wraps from the largest arena wager")
  T.eq(screen.notice, nil, "directional input clears stale arena notices")
end

local sameRollMatch = Rules.newMatch(data, 0, 2, function() return 1 end)
T.check(sameRollMatch.fighters[1].species ~= sameRollMatch.fighters[2].species,
  "a constant injected RNG still produces two distinct fighters")

local enabled, rank = true, "KINGPIN"
local saved = { gamble_campaign = State.defaults() }
local mod = { save = {
  get = function(_, key) return saved[key] end,
  set = function(_, key, value) saved[key] = value end,
} }
local nextToken, settledCalls = 0, 0
local function beginRound(gameId, stake)
  nextToken = nextToken + 1
  local token = "arena:" .. nextToken
  local value = State.sanitize(saved.gamble_campaign)
  value.reputation.pendingRounds[token] = {
    gameId = gameId, stake = stake, rankAtStart = rank,
  }
  saved.gamble_campaign = value
  return token
end
local function settleRound(_, token, result, returned)
  local value = State.sanitize(saved.gamble_campaign)
  local pending = value.reputation.pendingRounds[token]
  if not pending then
    for _, settled in ipairs(value.reputation.settledRounds) do
      if settled == token then return false, "ALREADY SETTLED" end
    end
    return false, "UNKNOWN ROUND"
  end
  value.reputation.pendingRounds[token] = nil
  value.reputation.settledRounds[#value.reputation.settledRounds + 1] = token
  value.reputation.completedGames = value.reputation.completedGames + 1
  value.reputation.byGame.arena = value.reputation.byGame.arena or {
    played = 0, wins = 0, losses = 0, draws = 0, wagered = 0, returned = 0,
  }
  local row = value.reputation.byGame.arena
  row.played, row.wagered, row.returned = row.played + 1,
    row.wagered + pending.stake, row.returned + returned
  row[result == "win" and "wins" or "losses"] =
    row[result == "win" and "wins" or "losses"] + 1
  saved.gamble_campaign = value
  settledCalls = settledCalls + 1
  return true, { rank = rank }
end

local allowed = true
local service = ServiceFactory(mod, {
  state = State, rules = Rules, active = function() return enabled end,
  coinCap = 1000000, rank = function() return rank end,
  allowed = function() return allowed, "CREDIT FROZEN" end,
  beginRound = beginRound, settleRound = settleRound,
})
local game = { data = data, save = { coins = 50000, party = { { species = "MEW" } } } }
local party = game.save.party
local access = service.access(game)
T.check(access and saved.gamble_campaign.arena.unlocked,
  "Kingpin access permanently unlocks the concealed arena")
local posted = assert(service.current(game, deterministic))
T.eq(posted.status, "POSTED", "a visit persists one posted fight card")
T.eq(service.current(game, deterministic).match.id, posted.match.id,
  "reopening the board cannot reroll an unplayed matchup")

local selected, stake = posted.match.winner, 100
local before = game.save.coins
local ok, ticket = service.placeBet(game, selected, stake)
T.check(ok and ticket.status == "BET", "a valid wager becomes a saved ticket")
T.eq(game.save.coins, before - stake, "the arena deducts a wager exactly once")
T.check(saved.gamble_campaign.reputation.pendingRounds[ticket.roundToken] ~= nil,
  "saving the arena ticket preserves the shared reputation round")
T.eq(game.save.party, party, "arena betting never mutates the player's party")
ok = service.placeBet(game, selected, stake)
T.check(not ok and game.save.coins == before - stake,
  "a pending ticket cannot be charged twice")

-- Recreate the service as a reload boundary: the exact fighters, outcome,
-- wager, and reputation token must resume rather than generating a new card.
service = ServiceFactory(mod, {
  state = State, rules = Rules, active = function() return enabled end,
  coinCap = 1000000, rank = function() return rank end,
  allowed = function() return true end,
  beginRound = beginRound, settleRound = settleRound,
})
local resumed = service.current(game, deterministic)
T.check(resumed.status == "BET" and resumed.match.id == posted.match.id,
  "save reload resumes the exact pending wager before animation")
allowed = false
local paidAccess = service.access(game)
T.check(paidAccess,
  "a default change cannot strand an already-paid pending match")
allowed = true
ok, ticket = service.settle(game)
T.check(ok and ticket.status == "RESULT" and ticket.won,
  "the resumed winner settles into a persistent result")
T.eq(game.save.coins, before - stake + Rules.payout(stake, selected, posted.match),
  "the settled ticket credits the posted payout exactly")
T.eq(saved.gamble_campaign.reputation.completedGames, 1,
  "arena settlement survives the shared campaign write ordering")
T.eq(saved.gamble_campaign.reputation.byGame.arena.played, 1,
  "the arena participates in High Roller statistics")
local coinsAfter = game.save.coins
ok = service.settle(game)
T.check(ok and game.save.coins == coinsAfter and settledCalls == 1,
  "reopening a result cannot duplicate payout or reputation")
T.check(service.acknowledge(), "acknowledging a result retires its ticket")
T.eq(service.snapshot(game).pending, nil, "the next visit is ready for a new card")

local interrupted = assert(service.current(game, deterministic))
local interruptedWinner, interruptedStake = interrupted.match.winner, 100
local interruptedBefore = game.save.coins
ok, ticket = service.placeBet(game, interruptedWinner, interruptedStake)
T.check(ok, "a second durable ticket can model an interrupted settlement")
local interruptedPayout = Rules.payout(interruptedStake,
  interruptedWinner, interrupted.match)
local settledBeforeResume = settledCalls
T.check(settleRound(game, ticket.roundToken, "win", interruptedPayout),
  "the shared reputation receipt can commit before the Arena result")
ok, ticket = service.settle(game)
T.check(ok and ticket.status == "RESULT" and ticket.won,
  "a BET ticket resumes after its reputation receipt already committed")
T.eq(settledCalls, settledBeforeResume + 1,
  "resuming a partial commit cannot settle reputation twice")
T.eq(game.save.coins,
  interruptedBefore - interruptedStake + interruptedPayout,
  "resuming a partial commit credits its Arena payout exactly once")
T.check(service.acknowledge(),
  "a recovered partial settlement remains acknowledgeable")

local story = StoryFactory(mod, {
  state = State, active = function() return enabled end,
})
saved.gamble_campaign.story.stage = story.STAGES.INVITATION
service = ServiceFactory(mod, {
  state = State, rules = Rules, active = function() return enabled end,
  coinCap = 1000000, rank = function() return rank end,
  allowed = function() return true end,
  beginRound = beginRound, settleRound = settleRound,
  exhibition = story.exhibitionAvailable,
  settleExhibition = story.settleExhibition,
})
local storyCard = assert(service.current(game, deterministic))
T.eq(storyCard.kind, "EXHIBITION",
  "an authenticated invitation replaces an unpaid ordinary card")
T.eq(service.current(game, deterministic).match.id, storyCard.match.id,
  "reopening cannot reroll the committed exhibition")
local storyMatchId = storyCard.match.id
ok = service.placeBet(game, storyCard.match.winner, 100)
T.check(ok, "the exhibition uses the ordinary durable wager boundary")
ok, ticket = service.settle(game)
T.check(ok and ticket.won, "a winning exhibition settles through the Arena ledger")
local storyState = story.snapshot(game)
T.eq(storyState.stage, story.STAGES.CHOICE,
  "winning Series 3 summons Giovanni's choice stage")
T.eq(storyState.exhibition.attempts, 1,
  "the story records one exhibition attempt exactly once")
T.eq(storyState.exhibition.wins, 1,
  "the story records the exhibition victory exactly once")
local attemptsAfterWin = storyState.exhibition.attempts
ok = service.settle(game)
T.check(ok and story.snapshot(game).exhibition.attempts == attemptsAfterWin,
  "reopening a won result cannot duplicate story settlement")
T.check(service.acknowledge(), "the won exhibition result remains acknowledgeable")

saved.gamble_campaign.story.stage = story.STAGES.INVITATION
saved.gamble_campaign.story.exhibition = {
  attempts = 0, wins = 0, lastMatchId = 0,
}
saved.gamble_campaign.arena.pending = nil
local losingCard = assert(service.current(game, deterministic))
ok = service.placeBet(game, 3 - losingCard.match.winner, 100)
T.check(ok, "the exhibition also accepts a losing committed selection")
ok, ticket = service.settle(game)
T.check(ok and not ticket.won, "a lost exhibition produces a durable loss")
storyState = story.snapshot(game)
T.eq(storyState.stage, story.STAGES.INVITATION,
  "losing keeps the invitation recoverable")
T.eq(storyState.exhibition.attempts, 1,
  "a lost exhibition is still counted once")
T.check(service.acknowledge(), "the player can acknowledge a lost exhibition")
local retryCard = assert(service.current(game, deterministic))
T.check(retryCard.match.id > storyMatchId
    and retryCard.match.fighters[1].species == losingCard.match.fighters[1].species
    and retryCard.match.fighters[2].species == losingCard.match.fighters[2].species,
  "a retry preserves the fixed Series 3 pairing under a new durable ticket")
T.check(service.resetPosted(), "the unplayed retry can be retired by the QA reset")

rank = "VIP"
saved.gamble_campaign.arena.unlocked = false
local denied, reason = service.access(game)
T.check(not denied and reason:find("KINGPIN", 1, true),
  "the concealed entrance explains its final-rank requirement")
rank = "KINGPIN"
allowed = false
service = ServiceFactory(mod, {
  state = State, rules = Rules, active = function() return enabled end,
  coinCap = 1000000, rank = function() return rank end,
  allowed = function() return false, "CREDIT FROZEN" end,
  beginRound = beginRound, settleRound = settleRound,
})
denied, reason = service.access(game)
T.check(not denied and reason == "CREDIT FROZEN",
  "defaulted Rocket credit freezes the luxury arena")
enabled = false
T.eq(service.snapshot(game), nil, "ordinary mode never exposes arena campaign state")

T.finish("arena")
