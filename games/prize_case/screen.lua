return function(ctx)
  local mod, Rules, View = ctx.mod, ctx.rules, ctx.view
  local Screen = { isOpaque = true }
  Screen.__index = Screen

  function Screen.new(game, opts)
    opts = opts or {}
    return setmetatable({ game = game, onClose = opts.onClose,
      phase = "ready", duration = Rules.SPIN_DURATION,
      winnerIndex = Rules.WINNER_INDEX, caseData = opts.caseData,
      autoOpen = opts.autoOpen or ctx.autoOpen,
      oneShot = opts.oneShot or ctx.oneShot,
      title = opts.title or ctx.title or "PRIZE CASE",
      cost = ctx.cost == nil and Rules.COST or ctx.cost }, Screen)
  end

  function Screen:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end

  function Screen:close()
    ctx.close(self.game, self)
    if self.onClose then self.onClose() end
  end

  function Screen:open()
    if ctx.coins(self.game) < self.cost then
      self.notice = "NEED " .. tostring(self.cost) .. " COINS"
      return
    end
    local pool = ctx.rewardPool(self.game, self.caseData)
    local random = function(maximum) return love.math.random(1, maximum) end
    self.winner = self.caseData and self.caseData.reward or Rules.choose(pool, random)
    if ctx.onChosen then ctx.onChosen(self.caseData, self.winner) end
    self.strip = Rules.strip(pool, self.winner, random)
    self.game.save.coins = ctx.coins(self.game) - self.cost
    self.elapsed, self.reelOffset = 0, 0
    self.phase, self.notice, self.message, self.refunded = "spinning", nil, nil, false
    mod.save:set(ctx.counterKey or "cases_opened",
      mod.save:get(ctx.counterKey or "cases_opened", 0) + 1)
    ctx.play(self.game, "Slots_New_Spin")
  end

  function Screen:settle()
    if self.phase ~= "spinning" then return end
    local ok, message = ctx.giveReward(self.game, self.winner)
    self.refunded = not ok and self.cost > 0
    self.claimSaved = not ok and self.cost == 0
    if not ok then
      self.game.save.coins = math.min(ctx.coinCap,
        ctx.coins(self.game) + self.cost)
    elseif ctx.onDelivered then
      ctx.onDelivered(self.caseData, self.winner)
    end
    self.message, self.phase = message, "result"
    ctx.play(self.game, ok and "Slots_Reward" or "Slots_Stop_Wheel")
  end

  function Screen:update(dt)
    local input = self.game.input
    if self.phase == "ready" then
      if self.autoOpen then self.autoOpen = false; self:open()
      elseif input:wasPressed("a") then self:open()
      elseif input:wasPressed("b") then self:close() end
    elseif self.phase == "spinning" then
      self.elapsed = math.min(self.duration,
        self.elapsed + math.min(0.05, dt or 1 / 60))
      local progress = self.elapsed / self.duration
      self.reelOffset = Rules.REEL_STOP_OFFSET * (1 - (1 - progress) ^ 4)
      if progress >= 1 then self:settle() end
    elseif self.oneShot and (input:wasPressed("a") or input:wasPressed("b")) then
      self:close()
    elseif input:wasPressed("a") then
      self.phase, self.notice = "ready", nil
      ctx.play(self.game, "Press_AB")
    elseif input:wasPressed("b") then self:close() end
  end

  function Screen:draw()
    View.draw(self, mod.ui.Font, ctx.coins(self.game))
  end

  return Screen
end
