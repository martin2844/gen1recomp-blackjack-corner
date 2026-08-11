return function(mod, opts)
  local Service, Rules = {}, assert(opts.rules)
  local State = opts.state.new(mod, opts.active)
  local coinCap = opts.coinCap or 1000000

  local function campaign(create)
    return State.load(create)
  end

  local function currentRank(game)
    return opts.rank and opts.rank(game) or "ROOKIE"
  end

  local function roundWasSettled(value, token)
    local settled = value and value.reputation
      and value.reputation.settledRounds or {}
    for _, candidate in ipairs(settled) do
      if candidate == token then return true end
    end
    return false
  end

  local function syncUnlock(game)
    local rank = currentRank(game)
    local value = campaign(false)
    if not value then return nil end
    if rank == "KINGPIN" and not value.arena.unlocked then
      value.arena.unlocked = true
      State.save(value)
    end
    return value
  end

  local function makeMatch(game, value, random)
    value.arena.nextMatchId = value.arena.nextMatchId + 1
    local exhibition = opts.exhibition and opts.exhibition(game) == true
    local match = exhibition
      and Rules.newExhibition(game.data, value.arena.nextMatchId, random)
      or Rules.newMatch(game.data, value.arena.reputation,
        value.arena.nextMatchId, random)
    value.arena.pending = {
      status = "POSTED",
      kind = exhibition and "EXHIBITION" or "STANDARD",
      match = match,
    }
    State.save(value)
    return value.arena.pending
  end

  function Service.access(game)
    if not opts.active() then return false, "GAMBLE MODE ONLY" end
    local value = syncUnlock(game) or campaign(true)
    if not value.arena.unlocked then
      return false, "KINGPIN ACCESS\nEIGHT BADGES AND\n4000 REP REQUIRED"
    end
    -- Once coins have been committed, debt/default changes cannot strand the
    -- ticket. Paid matches and saved results always remain resumable.
    local pending = value.arena.pending
    if pending and (pending.status == "BET" or pending.status == "RESULT") then
      return true
    end
    if opts.allowed then
      local allowed, reason = opts.allowed(game)
      if not allowed then return false, reason end
    end
    return true
  end

  function Service.snapshot(game)
    if not opts.active() then return nil end
    local value = syncUnlock(game) or campaign(true)
    local rank = currentRank(game)
    return {
      unlocked = value.arena.unlocked,
      reputation = value.arena.reputation,
      tier = Rules.tierFor(value.arena.reputation),
      matchesPlayed = value.arena.matchesPlayed,
      wins = value.arena.wins, losses = value.arena.losses,
      lifetimeWagered = value.arena.lifetimeWagered,
      lifetimeReturned = value.arena.lifetimeReturned,
      pending = value.arena.pending,
      rank = rank,
      wagerLimit = Rules.wagerLimit(rank),
      exhibitionAvailable = opts.exhibition and opts.exhibition(game) == true,
    }
  end

  function Service.current(game, random)
    local allowed, reason = Service.access(game)
    if not allowed then return nil, reason end
    local value = campaign(true)
    local pending = value.arena.pending
    if opts.exhibition and opts.exhibition(game) == true and pending
        and pending.status == "POSTED" and pending.kind ~= "EXHIBITION" then
      value.arena.pending = nil
      State.save(value)
      value = campaign(true)
    end
    return value.arena.pending or makeMatch(game, value, random)
  end

  function Service.placeBet(game, selected, stake)
    local allowed, reason = Service.access(game)
    if not allowed then return false, reason end
    local value = campaign(true)
    local pending = value.arena.pending
    if not pending or pending.status ~= "POSTED" then
      return false, "MATCH NOT OPEN"
    end
    selected, stake = math.floor(tonumber(selected) or 0),
      math.floor(tonumber(stake) or 0)
    local valid = false
    for _, offered in ipairs(Rules.availableBets(currentRank(game))) do
      if stake == offered then valid = true break end
    end
    if selected < 1 or selected > 2 or not valid then
      return false, "INVALID WAGER"
    end
    local coins = math.max(0, math.floor(tonumber(game.save.coins) or 0))
    if coins < stake then return false, "NOT ENOUGH COINS" end
    local maximumReturn = math.floor(stake * pending.match.odds[selected] / 100)
    if coins - stake + maximumReturn > coinCap then
      return false, "COIN CASE TOO FULL"
    end
    local matchId = pending.match.id
    local token = opts.beginRound and opts.beginRound("arena", stake, true)
    if not token then return false, "WAGER UNAVAILABLE" end
    -- beginRound writes the shared campaign record. Reload it before adding
    -- arena fields so neither service can overwrite the other's mutation.
    value = campaign(true)
    pending = value.arena.pending
    if not pending or pending.status ~= "POSTED"
        or pending.match.id ~= matchId then return false, "MATCH CHANGED" end
    game.save.coins = coins - stake
    pending.status, pending.selected, pending.stake = "BET", selected, stake
    pending.roundToken = token
    State.save(value)
    return true, pending
  end

  function Service.settle(game)
    if not opts.active() then return false, "GAMBLE MODE ONLY" end
    local value = campaign(false)
    local pending = value and value.arena.pending
    if not pending then return false, "NO PENDING MATCH" end
    if pending.status == "RESULT" then return true, pending end
    if pending.status ~= "BET" then return false, "MATCH HAS NO WAGER" end

    local payout = Rules.payout(pending.stake, pending.selected, pending.match)
    local coins = math.max(0, math.floor(tonumber(game.save.coins) or 0))
    payout = math.min(payout, math.max(0, coinCap - coins))
    local won = pending.selected == pending.match.winner
    local roundToken = pending.roundToken
    local settled, progress = opts.settleRound(game, roundToken,
      won and "win" or "loss", payout)
    if not settled then
      local settleReason = progress
      value = campaign(true)
      if settleReason ~= "ALREADY SETTLED"
          or not roundWasSettled(value, roundToken) then
        return false, settleReason or "ROUND SETTLEMENT FAILED"
      end
      -- The durable Arena ticket is still BET, but its shared reputation
      -- receipt already committed. Resume the remaining story/payout phases
      -- instead of permanently stranding the wager after an interrupted save.
      progress = nil
    end
    -- settleRound writes reputation into the same save object. Work from that
    -- fresh value before finalizing the arena result and payout ledger.
    value = campaign(true)
    pending = value.arena.pending
    if not pending or pending.status ~= "BET"
        or pending.roundToken ~= roundToken then return false, "MATCH CHANGED" end
    if pending.kind == "EXHIBITION" and opts.settleExhibition then
      local storySettled, _, storyReason = opts.settleExhibition(game,
        pending.match.id, won)
      if not storySettled and storyReason ~= "ALREADY SETTLED" then
        return false, storyReason or "STORY SETTLEMENT FAILED"
      end
      value = campaign(true)
      pending = value.arena.pending
      if not pending or pending.status ~= "BET"
          or pending.roundToken ~= roundToken then return false, "MATCH CHANGED" end
    end
    game.save.coins = coins + payout
    local arena = value.arena
    arena.matchesPlayed = arena.matchesPlayed + 1
    arena.lifetimeWagered = arena.lifetimeWagered + pending.stake
    arena.lifetimeReturned = arena.lifetimeReturned + payout
    arena.reputation = arena.reputation
      + math.max(2, math.floor(math.sqrt(pending.stake))) + (won and 25 or 0)
    if won then arena.wins = arena.wins + 1 else arena.losses = arena.losses + 1 end
    pending.status, pending.payout, pending.won = "RESULT", payout, won
    pending.rankUp = progress and progress.rankUp or nil
    table.insert(arena.history, 1, {
      id = pending.match.id, left = pending.match.fighters[1].species,
      right = pending.match.fighters[2].species,
      selected = pending.selected, winner = pending.match.winner,
      stake = pending.stake, payout = payout,
    })
    while #arena.history > 12 do table.remove(arena.history) end
    State.save(value)
    return true, pending
  end

  function Service.acknowledge()
    if not opts.active() then return false end
    local value = campaign(false)
    if not value or not value.arena.pending
        or value.arena.pending.status ~= "RESULT" then return false end
    value.arena.pending = nil
    State.save(value)
    return true
  end

  function Service.resetPosted()
    if not opts.active() then return false end
    local value = campaign(false)
    if not value or not value.arena.pending
        or value.arena.pending.status ~= "POSTED" then return false end
    value.arena.pending = nil
    State.save(value)
    return true
  end

  return Service
end
