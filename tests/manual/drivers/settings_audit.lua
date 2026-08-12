-- Native Red/Blue release audit for Blackjack Corner's global settings and
-- pre-Oak Gamble Mode prompt. Run SETTINGS_PHASE=seed once, then rerun the
-- same identity with SETTINGS_PHASE=verify so options.lua crosses a real
-- process boundary. SETTINGS_PROVIDER=external performs the compact schema
-- check with a supported shiny renderer installed.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local ManagerState = require("src.mods.ManagerState")
  local MapScripts = require("src.script.MapScripts")
  local ChoiceBox = require("src.ui.ChoiceBox")
  local OakSpeech = require("src.ui.OakSpeech")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local phase = (os.getenv("SETTINGS_PHASE") or "verify"):lower()
  local provider = (os.getenv("SETTINGS_PROVIDER") or "fallback"):lower()
  local defaultAnswer = (os.getenv("GAMBLE_DEFAULT") or "yes"):lower()
  local loader = assert(game.mods, "mod loader is unavailable")
  local api = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")

  local passed = {}
  local function pass(id, note)
    assert(not passed[id], "duplicate case " .. id)
    passed[id] = true
    U.log("PASS", id, note or "")
  end
  local function findMod()
    for _, row in ipairs(loader:status().available or {}) do
      if row.id == "blackjack_corner" then return row end
    end
    error("blackjack_corner is absent from ManagerState")
  end
  local function openOptions()
    local manager = ManagerState.new(game)
    game.stack:push(manager)
    manager.currentMod = findMod()
    manager:openOptions(manager.currentMod)
    U.wait(4)
    return manager
  end
  local function closeToPrior(prior)
    while game.stack:top() and game.stack:top() ~= prior do game.stack:pop() end
  end
  local function values()
    loader.modOptions.blackjack_corner =
      loader.modOptions.blackjack_corner or {}
    return loader.modOptions.blackjack_corner
  end
  local function textOf(box)
    local lines = {}
    for _, page in ipairs(box and box.pages or {}) do
      for _, line in ipairs(page) do lines[#lines + 1] = line end
    end
    return (table.concat(lines, " "):gsub("%s+", " "))
  end
  local function pokemonCount()
    local count = #(game.save.party or {})
    for _, box in ipairs(game.save.boxes or {}) do count = count + #box end
    return count
  end
  local function assertFallbackRows(manager)
    local expected = {
      "gamble_default", "table_intros", "reveal_speed", "shiny_upgrades",
      "shiny_sparkles", "shiny_chime", "shiny_markers", "shiny_colors",
      "__reset",
    }
    assert(#manager.optionRows == #expected,
      "fallback settings page does not contain eight rows plus RESET")
    for index, id in ipairs(expected) do
      assert(manager.optionRows[index].id == id,
        ("settings row %d is %s, expected %s"):format(
          index, tostring(manager.optionRows[index].id), id))
    end
  end

  U.wait(10)
  local prior = game.stack:top()
  local manager = openOptions()
  if provider == "external" then
    local expected = {
      "gamble_default", "table_intros", "reveal_speed", "shiny_upgrades",
      "__reset",
    }
    assert(#manager.optionRows == #expected,
      "external shiny provider did not leave four core rows plus RESET")
    for index, id in ipairs(expected) do
      assert(manager.optionRows[index].id == id,
        "external-provider settings row mismatch at " .. index)
    end
    assert(api.shiny_fallback == false,
      "bundled shiny renderer remained active beside an external provider")
    assert(U.shot(game, shotDir .. "/settings-external-provider.png"))
    pass("SET-03", "external provider keeps one compact core settings page")
    love.event.quit(0)
    return
  end

  assertFallbackRows(manager)
  assert(U.shot(game, shotDir .. "/settings-core-top.png"))
  pass("SET-01", "native MODS options page exposes every core setting")

  if phase == "seed" then
    -- Exercise the real ManagerState inputs, including scrolling beyond its
    -- four-row viewport, then exit so options.lua is read by a new process.
    manager.optionRows[#manager.optionRows].activate()
    U.tap(game, "right") -- Gamble Default: NO -> YES
    for _ = 1, 7 do
      U.tap(game, "down")
      U.tap(game, "right")
    end
    U.wait(20)
    assert(U.shot(game, shotDir .. "/settings-fallback-bottom.png"))
    local stored = values()
    assert(stored.gamble_default == "on" and stored.table_intros == false
      and stored.reveal_speed == "fast" and stored.shiny_upgrades == false,
      "core settings were not changed through ManagerState")
    assert(stored.shiny_sparkles == false and stored.shiny_chime == false
      and stored.shiny_markers == false and stored.shiny_colors == false,
      "fallback settings were not changed through the scrolled viewport")
    pass("SET-02", "all fallback rows scroll and accept native input")
    pass("SET-04-SEED", "custom settings were written for restart verification")
    love.event.quit(0)
    return
  end

  local stored = values()
  assert(stored.gamble_default == "on" and stored.table_intros == false
    and stored.reveal_speed == "fast" and stored.shiny_upgrades == false,
    "core settings did not survive the process restart")
  assert(stored.shiny_sparkles == false and stored.shiny_chime == false
    and stored.shiny_markers == false and stored.shiny_colors == false,
    "fallback settings did not survive the process restart")
  pass("SET-04-PERSIST", "all settings survived a real process restart")

  for _ = 1, #manager.optionRows - 1 do U.tap(game, "down") end
  U.tap(game, "a")
  U.wait(3)
  assert(stored.gamble_default == "off" and stored.table_intros == true
    and stored.reveal_speed == "normal" and stored.shiny_upgrades == true,
    "RESET DEFAULTS did not restore the core defaults")
  assert(stored.shiny_sparkles == true and stored.shiny_chime == true
    and stored.shiny_markers == true and stored.shiny_colors == true,
    "RESET DEFAULTS did not restore the fallback defaults")
  pass("SET-04-RESET", "RESET DEFAULTS restores all eight settings")

  -- Prepare the requested intro answer plus live runtime toggles after proving
  -- Reset Defaults. Direct row stepping is still the production ManagerState
  -- writer and emits/persists the same mod.options_changed event.
  if defaultAnswer == "yes" then manager.optionRows[1].step(game, 1) end
  manager.optionRows[2].step(game, 1) -- table intros OFF
  manager.optionRows[3].step(game, 1) -- reveal speed FAST
  manager.optionRows[4].step(game, 1) -- shiny upgrades OFF
  closeToPrior(prior)

  U.tap(game, "start")
  U.wait(10)
  U.tap(game, "a")
  U.wait(5)
  U.tap(game, "a")

  local prompt, speech
  for _ = 1, 600 do
    local top = game.stack:top()
    if getmetatable(top) == ChoiceBox then
      prompt = top
      for index = #game.stack.states, 1, -1 do
        local candidate = game.stack.states[index]
        if getmetatable(candidate) == OakSpeech then speech = candidate break end
      end
      break
    end
    -- Finish the question's typewriter/text confirmation; ChoiceBox is
    -- created only after that acknowledgement, not when the text ends.
    U.tap(game, "a")
    U.wait(2)
  end
  assert(prompt and speech, "pre-Oak Gamble Mode prompt did not appear")
  assert(speech.pic == nil and speech.steps[1].id == "blackjack_corner_gamble_mode"
    and speech.steps[2].id == "oak_welcome",
    "Oak appeared before the Gamble Mode decision")
  local expectedYes = defaultAnswer == "yes"
  assert(prompt.index == (expectedYes and 1 or 2),
    "Gamble Default did not preselect the requested answer")
  assert(U.shot(game, shotDir .. "/gamble-prompt-before-oak.png"))
  pass("INTRO-01", "Gamble Mode appears on a clean screen before Oak")
  pass(expectedYes and "INTRO-03-CURSOR" or "INTRO-02-CURSOR",
    "global default preselects but does not skip the explicit answer")
  U.tap(game, "a")

  for _ = 1, 900 do
    if game.overworld and game.stack:top() == game.overworld then break end
    U.tap(game, "a")
    U.wait(2)
  end
  assert(game.overworld and game.stack:top() == game.overworld,
    "new game did not reach the overworld")
  local bucket = assert(loader.modSave.blackjack_corner,
    "Blackjack Corner save namespace missing")
  assert(bucket.gamble_mode == expectedYes,
    "the explicit Gamble Mode answer was not saved")
  if expectedYes then
    assert(game.save.inventory and game.save.inventory.COIN_CASE
      and game.save.coins == 100,
      "accepted Gamble Mode did not grant its Coin Case and 100 coins")
    local roulettePieces = 0
    for _, object in ipairs(game.data.maps.OAKS_LAB.objects or {}) do
      if object.text == "TEXT_BLACKJACK_CORNER_STARTER_ROULETTE" then
        roulettePieces = roulettePieces + 1
      end
    end
    assert(roulettePieces > 0,
      "accepted Gamble Mode did not claim Oak's roulette objects")
    pass("INTRO-03",
      "YES grants the Coin Case, 100 coins, and Oak's private roulette")
  else
    for _, object in ipairs(game.data.maps.OAKS_LAB.objects or {}) do
      assert(object.text ~= "TEXT_BLACKJACK_CORNER_STARTER_ROULETTE",
        "declined Gamble Mode left a Lab object bound to the roulette")
    end

    -- Run the real Gym-victory hook in ordinary mode. It must preserve the
    -- native TM path and must not queue a Gamble Mode case.
    local flagsBefore, inventoryBefore = game.save.flags, game.save.inventory
    game.save.flags, game.save.inventory = {}, { COIN_CASE = 1 }
    local nativeRewardCalls = 0
    local Overworld = require("src.world.OverworldController")
    Overworld.checkVictoryRewards({ runVictoryHook = function()
      nativeRewardCalls = nativeRewardCalls + 1
    end, game = game }, "OPP_MISTY", 1)
    assert(nativeRewardCalls == 1 and game.save.inventory.CASCADEBADGE == 1
      and game.save.inventory.TM_BUBBLEBEAM == 1,
      "declined Gamble Mode did not preserve the native Gym reward path")
    assert(not bucket.gym_case_queue or #bucket.gym_case_queue == 0,
      "declined Gamble Mode queued a Gym case")
    game.save.flags, game.save.inventory = flagsBefore, inventoryBefore
    pass("INTRO-02",
      "NO preserves Oak's ordinary starter handler and native Gym rewards")
  end

  -- A global preference must never mutate this campaign's saved answer.
  manager = ManagerState.new(game)
  manager:setOption("blackjack_corner", "gamble_default",
    expectedYes and "off" or "on")
  assert(bucket.gamble_mode == expectedYes,
    "changing Gamble Default rewrote the live campaign")
  pass("INTRO-05", "global default leaves the existing campaign untouched")

  -- The rest of the driver validates live Gamble Mode-only screens. The
  -- save-scoped default invariant above is already proven, so enable it
  -- deliberately on the NO-default ROM rather than skipping half the gate.
  bucket.gamble_mode = true

  local function popToWorld()
    while game.stack:top() and game.stack:top() ~= game.overworld do
      game.stack:pop()
    end
  end
  game.save.inventory = game.save.inventory or {}
  game.save.inventory.COIN_CASE = 1
  game.save.coins = math.max(10000, tonumber(game.save.coins) or 0)
  local tableTalk = assert(MapScripts.talkScript(
    "BLACKJACK_LOUNGE", "TEXT_BLACKJACK_TABLE"))
  manager:setOption("blackjack_corner", "table_intros", false)
  tableTalk(game, game.overworld, nil)
  assert(game.stack:top().screenId == "BlackjackCornerTable",
    "Table Intros OFF did not open Blackjack directly")
  popToWorld()
  manager:setOption("blackjack_corner", "table_intros", true)
  tableTalk(game, game.overworld, nil)
  assert(game.stack:top().pages and not game.stack:top().screenId,
    "Table Intros ON did not preserve the rules card")
  assert(U.shot(game, shotDir .. "/table-intro-on.png"))
  popToWorld()
  manager:setOption("blackjack_corner", "table_intros", false)
  game.save.inventory.COIN_CASE = nil
  tableTalk(game, game.overworld, nil)
  assert(game.stack:top().pages and not game.stack:top().screenId,
    "direct launch bypassed the missing Coin Case denial")
  popToWorld()
  game.save.inventory.COIN_CASE = 1
  pass("PLAY-01", "table intros toggle live while Coin Case guards remain")

  -- Story-critical Arena copy is forced even while ordinary introductions
  -- are disabled. Seed the public rank requirements, then call the real
  -- bookie handler instead of pushing the screen directly.
  local campaign = api.campaign_state.defaults()
  campaign.reputation.points = 4000
  campaign.arena.unlocked = true
  bucket.gamble_campaign = campaign
  for _, badge in ipairs(api.reputation_rules.BADGES) do
    game.save.inventory[badge] = 1
  end
  local bookie = assert(MapScripts.talkScript(
    "ROCKET_BATTLE_ARENA", "TEXT_ARENA_BOOKIE"))
  local storyChecks = {
    { stage = api.arena_story.STAGES.INVITATION, marker = "SERIES 3 IS READY" },
    { stage = api.arena_story.STAGES.EXPOSED, ending = "EXPOSE",
      marker = "burned the ledger" },
    { stage = api.arena_story.STAGES.CHAMPION, ending = "CHAMPION",
      marker = "Welcome, CHAMPION" },
  }
  for _, check in ipairs(storyChecks) do
    campaign = api.campaign_state.defaults()
    campaign.reputation.points, campaign.arena.unlocked = 4000, true
    campaign.story.stage = check.stage
    if check.ending then
      campaign.story.ending.choice = check.ending
      campaign.story.ending.rewardClaimed = true
    end
    bucket.gamble_campaign = campaign
    bookie(game, game.overworld, nil)
    local copy = textOf(game.stack:top())
    assert(copy:find(check.marker, 1, true),
      "Table Intros OFF skipped Arena copy for " .. check.stage
        .. ": " .. copy)
    popToWorld()
  end
  pass("PLAY-02",
    "Arena invitation and both ending-reactive intros remain forced")

  manager:setOption("blackjack_corner", "shiny_upgrades", false)
  local prizes = game.data.screens.BlackjackCornerPokemonPrizes.new(game, {})
  prizes.onChoose(prizes.items[1])
  assert(#game.stack:top().items == 2,
    "Shiny Upgrades OFF did not leave NORMAL and CANCEL")
  game.stack:pop()
  manager:setOption("blackjack_corner", "shiny_upgrades", true)
  prizes = game.data.screens.BlackjackCornerPokemonPrizes.new(game, {})
  prizes.onChoose(prizes.items[1])
  assert(#game.stack:top().items == 3,
    "Shiny Upgrades ON did not restore NORMAL, SHINY, and CANCEL")
  game.stack:pop()
  manager:setOption("blackjack_corner", "shiny_upgrades", false)
  prizes = game.data.screens.BlackjackCornerPokemonPrizes.new(game, {})
  local beforeCoins, beforePokemon = game.save.coins, pokemonCount()
  prizes.onChoose(prizes.items[1])
  local normalMenu = game.stack:top()
  local normalCost = prizes.items[1].value.cost
  normalMenu.items[1].onSelect()
  assert(game.save.coins == beforeCoins - normalCost,
    "ordinary Pokemon prize did not debit its listed price")
  assert(pokemonCount() == beforePokemon + 1,
    "ordinary Pokemon prize was not delivered to party or PC")
  popToWorld()
  pass("PRIZE-01",
    "shiny choice updates live and ordinary purchase delivery succeeds")

  local speeds = { "relaxed", "normal", "fast" }
  local function drive(screen, finished, maximum)
    local frames = 0
    while not finished(screen) and frames < maximum do
      screen:update(1 / 60)
      frames = frames + 1
    end
    assert(finished(screen), "screen animation did not finish within its frame budget")
    return frames
  end
  local function ordered(label, runs)
    assert(runs.relaxed.frames > runs.normal.frames
      and runs.normal.frames > runs.fast.frames,
      label .. " reveal frames were not RELAXED > NORMAL > FAST")
    assert(runs.relaxed.result == runs.normal.result
      and runs.normal.result == runs.fast.result,
      label .. " result changed with reveal speed")
    assert(runs.relaxed.payout == runs.normal.payout
      and runs.normal.payout == runs.fast.payout,
      label .. " payout changed with reveal speed")
  end
  local function baseCampaign()
    local value = api.campaign_state.defaults()
    value.reputation.points = 4000
    value.arena.unlocked = true
    for _, rank in ipairs(api.reputation_rules.RANKS) do
      value.reputation.rankRewardsClaimed[rank.id] = true
    end
    return value
  end

  local rouletteRuns = {}
  for _, speed in ipairs(speeds) do
    manager:setOption("blackjack_corner", "reveal_speed", speed)
    love.math.setRandomSeed(20260812)
    local screen = game.data.screens.BlackjackCornerStarterRoulette.new(game, {})
    screen:start()
    local frames = drive(screen, function(value) return value.phase == "offer" end, 1000)
    rouletteRuns[speed] = {
      frames = frames,
      result = screen.playerStarter .. ":" .. screen.rivalStarter,
      payout = 0,
    }
  end
  ordered("Starter Roulette", rouletteRuns)

  local caseRuns = {}
  for _, speed in ipairs(speeds) do
    manager:setOption("blackjack_corner", "reveal_speed", speed)
    love.math.setRandomSeed(20260812)
    bucket.gamble_campaign = baseCampaign()
    bucket.paid_case_claim = nil
    game.save.coins = 100000
    local screen = game.data.screens.BlackjackCornerPrizeCase.new(game, {})
    screen:open()
    local frames = drive(screen, function(value) return value.phase == "result" end, 1200)
    assert(not screen.claimSaved, "Prize Case test reward could not be delivered")
    caseRuns[speed] = {
      frames = frames,
      result = tostring(screen.winner.kind) .. ":"
        .. tostring(screen.winner.id or screen.winner.species),
      payout = 0,
    }
  end
  ordered("Prize Case", caseRuns)

  local horseRuns = {}
  for _, speed in ipairs(speeds) do
    manager:setOption("blackjack_corner", "reveal_speed", speed)
    love.math.setRandomSeed(20260812)
    bucket.gamble_campaign = baseCampaign()
    game.save.coins = 100000
    local screen = game.data.screens.BlackjackCornerHorseRacing.new(game, {})
    screen:start()
    local frames = drive(screen, function(value) return value.phase == "result" end, 1500)
    horseRuns[speed] = {
      frames = frames, result = screen.race.winner, payout = screen.payout,
    }
  end
  ordered("Horse Racing", horseRuns)

  local plinkoRuns = {}
  for _, speed in ipairs(speeds) do
    manager:setOption("blackjack_corner", "reveal_speed", speed)
    love.math.setRandomSeed(20260812)
    bucket.gamble_campaign = baseCampaign()
    game.save.coins = 100000
    local screen = game.data.screens.BlackjackCornerPlinko.new(game, {})
    screen:dropBall()
    local frames = drive(screen, function(value) return value.phase == "result" end, 1000)
    plinkoRuns[speed] = {
      frames = frames, result = screen.drop.slot, payout = screen.payout,
    }
  end
  ordered("Plinko", plinkoRuns)

  local arenaRuns = {}
  for _, speed in ipairs(speeds) do
    manager:setOption("blackjack_corner", "reveal_speed", speed)
    love.math.setRandomSeed(20260812)
    bucket.gamble_campaign = baseCampaign()
    game.save.coins = 100000
    local screen = game.data.screens.BlackjackCornerBattleArena.new(game, {})
    assert(screen.phase == "bet", "Arena test did not begin on the wager screen")
    screen:startBattle()
    local frames = drive(screen, function(value) return value.phase == "result" end, 5000)
    arenaRuns[speed] = {
      frames = frames,
      result = screen.pending.match.fighters[1].species .. ":"
        .. screen.pending.match.fighters[2].species .. ":"
        .. screen.pending.match.winner,
      payout = screen.pending.payout,
    }
  end
  ordered("Battle Arena", arenaRuns)
  pass("PLAY-03",
    "all five production screens change pace without changing results or payouts")

  local crashRuns, tubeRuns = {}, {}
  for _, speed in ipairs(speeds) do
    manager:setOption("blackjack_corner", "reveal_speed", speed)
    love.math.setRandomSeed(20260812)
    bucket.gamble_campaign = baseCampaign()
    game.save.coins = 100000
    local crash = game.data.screens.BlackjackCornerCrash.new(game, {})
    crash:launch()
    crash.crashPoint = 999
    crash:update(0.05)
    crashRuns[speed] = { elapsed = crash.elapsed, multiplier = crash.multiplier }
    crash:cashOut()

    love.math.setRandomSeed(20260812)
    bucket.gamble_campaign = baseCampaign()
    game.save.coins = 100000
    local tube = game.data.screens.BlackjackCornerTubeFlyer.new(game, {})
    tube:start()
    tube:update(0.02)
    tubeRuns[speed] = {
      y = tube.run.y, velocity = tube.run.velocity, x = tube.run.tubes[1].x,
    }
    tube:finish()
  end
  for _, speed in ipairs({ "normal", "fast" }) do
    assert(crashRuns[speed].elapsed == crashRuns.relaxed.elapsed
      and crashRuns[speed].multiplier == crashRuns.relaxed.multiplier,
      "Reveal Speed changed Crash growth")
    assert(tubeRuns[speed].y == tubeRuns.relaxed.y
      and tubeRuns[speed].velocity == tubeRuns.relaxed.velocity
      and tubeRuns[speed].x == tubeRuns.relaxed.x,
      "Reveal Speed changed Tube Flyer physics")
  end
  pass("PLAY-04", "Crash growth and Tube Flyer physics ignore Reveal Speed")

  -- Leave the persisted global options at their exact seed values. This makes
  -- a second verify pass on the same identity a valid repeatability check.
  manager:setOption("blackjack_corner", "gamble_default", "on")
  manager:setOption("blackjack_corner", "table_intros", false)
  manager:setOption("blackjack_corner", "reveal_speed", "fast")
  manager:setOption("blackjack_corner", "shiny_upgrades", false)
  manager:setOption("blackjack_corner", "shiny_sparkles", false)
  manager:setOption("blackjack_corner", "shiny_chime", false)
  manager:setOption("blackjack_corner", "shiny_markers", false)
  manager:setOption("blackjack_corner", "shiny_colors", false)

  U.log("SETTINGS AUDIT COMPLETE")
  love.event.quit(0)
end
