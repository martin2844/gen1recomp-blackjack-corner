return function(ctx)
  local mod, UI = ctx.mod, ctx.ui
  local C = UI.colors
  local theme = { base = C.blueLight, header = C.gold, action = C.goldLight }
  local Screen = { isOpaque = true }
  Screen.__index = Screen

  function Screen.new(game, opts)
    return setmetatable({
      game = game,
      onClose = opts and opts.onClose,
      snapshot = ctx.progress.snapshot(game),
      rankUp = ctx.progress.consumeRankUp(),
    }, Screen)
  end

  function Screen:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end

  function Screen:close()
    ctx.close(self.game, self)
    if self.onClose then self.onClose() end
  end

  function Screen:update()
    local input = self.game.input
    if input:wasPressed("a") or input:wasPressed("b") then self:close() end
  end

  local function compact(value)
    value = math.max(0, math.floor(tonumber(value) or 0))
    if value >= 1000000 then
      if value >= 10000000 then return math.floor(value / 1000000) .. "M" end
      local millions = math.floor(value / 100000) / 10
      return (millions == math.floor(millions)
        and tostring(math.floor(millions)) or tostring(millions)) .. "M"
    end
    if value >= 10000 then return math.floor(value / 1000) .. "K" end
    return tostring(value)
  end

  local function right(Font, value, edge, y)
    Font.draw(value, edge - Font.width(value), y)
  end

  -- Record cells reserve one glyph for W/L/D and four for the abbreviated
  -- value. The fixed positions below keep even 999K from touching its label.
  local function compactCount(value)
    value = math.max(0, math.floor(tonumber(value) or 0))
    if value < 1000 then return tostring(value) end
    if value < 1000000 then return math.floor(value / 1000) .. "K" end
    if value < 1000000000 then return math.floor(value / 1000000) .. "M" end
    return math.min(999, math.floor(value / 1000000000)) .. "B"
  end

  local function currentRankStart(state)
    for _, rank in ipairs(ctx.rules.RANKS) do
      if rank.id == state.rank then return rank.points end
    end
    return 0
  end

  local function viewModel(state)
    state = state or {}
    local nextRank = state.nextRank
    local model = {
      rank = state.rankLabel or "ROOKIE",
      points = compact(state.points) .. " REP",
      wins = compactCount(state.wins),
      losses = compactCount(state.losses),
      draws = compactCount(state.draws),
      wagered = compact(state.lifetimeWagered),
      cold = compactCount(state.currentLossStreak),
      favorite = state.favoriteGame and state.favoriteGame.label or "NONE",
      bank = compact(state.pendingRewardCoins),
      hasBank = (tonumber(state.pendingRewardCoins) or 0) > 0,
      nextRank = nextRank,
      progress = 1,
    }
    if nextRank then
      local start = currentRankStart(state)
      model.progress = math.max(0, math.min(1,
        ((tonumber(state.points) or 0) - start)
          / math.max(1, nextRank.points - start)))
      if state.blockedByArena then
        model.requirement, model.requirementBlocked = "ARENA REQUIRED", true
      elseif state.blockedByBadges then
        model.requirement = ("NEED %d BADGE%s"):format(nextRank.badges,
          nextRank.badges == 1 and "" or "S")
        model.requirementBlocked = true
      else
        model.requirement = ("%s REP  %d BADGE%s"):format(
          compact(nextRank.points), nextRank.badges,
          nextRank.badges == 1 and "" or "S")
      end
    end
    return model
  end

  -- Exposed on screen instances so layout regressions can be tested without
  -- depending on pixels or a particular host window scale.
  function Screen:viewModel(state)
    return viewModel(state or self.snapshot)
  end

  function Screen:draw()
    local Font = mod.ui.Font
    local state = self.snapshot or {
      rankLabel = "ROOKIE", points = 0, badges = 0, wins = 0, losses = 0,
      currentLossStreak = 0, lifetimeWagered = 0,
    }
    local model = viewModel(state)
    UI.frame("HIGH ROLLER", Font, nil, theme)

    -- Current rank and progress are one compact card. Values are right-aligned
    -- to a fixed edge so changing REP never pushes into the rank label.
    UI.panel(8, 29, 144, 28, C.paper)
    UI.color(C.ink)
    Font.draw(model.rank, 14, 34)
    right(Font, model.points, 146, 34)
    if model.nextRank then
      UI.color(C.outline); UI.rect("fill", 14, 47, 132, 6)
      UI.color(C.green)
      UI.rect("fill", 16, 49, math.floor(128 * model.progress), 2)
    else
      UI.color(C.green); UI.rect("fill", 14, 47, 132, 6)
      UI.color(C.paper); UI.rect("fill", 16, 49, 128, 2)
    end

    -- The next unlock sits outside the card as a simple two-line goal. This
    -- keeps long rank names and badge locks from competing with the stats.
    UI.color(C.ink)
    if model.nextRank then
      Font.draw("NEXT", 10, 62)
      right(Font, model.nextRank.label, 150, 62)
      UI.color(model.requirementBlocked and C.red or C.outline)
      UI.centered(Font, model.requirement, 74)
    else
      Font.draw("RANK COMPLETE", 10, 62)
      right(Font, ("%d/8 BADGES"):format(state.badges or 0), 150, 74)
    end

    -- Four reserved rows replace the free-form text block. Every number has a
    -- right edge, and the three record counters each own a fixed-width column.
    UI.panel(8, 84, 144, 43, C.paper)
    UI.color(C.ink)
    Font.draw("W", 12, 88); right(Font, model.wins, 55, 88)
    Font.draw("L", 61, 88); right(Font, model.losses, 102, 88)
    Font.draw("D", 108, 88); right(Font, model.draws, 149, 88)
    UI.color(C.muted)
    UI.rect("fill", 57, 88, 1, 8); UI.rect("fill", 104, 88, 1, 8)
    UI.color(C.ink)
    Font.draw("WAGERED", 14, 98); right(Font, model.wagered, 146, 98)
    Font.draw("FAV", 14, 108); right(Font, model.favorite, 146, 108)
    if model.hasBank then
      Font.draw("BANKED", 14, 118); right(Font, model.bank, 146, 118)
    else
      Font.draw("COLD STREAK", 14, 118); right(Font, model.cold, 146, 118)
    end
    UI.color(C.ink); UI.centered(Font, "A/B BACK", 130)

    if self.rankUp then
      UI.panel(17, 41, 126, 64, C.paper, C.outline)
      UI.color(C.gold); UI.rect("fill", 20, 44, 120, 15)
      UI.color(C.ink); UI.centered(Font, "RANK UP!", 48)
      UI.centered(Font, self.rankUp.label, 66)
      UI.centered(Font, compact(self.rankUp.reward) .. " COINS BANKED", 79)
      UI.color(C.outline); UI.centered(Font, "A/B CLOSE", 92)
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  return Screen
end
