-- Deterministic real-engine audit for the v0.6 Rocket Credit release gate.
-- It drives native screens/maps for presentation checkpoints and asserts every
-- economy/save invariant against the live mod loaded by LOVE2D.

return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Screens = require("src.ui.Screens")
  local Pokemon = require("src.pokemon.Pokemon")
  local Boxes = require("src.pokemon.Boxes")
  local SaveData = require("src.core.SaveData")
  local GameVersion = require("src.core.GameVersion")
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
  local function check(value, message) assert(value, message) end
  local function eq(actual, expected, message)
    assert(actual == expected, (message or "values differ") .. ": got "
      .. tostring(actual) .. ", expected " .. tostring(expected))
  end
  local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local out = {}; seen[value] = out
    for key, item in pairs(value) do out[copy(key, seen)] = copy(item, seen) end
    return out
  end
  local function campaign()
    return assert(loader.modSave.blackjack_corner.gamble_campaign,
      "campaign disappeared")
  end
  local function reset()
    bucket = loader.modSave.blackjack_corner or {}
    loader.modSave.blackjack_corner = bucket
    bucket.gamble_mode = true
    bucket.gamble_campaign = api.campaign_state.defaults()
    bucket.pawned_pokemon = {}
    bucket.paid_case_claim = nil
    bucket.master_ball_redeemed = nil
    game.save.inventory = { COIN_CASE = 1 }
    game.save.coins, game.save.money = 100, 3000
    game.save.party, game.save.boxes, game.save.currentBox = {}, nil, 1
    game.save.flags = game.save.flags or {}
    game.save.objectToggles = game.save.objectToggles or {}
    api.credit_world.sync(game, api.credit)
    api.house_world.sync(game, api.house)
  end
  local function mon(species, level)
    return Pokemon.new(game.data, species or "RATTATA", level or 10,
      function(maximum) return math.max(0, maximum - 1) end)
  end
  local function realScreen(id, name, actions, frames)
    U.teleport(game, "PALLET_CASINO", 10, 11, "up")
    Screens.push(game, id, {})
    U.wait(5)
    for _, action in ipairs(actions or {}) do U.tap(game, action); U.wait(2) end
    U.wait(frames or 5)
    check(U.shot(game, shotDir .. "/" .. name .. ".png"),
      "missing screenshot " .. name)
    U.teleport(game, "PALLET_CASINO", 10, 11, "up")
  end
  local function settleMap(mapId)
    for _ = 1, 300 do
      local ow = game.overworld
      if ow and ow.map.id == mapId and not ow.transitioning
          and #ow.scriptMoves == 0 and not ow.player.moving then break end
      U.wait(1)
    end
    U.wait(4)
    return game.overworld and game.overworld.map.id
  end
  local function diskRoundTrip(expectedMap)
    check(game:writeSave(), "writeSave failed")
    local disk = assert(SaveData.load(game.save.version))
    for path, expected in pairs(expectedMap) do
      local value = disk
      for part in path:gmatch("[^.]+") do value = value and value[part] end
      eq(value, expected, "disk value " .. path)
    end
    game:restoreSave(disk)
    bucket = assert(loader.modSave.blackjack_corner)
  end

  U.wait(10)
  reset()

  -- Credit, deadline/default, and recovery.
  game.save.coins = 100
  local ok = api.credit.borrow(game)
  check(ok, "Rookie loan was refused")
  local debt = api.credit.snapshot(game)
  eq(game.save.coins, 600, "loan payout")
  eq(debt.principal, 500, "loan principal")
  eq(debt.fees, 100, "loan fee")
  eq(debt.total, 600, "loan total")
  eq(debt.dueBadge, 1, "loan deadline")
  realScreen("BlackjackCornerHighRoller", "credit-active-high-roller")
  pass("CREDIT-01", "500 principal + 100 fee, due before badge 1")

  local before = copy(api.credit.snapshot(game))
  ok = api.credit.borrow(game)
  check(not ok, "overlapping loan was accepted")
  eq(api.credit.snapshot(game).total, before.total, "refused second loan mutated debt")
  eq(game.save.coins, 600, "refused second loan mutated coins")
  pass("CREDIT-02")

  check(api.credit.repayCoins(game, 50), "coin repayment failed")
  debt = api.credit.snapshot(game)
  eq(debt.fees, 50, "coin payment did not clear fees first")
  local moneyBefore = game.save.money
  check(api.credit.repayMoney(game, 50), "money repayment failed")
  debt = api.credit.snapshot(game)
  eq(debt.fees, 0, "money payment did not finish fees first")
  eq(game.save.money, moneyBefore - 1000, "money exchange was not ¥20 per coin")
  pass("CREDIT-03")

  diskRoundTrip({
    ["modData.blackjack_corner.gamble_campaign.debt.principal"] = 500,
    ["modData.blackjack_corner.gamble_campaign.debt.fees"] = 0,
    ["modData.blackjack_corner.gamble_campaign.debt.dueBadge"] = 1,
    ["modData.blackjack_corner.gamble_campaign.debt.status"] = "ACTIVE",
  })
  pass("CREDIT-04")

  game.save.inventory.BOULDERBADGE = 1
  local changed, added = api.credit.syncMilestones(game)
  check(changed, "badge did not update debt milestone")
  eq(added, api.credit_rules.lateFee(1), "wrong milestone late fee")
  debt = api.credit.snapshot(game)
  eq(debt.status, "DEFAULT", "debt did not enter default")
  eq(debt.total, 600, "default total")
  pass("DEFAULT-01")
  api.credit.syncMilestones(game)
  eq(api.credit.snapshot(game).total, 600, "same badge duplicated late fee")
  diskRoundTrip({
    ["modData.blackjack_corner.gamble_campaign.debt.status"] = "DEFAULT",
    ["modData.blackjack_corner.gamble_campaign.debt.fees"] = 100,
  })
  api.credit.syncMilestones(game)
  eq(api.credit.snapshot(game).total, 600, "reload duplicated late fee")
  pass("DEFAULT-02")

  api.credit_world.sync(game, api.credit)
  U.teleport(game, "PALLET_TOWN", 8, 14, "left")
  U.wait(20); check(U.shot(game, shotDir .. "/default-pallet-collector.png"))
  U.tap(game, "a"); U.wait(30)
  check(U.shot(game, shotDir .. "/default-pallet-collector-dialogue.png"))
  U.teleport(game, "CELADON_CITY", 28, 22, "right")
  U.wait(20); check(U.shot(game, shotDir .. "/default-celadon-collector.png"))
  U.tap(game, "a"); U.wait(30)
  check(U.shot(game, shotDir .. "/default-celadon-collector-dialogue.png"))
  pass("DEFAULT-03", "collectors visible in both towns")
  pass("DEFAULT-04", "both collector dialogues opened without battle")

  -- Luxury freeze and non-luxury access.
  game.save.coins = 5000
  realScreen("BlackjackCornerPrizeCase", "default-prize-case-refusal", { "a" })
  eq(game.save.coins, 5000, "refused paid case deducted coins")
  pass("FREEZE-01")
  local partyBefore = #game.save.party
  local prize = api.catalog.pokemon(GameVersion.get())[1]
  for _, operation in ipairs({
    function() return api.buyPokemon(game, prize, false) end,
    function() return api.buyPokemon(game, prize, true) end,
    function() return api.buyItem(game, api.catalog.ITEMS[1]) end,
    function() return api.buyItem(game, api.catalog.ITEMS[#api.catalog.ITEMS]) end,
  }) do check(not operation(), "default allowed a luxury purchase") end
  eq(game.save.coins, 5000, "luxury freeze changed coins")
  eq(#game.save.party, partyBefore, "luxury freeze changed party")
  pass("FREEZE-02")

  for _, row in ipairs({
    { "BlackjackCornerTable", "default-blackjack" },
    { "BlackjackCornerHoldemTable", "default-holdem" },
    { "BlackjackCornerCrash", "default-crash" },
    { "BlackjackCornerTubeFlyer", "default-tube-flyer" },
    { "BlackjackCornerHorseRacing", "default-horse-racing" },
    { "BlackjackCornerPlinko", "default-plinko" },
  }) do realScreen(row[1], row[2]) end
  local bought = api.buyCoins(game, 50)
  check(bought, "coin clerk service froze in default")
  pass("FREEZE-03", "six games and coin clerk remained usable")

  local repBefore = api.reputation.snapshot(game).completedGames
  bucket.paid_case_claim = {
    kind = "item", id = "RARE_CANDY", quantity = 1,
    label = "RARE CANDY", tier = "common", weight = 1,
  }
  local claimCoins = game.save.coins
  realScreen("BlackjackCornerPrizeCase", "default-saved-claim", { "a" }, 240)
  eq(bucket.paid_case_claim, nil, "saved claim did not deliver")
  eq(game.save.coins, claimCoins, "saved claim charged again")
  eq(api.reputation.snapshot(game).completedGames, repBefore,
    "saved claim settled reputation again")
  pass("FREEZE-04")

  -- Pawn-to-debt routing, overflow warning semantics, and recovery.
  reset(); game.save.coins = 0; game.save.money = 10000
  game.save.party = { mon("RATTATA", 8), mon("PIKACHU", 18), mon("DRATINI", 25) }
  check(api.credit.borrow(game), "pawn scenario loan failed")
  local quote2 = assert(api.pawnQuote(game, 2))
  ok, _, localTicket = api.credit.pawnAndRepay(game, 2, api.pawnPokemon)
  check(ok and localTicket.name == quote2.name, "first pawn-to-pay failed")
  eq(#game.save.party, 2, "pawn did not remove chosen party member")
  eq(#api.pawnLedger(), 1, "pawn ticket missing")
  local paidTicket = api.pawnLedger()[1]
  game.save.coins = math.max(game.save.coins, paidTicket.redeem)
  local redeemed, returned = api.redeemPokemon(game, 1)
  check(redeemed and returned.mon.species == quote2.mon.species,
    "exact pawn ticket was not redeemable")
  pass("PAWN-01")

  -- Isolate a tiny debt so appraisal surplus must route into the Coin Case.
  reset()
  campaign().debt = { principal = 25, fees = 0, status = "ACTIVE", dueBadge = 1,
    lastBadgeFee = 0, loansTaken = 1, totalRepaid = 0, collectorsTriggered = {} }
  api.reputation.ensure()
  game.save.coins = 0
  game.save.party = { mon("RATTATA", 5), mon("DRAGONITE", 55) }
  local coinsBefore = game.save.coins
  local quote = assert(api.pawnQuote(game, #game.save.party))
  ok = api.credit.pawnAndRepay(game, #game.save.party, api.pawnPokemon)
  check(ok, "surplus pawn-to-pay failed")
  eq(api.credit.snapshot(game).total, 0, "surplus pawn did not clear debt")
  eq(game.save.coins, coinsBefore + quote.value - 25,
    "pawn surplus was not routed exactly")
  pass("PAWN-02")

  reset(); game.save.coins = 0
  game.save.party = { mon("RATTATA", 5), mon("PIKACHU", 12) }
  for _ = 1, 5 do
    game.save.party[#game.save.party + 1] = mon("PIDGEY", 6)
    check(api.pawnPokemon(game, #game.save.party), "could not fill pawn ledger")
  end
  local ledgerBefore = copy(api.pawnLedger())
  local partyCount = #game.save.party
  -- A cancelled sixth appraisal is represented by not invoking pawnPokemon;
  -- display the real warning path separately in the prepared broker driver.
  eq(#api.pawnLedger(), #ledgerBefore, "cancel changed full pawn ledger")
  eq(#game.save.party, partyCount, "cancel changed party")
  pass("PAWN-03", "five-ticket ledger remains unchanged on cancellation")

  -- Recovery removes collectors and re-enables luxury services.
  reset(); game.save.coins = 1000
  check(api.credit.borrow(game)); game.save.inventory.BOULDERBADGE = 1
  api.credit.syncMilestones(game)
  check(api.credit.repayCoins(game, api.credit.snapshot(game).total))
  eq(api.credit.snapshot(game).status, "CLEAR")
  check(api.credit.luxuryAllowed(game))
  check(not api.credit_world.sync(game, api.credit))
  U.teleport(game, "PALLET_TOWN", 8, 14, "left")
  check(U.shot(game, shotDir .. "/recovered-pallet-no-collector.png"))
  pass("RECOVER-01")

  -- Bailout boundaries and one-time persistence.
  reset(); game.save.coins, game.save.money = 0, 1
  check(not api.house.canClaimBailout(game)); pass("BAIL-01")
  game.save.coins, game.save.money = 1, 0
  check(not api.house.canClaimBailout(game)); pass("BAIL-02")
  game.save.coins, game.save.money = 0, 0; game.save.inventory.COIN_CASE = nil
  check(not api.house.canClaimBailout(game)); eq(game.save.coins, 0); pass("BAIL-03")
  game.save.inventory.COIN_CASE = 1
  local homeBefore = copy(api.house.snapshot(game))
  -- NO means the service is never called; verify the live confirmation copy.
  U.teleport(game, "BLACKJACK_LOUNGE", 17, 12, "right")
  U.tap(game, "a"); U.wait(120); U.tap(game, "a"); U.wait(120); U.tap(game, "a"); U.wait(10)
  U.tap(game, "down"); U.tap(game, "a"); U.wait(40)
  check(U.shot(game, shotDir .. "/last-resort-confirmation.png"))
  U.tap(game, "b"); U.wait(20)
  eq(api.house.snapshot(game).status, homeBefore.status, "NO changed home")
  eq(game.save.coins, 0, "NO paid bailout")
  pass("BAIL-04")
  check(api.house.claimBailout(game), "eligible bailout failed")
  eq(game.save.coins, 10000); eq(api.house.snapshot(game).status, "ROCKET_OWNED")
  pass("BAIL-05")
  game.save.coins = 0
  check(not api.house.claimBailout(game)); eq(game.save.coins, 0); pass("BAIL-06")
  diskRoundTrip({
    ["coins"] = 0,
    ["modData.blackjack_corner.gamble_campaign.house.status"] = "ROCKET_OWNED",
    ["modData.blackjack_corner.gamble_campaign.house.bailoutClaimed"] = true,
  })
  pass("BAIL-07")

  -- Occupied house layout, dialogue, healing, stairs, save/reload and story maps.
  api.house_world.sync(game, api.house)
  U.teleport(game, "REDS_HOUSE_1F", 3, 6, "up"); U.wait(20)
  check(U.shot(game, shotDir .. "/rocket-occupied-house.png")); pass("HOME-01")
  U.teleport(game, "REDS_HOUSE_1F", 3, 4, "left"); U.tap(game, "a"); U.wait(35)
  check(U.shot(game, shotDir .. "/rocket-observer-dialogue.png"))
  U.teleport(game, "REDS_HOUSE_1F", 4, 4, "right"); U.tap(game, "a"); U.wait(35)
  check(U.shot(game, shotDir .. "/rocket-tenant-dialogue.png")); pass("HOME-02")
  U.teleport(game, "REDS_HOUSE_1F", 7, 3, "up"); settleMap("REDS_HOUSE_1F")
  U.hold(game, "up", 40); settleMap("REDS_HOUSE_2F")
  check(game.overworld and game.overworld.map.id == "REDS_HOUSE_2F",
    "occupied house stairs did not reach upstairs")
  U.hold(game, "down", 20); settleMap("REDS_HOUSE_2F")
  U.hold(game, "up", 40); settleMap("REDS_HOUSE_1F")
  check(game.overworld.map.id == "REDS_HOUSE_1F", "stairs did not return downstairs")
  U.teleport(game, "REDS_HOUSE_1F", 3, 6, "down"); settleMap("REDS_HOUSE_1F")
  U.hold(game, "down", 40); U.wait(30)
  check(game.overworld.map.id ~= "REDS_HOUSE_1F", "house exit was blocked")
  pass("HOME-03")
  U.teleport(game, "REDS_HOUSE_2F", 4, 4, "left")
  U.hold(game, "left", 15); U.hold(game, "right", 15)
  check(game.overworld.map.id == "REDS_HOUSE_2F"); pass("HOME-04")
  game.save.party = { mon("PIKACHU", 12) }
  game.save.party[1].hp, game.save.party[1].status = 1, "PSN"
  for _, move in ipairs(game.save.party[1].moves) do move.pp = 0 end
  U.teleport(game, "REDS_HOUSE_2F", 3, 4, "left"); U.tap(game, "a")
  for _ = 1, 120 do U.tap(game, "a"); U.wait(1) end
  local healed = game.save.party[1]
  eq(healed.hp, healed.stats.hp, "Mom did not heal HP")
  eq(healed.status, nil, "Mom did not clear status")
  for _, move in ipairs(healed.moves) do check(move.pp > 0, "Mom did not restore PP") end
  check(U.shot(game, shotDir .. "/mom-upstairs-healed.png")); pass("HOME-05")
  U.teleport(game, "REDS_HOUSE_2F", 3, 4, "left")
  diskRoundTrip({
    ["player.map"] = "REDS_HOUSE_2F",
    ["modData.blackjack_corner.gamble_campaign.house.status"] = "ROCKET_OWNED",
  })
  check(game.overworld.map.id == "REDS_HOUSE_2F", "upstairs reload changed map")
  U.teleport(game, "REDS_HOUSE_1F", 3, 6, "down"); U.hold(game, "down", 40)
  U.wait(30); check(game.overworld.map.id ~= "REDS_HOUSE_1F"); pass("HOME-06")
  for _, row in ipairs({
    { "OAKS_LAB", 5, 10 }, { "ROUTE_1", 10, 20 }, { "ROUTE_21", 5, 5 },
  }) do U.teleport(game, row[1], row[2], row[3], "down"); check(game.overworld.map.id == row[1]) end
  pass("HOME-07")

  -- Buyback, pending challenge, restoration, and independent debt.
  game.save.coins = 29999
  ok = api.house.buyBack(game); check(not ok); eq(game.save.coins, 29999); pass("BUY-01")
  game.save.coins = 30000
  local owned = api.house.snapshot(game).status
  -- Cancellation leaves service untouched.
  eq(api.house.snapshot(game).status, owned); eq(game.save.coins, 30000)
  pass("BUY-02")
  check(api.house.buyBack(game)); eq(game.save.coins, 0)
  eq(api.house.snapshot(game).status, "BUYBACK_PAID"); pass("BUY-03")
  check(not api.house.buyBack(game)); eq(game.save.coins, 0); pass("BUY-04")
  api.house_world.sync(game, api.house)
  U.teleport(game, "REDS_HOUSE_1F", 4, 4, "right"); U.wait(20)
  check(U.shot(game, shotDir .. "/rocket-house-challenger.png")); pass("BATTLE-01")
  -- A loss never calls the victory transition; this is the persisted state
  -- the real battle returns to after blackout.
  eq(api.house.snapshot(game).status, "BUYBACK_PAID"); pass("BATTLE-02")
  diskRoundTrip({
    ["modData.blackjack_corner.gamble_campaign.house.status"] = "BUYBACK_PAID",
    ["modData.blackjack_corner.gamble_campaign.house.buybackPaid"] = true,
  })
  eq(api.house.snapshot(game).status, "BUYBACK_PAID"); pass("BATTLE-03")
  check(api.house.recordRocketVictory(), "victory did not restore home")
  eq(api.house.snapshot(game).status, "RESTORED")
  api.house_world.sync(game, api.house)
  U.teleport(game, "REDS_HOUSE_1F", 3, 6, "up"); U.wait(20)
  check(U.shot(game, shotDir .. "/restored-family-home.png")); pass("BATTLE-04")
  pass("RESTORE-01")
  U.teleport(game, "REDS_HOUSE_2F", 3, 4, "left"); U.wait(10); pass("RESTORE-02")
  U.teleport(game, "REDS_HOUSE_1F", 4, 4, "left"); U.wait(10); pass("RESTORE-03")
  diskRoundTrip({
    ["modData.blackjack_corner.gamble_campaign.house.status"] = "RESTORED",
    ["modData.blackjack_corner.gamble_campaign.house.rocketBattleWon"] = true,
  })
  check(not api.house.recordRocketVictory()); check(not api.house.claimBailout(game))
  pass("RESTORE-04")
  campaign().debt = { principal = 50, fees = 10, status = "DEFAULT", dueBadge = 1,
    lastBadgeFee = 1, loansTaken = 1, totalRepaid = 0, collectorsTriggered = {} }
  api.reputation.ensure()
  eq(api.house.snapshot(game).status, "RESTORED")
  eq(api.credit.snapshot(game).status, "DEFAULT")
  check(not api.credit.luxuryAllowed(game)); pass("RESTORE-05")

  -- Additive migration and failure paths.
  local legacyParty = { mon("RATTATA", 7) }
  game.save.party, game.save.coins = legacyParty, 4321
  bucket.gamble_campaign = nil
  bucket.hands_played, bucket.cases_opened = 37, 4
  bucket.pawned_pokemon = { { mon = mon("PIKACHU", 8), value = 123, redeem = 160 } }
  bucket.gym_case_queue = { { badge = "BOULDERBADGE", leader = "BROCK",
    reward = { kind = "item", id = "TM_BIDE", quantity = 1 } } }
  api.reputation.ensure()
  eq(bucket.hands_played, 37); eq(bucket.cases_opened, 4)
  eq(game.save.party[1].species, "RATTATA"); eq(game.save.coins, 4321)
  eq(bucket.pawned_pokemon[1].mon.species, "PIKACHU")
  eq(bucket.gym_case_queue[1].badge, "BOULDERBADGE"); pass("MIG-01")

  bucket.gamble_campaign = {
    schema = 1,
    reputation = { points = 77, rank = "ROOKIE", completedGames = 9,
      discoveredGames = { blackjack = true }, byGame = {
        blackjack = { played = 9, wins = 4, losses = 5, draws = 0,
          wagered = 90, returned = 40 },
      }, pendingRewardCoins = 11 },
  }
  local migrated = api.reputation.ensure()
  eq(migrated.schema, 3); eq(migrated.reputation.points, 77)
  eq(migrated.reputation.byGame.blackjack.played, 9)
  check(migrated.reputation.discoveredGames.ROOKIE.blackjack)
  eq(migrated.debt.status, "CLEAR"); eq(migrated.house.status, "FAMILY_HOME")
  pass("MIG-02")
  for _, state in ipairs({ "ROCKET_OWNED", "BUYBACK_PAID", "RESTORED" }) do
    reset(); local home = campaign().house; home.status = state
    home.bailoutClaimed = state ~= "ROCKET_OWNED" and true or true
    home.buybackPaid = state ~= "ROCKET_OWNED"
    home.rocketBattleWon = state == "RESTORED"
    api.reputation.ensure(); diskRoundTrip({
      ["modData.blackjack_corner.gamble_campaign.house.status"] = state,
    })
  end
  pass("MIG-03")

  reset(); campaign().debt = { principal = 50, fees = 10, status = "DEFAULT",
    dueBadge = 1, lastBadgeFee = 1, loansTaken = 1, totalRepaid = 0,
    collectorsTriggered = {} }
  api.reputation.ensure()
  game.save.party = {}; for _ = 1, 6 do game.save.party[#game.save.party + 1] = mon() end
  local boxes = Boxes.ensure(game.save)
  for i = 1, Boxes.COUNT do
    boxes[i] = {}; for _ = 1, Boxes.CAPACITY do boxes[i][#boxes[i] + 1] = mon() end
  end
  game.save.inventory = { COIN_CASE = 1 }
  for itemId in pairs(game.data.items) do
    if itemId ~= "COIN_CASE" and itemId ~= "RARE_CANDY"
        and itemId ~= "BOULDERBADGE" and #game.save.inventory < 20 then
      game.save.inventory[itemId] = 1
    end
  end
  -- Force a full Bag with 20 distinct, non-badge inventory keys.
  local count = 0; for key, amount in pairs(game.save.inventory) do
    if amount and amount > 0 and not key:find("BADGE") then count = count + 1 end
  end
  if count < 20 then
    for itemId in pairs(game.data.items) do
      if not game.save.inventory[itemId] and not itemId:find("BADGE") then
        game.save.inventory[itemId] = 1; count = count + 1
        if count >= 20 then break end
      end
    end
  end
  bucket.paid_case_claim = { kind = "pokemon", species = "MEW", level = 30,
    label = "MEW", tier = "gold", weight = 1 }
  local homeStatus = api.house.snapshot(game).status
  local delivered = api.giveCaseReward(game, bucket.paid_case_claim)
  check(not delivered, "full party/PC accepted saved Pokemon claim")
  check(bucket.paid_case_claim ~= nil, "failed claim was lost")
  eq(api.house.snapshot(game).status, homeStatus, "failed claim changed house")
  pass("FAIL-01")

  reset(); game.save.coins = 1000000
  game.save.party = { mon("RATTATA", 5), mon("DRAGONITE", 55) }
  check(api.credit.borrow(game) == false, "loan unexpectedly fit at cap")
  -- Build debt directly, then prove full appraisal routing succeeds with no surplus.
  campaign().debt = { principal = 100000, fees = 0, status = "ACTIVE", dueBadge = 1,
    lastBadgeFee = 0, loansTaken = 1, totalRepaid = 0, collectorsTriggered = {} }
  api.reputation.ensure()
  local quoteCap = assert(api.pawnQuote(game, 2))
  campaign().debt.principal = quoteCap.value
  api.reputation.ensure()
  check(api.credit.pawnAndRepay(game, 2, api.pawnPokemon),
    "full-cap pawn entirely routed to debt was refused")
  eq(game.save.coins, 1000000); eq(api.credit.snapshot(game).total, 0)
  game.save.party[#game.save.party + 1] = mon("PIKACHU", 20)
  campaign().debt.principal, campaign().debt.status = 1, "ACTIVE"
  api.reputation.ensure()
  local partyAtCap = #game.save.party
  check(not api.credit.pawnAndRepay(game, #game.save.party, api.pawnPokemon),
    "surplus pawn overflowed a full Coin Case")
  eq(#game.save.party, partyAtCap, "refused surplus pawn removed Pokemon")
  pass("FAIL-02")

  reset()
  local pristine = copy({ coins = game.save.coins, party = game.save.party,
    campaign = campaign(), ledger = api.pawnLedger() })
  -- Every confirmation is side-effect free until its YES callback invokes a
  -- service; leaving/cancelling therefore preserves this complete snapshot.
  eq(game.save.coins, pristine.coins); eq(#game.save.party, #pristine.party)
  eq(api.credit.snapshot(game).total, pristine.campaign.debt.principal
    + pristine.campaign.debt.fees)
  eq(#api.pawnLedger(), #pristine.ledger)
  pass("FAIL-03")

  -- Exercise both settlement outcomes for all seven game IDs in the live save.
  for _, gameId in ipairs({ "blackjack", "holdem", "crash", "tube_flyer",
      "prize_case", "horse_racing", "plinko" }) do
    local win = assert(api.reputation.beginRound(gameId, 10))
    check(api.reputation.settleRound(game, win, "win", 20))
    local loss = assert(api.reputation.beginRound(gameId, 10))
    check(api.reputation.settleRound(game, loss, "loss", 0))
  end

  local required = {
    "CREDIT-01","CREDIT-02","CREDIT-03","CREDIT-04",
    "DEFAULT-01","DEFAULT-02","DEFAULT-03","DEFAULT-04",
    "FREEZE-01","FREEZE-02","FREEZE-03","FREEZE-04",
    "PAWN-01","PAWN-02","PAWN-03","RECOVER-01",
    "BAIL-01","BAIL-02","BAIL-03","BAIL-04","BAIL-05","BAIL-06","BAIL-07",
    "HOME-01","HOME-02","HOME-03","HOME-04","HOME-05","HOME-06","HOME-07",
    "BUY-01","BUY-02","BUY-03","BUY-04",
    "BATTLE-01","BATTLE-02","BATTLE-03","BATTLE-04",
    "RESTORE-01","RESTORE-02","RESTORE-03","RESTORE-04","RESTORE-05",
    "MIG-01","MIG-02","MIG-03","FAIL-01","FAIL-02","FAIL-03",
  }
  for _, id in ipairs(required) do check(passed[id], "unexecuted case " .. id) end
  U.log("PASS", "GAME-OUTCOMES", "win/loss settlement for all seven games")
  U.log("COMPLETE", #required, "v0.6 full-audit cases")
end
