local function factory(mod, opts)
  local State, Rules = opts.state, opts.rules
  local store = State.new(mod, opts.active)
  local Service = {}

  local function settledMap(rep)
    local out = {}
    for _, token in ipairs(rep.settledRounds) do out[token] = true end
    return out
  end

  local function persist(campaign)
    store.save(campaign)
    return campaign
  end

  local function awardRanks(game, rep, oldRank, newRank)
    local oldIndex, newIndex = Rules.rankIndex(oldRank), Rules.rankIndex(newRank)
    for index = oldIndex + 1, newIndex do
      local rank = Rules.RANKS[index]
      if rank and not rank.deferred and not rep.rankRewardsClaimed[rank.id] then
        rep.rankRewardsClaimed[rank.id] = true
        rep.pendingRankUps[#rep.pendingRankUps + 1] = rank.id
        if rank.reward > 0 and game and game.save then
          game.save.coins = math.min(opts.coinCap,
            math.max(0, tonumber(game.save.coins) or 0) + rank.reward)
        end
      end
    end
  end

  function Service.ensure()
    return store.load(true)
  end

  function Service.snapshot(game)
    local campaign = store.load(false)
    if not campaign then return nil end
    local rep = campaign.reputation
    local progress = Rules.progress(rep.points, Rules.badgeCount(game))
    if Rules.rankIndex(progress.current.id) > Rules.rankIndex(rep.rank) then
      awardRanks(game, rep, rep.rank, progress.current.id)
      rep.rank = progress.current.id
      persist(campaign)
    end
    return {
      schema = campaign.schema,
      points = rep.points,
      rank = progress.current.id,
      rankLabel = progress.current.label,
      nextRank = progress.next,
      badges = progress.badges,
      blockedByBadges = progress.blockedByBadges,
      lifetimeWagered = rep.lifetimeWagered,
      completedGames = rep.completedGames,
      wins = rep.wins,
      losses = rep.losses,
      draws = rep.draws,
      currentLossStreak = rep.currentLossStreak,
      bestLossStreak = rep.bestLossStreak,
      byGame = rep.byGame,
      pendingRankUps = rep.pendingRankUps,
    }
  end

  function Service.beginRound(gameId, stake)
    if not Rules.GAMES[gameId] then return nil, "UNKNOWN GAME" end
    local campaign = store.load(true)
    if not campaign then return nil, "GAMBLE MODE OFF" end
    local rep = campaign.reputation
    rep.nextRoundId = rep.nextRoundId + 1
    local token = gameId .. ":" .. tostring(rep.nextRoundId)
    rep.pendingRounds[token] = {
      gameId = gameId,
      stake = math.max(0, math.floor(tonumber(stake) or 0)),
    }
    persist(campaign)
    return token
  end

  function Service.settleRound(game, token, result, returned)
    if type(token) ~= "string" then return false, "NO ROUND" end
    local campaign = store.load(true)
    if not campaign then return false, "GAMBLE MODE OFF" end
    local rep = campaign.reputation
    if settledMap(rep)[token] then return false, "ALREADY SETTLED" end
    local pending = rep.pendingRounds[token]
    if not pending then return false, "UNKNOWN ROUND" end
    rep.pendingRounds[token] = nil
    rep.settledRounds[#rep.settledRounds + 1] = token
    while #rep.settledRounds > 128 do table.remove(rep.settledRounds, 1) end

    result = ({ win = true, loss = true, draw = true })[result]
      and result or "loss"
    returned = math.max(0, math.floor(tonumber(returned) or 0))
    local first = not rep.discoveredGames[pending.gameId]
    rep.discoveredGames[pending.gameId] = true
    local gained = Rules.pointsFor(pending.stake, result, first)
    rep.points = rep.points + gained
    rep.lifetimeWagered = rep.lifetimeWagered + pending.stake
    rep.completedGames = rep.completedGames + 1
    rep[result == "win" and "wins" or result == "draw" and "draws" or "losses"] =
      rep[result == "win" and "wins" or result == "draw" and "draws" or "losses"] + 1
    if result == "loss" then
      rep.currentLossStreak = rep.currentLossStreak + 1
      rep.bestLossStreak = math.max(rep.bestLossStreak, rep.currentLossStreak)
    else
      rep.currentLossStreak = 0
    end
    local row = rep.byGame[pending.gameId] or {
      played = 0, wins = 0, losses = 0, draws = 0,
      wagered = 0, returned = 0,
    }
    rep.byGame[pending.gameId] = row
    row.played = row.played + 1
    local resultKey = result == "win" and "wins"
      or result == "draw" and "draws" or "losses"
    row[resultKey] = row[resultKey] + 1
    row.wagered, row.returned = row.wagered + pending.stake, row.returned + returned

    local oldRank = rep.rank
    local newRank = Rules.rankFor(rep.points, Rules.badgeCount(game)).id
    awardRanks(game, rep, oldRank, newRank)
    rep.rank = newRank
    persist(campaign)
    return true, { points = gained, rank = newRank, rankUp = oldRank ~= newRank }
  end

  function Service.increaseStake(token, amount)
    local campaign = store.load(true)
    if not campaign then return false, "GAMBLE MODE OFF" end
    local pending = campaign.reputation.pendingRounds[token]
    if not pending then return false, "UNKNOWN ROUND" end
    pending.stake = pending.stake + math.max(0, math.floor(tonumber(amount) or 0))
    persist(campaign)
    return true
  end

  function Service.consumeRankUp()
    local campaign = store.load(false)
    if not campaign or #campaign.reputation.pendingRankUps == 0 then return nil end
    local id = table.remove(campaign.reputation.pendingRankUps, 1)
    persist(campaign)
    for _, rank in ipairs(Rules.RANKS) do
      if rank.id == id then return rank end
    end
    return nil
  end

  function Service.resetForQA()
    return store.reset()
  end

  return Service
end

return factory
