package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function loadModule(relative)
  return assert(loadfile("mods/blackjack_corner/" .. relative))()
end

local State = loadModule("other/gamble/state.lua")
local ReputationRules = loadModule("other/gamble/reputation/rules.lua")
local CreditRules = loadModule("other/gamble/credit/rules.lua")
local CreditFactory = loadModule("other/gamble/credit/service.lua")

T.eq(CreditRules.offer("ROOKIE").coins, 500,
  "Rookie credit begins with a controlled small offer")
T.eq(CreditRules.offer("VIP").coins, 10000,
  "VIP rank unlocks the largest initial offer")
T.eq(CreditRules.offer("KINGPIN").coins, 10000,
  "Kingpin credit never falls back to the Rookie offer")
local debt = { principal = 500, fees = 100 }
local principal, fees, paid = CreditRules.allocatePayment(debt, 150)
T.eq(fees, 0, "repayment clears fixed fees first")
T.eq(principal, 450, "remaining repayment reduces principal")
T.eq(paid, 150, "repayment allocation reports the exact paid amount")

local enabled = true
local saved = {}
local mod = { save = {
  get = function(_, key, default)
    return saved[key] == nil and default or saved[key]
  end,
  set = function(_, key, value) saved[key] = value end,
} }
local currentRank = "ROOKIE"
local service = CreditFactory(mod, {
  state = State, rules = CreditRules, active = function() return enabled end,
  coinCap = 1000000, badgeCount = ReputationRules.badgeCount,
  rank = function() return currentRank end,
})

saved.gamble_campaign = State.defaults()
local game = { save = { coins = 0, money = 10000, inventory = {} } }
local ok = service.borrow(game)
T.check(not ok, "Rocket Credit requires the Coin Case")
game.save.inventory.COIN_CASE = 1
local message
ok, message = service.borrow(game)
T.check(ok and message:find("500", 1, true), "the broker issues the Rookie offer")
T.eq(game.save.coins, 500, "loan principal arrives in the Coin Case")
local snapshot = service.snapshot(game)
T.eq(snapshot.principal, 500, "loan principal is persisted")
T.eq(snapshot.fees, 100, "the fixed fee is visible immediately")
T.eq(snapshot.total, 600, "the statement totals principal and fees")
T.eq(snapshot.status, "ACTIVE", "a new loan enters ACTIVE status")
T.eq(snapshot.dueBadge, 1, "a fresh loan is due at the next badge")

ok = service.borrow(game)
T.check(not ok, "the broker refuses overlapping loans")
ok = service.repayCoins(game, 250)
T.check(ok, "casino coins can repay debt")
T.eq(game.save.coins, 250, "coin repayment deducts the selected amount")
snapshot = service.snapshot(game)
T.eq(snapshot.fees, 0, "coin repayment clears fees before principal")
T.eq(snapshot.principal, 350, "coin repayment reduces principal")

ok = service.repayMoney(game, 100)
T.check(ok, "ordinary money can repay a coin-denominated debt")
T.eq(game.save.money, 8000, "money repayment uses the documented exchange rate")
T.eq(service.snapshot(game).total, 250, "money repayment reduces the same ledger")

game.save.inventory.BOULDERBADGE = 1
local luxuryAllowed, luxuryMessage = service.luxuryAllowed(game)
T.check(not luxuryAllowed and luxuryMessage:find("frozen", 1, true),
  "luxury authorization enforces a newly passed badge deadline immediately")
local changed, added, status = service.syncMilestones(game)
T.check(not changed and added == 0,
  "rechecking the synchronized badge deadline cannot duplicate its late fee")
T.eq(status, "DEFAULT", "missing the badge deadline enters DEFAULT")
T.eq(service.snapshot(game).fees, CreditRules.lateFee(1),
  "the authorization boundary applies exactly one fixed late fee")
T.check(service.noteCollector("PALLET_TOWN"),
  "the first collector encounter is persisted during default")
T.check(not service.noteCollector("PALLET_TOWN"),
  "the same collector encounter is idempotent")
T.check(service.snapshot(game).collectorsTriggered.PALLET_TOWN,
  "credit statements retain the collector history")
luxuryAllowed, luxuryMessage = service.luxuryAllowed(game)
T.check(not luxuryAllowed and luxuryMessage:find("frozen", 1, true),
  "default freezes only the campaign's luxury prize services")
local afterDefault = service.snapshot(game)
service.syncMilestones(game)
T.eq(service.snapshot(game).total, afterDefault.total,
  "rechecking the same milestone never duplicates a late fee")

game.save.coins = 1000
ok = service.repayCoins(game, 1000)
T.check(ok, "a default remains fully recoverable")
snapshot = service.snapshot(game)
T.eq(snapshot.total, 0, "full repayment clears every debt component")
T.eq(snapshot.status, "CLEAR", "full repayment exits DEFAULT")
T.check(service.luxuryAllowed(game), "clearing debt immediately restores luxury services")

game.save.coins = 0
ok = service.borrow(game)
T.check(ok, "a cleared account can take a later loan")
local pawnCalled = false
ok, message, entry, sold, paid = service.pawnAndRepay(game, 2,
  function(pawnGame, partyIndex, reserved)
    pawnCalled = partyIndex == 2
    local ticket = { name = "SHELLY", value = 700, redeem = 910 }
    local routed = math.min(ticket.value, reserved)
    pawnGame.save.coins = pawnGame.save.coins + ticket.value - routed
    return true, ticket, nil, routed
  end)
T.check(ok and pawnCalled, "a party appraisal can be routed into Rocket Credit")
T.eq(paid, 600, "pawn repayment never pays beyond the live debt")
T.eq(game.save.coins, 600,
  "pawn value above the debt leaves the existing coins plus surplus in the Coin Case")
T.eq(service.snapshot(game).total, 0, "pawn-and-pay can clear the full ledger")
T.check(message:find("SHELLY", 1, true) ~= nil,
  "pawn repayment confirms the exact Pokemon ticket")

currentRank = "VIP"
game.save.coins = 999500
ok = service.borrow(game)
T.check(not ok, "credit never overflows the one-million Coin Case")
T.eq(service.snapshot(game).total, 0,
  "a refused oversized loan does not mutate debt")

enabled = false
T.eq(service.snapshot(game), nil, "base mode never exposes Rocket Credit")
T.check(service.luxuryAllowed(game), "base mode never inherits campaign restrictions")
ok = service.borrow(game)
T.check(not ok, "base mode cannot create campaign debt")

T.finish("credit")
