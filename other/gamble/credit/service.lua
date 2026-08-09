return function(mod, opts)
  local State, Rules = opts.state, opts.rules
  local store = State.new(mod, opts.active)
  local Service = {}

  local function load(create)
    local campaign = store.load(create)
    return campaign, campaign and campaign.debt
  end

  local function save(campaign)
    store.save(campaign)
    return campaign
  end

  local function badgeCount(game)
    return opts.badgeCount(game)
  end

  function Service.snapshot(game)
    local campaign, debt = load(false)
    if not campaign then return nil end
    local rank = opts.rank(game) or "ROOKIE"
    return {
      status = debt.status,
      principal = debt.principal,
      fees = debt.fees,
      total = Rules.total(debt),
      dueBadge = debt.dueBadge,
      badges = badgeCount(game),
      offer = Rules.offer(rank),
      rank = rank,
      loansTaken = debt.loansTaken,
      totalRepaid = debt.totalRepaid,
    }
  end

  function Service.borrow(game)
    local campaign, debt = load(true)
    if not campaign then return false, "GAMBLE MODE OFF" end
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      return false, "You need a\nCOIN CASE."
    end
    if Rules.total(debt) > 0 or debt.status ~= "CLEAR" then
      return false, "Settle your old\ndebt first."
    end
    local rank = opts.rank(game) or "ROOKIE"
    local offer = Rules.offer(rank)
    local coins = math.max(0, math.floor(tonumber(game.save.coins) or 0))
    if coins + offer.coins > opts.coinCap then
      return false, "Your COIN CASE\nneeds more room."
    end
    game.save.coins = coins + offer.coins
    debt.principal, debt.fees = offer.coins, offer.fee
    debt.status = "ACTIVE"
    debt.dueBadge = badgeCount(game) + 1
    debt.lastBadgeFee = badgeCount(game)
    debt.loansTaken = debt.loansTaken + 1
    save(campaign)
    return true, ("Take %d coins.\fPay %d before\nyour next BADGE.")
      :format(offer.coins, offer.coins + offer.fee)
  end

  local function applyPayment(campaign, debt, amount)
    local principal, fees, paid = Rules.allocatePayment(debt, amount)
    debt.principal, debt.fees = principal, fees
    debt.totalRepaid = debt.totalRepaid + paid
    if Rules.total(debt) == 0 then
      debt.status, debt.dueBadge, debt.lastBadgeFee = "CLEAR", 0, 0
    end
    save(campaign)
    return paid, Rules.total(debt)
  end

  function Service.repayCoins(game, requested)
    local campaign, debt = load(false)
    if not campaign or Rules.total(debt) == 0 then return false, "You owe nothing." end
    local coins = math.max(0, math.floor(tonumber(game.save.coins) or 0))
    local amount = math.min(coins, Rules.total(debt),
      math.max(0, math.floor(tonumber(requested) or Rules.total(debt))))
    if amount <= 0 then return false, "You have no coins\nto repay with." end
    game.save.coins = coins - amount
    local paid, remaining = applyPayment(campaign, debt, amount)
    return true, remaining == 0 and "Debt cleared.\nWe're square."
      or ("Paid %d coins.\fStill owe %d."):format(paid, remaining)
  end

  function Service.repayMoney(game, requestedCoins)
    local campaign, debt = load(false)
    if not campaign or Rules.total(debt) == 0 then return false, "You owe nothing." end
    local money = math.max(0, math.floor(tonumber(game.save.money) or 0))
    local maximum = math.floor(money / Rules.MONEY_PER_COIN)
    local amount = math.min(maximum, Rules.total(debt),
      math.max(0, math.floor(tonumber(requestedCoins) or Rules.total(debt))))
    if amount <= 0 then return false, "Not enough money\nto make a payment." end
    game.save.money = money - amount * Rules.MONEY_PER_COIN
    local paid, remaining = applyPayment(campaign, debt, amount)
    return true, remaining == 0 and "Debt cleared.\nWe're square."
      or ("Paid ¥%d.\fStill owe %d coins.")
        :format(paid * Rules.MONEY_PER_COIN, remaining)
  end

  function Service.syncMilestones(game)
    local campaign, debt = load(false)
    if not campaign or Rules.total(debt) == 0 then return false end
    local badges = badgeCount(game)
    local changed, added = false, 0
    if debt.dueBadge > 0 and badges >= debt.dueBadge
        and debt.status ~= "DEFAULT" then
      debt.status = "DEFAULT"
      changed = true
    end
    for badge = debt.lastBadgeFee + 1, badges do
      if badge >= debt.dueBadge and debt.dueBadge > 0 then
        local fee = Rules.lateFee(badge)
        debt.fees, added = debt.fees + fee, added + fee
        changed = true
      end
    end
    if badges > debt.lastBadgeFee then
      debt.lastBadgeFee = badges
      changed = true
    end
    if changed then save(campaign) end
    return changed, added, debt.status
  end

  function Service.resetForQA()
    local campaign = store.load(true)
    if not campaign then return false end
    campaign.debt = State.defaults().debt
    save(campaign)
    return true
  end

  return Service
end
