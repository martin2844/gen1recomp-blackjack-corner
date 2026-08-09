return function(ctx)
  local mod, Rules, View = ctx.mod, ctx.rules, ctx.view
  local Screen = { isOpaque = true }
  Screen.__index = Screen

  function Screen.new(game, opts)
    return setmetatable({ game = game, onClose = opts and opts.onClose,
      phase = "ready", duration = Rules.SPIN_DURATION, choice = 1 }, Screen)
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
    self.message, self.choice = nil, 1
    ctx.play(self.game, "Slots_New_Spin")
  end

  function Screen:enter() self:start() end

  function Screen:settle()
    self.phase, self.choice, self.message = "offer", 1, nil
    ctx.play(self.game, "Slots_Stop_Wheel")
  end

  function Screen:accept()
    local ok, message = ctx.complete(self.game, self.playerStarter, self.rivalStarter)
    self.message = message
    self.phase = ok and "result" or "failed"
    ctx.play(self.game, ok and "Slots_Reward" or "Slots_Stop_Wheel")
    return ok
  end

  function Screen:canRespin()
    return Rules.canRespin(self.game.save.money)
  end

  function Screen:respin()
    if not self:canRespin() then
      self.message, self.choice = "NEED ¥" .. Rules.RESPIN_COST, 1
      ctx.play(self.game, "Slots_Stop_Wheel")
      return false
    end
    self.game.save.money = math.floor(tonumber(self.game.save.money) or 0)
      - Rules.RESPIN_COST
    self:start()
    return true
  end

  function Screen:update(dt)
    local input = self.game.input
    if self.phase == "spinning" then
      self.elapsed = math.min(self.duration,
        self.elapsed + math.min(0.05, dt or 1 / 60))
      local progress = self.elapsed / self.duration
      self.reelOffset = Rules.STOP_OFFSET * (1 - (1 - progress) ^ 4)
      if progress >= 1 then self:settle() end
    elseif self.phase == "offer" then
      if input:wasPressed("left") or input:wasPressed("up") then
        self.choice = 1
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("right") or input:wasPressed("down") then
        self.choice = self:canRespin() and 2 or 1
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("a") then
        if self.choice == 2 then self:respin() else self:accept() end
      elseif input:wasPressed("b") then
        -- The lab cannot be left without a starter; B safely keeps the roll.
        self:accept()
      end
    elseif input:wasPressed("a") or input:wasPressed("b") then
      self:close()
    end
  end

  function Screen:draw()
    View.draw(self, mod.ui.Font, self.game.data.pokemon, Rules)
  end

  return Screen
end
