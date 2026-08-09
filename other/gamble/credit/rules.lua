local Rules = {}

Rules.MONEY_PER_COIN = 20

Rules.OFFERS = {
  ROOKIE = { coins = 500, fee = 100, label = "SMALL 500" },
  REGULAR = { coins = 2000, fee = 400, label = "REGULAR 2K" },
  HIGH_ROLLER = { coins = 5000, fee = 1000, label = "HIGH 5K" },
  VIP = { coins = 10000, fee = 2000, label = "VIP 10K" },
}

Rules.LATE_FEES = { 100, 150, 250, 400, 600, 850, 1200, 1600 }

function Rules.offer(rank)
  return Rules.OFFERS[rank] or Rules.OFFERS.ROOKIE
end

function Rules.total(debt)
  debt = type(debt) == "table" and debt or {}
  return math.max(0, math.floor(tonumber(debt.principal) or 0))
    + math.max(0, math.floor(tonumber(debt.fees) or 0))
end

function Rules.allocatePayment(debt, amount)
  amount = math.max(0, math.floor(tonumber(amount) or 0))
  local fees = math.max(0, math.floor(tonumber(debt.fees) or 0))
  local principal = math.max(0, math.floor(tonumber(debt.principal) or 0))
  local feePaid = math.min(fees, amount)
  fees, amount = fees - feePaid, amount - feePaid
  local principalPaid = math.min(principal, amount)
  return principal - principalPaid, fees, feePaid + principalPaid
end

function Rules.lateFee(badgeNumber)
  return Rules.LATE_FEES[math.max(1,
    math.min(#Rules.LATE_FEES, math.floor(tonumber(badgeNumber) or 1)))]
end

return Rules
