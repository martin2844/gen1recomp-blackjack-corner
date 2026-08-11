package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function loadModule(relative)
  return assert(loadfile("mods/blackjack_corner/" .. relative))()
end

local State = loadModule("other/gamble/state.lua")
local HouseFactory = loadModule("other/gamble/credit/house_service.lua")

local enabled, saved = true, {}
local mod = { save = {
  get = function(_, key, default)
    return saved[key] == nil and default or saved[key]
  end,
  set = function(_, key, value) saved[key] = value end,
} }
local house = HouseFactory(mod, {
  state = State, active = function() return enabled end, coinCap = 1000000,
})

local lowCapHouse = HouseFactory(mod, {
  state = State, active = function() return enabled end, coinCap = 9999,
})
local function game(coins, money, coinCase)
  return { save = {
    coins = coins or 0, money = money or 0,
    inventory = coinCase == false and {} or { COIN_CASE = 1 },
  } }
end

saved.gamble_campaign = State.defaults()
local player = game(0, 0)
local snapshot = house.snapshot(player)
T.eq(snapshot.status, "FAMILY_HOME", "a fresh campaign keeps the family home")
T.eq(snapshot.bailoutCoins, 10000, "pawning the home has one fixed payout")
T.eq(snapshot.buybackCost, 30000, "the family deed has one fixed buyback cost")

local ok, message = house.canPawnHome(game(500, 2500, false))
T.check(not ok and message:find("COIN CASE", 1, true),
  "house pawning cannot create inaccessible casino coins")
ok = house.canPawnHome(game(1, 999999))
T.check(ok, "ordinary money never blocks house pawning")
ok = house.canPawnHome(game(12345, 1))
T.check(ok, "an existing casino balance never blocks house pawning")
local capPlayer = game(990000, 100000)
ok = house.canPawnHome(capPlayer)
T.check(ok, "exactly ten thousand free Coin Case space permits pawning")
ok, message = house.canPawnHome(game(990001, 0))
T.check(not ok and message:find("10000 free", 1, true),
  "house pawning requires room for its complete payout")
local lowCapPlayer = game(0, 0)
ok = lowCapHouse.canPawnHome(lowCapPlayer)
T.check(not ok, "a configured cap below the payout is never silently raised")
ok = lowCapHouse.pawnHome(lowCapPlayer)
T.check(not ok, "a low-cap Coin Case cannot receive an oversized house payout")
T.eq(lowCapPlayer.save.coins, 0, "a refused low-cap pawn pays no coins")
T.eq(lowCapHouse.snapshot(lowCapPlayer).status, "FAMILY_HOME",
  "a refused low-cap pawn leaves home ownership unchanged")

local debtBefore = saved.gamble_campaign.debt
player.save.coins, player.save.money = 1250, 50000
ok, message = house.pawnHome(player)
T.check(ok and message:find("10000", 1, true), "a player can pawn the home at any balance")
T.eq(player.save.coins, 11250, "house pawning adds exactly ten thousand coins")
snapshot = house.snapshot(player)
T.eq(snapshot.status, "ROCKET_OWNED", "house pawning transfers ownership")
T.check(snapshot.bailoutClaimed, "one-time house pawning is persisted")
T.eq(saved.gamble_campaign.debt.principal, debtBefore.principal,
  "selling the house never rewrites the independent debt ledger")

local coinsBefore = player.save.coins
ok = house.pawnHome(player)
T.check(not ok, "the house cannot be pawned twice")
T.eq(player.save.coins, coinsBefore, "repeated house pawning pays nothing")

player.save.coins = 29999
ok, message = house.buyBack(player)
T.check(not ok and message:find("30000", 1, true),
  "buyback explains the exact missing threshold")
T.eq(player.save.coins, 29999, "an unaffordable buyback charges nothing")
player.save.coins = 30025
ok, message = house.buyBack(player)
T.check(ok and message:find("battle", 1, true),
  "paying the deed clearly leaves one battle requirement")
T.eq(player.save.coins, 25, "buyback deducts exactly thirty thousand coins")
snapshot = house.snapshot(player)
T.eq(snapshot.status, "BUYBACK_PAID", "the paid deed persists before battle")
T.check(snapshot.buybackPaid and not snapshot.rocketBattleWon,
  "the deed and battle requirements remain independently visible")

coinsBefore = player.save.coins
ok = house.buyBack(player)
T.check(not ok, "the family deed cannot be purchased twice")
T.eq(player.save.coins, coinsBefore, "a repeated buyback charges nothing")
ok = house.recordRocketVictory()
T.check(ok, "winning after deed payment completes restoration")
snapshot = house.snapshot(player)
T.eq(snapshot.status, "RESTORED", "the complete quest restores the family home")
T.check(snapshot.buybackPaid and snapshot.rocketBattleWon,
  "restoration preserves both completion requirements")
T.check(not house.recordRocketVictory(), "the restoration victory is idempotent")

house.resetForQA()
snapshot = house.snapshot(player)
T.eq(snapshot.status, "FAMILY_HOME", "the QA reset returns the house state machine to start")
T.check(not snapshot.bailoutClaimed and not snapshot.buybackPaid
    and not snapshot.rocketBattleWon, "the QA reset clears all house milestones")

saved.gamble_campaign.house = {
  status = "BUYBACK_PAID", bailoutClaimed = false,
  buybackPaid = false, rocketBattleWon = false,
}
snapshot = house.snapshot(player)
T.check(snapshot.bailoutClaimed and snapshot.buybackPaid,
  "sanitation repairs the prerequisites of a battle-pending save")
saved.gamble_campaign.house = {
  status = "FAMILY_HOME", bailoutClaimed = false,
  buybackPaid = false, rocketBattleWon = true,
}
snapshot = house.snapshot(player)
T.eq(snapshot.status, "RESTORED",
  "a recorded Rocket victory repairs a partially written house status")
T.check(snapshot.bailoutClaimed and snapshot.buybackPaid,
  "restored sanitation prevents duplicate bailout or deed payment")

enabled = false
T.eq(house.snapshot(player), nil, "base mode exposes no house campaign state")
ok = house.pawnHome(player)
T.check(not ok, "base mode can never pawn the family home")

T.eq(house.canClaimBailout, house.canPawnHome,
  "the legacy eligibility API remains compatible")
T.eq(house.claimBailout, house.pawnHome,
  "the legacy claim API remains compatible")

T.finish("house")
