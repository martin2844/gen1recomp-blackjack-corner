package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local ImageWriter = require("src.import.ImageWriter")
local HeadlessFs = assert(loadfile(
  "mods/blackjack_corner/tests/support/headless_fs.lua"))()
local CasinoCatalog = assert(loadfile(
  "mods/blackjack_corner/tests/support/casino_catalog.lua"))()

local MOD = "mods/blackjack_corner"
local SOURCE_PREFIX = "assets/" .. "generated/"

-- A dedicated provider must load first and own the shiny presentation hooks.
for _, provider in ipairs({
  { id = "shiny_indicators", path = MOD .. "/tests/fixtures/shiny_indicators" },
  { id = "SHINY_POKEMON", path = MOD .. "/tests/fixtures/shiny_provider" },
  { id = "crystal_animated_sprites_with_shiny_visuals",
    path = MOD .. "/tests/fixtures/crystal_animated_sprites_with_shiny_visuals" },
  { id = "gen2_shiny_visuals", path = MOD .. "/tests/fixtures/gen2_shiny_visuals" },
  { id = "shiny_visuals", path = MOD .. "/tests/fixtures/shiny_visuals" },
}) do
  local run = T.sdk.loadMods({ provider.path, MOD }, {
    data = CasinoCatalog.seed(T.fixtures.fresh()), dev = true,
    fs = HeadlessFs.new({ provider.path, MOD }),
  })
  T.eq(#run.errors, 0, "external shiny provider and Blackjack Corner load cleanly")
  T.eq(run.loader.order[1], provider.id,
    "the optional shiny provider loads before Blackjack Corner")
  T.eq(run.loader.order[2], "blackjack_corner",
    "Blackjack Corner loads after its optional shiny provider")
  local api = run.loader.exports.blackjack_corner
  T.eq(api.shiny_provider, provider.id,
    "Blackjack Corner reports the active external provider")
  T.eq(api.shiny_fallback, false,
    "the bundled fallback stays disabled beside an external provider")
  T.eq(#run.loader.optionSchemas.blackjack_corner, 4,
    "core Blackjack Corner settings remain available beside an external shiny provider")
  T.eq(run.loader.optionSchemas.blackjack_corner[1].key, "gamble_default",
    "the external-provider settings page begins with the campaign default")
  local hooks = T.record.hooks(run.loader)
  T.eq(hooks:depth("pokemon.sprite"), 1,
    "Blackjack Corner preserves exactly one external shiny sprite hook")
  T.eq(hooks:depth("battle.overlay"), 1,
    "Blackjack Corner preserves exactly one external shiny indicator hook")
  run.release()
end

local run = T.sdk.loadMod(MOD, {
  data = CasinoCatalog.seed(T.fixtures.fresh()), dev = true,
  fs = HeadlessFs.new({ MOD }),
})
T.eq(#run.errors, 0, "Blackjack Corner loads cleanly without a shiny provider")
local api = run.loader.exports.blackjack_corner
T.eq(api.shiny_provider, "blackjack_corner",
  "Blackjack Corner identifies itself as the fallback provider")
T.eq(api.shiny_fallback, true,
  "the bundled shiny fallback activates when no provider is installed")

local function mon(attack, defense, speed, special)
  return { dvs = {
    attack = attack, defense = defense, speed = speed, special = special,
  } }
end

for _, attack in ipairs({ 2, 3, 6, 7, 10, 11, 14, 15 }) do
  T.check(api.isShiny(mon(attack, 10, 10, 10)),
    "accepts Gen II shiny Attack DV " .. attack)
end
T.check(not api.isShiny(mon(1, 10, 10, 10)),
  "rejects a non-shiny Attack DV")
T.check(not api.isShiny(mon(2, 9, 10, 10)),
  "requires Defense DV 10")
T.check(not api.isShiny(mon(2, 10, 9, 10)),
  "requires Speed DV 10")
T.check(not api.isShiny(mon(2, 10, 10, 9)),
  "requires Special DV 10")
T.check(api.isShiny({ shiny = true }),
  "supports an explicit shiny flag from compatible mods")

T.same(api.shiny_status_icon, {
  ".#......", "###.....", ".#....#.", ".....###",
  "......#.", "...#....", "..###...", "...#....",
}, "status marker matches Crystal's three-sparkle tile")
T.eq(#run.loader.optionSchemas.blackjack_corner, 8,
  "the fallback appends four presentation settings to four core settings")
T.eq(run.loader.optionSchemas.blackjack_corner[5].key, "shiny_sparkles",
  "fallback-only presentation settings follow the stable core rows")

-- All 151 front and back sprites receive their canonical Crystal palettes.
do
  local transform = assert(loadfile(MOD .. "/transforms.lua"))()
  local written, palettes = {}, {}
  transform({
    exists = function(path) return path:sub(1, 7) == "battle/" end,
    readImage = function(path) return path end,
    recolor = function(image, shades)
      palettes[#palettes + 1] = shades
      return image
    end,
    writeImage = function(_, path) written[#written + 1] = path end,
    blank = ImageWriter.blank,
    blit = ImageWriter.blit,
  })
  local shiny = {}
  for _, path in ipairs(written) do
    if path:sub(1, 6) == "shiny/" then shiny[#shiny + 1] = path end
  end
  T.eq(#shiny, 302, "front and back art is generated for all 151 species")
  T.same(palettes[49][2], { 248, 136, 0 },
    "Pikachu uses Crystal shiny color one")
  T.same(palettes[49][3], { 160, 16, 88 },
    "Pikachu uses Crystal shiny color two")
  T.same(palettes[301][2], { 144, 192, 248 },
    "Mew uses Crystal shiny color one")
  T.same(palettes[301][3], { 56, 88, 208 },
    "Mew uses Crystal shiny color two")
end

local oldGetInfo = love.filesystem.getInfo
love.filesystem.getInfo = function(path)
  if path == "save/mod-derived/blackjack_corner/shiny/battle/front/pikachu.png" then
    return { type = "file" }
  end
  return oldGetInfo(path)
end

local displayGame = { save = { options = { colors = "gbc" } } }
run.loader.events:emit("game.ready", { game = displayGame })
local SummaryMenu = require("src.ui.SummaryMenu")
T.check(SummaryMenu._blackjackCornerShinyBridge ~= nil,
  "the active fallback connects its reload-safe status marker bridge")
local spriteCtx = {
  mon = mon(10, 10, 10, 10), species = "PIKACHU",
  side = "front", kind = "battle", trueColor = false,
}
local shinyPath = run.loader.hooks:call("pokemon.sprite",
  function(path) return path end,
  SOURCE_PREFIX .. "battle/front/pikachu.png", spriteCtx)
T.eq(shinyPath,
  "save/mod-derived/blackjack_corner/shiny/battle/front/pikachu.png",
  "a shiny instance selects its derived Crystal-colored sprite")
T.eq(spriteCtx.trueColor, true,
  "the colored shiny sprite bypasses the normal palette remap")

local ordinaryCtx = {
  mon = mon(1, 1, 1, 1), species = "PIKACHU",
  side = "front", kind = "battle", trueColor = false,
}
local ordinaryPath = run.loader.hooks:call("pokemon.sprite",
  function(path) return path end,
  SOURCE_PREFIX .. "battle/front/pikachu.png", ordinaryCtx)
T.eq(ordinaryPath, SOURCE_PREFIX .. "battle/front/pikachu.png",
  "an ordinary instance keeps its normal sprite")

-- Regression: the old white-on-white sparkle left only a black 4x4 outline.
local calls = {}
local oldColor = love.graphics.setColor
local oldPolygon = love.graphics.polygon
local oldRectangle = love.graphics.rectangle
love.graphics.setColor = function(...) calls[#calls + 1] = { "color", ... } end
love.graphics.polygon = function(...) calls[#calls + 1] = { "polygon", ... } end
love.graphics.rectangle = function(...) calls[#calls + 1] = { "rectangle", ... } end
run.loader.modOptions.blackjack_corner = { shiny_chime = false }
local battle = {
  frame = 0,
  enemy = { mon = mon(10, 10, 10, 10) },
  player = { mon = mon(1, 1, 1, 1) },
}
run.loader.hooks:call("battle.overlay", function() end, battle)
local gold, filledMarker, outlinedDot = false, false, false
for _, call in ipairs(calls) do
  if call[1] == "color" and call[2] == 1 and call[3] == 0.82
      and call[4] == 0.08 then gold = true end
  if call[1] == "rectangle" and call[2] == "fill" then filledMarker = true end
  if call[1] == "rectangle" and call[2] == "line"
      and call[5] == 4 and call[6] == 4 then outlinedDot = true end
end
T.check(gold, "the fallback draws a visible gold shiny effect")
T.check(filledMarker, "the fallback draws Crystal's filled sparkle marker")
T.check(not outlinedDot, "the fallback never draws the old black outlined dot")
T.eq(api.shiny_effect_count(battle), 1,
  "a shiny battler schedules one entrance animation")

-- The independent chime option still works when animation and markers are off.
local oldAudio = love.audio
love.audio = love.audio or {}
local oldNewSource = love.audio.newSource
local chimeCount = 0
love.audio.newSource = function()
  return {
    play = function() chimeCount = chimeCount + 1 end,
    isPlaying = function() return false end,
  }
end
run.loader.modOptions.blackjack_corner = {
  shiny_sparkles = false, shiny_chime = true, shiny_markers = false,
}
local chimeBattle = {
  frame = 0,
  enemy = { mon = mon(10, 10, 10, 10) },
  player = { mon = mon(1, 1, 1, 1) },
}
calls = {}
run.loader.hooks:call("battle.overlay", function() end, chimeBattle)
T.eq(api.shiny_effect_count(chimeBattle), 0,
  "disabling animation schedules no entrance effect")
T.eq(chimeCount, 1,
  "the separately enabled chime still plays without animation")
local markerPixels = 0
for _, call in ipairs(calls) do
  if call[1] == "rectangle" and call[2] == "fill" then
    markerPixels = markerPixels + 1
  end
end
T.eq(markerPixels, 0, "disabling battle markers draws no marker pixels")

love.audio.newSource = oldNewSource
love.audio = oldAudio
love.graphics.setColor = oldColor
love.graphics.polygon = oldPolygon
love.graphics.rectangle = oldRectangle
love.filesystem.getInfo = oldGetInfo
run.release()

-- A hot reload that adds a provider must disconnect the old status wrapper.
do
  local external = T.sdk.loadMods({
    MOD .. "/tests/fixtures/shiny_indicators", MOD,
  }, {
    data = CasinoCatalog.seed(T.fixtures.fresh()), dev = true,
    fs = HeadlessFs.new({ MOD .. "/tests/fixtures/shiny_indicators", MOD }),
  })
  T.eq(#external.errors, 0,
    "Blackjack Corner hot reloads cleanly with an external provider")
  T.eq(SummaryMenu._blackjackCornerShinyBridge, nil,
    "an external provider disconnects the old fallback status marker")
  external.release()
end

T.finish("shiny_fallback")
