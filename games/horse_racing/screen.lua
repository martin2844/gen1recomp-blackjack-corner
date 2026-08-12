return function(ctx)
  local mod, Rules, View = ctx.mod, ctx.rules, ctx.view
  local Screen = { isOpaque = true }
  Screen.__index = Screen

  function Screen.new(game, opts)
    return setmetatable({ game = game, onClose = opts and opts.onClose,
      phase = "bet", horseIndex = 1, betIndex = 1 }, Screen)
  end

  function Screen:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end

  function Screen:close()
    ctx.close(self.game, self)
    if self.onClose then self.onClose() end
  end

  function Screen:start()
    local bet = Rules.BETS[self.betIndex]
    if ctx.coins(self.game) < bet then self.notice = "NOT ENOUGH COINS"; return end
    self.game.save.coins = ctx.coins(self.game) - bet
    self.reputationRound = ctx.beginRound("horse_racing", bet)
    self.bet = bet
    self.race = Rules.new(function(maximum) return love.math.random(1, maximum) end)
    self.phase, self.notice, self.payout = "racing", nil, nil
    mod.save:set("horse_races", mod.save:get("horse_races", 0) + 1)
    ctx.play(self.game, "Slots_New_Spin")
  end

  function Screen:finish()
    self.payout = ctx.creditPayout(self.game,
      Rules.payout(self.bet, self.horseIndex, self.race.winner))
    local _, progress = ctx.settleRound(self.game, self.reputationRound,
      self.payout > 0 and "win" or "loss", self.payout)
    self.rankUpPending = progress and progress.rankUp
    self.phase = "result"
    if self.payout > 0 then
      mod.save:set("horse_wins", mod.save:get("horse_wins", 0) + 1)
      ctx.play(self.game, "Slots_Reward")
    else
      ctx.play(self.game, "Slots_Stop_Wheel")
    end
  end

  function Screen:update(dt)
    local input = self.game.input
    if self.phase == "bet" then
      if input:wasPressed("up") then
        self.horseIndex = self.horseIndex > 1 and self.horseIndex - 1 or #Rules.HORSES
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("down") then
        self.horseIndex = self.horseIndex < #Rules.HORSES and self.horseIndex + 1 or 1
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("left") then
        self.betIndex = self.betIndex > 1 and self.betIndex - 1 or #Rules.BETS
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("right") then
        self.betIndex = self.betIndex < #Rules.BETS and self.betIndex + 1 or 1
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("a") then self:start()
      elseif input:wasPressed("b") then self:close() end
    elseif self.phase == "racing" then
      local step = ctx.revealStep and ctx.revealStep(dt)
        or math.min(0.05, dt or 1 / 60)
      if Rules.update(self.race, step) then self:finish() end
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
