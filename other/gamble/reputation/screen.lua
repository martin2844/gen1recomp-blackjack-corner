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
    if value >= 1000000 then return math.floor(value / 100000) / 10 .. "M" end
    if value >= 10000 then return math.floor(value / 1000) .. "K" end
    return tostring(value)
  end

  function Screen:draw()
    local Font = mod.ui.Font
    local state = self.snapshot or {
      rankLabel = "ROOKIE", points = 0, badges = 0, wins = 0, losses = 0,
      currentLossStreak = 0, lifetimeWagered = 0,
    }
    UI.frame("HIGH ROLLER", Font, nil, theme)
    UI.panel(10, 30, 140, 27, C.paper)
    UI.color(C.ink)
    Font.draw(state.rankLabel or "ROOKIE", 16, 35)
    local points = compact(state.points) .. " REP"
    Font.draw(points, 144 - Font.width(points), 35)

    local nextRank = state.nextRank
    local start = 0
    if nextRank then
      for _, rank in ipairs(ctx.rules.RANKS) do
        if rank.id == state.rank then start = rank.points; break end
      end
      local span = math.max(1, nextRank.points - start)
      local filled = math.max(0, math.min(1, (state.points - start) / span))
      UI.color(C.outline); UI.rect("fill", 16, 47, 128, 6)
      UI.color(C.green); UI.rect("fill", 18, 49, math.floor(124 * filled), 2)
    else
      UI.color(C.green); Font.draw("TOP RANK", 16, 47)
    end

    UI.color(C.ink)
    if nextRank then
      Font.draw("NEXT " .. nextRank.label, 10, 64)
      if state.blockedByBadges then
        UI.color(C.red)
        UI.centered(Font, ("NEED %d BADGE%s"):format(nextRank.badges,
          nextRank.badges == 1 and "" or "S"), 76)
      else
        Font.draw(("%s REP  %d BADGE%s"):format(compact(nextRank.points),
          nextRank.badges, nextRank.badges == 1 and "" or "S"), 10, 76)
      end
    else
      Font.draw(("BADGES %d/8"):format(state.badges), 10, 70)
    end

    UI.panel(10, 89, 140, 31, C.paper)
    UI.color(C.ink)
    Font.draw(("W %d  L %d  D %d"):format(
      state.wins or 0, state.losses or 0, state.draws or 0), 16, 94)
    Font.draw("WAGERED " .. compact(state.lifetimeWagered), 16, 105)
    local streak = "COLD " .. tostring(state.currentLossStreak or 0)
    Font.draw(streak, 144 - Font.width(streak), 105)
    UI.color(C.ink); UI.centered(Font, "A/B RETURN", 130)

    if self.rankUp then
      UI.panel(19, 47, 122, 48, C.goldLight, C.outline)
      UI.color(C.red); UI.centered(Font, "RANK UP!", 55)
      UI.color(C.ink); UI.centered(Font, self.rankUp.label, 68)
      UI.centered(Font, "REWARD " .. tostring(self.rankUp.reward) .. " COINS", 80)
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  return Screen
end
