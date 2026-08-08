return function(ctx)
  local mod, Rules, View = ctx.mod, ctx.rules, ctx.view
  local Screen = { isOpaque = true }
  Screen.__index = Screen

  function Screen.new(game, opts)
    return setmetatable({ game = game, onClose = opts and opts.onClose,
      phase = "ready", duration = Rules.SPIN_DURATION }, Screen)
  end

  function Screen:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end

  function Screen:close()
    ctx.close(self.game, self)
    if self.onClose then self.onClose() end
  end

  function Screen:start()
    local random = function(maximum) return love.math.random(1, maximum) end
    self.pool = Rules.pool(self.game.data.pokemon)
    self.playerStarter = Rules.choose(self.pool, random)
    self.rivalStarter = Rules.choose(self.pool, random, self.playerStarter)
    self.strip = Rules.strip(self.pool, self.playerStarter, random)
    self.elapsed, self.reelOffset, self.phase = 0, 0, "spinning"
    ctx.play(self.game, "Slots_New_Spin")
  end

  function Screen:enter() self:start() end

  function Screen:settle()
    local ok, message = ctx.complete(self.game, self.playerStarter, self.rivalStarter)
    self.message = message
    self.phase = ok and "result" or "failed"
    ctx.play(self.game, ok and "Slots_Reward" or "Slots_Stop_Wheel")
  end

  function Screen:update(dt)
    local input = self.game.input
    if self.phase == "spinning" then
      self.elapsed = math.min(self.duration,
        self.elapsed + math.min(0.05, dt or 1 / 60))
      local progress = self.elapsed / self.duration
      self.reelOffset = Rules.STOP_OFFSET * (1 - (1 - progress) ^ 4)
      if progress >= 1 then self:settle() end
    elseif input:wasPressed("a") or input:wasPressed("b") then self:close() end
  end

  function Screen:draw()
    View.draw(self, mod.ui.Font, self.game.data.pokemon, Rules)
  end

  return Screen
end
