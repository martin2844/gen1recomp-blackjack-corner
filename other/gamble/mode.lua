local Gamble = {}

local BALL_TEXTS = {
  "TEXT_OAKSLAB_CHARMANDER_POKE_BALL",
  "TEXT_OAKSLAB_SQUIRTLE_POKE_BALL",
  "TEXT_OAKSLAB_BULBASAUR_POKE_BALL",
  "TEXT_OAKSLAB_EEVEE_POKE_BALL",
}

local BALL_NAMES = {
  "OAKSLAB_CHARMANDER_POKE_BALL", "OAKSLAB_SQUIRTLE_POKE_BALL",
  "OAKSLAB_BULBASAUR_POKE_BALL", "OAKSLAB_EEVEE_POKE_BALL",
}

local ROULETTE_TEXT = "TEXT_BLACKJACK_CORNER_STARTER_ROULETTE"

local OAK_GAMBLE_TEXTS = {
  _OaksLabRivalFedUpWithWaitingText =
    "{RIVAL}: Gramps!\nCan we gamble\nalready?",
  _OaksLabOakChooseMonText =
    "OAK: Choosing is\nsafe.\fSafe is terribly\ndull!\fSpin the roulette,\n{PLAYER}!\fGamble for your\nfirst POKéMON!",
  _OaksLabRivalWhatAboutMeText =
    "{RIVAL}: Hey!\nI want a spin too!",
  _OaksLabOakBePatientText =
    "OAK: That's the\nspirit, {RIVAL}!\fNever let {PLAYER}\nhoard the action.\fYou gamble next!",
}

local function copyParty(party)
  local out = {}
  for index, slot in ipairs(party or {}) do
    local clone = {}
    for key, value in pairs(slot) do clone[key] = value end
    out[index] = clone
  end
  return out
end

