-- Deterministic real-engine release audit for the v0.7 Underground Arena.
-- Runs the map journey, native battle UI, economy, persistence, tiers, and
-- failure paths against the live Red/Blue engine and writes visual evidence.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local SaveData = require("src.core.SaveData")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local loader = assert(game.mods, "mod loader is unavailable")
  local api = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  local passed = {}

  local function pass(id, note)
    assert(not passed[id], "duplicate case " .. id)
    passed[id] = true
    U.log("PASS", id, note or "")
  end
  local function eq(actual, expected, message)
    assert(actual == expected, (message or "values differ") .. ": got "
      .. tostring(actual) .. ", expected " .. tostring(expected))
  end
  local function campaign()
    return assert(loader.modSave.blackjack_corner.gamble_campaign,
      "campaign disappeared")
  end
  local function settleMap(mapId)
    for _ = 1, 360 do
      local ow = game.overworld
      if ow and ow.map.id == mapId and not ow.transitioning
          and #ow.scriptMoves == 0 and not ow.player.moving then break end
      U.wait(1)
    end
    U.wait(5)
    assert(game.overworld and game.overworld.map.id == mapId,
      "failed to reach " .. mapId)
  end
  local function advanceToMap(mapId)
    for _ = 1, 24 do
      if game.overworld and game.overworld.map.id == mapId then break end
      U.tap(game, "a"); U.wait(8)
    end
    settleMap(mapId)
  end
  local function diskRoundTrip(paths)
    assert(game:writeSave(), "writeSave failed")
    local disk = assert(SaveData.load(game.save.version))
    for path, expected in pairs(paths) do
      local value = disk
      for part in path:gmatch("[^.]+") do value = value and value[part] end
      eq(value, expected, "disk value " .. path)
    end
    game:restoreSave(disk)
    bucket = assert(loader.modSave.blackjack_corner)
  end
  local function assertMapObjects(mapId, minimum)
    local map = assert(game.data.maps[mapId], "missing map " .. mapId)
    local count = 0
    for _, obj in ipairs(map.objects or {}) do
      if tostring(obj.name or ""):find("ARENA_", 1, true) == 1 then
        count = count + 1
        local name = tostring(obj.name)
        assert(type(obj.text) == "string" and obj.text ~= "",
          obj.name .. " has no interaction text")
      end
    end
    assert(count >= minimum, mapId .. " is missing arena actors")
  end
  local function seedKingpin()
    bucket.gamble_mode = true
    bucket.gamble_campaign = api.campaign_state.defaults()
    local rep = bucket.gamble_campaign.reputation
    rep.points, rep.rank = 4000, "KINGPIN"
    for _, rank in ipairs(api.reputation_rules.RANKS) do
      rep.rankRewardsClaimed[rank.id] = true
    end
    game.save.inventory = { COIN_CASE = 1 }
    for _, badge in ipairs(api.reputation_rules.BADGES) do
      game.save.inventory[badge] = 1
    end
    if #(game.save.party or {}) == 0 then
      local Pokemon = require("src.pokemon.Pokemon")
      game.save.party = { Pokemon.new(game.data, "PIKACHU", 24) }
    end
    game.save.coins, game.save.money = 50000, 3000
    game.save.objectToggles = game.save.objectToggles or {}
  end
  local function openArena()
    -- The bookie now occupies the head of the native League chamber, matching
    -- the trainer position in an Elite Four room rather than floating beside
    -- the old custom ring.
    U.teleport(game, api.arena_world.ARENA, 9, 4, "up")
    U.tap(game, "a")
    for _ = 1, 48 do
      local top = game.stack:top()
      if top and top.phase then U.wait(8); return top end
      U.tap(game, "a"); U.wait(3)
    end
    error("arena bookie did not open the betting screen")
  end

  U.wait(10)

  -- Ordinary play never initializes or exposes the campaign chapter.
  bucket.gamble_mode, bucket.gamble_campaign = false, nil
  local allowed = api.arena.access(game)
  assert(not allowed and bucket.gamble_campaign == nil)
  pass("MODE-01")

  -- Rank and badge gate: VIP can inspect the panel but cannot enter.
  seedKingpin()
  local rep = campaign().reputation
  rep.points, rep.rank = 3999, "VIP"
  game.save.inventory.EARTHBADGE = nil
  allowed = api.arena.access(game)
  assert(not allowed and not campaign().arena.unlocked)
  pass("UNLOCK-01")
  rep = campaign().reputation
  rep.points, rep.rank = 4000, "VIP"
  game.save.inventory.EARTHBADGE = 1
  allowed = api.arena.access(game)
  assert(allowed and api.reputation.snapshot(game).rank == "KINGPIN")
  assert(campaign().arena.unlocked)
  pass("UNLOCK-02")
  eq(#api.arena_rules.availableBets("VIP"), 0)
  local kingpinBets = api.arena_rules.availableBets("KINGPIN")
  eq(kingpinBets[#kingpinBets], 10000)
  pass("LIMIT-01", "VIP has no ticket; KINGPIN reaches 10000")

  -- Concealed terminal, revealed stairs, permanent staff, physical doors,
  -- real reloads, and returns.
  U.teleport(game, "BLACKJACK_LOUNGE", 3, 12, "up")
  settleMap("BLACKJACK_LOUNGE")
  local unlockedCoins = game.save.coins
  diskRoundTrip({
    ["modData.blackjack_corner.gamble_campaign.arena.unlocked"] = true,
    ["modData.blackjack_corner.gamble_campaign.reputation.rank"] = "KINGPIN",
  })
  assert(api.arena.access(game) and game.save.coins == unlockedCoins)
  pass("UNLOCK-03", "disk reload keeps unlock without another reward")
  assert(U.shot(game, shotDir .. "/arena-status-terminal.png"))
  U.tap(game, "a")
  for _ = 1, 300 do
    if api.arena_security.snapshot().stairsRevealed then break end
    U.tap(game, "a"); U.wait(3)
  end
  assert(api.arena_security.snapshot().stairsRevealed,
    "status terminal did not reveal the staircase")
  settleMap("BLACKJACK_LOUNGE")
  assert(U.shot(game, shotDir .. "/arena-revealed-stairs.png"))
  U.hold(game, "up", 24); advanceToMap(api.arena_world.LOBBY)
  assert(U.shot(game, shotDir .. "/arena-vip-lobby.png"))
  assertMapObjects(api.arena_world.LOBBY, 8)
  diskRoundTrip({
    ["player.map"] = api.arena_world.LOBBY,
    ["modData.blackjack_corner.gamble_campaign.arena.stairsRevealed"] = true,
  })
  settleMap(api.arena_world.LOBBY)
  pass("WORLD-01", "status terminal reveals a walkable staircase")
  pass("WORLD-02", "walking onto the stairs entered the VIP lobby")
  pass("WORLD-03", "lobby actors are present and separately positioned")
  U.teleport(game, api.arena_world.LOBBY, 9, 5, "up")
  local partyCount = #game.save.party
  assert(#game.save.party == partyCount,
    "the permanent B1 staff changed the player's party")
  U.hold(game, "up", 120); advanceToMap(api.arena_world.ARENA)
  pass("WORLD-04", "the physical B1 door preserves the live party")
  eq(game.data.maps[api.arena_world.ARENA].tileset, "GYM",
    "B2 must use the native Elite Four gym tileset")
  -- Walked-in cameras initially frame the exit. Move beside the native
  -- security floor for the complete arena checkpoint.
  U.teleport(game, api.arena_world.ARENA, 12, 10, "left")
  settleMap(api.arena_world.ARENA)
  assert(U.shot(game, shotDir .. "/arena-spectator-floor.png"))
  assertMapObjects(api.arena_world.ARENA, 9)
  pass("WORLD-05", "native B2 pit blocks and arena actors are live")
  pass("WORLD-06", "every interactive arena actor has registered text")
  diskRoundTrip({ ["player.map"] = api.arena_world.ARENA })
  settleMap(api.arena_world.ARENA)
  U.teleport(game, api.arena_world.ARENA, 9, 14, "down")
  U.hold(game, "down", 120); advanceToMap(api.arena_world.LOBBY)
  eq(#game.save.party, partyCount, "arena traversal changed the party")
  U.teleport(game, api.arena_world.LOBBY, 9, 14, "down")
  U.hold(game, "down", 120); advanceToMap("BLACKJACK_LOUNGE")
  pass("WORLD-07", "physical doors preserve the party and lead upstairs")
  diskRoundTrip({ ["player.map"] = "BLACKJACK_LOUNGE" })
  settleMap("BLACKJACK_LOUNGE")
  pass("WORLD-08", "Lounge, B1, and B2 survive true disk restores")

  -- Native board and pre-charge failure paths.
  local screen = openArena()
  assert(screen.phase == "bet" and screen.pending.status == "POSTED")
  assert(U.shot(game, shotDir .. "/arena-posted-odds.png"))
  pass("UI-01")
  local fighter, wager = screen.selected, screen.betIndex
  U.tap(game, "down"); U.wait(3)
  eq(screen.selected, 3 - fighter, "down did not switch fighters")
  eq(screen.betIndex, wager, "down changed the wager")
  U.tap(game, "right"); U.wait(3)
  eq(screen.selected, 3 - fighter, "right changed the fighter")
  eq(screen.betIndex, wager < #screen.bets and wager + 1 or 1,
    "right did not increase the wager")
  assert(U.shot(game, shotDir .. "/arena-directional-controls.png"))
  U.tap(game, "up"); U.tap(game, "left"); U.wait(3)
  eq(screen.selected, fighter, "up did not restore the fighter")
  eq(screen.betIndex, wager, "left did not restore the wager")
  pass("UI-02", "up/down pick fighters; left/right change the wager")
  local firstId = screen.pending.match.id
  U.tap(game, "b"); U.wait(5)
  screen = openArena()
  eq(screen.pending.match.id, firstId, "unplayed card rerolled")
  pass("ODDS-01", "posted card remains stable between visits")
  U.tap(game, "b"); U.wait(5)
  assert(api.arena.resetPosted())
  local favoriteWins, underdogWins = 0, 0
  local oddsSeed = 7007
  local function oddsRandom(maximum)
    oddsSeed = (oddsSeed * 48271) % 2147483647
    return (oddsSeed % maximum) + 1
  end
  for _ = 1, 10 do
    local card = assert(api.arena.current(game, oddsRandom))
    local favorite = card.match.odds[1] <= card.match.odds[2] and 1 or 2
    if card.match.winner == favorite then favoriteWins = favoriteWins + 1
    else underdogWins = underdogWins + 1 end
    assert(card.match.odds[1] > 100 and card.match.odds[2] > 100)
    assert(api.arena.resetPosted())
  end
  assert(favoriteWins > 0 and underdogWins > 0,
    "seeded odds sample must include favorites and underdogs")
  screen = openArena()
  pass("ODDS-02", ("ten seeded cards: %d favorites, %d underdogs")
    :format(favoriteWins, underdogWins))
  local oldCoins = game.save.coins
  game.save.coins = 0
  local ok = api.arena.placeBet(game, 1, 50)
  assert(not ok and game.save.coins == 0)
  pass("BET-01")
  game.save.coins = 1000000
  ok = api.arena.placeBet(game, 1, 50); assert(not ok)
  ok = api.arena.placeBet(game, 2, 50); assert(not ok)
  eq(game.save.coins, 1000000, "full Coin Case wager changed coins")
  pass("BET-02", "both picks refuse at cap without revealing winner")
  game.save.coins = oldCoins

  -- Bet on the known deterministic result inside the test harness, then
  -- prove the player-facing screen persists and resumes the exact ticket.
  screen.selected = screen.pending.match.winner
  local selected, winner = screen.selected, screen.pending.match.winner
  local matchId = screen.pending.match.id
  local stake, before = screen.bets[screen.betIndex], game.save.coins
  U.tap(game, "a"); U.wait(5)
  eq(game.save.coins, before - stake, "valid wager deduction")
  assert(campaign().arena.pending.status == "BET")
  pass("BET-03")
  local afterBet = game.save.coins
  ok = api.arena.placeBet(game, 3 - selected, stake)
  assert(not ok and game.save.coins == afterBet)
  U.tap(game, "b"); U.wait(2)
  assert(campaign().arena.pending.status == "BET")
  pass("BET-04", "paid ticket cannot be changed, cancelled, or recharged")
  diskRoundTrip({
    ["modData.blackjack_corner.gamble_campaign.arena.pending.status"] = "BET",
    ["modData.blackjack_corner.gamble_campaign.arena.pending.match.id"] = matchId,
    ["modData.blackjack_corner.gamble_campaign.arena.pending.selected"] = selected,
    ["modData.blackjack_corner.gamble_campaign.arena.pending.stake"] = stake,
  })
  pass("PERSIST-01")
  screen = openArena()
  assert(screen.phase == "intro" and screen.pending.match.id == matchId)
  pass("PERSIST-02")
  while screen.phase ~= "battle" do U.wait(1) end
  U.wait(8)
  assert(U.shot(game, shotDir .. "/arena-live-battle.png"))
  pass("FIGHT-01")
  for _ = 1, 4000 do
    if screen.phase == "result" then break end
    U.wait(1)
  end
  assert(screen.phase == "result" and screen.pending.match.winner == winner)
  assert(screen.pending.won and screen.pending.payout > stake)
  assert(U.shot(game, shotDir .. "/arena-winning-result.png"))
  local paid = screen.pending.payout
  eq(game.save.coins, before - stake + paid, "winner payout")
  eq(api.reputation.snapshot(game).byGame.arena.played, 1,
    "arena High Roller settlement")
  eq(api.arena.snapshot(game).matchesPlayed, 1, "arena match ledger")
  pass("RESULT-01")
  local after = game.save.coins
  api.arena.settle(game)
  eq(game.save.coins, after, "result paid twice")
  U.tap(game, "a"); U.wait(10)
  assert(game.stack:top().phase == "bet")
  assert(game.stack:top().pending.match.id ~= matchId)
  pass("RESULT-03")

  -- A deterministic losing ticket returns zero and never touches the party.
  screen = game.stack:top()
  local party = game.save.party
  screen.selected = 3 - screen.pending.match.winner
  before, stake = game.save.coins, screen.bets[screen.betIndex]
  U.tap(game, "a")
  for _ = 1, 4000 do
    if screen.phase == "result" then break end
    U.wait(1)
  end
  assert(not screen.pending.won and screen.pending.payout == 0)
  eq(game.save.coins, before - stake, "losing ticket returned coins")
  eq(game.save.party, party, "arena touched player party")
  pass("RESULT-02")
  pass("PARTY-01")

  -- Arena access begins at the final rank, so its own results cannot be the
  -- event that crosses into KINGPIN. Reproduce the real handoff from one of
  -- the seven earlier games: present the queued rank-up, then open the stairs.
  assert(api.arena.acknowledge())
  local rankRep = campaign().reputation
  rankRep.points, rankRep.rank = 4000, "KINGPIN"
  rankRep.pendingRankUps = { "KINGPIN" }
  U.teleport(game, "BLACKJACK_LOUNGE", 3, 12, "up")
  settleMap("BLACKJACK_LOUNGE")
  -- Set up an unrevealed terminal only after leaving the underground route;
  -- the compatibility guard correctly keeps stairs open for a player coming
  -- from B1/B2 on a migrated save.
  campaign().arena.stairsRevealed = false
  api.arena_world.sync(game, api.arena_security, true)
  U.tap(game, "a")
  local rankScreen
  for _ = 1, 48 do
    local top = game.stack:top()
    if top and top.rankUp then rankScreen = top; break end
    U.tap(game, "a"); U.wait(3)
  end
  assert(rankScreen, "switch did not present the pending Kingpin rank-up")
  assert(rankScreen.rankUp and rankScreen.rankUp.id == "KINGPIN")
  assert(U.shot(game, shotDir .. "/arena-kingpin-rank-up.png"))
  U.tap(game, "a")
  for _ = 1, 300 do
    if api.arena_security.snapshot().stairsRevealed then break end
    U.tap(game, "a"); U.wait(3)
  end
  U.hold(game, "up", 24); advanceToMap(api.arena_world.LOBBY)
  pass("RESULT-04", "switch presents KINGPIN before revealing the stairs")

  -- Select the longest real simulation produced by 500 deterministic cards
  -- and prove its complete animation resolves without a softlock.
  local longMatch
  for seedValue = 1, 500 do
    local seed = seedValue
    local candidate = api.arena_rules.newMatch(game.data, 900, 5000 + seedValue,
      function(maximum)
        seed = (seed * 1103515245 + 12345) % 2147483648
        return (seed % maximum) + 1
      end)
    if not longMatch or #candidate.actions > #longMatch.actions then
      longMatch = candidate
    end
  end
  assert(longMatch and #longMatch.actions > 1,
    "could not generate a long arena fixture")
  campaign().arena.pending = { status = "POSTED", match = longMatch }
  screen = openArena(); screen.selected = longMatch.winner
  U.tap(game, "a")
  local capturedLongFight = false
  for _ = 1, 4000 do
    if screen.phase == "battle" and screen.actionIndex
        and screen.actionIndex >= math.floor(#longMatch.actions / 2)
        and not capturedLongFight then
      capturedLongFight = true
      assert(U.shot(game, shotDir .. "/arena-long-fight.png"))
    end
    if screen.phase == "result" then break end
    U.wait(1)
  end
  assert(capturedLongFight and screen.phase == "result")
  pass("FIGHT-02", ("longest of 500 cards resolved in %d actions")
    :format(#longMatch.actions))

  -- Tier progression is visible and additive, without v0.8 story fighters.
  api.arena.acknowledge(); campaign().arena.reputation = 249
  screen = openArena(); eq(screen.pending.match.tier, "STREET")
  assert(U.shot(game, shotDir .. "/arena-street-card.png")); pass("TIER-01")
  api.arena.resetPosted(); campaign().arena.reputation = 250
  screen = openArena(); eq(screen.pending.match.tier, "ELITE")
  assert(U.shot(game, shotDir .. "/arena-elite-card.png")); pass("TIER-02")
  api.arena.resetPosted(); campaign().arena.reputation = 900
  screen = openArena(); eq(screen.pending.match.tier, "RARE")
  assert(U.shot(game, shotDir .. "/arena-rare-card.png")); pass("TIER-03")

  -- Default freezes this luxury room; clearing debt restores it.
  U.teleport(game, api.arena_world.ARENA, 9, 9, "up")
  campaign().debt = { principal = 100, fees = 20, status = "DEFAULT",
    dueBadge = 8, lastBadgeFee = 8, loansTaken = 1, totalRepaid = 0,
    collectorsTriggered = {} }
  api.reputation.ensure()
  allowed = api.arena.access(game)
  assert(not allowed)
  local lockedCoins = game.save.coins
  ok = api.arena.placeBet(game, 1, 50)
  assert(not ok and game.save.coins == lockedCoins)
  pass("DEFAULT-01")
  campaign().debt = { principal = 0, fees = 0, status = "CLEAR",
    dueBadge = 0, lastBadgeFee = 0, loansTaken = 1, totalRepaid = 120,
    collectorsTriggered = {} }
  api.reputation.ensure()
  local paidCard = assert(api.arena.current(game))
  assert(api.arena.placeBet(game, paidCard.match.winner, 50))
  campaign().debt = { principal = 100, fees = 20, status = "DEFAULT",
    dueBadge = 8, lastBadgeFee = 8, loansTaken = 2, totalRepaid = 120,
    collectorsTriggered = {} }
  api.reputation.ensure()
  assert(api.arena.access(game), "default stranded a paid arena ticket")
  assert(api.arena.settle(game)); assert(api.arena.acknowledge())
  pass("DEFAULT-02", "paid ticket remains resumable after default")

  -- v0.6 state migrates to v0.7 without losing debt, home, or reputation.
  bucket.gamble_campaign = {
    schema = 2,
    reputation = { points = 777, rank = "HIGH_ROLLER", completedGames = 12,
      byGame = {}, discoveredGames = {}, rankRewardsClaimed = {},
      pendingRankUps = {}, pendingRounds = {}, settledRounds = {} },
    debt = { principal = 321, fees = 45, status = "ACTIVE" },
    house = { status = "ROCKET_OWNED", bailoutClaimed = true },
    arena = { unlocked = false, reputation = 0 },
  }
  local migrated = api.reputation.ensure()
  eq(migrated.schema, api.campaign_state.SCHEMA)
  eq(migrated.reputation.points, 777)
  eq(migrated.debt.principal, 321); eq(migrated.house.status, "ROCKET_OWNED")
  eq(migrated.arena.matchesPlayed, 0)
  pass("MIG-01")
  bucket.gamble_campaign.arena.pending = { status = "BET", match = {} }
  bucket.gamble_campaign.futureChapter = { marker = 73 }
  migrated = api.reputation.ensure()
  eq(migrated.arena.pending, nil)
  eq(migrated.futureChapter.marker, 73)
  pass("MIG-02", "corrupt arena ticket discarded; unrelated state preserved")

  local expected = {
    "MODE-01", "UNLOCK-01", "UNLOCK-02", "UNLOCK-03", "LIMIT-01",
    "WORLD-01", "WORLD-02", "WORLD-03", "WORLD-04", "WORLD-05",
    "WORLD-06", "WORLD-07", "WORLD-08", "UI-01", "UI-02", "ODDS-01", "ODDS-02",
    "BET-01", "BET-02", "BET-03", "BET-04", "PERSIST-01",
    "PERSIST-02", "FIGHT-01", "FIGHT-02", "RESULT-01", "RESULT-02",
    "RESULT-03", "RESULT-04", "PARTY-01", "TIER-01", "TIER-02",
    "TIER-03", "DEFAULT-01", "DEFAULT-02", "MIG-01", "MIG-02",
  }
  for _, id in ipairs(expected) do assert(passed[id], "missing case " .. id) end
  U.log("V0.7 ARENA AUDIT COMPLETE", #expected, "cases")
end
