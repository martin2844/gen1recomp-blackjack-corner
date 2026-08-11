return function(mod, opts)
  local store = opts.state.new(mod, opts.active)
  local House = {
    BAILOUT_COINS = 10000,
    BUYBACK_COST = 30000,
  }
  local coinCap = math.max(0,
    math.floor(tonumber(opts.coinCap) or 1000000))

  local function load(create)
    local campaign = store.load(create)
    return campaign, campaign and campaign.house
  end

  local function save(campaign)
    store.save(campaign)
    return campaign
  end

  local function coins(game)
    return math.max(0, math.floor(tonumber(game.save.coins) or 0))
  end

  local function money(game)
    return math.max(0, math.floor(tonumber(game.save.money) or 0))
  end

  function House.snapshot(game)
    local _, home = load(false)
    if not home then return nil end
    return {
      status = home.status,
      bailoutClaimed = home.bailoutClaimed,
      buybackPaid = home.buybackPaid,
      rocketBattleWon = home.rocketBattleWon,
      bailoutCoins = House.BAILOUT_COINS,
      buybackCost = House.BUYBACK_COST,
      coins = coins(game),
      money = money(game),
    }
  end

  local function pawnEligibility(game, home)
    if not home then return false, "GAMBLE MODE OFF" end
    if home.bailoutClaimed or home.status ~= "FAMILY_HOME" then
      return false, "The family home was\nalready pawned."
    end
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      return false, "You need a\nCOIN CASE."
    end
    if coins(game) + House.BAILOUT_COINS > coinCap then
      return false, "The COIN CASE needs\n10000 free space."
    end
    return true
  end

  function House.canPawnHome(game)
    local _, home = load(false)
    return pawnEligibility(game, home)
  end

  function House.pawnHome(game)
    local campaign, home = load(false)
    local allowed, message = pawnEligibility(game, home)
    if not allowed then return false, message end
    game.save.coins = coins(game) + House.BAILOUT_COINS
    home.bailoutClaimed = true
    home.status = "ROCKET_OWNED"
    home.buybackPaid = false
    home.rocketBattleWon = false
    save(campaign)
    return true, "You gained 10000 coins.\fTEAM ROCKET now owns\nyour Pallet home."
  end

  -- Preserve the v0.5 API used by older QA drivers and companion mods. The
  -- persisted field also keeps its original name so existing saves migrate
  -- without a schema-only rewrite.
  House.canClaimBailout = House.canPawnHome
  House.claimBailout = House.pawnHome

  function House.buyBack(game)
    local campaign, home = load(false)
    if not campaign then return false, "GAMBLE MODE OFF" end
    if home.status == "BUYBACK_PAID" then
      return false, "The deed is paid.\fWin the house battle."
    end
    if home.status == "RESTORED" then return false, "Your home is yours." end
    if home.status ~= "ROCKET_OWNED" then
      return false, "TEAM ROCKET does\nnot own your home."
    end
    if coins(game) < House.BUYBACK_COST then
      return false, ("You need %d coins\nto buy back the deed.")
        :format(House.BUYBACK_COST)
    end
    game.save.coins = coins(game) - House.BUYBACK_COST
    home.buybackPaid = true
    home.status = "BUYBACK_PAID"
    save(campaign)
    return true, "The deed is paid.\fOne Rocket battle\nremains downstairs."
  end

  function House.recordRocketVictory()
    local campaign, home = load(false)
    if not campaign or home.status ~= "BUYBACK_PAID"
        or not home.buybackPaid then return false end
    home.rocketBattleWon = true
    home.status = "RESTORED"
    save(campaign)
    return true
  end

  function House.resetForQA()
    local campaign = store.load(true)
    if not campaign then return false end
    campaign.house = opts.state.defaults().house
    save(campaign)
    return true
  end

  return House
end
