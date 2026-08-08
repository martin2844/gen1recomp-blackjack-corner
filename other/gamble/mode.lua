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
      for _, name in ipairs(BALL_NAMES) do
        if object.name == name then
          matches[#matches + 1] = object
          break
        end
      end
    end
    if #matches == 1 then
      -- Yellow has one gift ball, so use the center cabinet piece.
      matches[1]._blackjackCornerOriginalSprite =
        matches[1]._blackjackCornerOriginalSprite or matches[1].sprite
      matches[1].sprite = pieces[2]
    else
      for index, object in ipairs(matches) do
        object._blackjackCornerOriginalSprite =
          object._blackjackCornerOriginalSprite or object.sprite
        object.sprite = pieces[math.min(index, #pieces)]
      end
    end
  end

  local function restoreLabSprites(game)
    local lab = game and game.data and game.data.maps and game.data.maps.OAKS_LAB
    for _, object in ipairs(lab and lab.objects or {}) do
      if object._blackjackCornerOriginalSprite then
        object.sprite = object._blackjackCornerOriginalSprite
      end
    end
  end

  mod.hooks:wrap("intro.oak_speech.build", function(next, steps, speech)
    steps = next(steps, speech)
    mod.ui.insertStepAfter(steps, "oak_welcome", {
      id = "blackjack_corner_gamble_mode", kind = "yesno", pic = "oak",
      saveKey = "gamble_mode", defaultNo = true,
      text = "Enable GAMBLE MODE?\fRandom starter.\nGyms give cases.",
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
    elseif ev.speech and ev.speech.game then
      restoreLabSprites(ev.speech.game)
    end
  end)

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
  for _, textId in ipairs(BALL_TEXTS) do
    talk[textId] = function(game, ow, npc, done)
      if not active() then return runBase(textId, game, ow, npc, done) end
      local flags = game.save.flags or {}
      if flags.EVENT_GOT_STARTER then
        opts.text(game, "The roulette is\nlocked for good.", done)
        return
      end
      local invited = flags.EVENT_FOLLOWED_OAK_INTO_LAB
        or flags.EVENT_FOLLOWED_OAK_INTO_LAB_2
        or flags.EVENT_OAK_ASKED_TO_CHOOSE_MON
      if not invited then return runBase(textId, game, ow, npc, done) end
      mod.ui.push(game, screenId, { onClose = done })
    end
  end
  talk.TEXT_OAKSLAB_OAK1 = function(game, ow, npc, done)
    if active() and not game.save.flags.EVENT_GOT_STARTER
        and (game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB
          or game.save.flags.EVENT_FOLLOWED_OAK_INTO_LAB_2
          or game.save.flags.EVENT_OAK_ASKED_TO_CHOOSE_MON) then
      opts.text(game, "No choosing today.\fThe roulette gives\nyou one POKEMON.\fYour rival spins\nseparately.", done)
      return
    end
    return runBase("TEXT_OAKSLAB_OAK1", game, ow, npc, done)
  end
  talk.TEXT_OAKSLAB_RIVAL = function(game, ow, npc, done)
    if active() and not game.save.flags.EVENT_GOT_STARTER then
      opts.text(game, "Fine by me!\fI'll win with\nwhatever I roll.", done)
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
  end)

  mod.events:on("game.ready", function(ev)
    local game = ev and ev.game
    if not game then return end
    if active() then applyLabSprites(game) else restoreLabSprites(game) end
  end)

  return { active = active, complete = complete }
end

return Gamble
