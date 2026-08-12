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
  pass(expectedYes and "INTRO-03" or "INTRO-02",
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
  end

  -- A global preference must never mutate this campaign's saved answer.
  manager = ManagerState.new(game)
  manager:setOption("blackjack_corner", "gamble_default",
    expectedYes and "off" or "on")
  assert(bucket.gamble_mode == expectedYes,
    "changing Gamble Default rewrote the live campaign")
  pass("INTRO-05", "global default leaves the existing campaign untouched")

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
  if expectedYes then
    local campaign = api.campaign_state.defaults()
    campaign.reputation.points = 4000
    bucket.gamble_campaign = campaign
    for _, badge in ipairs(api.reputation_rules.BADGES) do
      game.save.inventory[badge] = 1
    end
    local bookie = assert(MapScripts.talkScript(
      "ROCKET_BATTLE_ARENA", "TEXT_ARENA_BOOKIE"))
    bookie(game, game.overworld, nil)
    assert(game.stack:top().pages and not game.stack:top().screenId,
      "Table Intros OFF skipped the Arena's forced story copy")
    popToWorld()
    pass("PLAY-02", "Arena narrative remains forced at KINGPIN access")
  end

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
  pass("PRIZE-01", "shiny purchase choice updates live without blocking normal prizes")

  local settings = assert(api.settings, "settings export is unavailable")
  manager:setOption("blackjack_corner", "reveal_speed", "relaxed")
  local relaxed = settings.revealStep(0.02)
  manager:setOption("blackjack_corner", "reveal_speed", "normal")
  local normal = settings.revealStep(0.02)
  manager:setOption("blackjack_corner", "reveal_speed", "fast")
  local fast = settings.revealStep(0.02)
  assert(relaxed < normal and normal < fast,
    "native settings did not produce ordered reveal clocks")
  pass("PLAY-03", "Relaxed, Normal, and Fast expose ordered shared reveal clocks")
  pass("PLAY-04", "Crash and Tube Flyer remain outside the shared reveal clock")

  U.log("SETTINGS AUDIT COMPLETE")
  love.event.quit(0)
end
