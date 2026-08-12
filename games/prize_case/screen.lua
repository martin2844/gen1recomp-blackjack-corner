return function(ctx)
  local mod, Rules, View = ctx.mod, ctx.rules, ctx.view
  local Screen = { isOpaque = true }
  Screen.__index = Screen

  function Screen.new(game, opts)
    opts = opts or {}
    local cost = ctx.cost == nil and Rules.COST or ctx.cost
    local claimKey = ctx.claimKey or "paid_case_claim"
    return setmetatable({ game = game, onClose = opts.onClose,
      phase = "ready", duration = Rules.SPIN_DURATION,
      winnerIndex = Rules.WINNER_INDEX, caseData = opts.caseData,
      autoOpen = opts.autoOpen or ctx.autoOpen,
      oneShot = opts.oneShot or ctx.oneShot,
      title = opts.title or ctx.title or "PRIZE CASE",
      cost = cost, claimKey = claimKey,
      hasSavedClaim = cost > 0 and mod.save:get(claimKey) ~= nil }, Screen)
  end

  function Screen:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end

  function Screen:close()
    ctx.close(self.game, self)
    if self.onClose then self.onClose() end
  end

  function Screen:open()
    local savedClaim = self.cost > 0 and mod.save:get(self.claimKey) or nil
    if not savedClaim and self.cost > 0 and ctx.canOpen then
      local allowed, message = ctx.canOpen(self.game)
      if not allowed then
        self.notice = message or "ROCKET CREDIT HOLD"
        return
      end
    end
    if not savedClaim and ctx.coins(self.game) < self.cost then
      self.notice = "NEED " .. tostring(self.cost) .. " COINS"
      return
    end
    local pool = ctx.rewardPool(self.game, self.caseData)
    local random = function(maximum) return love.math.random(1, maximum) end
    self.winner = savedClaim or self.caseData and self.caseData.reward
      or Rules.choose(pool, random)
    if not savedClaim and ctx.onChosen then ctx.onChosen(self.caseData, self.winner) end
    self.strip = Rules.strip(pool, self.winner, random)
    if not savedClaim then
      self.game.save.coins = ctx.coins(self.game) - self.cost
    end
    if self.cost > 0 and not savedClaim then
      self.reputationRound = ctx.beginRound("prize_case", self.cost)
      -- The campaign settles on the paid reel's immutable choice. Delivery
      -- retries must never duplicate reputation.
      local _, progress = ctx.settleRound(
        self.game, self.reputationRound, "win", self.cost)
      self.rankUpPending = progress and progress.rankUp
      mod.save:set(self.claimKey, self.winner)
    end
    self.elapsed, self.reelOffset = 0, 0
    self.phase, self.notice, self.message = "spinning", nil, nil
    self.refunded, self.claimSaved, self.hasSavedClaim = false, false, savedClaim ~= nil
    if not savedClaim then
      mod.save:set(ctx.counterKey or "cases_opened",
        mod.save:get(ctx.counterKey or "cases_opened", 0) + 1)
    end
    ctx.play(self.game, "Slots_New_Spin")
  end

  function Screen:settle()
    if self.phase ~= "spinning" then return end
    local ok, message = ctx.giveReward(self.game, self.winner)
    self.refunded = false
    self.claimSaved = not ok
    if ok then
      if self.cost > 0 then mod.save:set(self.claimKey, nil) end
      self.hasSavedClaim = false
      if ctx.onDelivered then ctx.onDelivered(self.caseData, self.winner) end
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
      local step = ctx.revealStep and ctx.revealStep(dt)
        or math.min(0.05, dt or 1 / 60)
      self.elapsed = math.min(self.duration, self.elapsed + step)
      local progress = self.elapsed / self.duration
      self.reelOffset = Rules.REEL_STOP_OFFSET * (1 - (1 - progress) ^ 4)
      if progress >= 1 then self:settle() end
    elseif self.oneShot and (input:wasPressed("a") or input:wasPressed("b")) then
      self:close()
    elseif input:wasPressed("a") then
      if self.claimSaved then
        self.phase = "ready"
        self:open()
      elseif self.rankUpPending and ctx.showRankUp then
        self.rankUpPending = false
        ctx.showRankUp(self.game)
      else
        self.phase, self.notice = "ready", nil
        ctx.play(self.game, "Press_AB")
      end
    elseif input:wasPressed("b") then
      if self.rankUpPending and ctx.showRankUp then
        self.rankUpPending = false
        ctx.showRankUp(self.game)
      else
        self:close()
      end
    end
  end

  function Screen:draw()
    View.draw(self, mod.ui.Font, ctx.coins(self.game))
  end

  return Screen
end
