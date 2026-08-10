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
      collectorsTriggered = debt.collectorsTriggered,
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

  function Service.pawnAndRepay(game, partyIndex, pawnPokemon)
    local campaign, debt = load(false)
    if not campaign or Rules.total(debt) == 0 then return false, "You owe nothing." end
    if type(pawnPokemon) ~= "function" then
      return false, "Pawn service is\nunavailable."
    end
    local requested = Rules.total(debt)
    local ok, entry, sold, routed = pawnPokemon(game, partyIndex, requested)
    if not ok then return false, entry end

    -- The pawn ledger stays authoritative for the exact ticket/FIFO behavior.
    -- Its optional routed amount bypasses Coin Case capacity only for coins
    -- that move directly into this debt; appraisal surplus is paid normally.
    local amount = math.min(math.max(0, math.floor(tonumber(routed) or 0)),
      Rules.total(debt), entry.value)
    local paid, remaining = applyPayment(campaign, debt, amount)
    local message = ("%s pawned.\f%d coins paid.\nOwe %d.")
      :format(entry.name or "POKEMON", paid, remaining)
    if sold then
      message = message .. ("\f%s was sold off.")
        :format(sold.name or "The oldest POKEMON")
    end
    return true, message, entry, sold, paid
  end

  function Service.luxuryAllowed(game)
    Service.syncMilestones(game)
    local state = Service.snapshot(game)
    if not state or state.status ~= "DEFAULT" then return true end
    return false, "ROCKET CREDIT has\nfrozen luxury prizes.\fRepay your debt in\nthe Celadon Lounge."
  end

  function Service.noteCollector(mapId)
    local campaign, debt = load(false)
    if not campaign or debt.status ~= "DEFAULT" or type(mapId) ~= "string" then
      return false
    end
    if debt.collectorsTriggered[mapId] then return false end
    debt.collectorsTriggered[mapId] = true
    save(campaign)
    return true
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
