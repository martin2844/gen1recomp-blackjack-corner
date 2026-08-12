local Settings = {}

local CORE_ROWS = {
  {
    key = "gamble_default", label = "GAMBLE DEFAULT", type = "choice",
    default = "off",
    choices = { { "NO", "off" }, { "YES", "on" } },
    help = "Preselect the Gamble Mode answer for each new campaign.",
  },
  {
    key = "table_intros", label = "TABLE INTROS", type = "toggle",
    default = true,
    help = "Show the rules card before opening a casino game.",
  },
  {
    key = "reveal_speed", label = "REVEAL SPEED", type = "choice",
    default = "normal",
    choices = {
      { "RELAXED", "relaxed" }, { "NORMAL", "normal" }, { "FAST", "fast" },
    },
    help = "Set the pace of reels, races, Plinko, and arena battles.",
  },
  {
    key = "shiny_upgrades", label = "SHINY UPGRADES", type = "toggle",
    default = true,
    help = "Offer the extra-cost shiny version at Pokemon prize counters.",
  },
}

local SPEED = { relaxed = 0.75, normal = 1, fast = 1.6 }

local function copyRows(rows)
  local out = {}
  for _, row in ipairs(rows or {}) do
    local clone = {}
    for key, value in pairs(row) do clone[key] = value end
    out[#out + 1] = clone
  end
  return out
end

-- Own the complete schema in one place. mod.options:define replaces the
-- previous schema, so conditional modules contribute rows instead of defining
-- their own isolated settings page.
function Settings.install(mod, extraRows)
  local rows = copyRows(CORE_ROWS)
  for _, row in ipairs(copyRows(extraRows)) do rows[#rows + 1] = row end
  mod.options:define(rows)

  local interface = {}

  function interface.gambleDefault()
    return mod.options:get("gamble_default") == "on"
  end

  function interface.tableIntros()
    return mod.options:get("table_intros") ~= false
  end

  function interface.revealScale()
    return SPEED[mod.options:get("reveal_speed")] or SPEED.normal
  end

  function interface.revealStep(dt)
    local elapsed = math.max(0, tonumber(dt) or 1 / 60)
    return math.min(0.05, elapsed * interface.revealScale())
  end

  function interface.shinyUpgrades()
    return mod.options:get("shiny_upgrades") ~= false
  end

  return interface
end

return Settings
