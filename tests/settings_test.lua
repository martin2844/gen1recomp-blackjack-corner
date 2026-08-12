package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Settings = assert(loadfile("mods/blackjack_corner/other/settings.lua"))()

local stored, schema = {}, nil
local mod = { options = {} }

function mod.options:define(rows)
  schema = rows
end

function mod.options:get(key)
  if stored[key] ~= nil then return stored[key] end
  for _, row in ipairs(schema or {}) do
    if row.key == key then return row.default end
  end
end

local settings = Settings.install(mod, {
  { key = "extra", label = "EXTRA", type = "toggle", default = true },
})

T.eq(#schema, 5, "the settings module combines four core rows with contributed rows")
T.same({ schema[1].key, schema[2].key, schema[3].key, schema[4].key }, {
  "gamble_default", "table_intros", "reveal_speed", "shiny_upgrades",
}, "the core settings keep a stable player-facing order")
T.check(not settings.gambleDefault(),
  "ordinary progression remains the default new-campaign selection")
stored.gamble_default = "on"
T.check(settings.gambleDefault(),
  "the persistent default can preselect Gamble Mode")

T.check(settings.tableIntros(), "table introductions default on")
stored.table_intros = false
T.check(not settings.tableIntros(), "table introductions can be disabled")

T.eq(settings.revealScale(), 1, "reveal animations default to normal speed")
stored.reveal_speed = "relaxed"
T.eq(settings.revealScale(), 0.75, "relaxed reveal speed slows non-reflex games")
T.eq(settings.revealStep(0.04), 0.03,
  "the shared reveal step applies the selected pace")
stored.reveal_speed = "fast"
T.eq(settings.revealScale(), 1.6, "fast reveal speed accelerates non-reflex games")
T.eq(settings.revealStep(1), 0.05,
  "reveal steps retain the engine's frame-stall clamp")

T.check(settings.shinyUpgrades(), "shiny prize upgrades default on")
stored.shiny_upgrades = false
T.check(not settings.shinyUpgrades(), "shiny prize upgrades can be hidden")

T.finish("settings")
