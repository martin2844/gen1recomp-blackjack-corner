-- Adapted from Gen II Shiny Indicators v1.5.3 by Deftones565.
-- Upstream: https://github.com/Deftones565/gen1recomp-mod-shiny-indicators
-- Source commit: 8553a2e188fc82b0dcaebfe03ee5755590016d30
-- Used under the MIT grant recorded in THIRD_PARTY_NOTICES.md.

local SHINY_ATTACK = {
  [2] = true, [3] = true, [6] = true, [7] = true,
  [10] = true, [11] = true, [14] = true, [15] = true,
}

local Fallback = {}

local OPTION_ROWS = {
  { key = "shiny_sparkles", label = "SHINY ANIMATION", type = "toggle", default = true },
  { key = "shiny_chime", label = "SHINY CHIME", type = "toggle", default = true },
  { key = "shiny_markers", label = "BATTLE MARKERS", type = "toggle", default = true },
  { key = "shiny_colors", label = "SHINY COLORS", type = "toggle", default = true },
}

function Fallback.optionRows()
  local rows = {}
  for _, row in ipairs(OPTION_ROWS) do
    local clone = {}
    for key, value in pairs(row) do clone[key] = value end
    rows[#rows + 1] = clone
  end
  return rows
end

function Fallback.disable()
  local ok, SummaryMenu = pcall(require, "src.ui.SummaryMenu")
  if ok and type(SummaryMenu) == "table" then
    SummaryMenu._blackjackCornerShinyBridge = nil
  end
end

function Fallback.install(mod)
  local battles = setmetatable({}, { __mode = "k" })
  local chimeData, playing = nil, {}
  local derived = {}
  local game
  local sourcePrefix = "assets/" .. "generated/"

  local function isShiny(mon)
    if type(mon) ~= "table" then return false end
    if mon.shiny == true then return true end
    local dvs = mon.dvs
    if type(dvs) ~= "table" then return false end
    return dvs.defense == 10 and dvs.speed == 10 and dvs.special == 10
      and SHINY_ATTACK[dvs.attack] == true
  end

  local function shinyColorMode()
    -- Stable save ids: `gbc` is displayed as SGB and `redpp` as ADVANCED.
    -- Those modes preserve enough color for the Crystal palettes.
    local options = game and game.save and game.save.options
    return options == nil or options.colors == "gbc" or options.colors == "redpp"
  end

  local function normalizeSourcePath(path)
    if type(path) ~= "string" then return nil end
    if path:sub(1, #sourcePrefix) == sourcePrefix then
      return path:sub(#sourcePrefix + 1)
    end
    local fromDerived = path:match("^save/mod%-derived/[^/]+/(.+)$")
    if fromDerived then return fromDerived end
    if path:find("/generated/") then
      return path:match("^.+/generated/(.+)$")
    end
    return nil
  end

  local function derivedShinyPath(path)
    local rel = normalizeSourcePath(path)
    if not rel then return nil end
    if rel:sub(1, 6) == "shiny/" then
      local shinyPath = "save/mod-derived/" .. mod.id .. "/" .. rel
      if derived[shinyPath] == nil then
        local ok, info = pcall(love.filesystem.getInfo, shinyPath)
        derived[shinyPath] = ok and info ~= nil or false
      end
      return derived[shinyPath] and shinyPath or nil
    end
    local candidate = "save/mod-derived/" .. mod.id .. "/shiny/" .. rel
    if derived[candidate] == nil then
      local ok, info = pcall(love.filesystem.getInfo, candidate)
      derived[candidate] = ok and info ~= nil or false
    end
    return derived[candidate] and candidate or nil
  end

  -- Run after every art-selection hook and recolor whichever Gen I image won.
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    local out = next(path, ctx)
    if mod.options:get("shiny_colors") == false or not shinyColorMode()
        or not (ctx and isShiny(ctx.mon)) then
      return out
    end
    local shiny = derivedShinyPath(out)
    if not shiny then return out end
    ctx.trueColor = true
    return shiny
  end, 100)

  mod.events:on("assets.transformed", function(ev)
    if ev and ev.modId == mod.id then derived = {} end
  end)

  -- A tiny two-note square-wave flourish is synthesized in memory. This
  -- keeps the fallback self-contained and avoids replacing a game sound bank.
  local function makeChime()
    if chimeData ~= nil then return chimeData or nil end
    chimeData = false
    local ok, data = pcall(function()
      if not (love.sound and love.sound.newSoundData) then return nil end
      local rate, duration = 22050, 0.30
      local sound = love.sound.newSoundData(math.floor(rate * duration), rate, 16, 1)
      for i = 0, sound:getSampleCount() - 1 do
        local t = i / rate
        local frequency = t < 0.12 and 1318.51 or 1760.00
        local phase = (t * frequency) % 1
        local envelope = math.max(0, 1 - t / duration)
        local sample = (phase < 0.5 and 1 or -1) * 0.16 * envelope
        sound:setSample(i, sample)
      end
      return sound
    end)
    if ok and data then chimeData = data end
    return chimeData or nil
  end

  local function playChime()
    if mod.options:get("shiny_chime") == false then return end
    local data = makeChime()
    if not data then return end
    local ok, source = pcall(function()
      if not (love.audio and love.audio.newSource) then return nil end
      local sound = love.audio.newSource(data)
      sound:play()
      return sound
    end)
    if ok and source then playing[#playing + 1] = source end
  end

  local function reapSounds()
    for i = #playing, 1, -1 do
      local ok, active = pcall(playing[i].isPlaying, playing[i])
      if not ok or not active then table.remove(playing, i) end
    end
  end

  local function battleState(battle)
    local state = battles[battle]
    if not state then
      state = { current = {}, announced = setmetatable({}, { __mode = "k" }), effects = {} }
      battles[battle] = state
    end
    return state
  end

  local function visible(battle, side)
    if (battle.introSlide or 0) > 0 then return false end
    if side == "enemy" then
      return not battle.showEnemyTrainer and not battle.enemySendingOut
        and not (battle.growIn and battle.growIn.battler == battle.enemy)
    end
    return not battle.showPlayerBack and not battle.sendingOut
      and not (battle.growIn and battle.growIn.battler == battle.player)
  end

  local function scheduleIfReady(battle, state, side, battler)
    if not battler or not battler.mon then return end
    if state.current[side] ~= battler then
      state.current[side] = battler
      state.announced[battler] = nil
    end
    if state.announced[battler] or not visible(battle, side) then return end
    state.announced[battler] = true
    if not isShiny(battler.mon) then return end
    if mod.options:get("shiny_sparkles") ~= false then
      state.effects[#state.effects + 1] = {
        side = side, battler = battler, start = battle.frame or 0, duration = 58,
      }
    end
    playChime()
  end

  local function centerFor(battle, side)
    local shot = battle.dramaticShapeShot
    if shot and shot[side] then
      return shot[side][1], shot[side][2] - (side == "enemy" and 24 or 28)
    end
    if battle.wideLayout and battle:wideLayout() then
      return side == "enemy" and 260 or 60, side == "enemy" and 32 or 74
    end
    return side == "enemy" and 124 or 40, side == "enemy" and 32 or 70
  end

  local function starVertices(cx, cy, outer, inner, rotation)
    local points = {}
    for i = 0, 7 do
      local radius = i % 2 == 0 and outer or inner
      local angle = rotation + i * math.pi / 4
      points[#points + 1] = cx + math.cos(angle) * radius
      points[#points + 1] = cy + math.sin(angle) * radius
    end
    return points
  end

  local function drawStar(cx, cy, size, alpha, rotation)
    local graphics = love.graphics
    graphics.setColor(1, 0.82, 0.08, alpha)
    graphics.polygon("fill", starVertices(cx, cy, size,
      math.max(1, size * 0.24), rotation))
    graphics.setColor(1, 1, 1, alpha)
    local core = math.max(1, size * 0.34)
    graphics.polygon("fill", starVertices(cx, cy, core,
      math.max(0.5, core * 0.22), rotation))
  end

  local OFFSETS = {
    { -1.00, -0.30 }, { 0.75, -0.85 }, { 1.00, 0.35 },
    { 0.15, 1.00 }, { -0.80, 0.70 },
  }

  local function drawEffect(battle, effect)
    local age = (battle.frame or 0) - effect.start
    if age < 0 or age >= effect.duration then return false end
    local cx, cy = centerFor(battle, effect.side)
    for i, offset in ipairs(OFFSETS) do
      local localAge = age - (i - 1) * 5
      if localAge >= 0 and localAge < 34 then
        local progress = localAge / 34
        local distance = 10 + 24 * progress
        local pulse = math.sin(math.min(1, localAge / 8) * math.pi / 2)
        local fade = math.min(1, (34 - localAge) / 10)
        drawStar(cx + offset[1] * distance, cy + offset[2] * distance,
          2 + 4 * pulse, fade, progress * math.pi / 2)
      end
    end
    return true
  end

  -- Pokémon Crystal's exact 8x8 three-sparkle status tile.
  local STATUS_ICON = {
    ".#......",
    "###.....",
    ".#....#.",
    ".....###",
    "......#.",
    "...#....",
    "..###...",
    "...#....",
  }

  local function drawSparkleTile(x, y, r, g, b)
    love.graphics.setColor(r, g, b, 1)
    for row, pixels in ipairs(STATUS_ICON) do
      for column = 1, 8 do
        if pixels:sub(column, column) == "#" then
          love.graphics.rectangle("fill", x + column - 1, y + row - 1, 1, 1)
        end
      end
    end
  end

  local function drawMarker(x, y)
    if shinyColorMode() then
      drawSparkleTile(x - 4, y - 4, 1, 0.82, 0.08)
      -- Keep gold from being washed into the HUD paper by the palette pass.
      local ok, palette = pcall(require, "src.render.PaletteFX")
      if ok and palette and palette.markTrueColor then
        palette.markTrueColor(x - 4, y - 4, 8, 8)
      end
    else
      drawSparkleTile(x - 4, y - 4, 0, 0, 0)
    end
  end

  local function drawStatusIcon()
    drawSparkleTile(152, 0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
  end

  local function markerPosition(battle, side)
    if battle.wideLayout and battle:wideLayout() then
      return side == "enemy" and 136 or 174, side == "enemy" and 10 or 66
    end
    return side == "enemy" and 94 or 62, side == "enemy" and 10 or 66
  end

  mod.events:on("battle.started", function(ev)
    if ev and ev.battle then battleState(ev.battle) end
  end)

  mod.events:on("battle.battler_switched", function(ev)
    if not (ev and ev.battle and ev.battler) then return end
    local state = battleState(ev.battle)
    local side = ev.battler.isPlayer and "player" or "enemy"
    state.current[side] = nil
  end)

  mod.events:on("battle.ended", function(ev)
    if ev and ev.battle then battles[ev.battle] = nil end
    reapSounds()
  end)

  -- The public UI hooks do not yet include a summary overlay, so wrap only
  -- the status screen's draw method at runtime.
  mod.events:on("game.ready", function(ev)
    game = ev and ev.game or game
    local ok, SummaryMenu = pcall(require, "src.ui.SummaryMenu")
    if not ok or type(SummaryMenu) ~= "table" then return end
    if not SummaryMenu._blackjackCornerShinyWrapped then
      local draw = SummaryMenu.draw
      SummaryMenu.draw = function(screen, ...)
        draw(screen, ...)
        local bridge = SummaryMenu._blackjackCornerShinyBridge
        if bridge and bridge.isShiny(screen.mon) then bridge.drawStatusIcon() end
      end
      SummaryMenu._blackjackCornerShinyWrapped = true
    end
    SummaryMenu._blackjackCornerShinyBridge = {
      isShiny = isShiny,
      drawStatusIcon = drawStatusIcon,
    }
  end)

  mod.hooks:wrap("battle.overlay", function(next, battle)
    next(battle)
    if not battle or not (love and love.graphics) then return end
    local state = battleState(battle)
    scheduleIfReady(battle, state, "enemy", battle.enemy)
    scheduleIfReady(battle, state, "player", battle.player)

    if mod.options:get("shiny_markers") ~= false and not battle.introBalls then
      for _, side in ipairs({ "enemy", "player" }) do
        local battler = battle[side]
        if battler and isShiny(battler.mon) and visible(battle, side) then
          local x, y = markerPosition(battle, side)
          drawMarker(x, y)
        end
      end
    end

    for i = #state.effects, 1, -1 do
      if not drawEffect(battle, state.effects[i]) then table.remove(state.effects, i) end
    end
    love.graphics.setColor(1, 1, 1, 1)
    reapSounds()
  end)

  mod.exports.shiny_fallback = true
  mod.exports.isShiny = isShiny
  mod.exports.shiny_status_icon = STATUS_ICON
  mod.exports.shiny_derived_path = derivedShinyPath
  mod.exports.shiny_color_mode = shinyColorMode
  mod.exports.shiny_effect_count = function(battle)
    local state = battles[battle]
    return state and #state.effects or 0
  end
end

return Fallback
