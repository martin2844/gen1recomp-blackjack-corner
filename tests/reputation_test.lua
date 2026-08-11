package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function loadModule(relative)
  local path = "mods/blackjack_corner/" .. relative
  return assert(loadfile(path))()
end

local State = loadModule("other/gamble/state.lua")
local Rules = loadModule("other/gamble/reputation/rules.lua")
local ServiceFactory = loadModule("other/gamble/reputation/service.lua")

T.eq(State.SCHEMA, 6,
  "the Cinnabar investigation advances the campaign schema explicitly")
local clean = State.sanitize({ reputation = {
  points = -50, completedGames = "4", currentLossStreak = 0 / 0,
  byGame = { blackjack = { played = "2", wins = 1 } },
} })
T.eq(clean.reputation.points, 0, "invalid negative reputation is repaired")
T.eq(clean.reputation.completedGames, 4, "numeric legacy fields migrate safely")
T.eq(clean.reputation.currentLossStreak, 0, "NaN save values are repaired")
T.eq(clean.reputation.byGame.blackjack.played, 2,
  "per-game campaign statistics survive sanitation")
T.eq(clean.debt.principal, 0, "Rocket Credit debt has an additive default")
T.check(clean.house.status == "FAMILY_HOME" and not clean.arena.unlocked,
  "future campaign chapters begin disabled")

local migratedDebt = State.sanitize({ schema = 1,
  debt = { balance = 321 }, house = { repossessed = true } })
T.eq(migratedDebt.schema, State.SCHEMA, "schema-one campaigns migrate in order")
T.eq(migratedDebt.debt.principal, 321, "legacy debt balance becomes principal")
T.eq(migratedDebt.house.status, "ROCKET_OWNED",
  "legacy repossession state survives the schema-two migration")

local future = State.sanitize({
  schema = 7,
  futureChapter = { enabled = true },
  reputation = { rank = "BOGUS", futureStat = 42 },
  debt = { balance = 7, principal = 99 },
})
T.eq(future.schema, 7, "newer campaign schemas are never downgraded")
T.check(future.futureChapter.enabled and future.reputation.futureStat == 42,
  "unknown future campaign fields survive sanitation")
T.eq(future.debt.principal, 99, "unknown nested debt fields survive sanitation")
T.eq(future.reputation.rank, "ROOKIE", "invalid saved ranks are rejected")
local futureAgain = State.sanitize(future)
T.eq(futureAgain.schema, 7, "repeated future-schema loading is idempotent")
T.eq(futureAgain.debt.principal, 99,
  "repeated sanitation preserves unknown nested fields")

T.eq(Rules.rankFor(9999, 0).id, "ROOKIE",
  "reputation banks behind the first badge ceiling")
T.eq(Rules.rankFor(100, 1).id, "REGULAR",
  "one badge and enough reputation unlock Regular")
T.eq(Rules.rankFor(500, 3).id, "HIGH_ROLLER",
  "three badges unlock High Roller")
T.eq(Rules.rankFor(1500, 5).id, "VIP", "five badges unlock VIP")
T.eq(Rules.rankFor(99999, 8).id, "KINGPIN",
  "eight badges and enough reputation unlock the arena's final rank")
T.check(Rules.atLeast("KINGPIN", "HIGH_ROLLER"),
  "Kingpin remains eligible for every high-tier rank feature")
T.eq(Rules.progress(4000, 8).current.id, "KINGPIN",
  "the arena release removes the former Kingpin deferral")
T.check(Rules.progress(100, 0).blockedByBadges,
  "the progress model explains a badge-locked rank")
T.check(Rules.pointsFor(500, "win", false) > Rules.pointsFor(500, "loss", false),
  "wins add a modest reputation bonus")
T.check(Rules.pointsFor(10, "loss", true) > Rules.pointsFor(10, "loss", false),
  "trying a new casino game grants a discovery bonus")

local enabled, save = false, { unrelated = "kept" }
local mod = { save = {
  get = function(_, key, default)
    local value = save[key]
    return value == nil and default or value
  end,
  set = function(_, key, value) save[key] = value end,
} }
local service = ServiceFactory(mod, {
  state = State, rules = Rules, active = function() return enabled end,
  coinCap = 1000000,
})

T.eq(service.ensure(), nil, "base mode never creates Gamble campaign state")
T.eq(save.gamble_campaign, nil, "base-mode saves remain untouched")
enabled = true
local campaign = service.ensure()
T.eq(campaign.schema, State.SCHEMA,
  "Gamble Mode lazily creates current campaign state")
T.eq(save.unrelated, "kept", "campaign initialization preserves other mod data")

local game = { save = { coins = 100, inventory = {} } }
local token = assert(service.beginRound("blackjack", 10))
T.eq(type(token), "table", "screen-only games use transient round tokens")
T.eq(next(save.gamble_campaign.reputation.pendingRounds), nil,
  "starting a non-resumable game cannot leak a pending save entry")
T.check(service.increaseStake(token, 10), "progressive bets extend the same round")
local ok, result = service.settleRound(game, token, "loss", 0)
T.check(ok, "a paid casino round settles")
T.eq(result.points, Rules.pointsFor(20, "loss", true),
  "settlement uses the complete progressive stake")
T.eq(service.snapshot(game).currentLossStreak, 1,
  "losses still advance campaign statistics")
