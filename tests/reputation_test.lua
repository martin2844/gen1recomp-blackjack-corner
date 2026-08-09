package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function loadModule(relative)
  local path = "mods/blackjack_corner/" .. relative
  return assert(loadfile(path))()
end

local State = loadModule("other/gamble/state.lua")
local Rules = loadModule("other/gamble/reputation/rules.lua")
local ServiceFactory = loadModule("other/gamble/reputation/service.lua")

T.eq(State.SCHEMA, 1, "the Gamble campaign save starts with an explicit schema")
local clean = State.sanitize({ reputation = {
  points = -50, completedGames = "4", currentLossStreak = 0 / 0,
  byGame = { blackjack = { played = "2", wins = 1 } },
} })
T.eq(clean.reputation.points, 0, "invalid negative reputation is repaired")
T.eq(clean.reputation.completedGames, 4, "numeric legacy fields migrate safely")
T.eq(clean.reputation.currentLossStreak, 0, "NaN save values are repaired")
T.eq(clean.reputation.byGame.blackjack.played, 2,
  "per-game campaign statistics survive sanitation")
T.eq(clean.debt.balance, 0, "future debt state has an additive default")
T.check(not clean.house.repossessed and not clean.arena.unlocked,
  "future campaign chapters begin disabled")

T.eq(Rules.rankFor(9999, 0).id, "ROOKIE",
  "reputation banks behind the first badge ceiling")
T.eq(Rules.rankFor(100, 1).id, "REGULAR",
  "one badge and enough reputation unlock Regular")
T.eq(Rules.rankFor(500, 3).id, "HIGH_ROLLER",
  "three badges unlock High Roller")
T.eq(Rules.rankFor(1500, 5).id, "VIP", "five badges unlock VIP")
T.eq(Rules.rankFor(99999, 8).id, "VIP",
  "the deferred Kingpin rank cannot unlock before the arena release")
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
T.eq(campaign.schema, 1, "Gamble Mode lazily creates its campaign state")
T.eq(save.unrelated, "kept", "campaign initialization preserves other mod data")

local game = { save = { coins = 100, inventory = {} } }
local token = assert(service.beginRound("blackjack", 10))
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

enabled = false
local before = save.gamble_campaign.reputation.points
T.eq(service.beginRound("blackjack", 50), nil,
  "turning Gamble Mode off disables reputation recording")
T.eq(save.gamble_campaign.reputation.points, before,
  "base play cannot mutate banked campaign progress")

T.finish("reputation")