function Gamble.install(mod, opts)
  local Rules, Service, screenId = opts.rules, opts.service, opts.screenId
  local MapScripts = require("src.script.MapScripts")
  local Commands = require("src.script.Commands")

  local function active() return mod.save:get("gamble_mode", false) == true end

  local function applyLabSprites(game)
    local lab = game and game.data and game.data.maps and game.data.maps.OAKS_LAB
    local pieces = { "SPRITE_STARTER_ROULETTE_01", "SPRITE_STARTER_ROULETTE_02",
      "SPRITE_STARTER_ROULETTE_03" }
    local matches = {}
    for _, object in ipairs(lab and lab.objects or {}) do
      local isGift = object._blackjackCornerOriginalSprite ~= nil
      for index, name in ipairs(BALL_NAMES) do
        if object.name == name or object.text == BALL_TEXTS[index] then
          isGift = true
          break
        end
      end
      -- Starter overhauls may replace the object identity as well as its text
      -- binding. On the stock Red/Blue Lab, only gift stands occupy this part
      -- of row 3, so native geometry is the final first-pass compatibility seam.
      if not isGift then
        local x, y = tonumber(object.x), tonumber(object.y)
        if y == 3 and x and x >= 6 and x <= 8 and not object.trainerClass then
          isGift = true
        end
      end
      if isGift then matches[#matches + 1] = object end
    end
    table.sort(matches, function(left, right)
      local lx, rx = tonumber(left.x) or 0, tonumber(right.x) or 0
      if lx ~= rx then return lx < rx end
      return (tonumber(left.index) or 0) < (tonumber(right.index) or 0)
    end)
    local function apply(object, sprite)
      -- Keep the physical object but move its A-press onto a private text
      -- binding. The full Randomizer owns the vanilla ball handlers at a
      -- higher map-script priority; rebinding lets its starters work when
      -- Gamble Mode is off without letting them replace the roulette.
      if not tostring(object.sprite or ""):find("SPRITE_STARTER_ROULETTE_", 1, true) then
        object._blackjackCornerOriginalSprite = object.sprite
      end
      if object.text ~= ROULETTE_TEXT then
        object._blackjackCornerOriginalText = object.text or false
      end
      object.sprite = sprite
      object.text = ROULETTE_TEXT
    end
    if #matches == 1 then
      -- Yellow has one gift ball, so use the center cabinet piece.
      apply(matches[1], pieces[2])
    else
      for index, object in ipairs(matches) do
        apply(object, pieces[math.min(index, #pieces)])
      end
    end
  end

  local function restoreLabSprites(game)
    local lab = game and game.data and game.data.maps and game.data.maps.OAKS_LAB
    for _, object in ipairs(lab and lab.objects or {}) do
      if object._blackjackCornerOriginalSprite then
        object.sprite = object._blackjackCornerOriginalSprite
      end
      if object._blackjackCornerOriginalText ~= nil then
        if object._blackjackCornerOriginalText == false then
          object.text = nil
        else
          object.text = object._blackjackCornerOriginalText
        end
      end
    end
  end

  local function applyOakDialogue(game)
    local data = game and game.data
    local text = data and data.text
    if not text then return end
    data._blackjackCornerOriginalOakTexts =
      data._blackjackCornerOriginalOakTexts or {}
    local originals = data._blackjackCornerOriginalOakTexts
    for key, value in pairs(OAK_GAMBLE_TEXTS) do
      if originals[key] == nil then originals[key] = text[key] or false end
      text[key] = value
    end
  end

  local function restoreOakDialogue(game)
    local data = game and game.data
    local text, originals = data and data.text,
      data and data._blackjackCornerOriginalOakTexts
    if not text or not originals then return end
    for key in pairs(OAK_GAMBLE_TEXTS) do
      if originals[key] == false then
        text[key] = nil
      else
        text[key] = originals[key]
      end
    end
  end

  mod.hooks:wrap("intro.oak_speech.build", function(next, steps, speech)
    steps = next(steps, speech)
    mod.ui.insertStepBefore(steps, "oak_welcome", {
      id = "blackjack_corner_gamble_mode", kind = "yesno",
      saveKey = "gamble_mode",
      defaultNo = not (opts.defaultGamble and opts.defaultGamble()),
      text = "BLACKJACK CORNER\fEnable GAMBLE MODE?\fRandom starter.\nGyms give cases.",
    })
    return steps
  end)

  mod.events:on("intro.oak_speech.answered", function(ev)
    if ev.saveKey ~= "gamble_mode" then return end
    mod.save:set("gamble_mode", ev.value == true)
    if ev.value == true and ev.speech and ev.speech.game then
      local save = ev.speech.game.save
      save.inventory = save.inventory or {}
      save.inventory.COIN_CASE = math.max(1, save.inventory.COIN_CASE or 0)
      save.coins = math.max(100, tonumber(save.coins) or 0)
      applyLabSprites(ev.speech.game)
      applyOakDialogue(ev.speech.game)
    elseif ev.speech and ev.speech.game then
      restoreLabSprites(ev.speech.game)
      restoreOakDialogue(ev.speech.game)
    end
  end)

  -- Nuzlocke 2's World Building listener opens an Oak flavor TextBox from
  -- intro.oak_speech.finished. The engine emits that event before OakSpeech
  -- removes itself; Oak would therefore pop the new box instead and remain as
  -- an exhausted opaque white screen. Temporarily lift post-intro overlays
  -- above Oak, then restore them from Oak's completion callback.
  mod.events:on("intro.oak_speech.finished", function(ev)
    local speech = ev and ev.speech
    local game = speech and speech.game
    local loader = game and game.mods
    local nuzlocke = loader and loader.mods and loader.mods.nuzlocke
    local stack = game and game.stack
    local states = stack and stack.states
    if not (nuzlocke and nuzlocke.enabled ~= false and not nuzlocke.failed
        and type(states) == "table" and not speech._blackjackCornerIntroDeferred) then
      return
    end

    local speechIndex
    for index = #states, 1, -1 do
      if states[index] == speech then speechIndex = index break end
    end
    if not speechIndex or speechIndex == #states then return end

    local deferred = {}
    for index = #states, speechIndex + 1, -1 do
      table.insert(deferred, 1, table.remove(states, index))
    end
    if #deferred == 0 then return end

    speech._blackjackCornerIntroDeferred = true
    local originalOnDone = speech.onDone
    speech.onDone = function(...)
      if originalOnDone then originalOnDone(...) end
      for _, state in ipairs(deferred) do states[#states + 1] = state end
    end
  end, -10000)

  local function runBase(textId, game, ow, npc, done)
    local script = MapScripts.baseTalk("OAKS_LAB", textId)
    if type(script) == "function" then return script(game, ow, npc, done) end
    if type(script) == "table" then
      ow.runner:run(script, { npc = npc, onDone = done })
      return
    end
    if done then done() end
  end

  local talk = {}
  talk[ROULETTE_TEXT] = function(game, ow, npc, done)
    if not active() then
      restoreLabSprites(game)
      if done then done() end
      return
    end
    applyLabSprites(game)
    local flags = game.save.flags or {}
    if flags.EVENT_GOT_STARTER then
      opts.text(game, "The roulette is\nlocked for good.", done)
      return
    end
    local invited = flags.EVENT_FOLLOWED_OAK_INTO_LAB
      or flags.EVENT_FOLLOWED_OAK_INTO_LAB_2
      or flags.EVENT_OAK_ASKED_TO_CHOOSE_MON
    if not invited then
      opts.text(game, "OAK decides when\nthe wheel opens.", done)
      return
    end
    mod.ui.push(game, screenId, { onClose = done })
  end
  talk.TEXT_OAKSLAB_OAK1 = function(game, ow, npc, done)
    if active() and not game.save.flags.EVENT_GOT_STARTER
        and (game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB
          or game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB_2
          or game.save.flags.EVENT_OAK_ASKED_TO_CHOOSE_MON) then
      opts.text(game, "No choosing today!\fAny fool can pick.\fA bold trainer lets\nluck decide.\fSpin for your first\nPOKéMON!", done)
      return
    end
    return runBase("TEXT_OAKSLAB_OAK1", game, ow, npc, done)
  end
  talk.TEXT_OAKSLAB_RIVAL = function(game, ow, npc, done)
    if active() and not game.save.flags.EVENT_GOT_STARTER then
      opts.text(game, "Now you're talking!\fI'll gamble too--\nand still beat you.", done)
      return
    end
    return runBase("TEXT_OAKSLAB_RIVAL", game, ow, npc, done)
  end

  local function onStep(game, ow, x, y)
    local flags = game.save.flags or {}
    if not active() or not flags.EVENT_GOT_STARTER
        or flags.EVENT_BATTLED_RIVAL_IN_OAKS_LAB or y < 6 then
      return false
    end
    local rival = ow:npcByIndex(1)
    if not rival then return false end
    local rows = {
      { "stop_music" },
      { "play_music", "Music_MeetRival" },
      { "show_text", "_OaksLabRivalIllTakeYouOnText" },
    }
    local target
    for _, cell in ipairs({ { x, y - 1 }, { x - 1, y }, { x + 1, y },
                             { x, y + 1 } }) do
      if ow.map:inBounds(cell[1], cell[2])
          and ow.map:isWalkableCell(cell[1], cell[2]) then
        target = cell
        break
      end
    end
    if target then rows[#rows + 1] = { "move_npc_to", 1, target[1], target[2] } end
    rows[#rows + 1] = { "face_object", 1,
      target and target[2] < y and "down"
      or target and target[2] > y and "up"
      or target and target[1] < x and "right" or "left" }
    -- Party 3 is only a base roster. trainer.party replaces its final slot
    -- with the rival's separately rolled starter and level-appropriate form.
    rows[#rows + 1] = { "start_battle", "trainer", "OPP_RIVAL1", 3 }
    rows[#rows + 1] = { "heal_party" }
    rows[#rows + 1] = { "set_flag", "EVENT_BATTLED_RIVAL_IN_OAKS_LAB" }
    rows[#rows + 1] = { "wait", 20 }
    rows[#rows + 1] = { "show_text", "_OaksLabRivalSmellYouLaterText" }
    rows[#rows + 1] = { "stop_music" }
    rows[#rows + 1] = { "play_music", "Music_MeetRival" }
    rows[#rows + 1] = { "move_npc_to", 1, 4, 11 }
    rows[#rows + 1] = { "hide_object", "OAKS_LAB", "OAKSLAB_RIVAL" }
    rows[#rows + 1] = { "play_music", "Music_OaksLab" }
    ow.runner:run(rows, { npc = rival })
    return true
  end

  mod.content.map_scripts:register("OAKS_LAB", { talk = talk, onStep = onStep })

  local function complete(game, playerStarter, rivalStarter)
    if game.save.flags.EVENT_GOT_STARTER then return false, "ALREADY CHOSEN" end
    local fallback = Rules.FALLBACK_MOVES[playerStarter]
    local ok = Service.givePokemon(game,
      { species = playerStarter, level = 5, label = playerStarter,
        moves = fallback and { fallback } or nil }, false)
    if not ok then return false, "NO STORAGE" end
    game.save.flags.EVENT_GOT_STARTER = true
    game.save.flags.EVENT_CHOSE_BULBASAUR = true
    game.save.flags.EVENT_CHOSE_CHARMANDER = nil
    game.save.flags.EVENT_CHOSE_SQUIRTLE = nil
    game.save.flags.EVENT_CHOSE_PIKACHU = nil
    mod.save:set("roulette_player_starter", playerStarter)
    mod.save:set("roulette_rival_starter", rivalStarter)
    local ctx = { save = game.save, game = game, overworld = game.overworld }
    for _, name in ipairs(BALL_NAMES) do pcall(Commands.hide_object, ctx, "OAKS_LAB", name) end
    return true, (game.data.pokemon[playerStarter].name or playerStarter)
  end

  mod.hooks:wrap("trainer.party", function(next, trainerClass, partyIndex, party)
    local out = next(trainerClass, partyIndex, party)
    if not active() or not ({ OPP_RIVAL1 = true, OPP_RIVAL2 = true,
      OPP_RIVAL3 = true })[trainerClass] then return out end
    local species = mod.save:get("roulette_rival_starter")
    local game = require("src.core.Game")
    if not species or not (game.data and game.data.pokemon and game.data.pokemon[species]) then
      return out
    end
    out = copyParty(out)
    local last = out[#out]
    if last then
      last.species = Rules.evolveForLevel(game.data.pokemon, species, last.level)
      local fallback = Rules.FALLBACK_MOVES[last.species]
      if fallback then last.moves = { fallback } end
    end
    return out
  end, 1000)

  local function reconcileLab(game)
    if not game then return end
    if active() then
      applyLabSprites(game)
      applyOakDialogue(game)
    else
      restoreLabSprites(game)
      restoreOakDialogue(game)
    end
  end

  -- Run after ordinary mod listeners. Gamble Mode owns the Lab objects and
  -- their private A-press binding only while enabled; disabling it restores
  -- the original bindings so the full Randomizer can award its saved starters.
  mod.events:on("game.ready", function(ev)
    local game = ev and ev.game
    reconcileLab(game)
  end, -10000)
  mod.events:on("save.loaded", function(ev)
    local game = require("src.core.Game")
    reconcileLab(game)
    local mapId = ev and ev.save and ev.save.player and ev.save.player.map
    local ow = game and game.overworld
    if mapId == "OAKS_LAB" and ow and ow.map
        and ow.map.id == mapId and ow.reloadMap then
      ow:reloadMap(mapId, "gamble-starter-sync")
    end
  end, -10000)
  mod.events:on("map.exited", function(ev)
    if ev and ev.toMapId == "OAKS_LAB" then
      reconcileLab(require("src.core.Game"))
    end
  end, -10000)

  return { active = active, complete = complete, reconcileLab = reconcileLab }
end

return Gamble
