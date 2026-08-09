return function(ctx)
  local mod, Rules, View = ctx.mod, ctx.rules, ctx.view
  local Screen = { isOpaque = true }
  Screen.__index = Screen

  function Screen.new(game, opts)
    return setmetatable({ game = game, onClose = opts and opts.onClose,
      phase = "bet", betIndex = 1 }, Screen)
  end

  function Screen:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end

  function Screen:close()
    ctx.close(self.game, self)
    if self.onClose then self.onClose() end
  end

  function Screen:dropBall()
    local bet = Rules.BETS[self.betIndex]
    if ctx.coins(self.game) < bet then self.notice = "NOT ENOUGH COINS"; return end
    self.game.save.coins = ctx.coins(self.game) - bet
    self.reputationRound = ctx.beginRound("plinko", bet)
    self.bet = bet
    self.drop = Rules.new(function(maximum) return love.math.random(1, maximum) end)
    self.phase, self.notice = "dropping", nil
    mod.save:set("plinko_drops", mod.save:get("plinko_drops", 0) + 1)
    ctx.play(self.game, "Slots_New_Spin")
  end

  function Screen:finish()
    self.payout = math.min(ctx.coinCap - ctx.coins(self.game),
      Rules.payout(self.bet, self.drop.slot))
    self.game.save.coins = ctx.coins(self.game) + self.payout
    local _, progress = ctx.settleRound(self.game, self.reputationRound,
      self.payout > self.bet and "win"
        or self.payout == self.bet and "draw" or "loss",
      self.payout)
    self.rankUpPending = progress and progress.rankUp
    self.phase = "result"
    mod.save:set("plinko_best", math.max(mod.save:get("plinko_best", 0), self.payout))
    ctx.play(self.game, self.payout >= self.bet and "Slots_Reward" or "Slots_Stop_Wheel")
  end

  function Screen:update(dt)
    local input = self.game.input
    if self.phase == "bet" then
      if input:wasPressed("left") then
        self.betIndex = self.betIndex > 1 and self.betIndex - 1 or #Rules.BETS
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("right") then
        self.betIndex = self.betIndex < #Rules.BETS and self.betIndex + 1 or 1
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("a") then self:dropBall()
      elseif input:wasPressed("b") then self:close() end
    elseif self.phase == "dropping" then
      if Rules.update(self.drop, math.min(0.05, dt or 1 / 60)) then self:finish() end
    elseif input:wasPressed("a") then
      if self.rankUpPending and ctx.showRankUp then
        self.rankUpPending = false; ctx.showRankUp(self.game)
      else self.phase, self.notice = "bet", nil end
    elseif input:wasPressed("b") then
      if self.rankUpPending and ctx.showRankUp then
        self.rankUpPending = false; ctx.showRankUp(self.game)
      else self:close() end
    end
  end

  function Screen:draw()
    View.draw(self, mod.ui.Font, ctx.coins(self.game), Rules)
  end

  return Screen
end