ok = service.settleRound(game, token, "win", 1000)
T.check(not ok, "the same casino round cannot settle twice")
T.eq(service.snapshot(game).completedGames, 1,
  "duplicate settlement cannot duplicate reputation")

local durable = assert(service.beginRound("arena", 50, true))
T.eq(type(durable), "string", "resumable games opt into durable round tokens")
T.check(save.gamble_campaign.reputation.pendingRounds[durable] ~= nil,
  "a durable Arena round survives a save/reload boundary")
T.check(service.settleRound(game, durable, "loss", 0),
  "a durable round settles through the same reputation ledger")
T.eq(save.gamble_campaign.reputation.pendingRounds[durable], nil,
  "settling a durable round clears its pending save entry")

local rookieSecond = assert(service.beginRound("blackjack", 10))
local rookieSecondResult
ok, rookieSecondResult = service.settleRound(game, rookieSecond, "loss", 0)
T.eq(rookieSecondResult.points, Rules.pointsFor(10, "loss", false),
  "a game earns its discovery bonus only once within one rank")

for gameId in pairs(Rules.GAMES) do
  local round = assert(service.beginRound(gameId, 10))
  T.check(service.settleRound(game, round, "draw", 10),
    gameId .. " participates in shared High Roller progression")
end

campaign = save.gamble_campaign
campaign.reputation.points = 99
campaign.reputation.rank = "ROOKIE"
campaign.reputation.rankRewardsClaimed = {}
campaign.reputation.pendingRankUps = {}
game.save.inventory.BOULDERBADGE = 1
local rankRound = assert(service.beginRound("plinko", 10))
ok, result = service.settleRound(game, rankRound, "loss", 0)
T.check(ok and result.rank == "REGULAR" and result.rankUp,
  "a qualifying result produces one rank-up")
T.eq(game.save.coins, 350, "the Regular reward is granted once")
T.eq(service.consumeRankUp().id, "REGULAR",
  "the High Roller screen consumes the pending presentation")
T.eq(service.consumeRankUp(), nil, "rank-up presentation is exactly once")

local regularDiscovery = assert(service.beginRound("blackjack", 10))
local regularDiscoveryResult
ok, regularDiscoveryResult = service.settleRound(
  game, regularDiscovery, "loss", 0)
T.eq(regularDiscoveryResult.points, Rules.pointsFor(10, "loss", true),
  "the same game earns a fresh discovery bonus after ranking up")
local regularRepeat = assert(service.beginRound("blackjack", 10))
local regularRepeatResult
ok, regularRepeatResult = service.settleRound(game, regularRepeat, "loss", 0)
T.eq(regularRepeatResult.points, Rules.pointsFor(10, "loss", false),
  "the per-rank discovery bonus still settles only once")

campaign = save.gamble_campaign
campaign.reputation.points = 500
campaign.reputation.rank = "REGULAR"
campaign.reputation.pendingRankUps = {}
campaign.reputation.rankRewardsClaimed.HIGH_ROLLER = nil
game.save.inventory.CASCADEBADGE = 1
game.save.inventory.THUNDERBADGE = 1
local beforeReward = game.save.coins
local unlocked = service.snapshot(game)
T.eq(unlocked.rank, "HIGH_ROLLER",
  "a new badge immediately releases banked reputation")
T.eq(game.save.coins, beforeReward + 1000,
  "removing a badge ceiling grants its rank reward once")
T.eq(service.consumeRankUp().id, "HIGH_ROLLER",
  "badge-triggered rank-ups keep their presentation")

campaign = save.gamble_campaign
campaign.reputation.points = 99
campaign.reputation.rank = "ROOKIE"
campaign.reputation.rankRewardsClaimed = {}
campaign.reputation.pendingRankUps = {}
campaign.reputation.pendingRewardCoins = 0
campaign.reputation.discoveredGames = {}
game.save.inventory.CASCADEBADGE = nil
game.save.inventory.THUNDERBADGE = nil
game.save.coins = 1000000
local cappedRound = assert(service.beginRound("crash", 10))
ok = service.settleRound(game, cappedRound, "loss", 0)
T.check(ok, "a rank-up at the Coin Case cap still settles")
T.eq(game.save.coins, 1000000, "rank rewards never overflow the Coin Case")
T.eq(save.gamble_campaign.reputation.pendingRewardCoins, 250,
  "an undeliverable rank reward is banked in full")
game.save.coins = 999900
local cappedSnapshot = service.snapshot(game)
T.eq(game.save.coins, 1000000, "banked rewards fill newly available Coin Case space")
T.eq(cappedSnapshot.pendingRewardCoins, 150,
  "the unpaid reward remainder stays claimable")
game.save.coins = 999000
cappedSnapshot = service.snapshot(game)
T.eq(game.save.coins, 999150, "the remaining banked reward is delivered later")
T.eq(cappedSnapshot.pendingRewardCoins, 0,
  "a banked rank reward is paid exactly once")

campaign = save.gamble_campaign
campaign.reputation.byGame.blackjack.played = 5
campaign.reputation.byGame.plinko.played = 2
T.eq(service.snapshot(game).favoriteGame.id, "blackjack",
  "the status snapshot exposes a deterministic most-played game")

enabled = false
local before = save.gamble_campaign.reputation.points
T.eq(service.beginRound("blackjack", 50), nil,
  "turning Gamble Mode off disables reputation recording")
T.eq(save.gamble_campaign.reputation.points, before,
  "base play cannot mutate banked campaign progress")

T.finish("reputation")
