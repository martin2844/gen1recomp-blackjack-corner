return function(ctx)
  local mod, Rules, View, CardView = ctx.mod, ctx.rules, ctx.view, ctx.cardView
  local bets = ctx.bets
  local Screen = { isOpaque = true }
  Screen.__index = Screen

  function Screen.new(game, opts)
    return setmetatable({ game = game, onClose = opts and opts.onClose,
      phase = "bet", betIndex = 1, actionIndex = 1, settled = false }, Screen)
  end

  function Screen:close()
    ctx.close(self.game, self)
    if self.onClose then self.onClose() end
  end

  function Screen:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end

  function Screen:actions()
    if not self.round or self.round.state ~= "playing" then return {} end
    local base = self.round.start
    if self.round.phase == "preflop" then
      return {
        { label = "CHECK", kind = "check", enabled = true },
        { label = "BET 3X", kind = "bet", multiplier = 3,
          enabled = ctx.coins(self.game) >= base * 3 },
        { label = "BET 4X", kind = "bet", multiplier = 4,
          enabled = ctx.coins(self.game) >= base * 4 },
      }
    elseif self.round.phase == "flop" then
      return {
        { label = "CHECK", kind = "check", enabled = true },
        { label = "BET 2X", kind = "bet", multiplier = 2,
          enabled = ctx.coins(self.game) >= base * 2 },
      }
    end
    return {
      { label = "CHECK", kind = "check", enabled = true },
      { label = "BET 1X", kind = "bet", multiplier = 1,
        enabled = ctx.coins(self.game) >= base },
    }
  end

  function Screen:deal()
    local startingBet = bets[self.betIndex]
    if ctx.coins(self.game) < startingBet then
      self.notice = ("NEED %d COINS"):format(startingBet)
      return
    end
    self.notice = nil
    self.game.save.coins = ctx.coins(self.game) - startingBet
    self.reputationRound = ctx.beginRound("holdem", startingBet)
    self.round = Rules.newRound(startingBet, Rules.newDeck(function(n)
      return love.math.random(1, n)
    end))
    self.phase, self.actionIndex, self.settled = "play", 1, false
    ctx.play(self.game, "Slots_New_Spin")
  end

  function Screen:recordRound()
    if self.settled or not self.round or self.round.state ~= "done" then return end
    self.settled = true
    local returned = ctx.creditPayout(self.game, self.round.payout)
    local _, progress = ctx.settleRound(self.game, self.reputationRound,
      self.round.result == "win" and "win"
        or self.round.result == "push" and "draw" or "loss",
      returned)
    self.rankUpPending = progress and progress.rankUp
    mod.save:set("holdem_hands_played", mod.save:get("holdem_hands_played", 0) + 1)
    if self.round.result == "win" then
      mod.save:set("holdem_hands_won", mod.save:get("holdem_hands_won", 0) + 1)
    end
    if self.round.playerEval and self.round.playerEval.name == "ROYAL FLUSH" then
      mod.save:set("holdem_royals", mod.save:get("holdem_royals", 0) + 1)
    end
    self.phase = "result"
    ctx.play(self.game,
      self.round.result == "win" and "Slots_Reward" or "Slots_Stop_Wheel")
  end

  function Screen:moveAction(direction)
    local actions = self:actions()
    if #actions == 0 then return end
    local nextIndex = self.actionIndex
    repeat nextIndex = ((nextIndex - 1 + direction) % #actions) + 1
    until actions[nextIndex].enabled ~= false or nextIndex == self.actionIndex
    self.actionIndex = nextIndex
  end

  function Screen:chooseAction(index)
    local action = self:actions()[index or self.actionIndex]
    if not action or action.enabled == false then
      self.notice = "NOT ENOUGH COINS"
      return
    end
    self.notice = nil
    if action.kind == "check" then
      Rules.check(self.round)
    else
      local wager = self.round.start * action.multiplier
      self.game.save.coins = ctx.coins(self.game) - wager
      ctx.increaseStake(self.reputationRound, wager)
      Rules.bet(self.round, action.multiplier)
    end
    if self.round.state == "playing" then
      self.actionIndex = 1
      ctx.play(self.game, "Slots_Stop_Wheel")
      return
    end
    self:recordRound()
  end

  function Screen:update()
    local input = self.game.input
    if self.phase == "bet" then
      if input:wasPressed("left") then
        self.betIndex = self.betIndex > 1 and self.betIndex - 1 or #bets
        self.notice = nil
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("right") then
        self.betIndex = self.betIndex < #bets and self.betIndex + 1 or 1
        self.notice = nil
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("a") then self:deal()
      elseif input:wasPressed("b") then self:close() end
    elseif self.phase == "play" then
      if input:wasPressed("left") then self:moveAction(-1); ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("right") then self:moveAction(1); ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("a") then self:chooseAction()
      elseif input:wasPressed("b") then self:chooseAction(1) end
    elseif self.phase == "result" then
      if input:wasPressed("a") then
        if self.rankUpPending and ctx.showRankUp then
          self.rankUpPending = false; ctx.showRankUp(self.game)
        else
          self.phase, self.round, self.notice, self.actionIndex = "bet", nil, nil, 1
          ctx.play(self.game, "Press_AB")
        end
      elseif input:wasPressed("b") then
        if self.rankUpPending and ctx.showRankUp then
          self.rankUpPending = false; ctx.showRankUp(self.game)
        else self:close() end
      end
    end
  end

  function Screen:draw()
    View.draw({ phase = self.phase, betIndex = self.betIndex,
      actionIndex = self.actionIndex, round = self.round,
      actions = self:actions(), notice = self.notice },
      mod.ui.Font, Rules, CardView, ctx.coins(self.game), bets)
  end

  return Screen
end
