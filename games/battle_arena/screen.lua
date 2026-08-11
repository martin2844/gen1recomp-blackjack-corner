return function(ctx)
  local mod, Rules, View, Service = ctx.mod, ctx.rules, ctx.view, ctx.service
  local Screen = { isOpaque = true }
  Screen.__index = Screen

  local function loadImages(game, pending)
    local images = {}
    if not pending or not pending.match then return images end
    local Sprites = require("src.pokemon.Sprites")
    for index, fighter in ipairs(pending.match.fighters) do
      local path = Sprites.path(game.data, fighter.species, "front", { kind = "arena" })
      if path then
        local ok, image = pcall(love.graphics.newImage, path)
        if ok then images[index] = image end
      end
    end
    return images
  end

  function Screen.new(game, opts)
    local self = setmetatable({ game = game, onClose = opts and opts.onClose,
      selected = 1, betIndex = 1, notice = nil, hp = { 1, 1 } }, Screen)
    local pending, reason = Service.current(game,
      function(maximum) return love.math.random(1, maximum) end)
    self.pending, self.notice = pending, reason
    self.bets = Rules.availableBets((Service.snapshot(game) or {}).rank)
    if pending then
      self.images = loadImages(game, pending)
      local fighters = pending.match.fighters
      self.hp = { fighters[1].maxHP, fighters[2].maxHP }
      if pending.status == "BET" then self.phase = "intro"
      elseif pending.status == "RESULT" then
        self.phase = "result"
        self.hp[pending.match.winner], self.hp[3 - pending.match.winner] =
          pending.match.fighters[pending.match.winner].maxHP, 0
      else self.phase = "bet" end
    else self.phase = "blocked" end
    return self
  end

  function Screen:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end

  function Screen:close()
    ctx.close(self.game, self)
    if self.onClose then self.onClose() end
  end

  function Screen:startBattle()
    local stake = self.bets[self.betIndex]
    local ok, pending = Service.placeBet(self.game, self.selected, stake)
    if not ok then self.notice = pending; return end
    self.pending, self.phase, self.notice = pending, "intro", nil
    self.elapsed, self.actionIndex, self.actionTimer = 0, 0, 0
    local fighters = pending.match.fighters
    self.hp = { fighters[1].maxHP, fighters[2].maxHP }
    ctx.play(self.game, "Slots_New_Spin")
  end

  function Screen:finishBattle()
    local ok, pending = Service.settle(self.game)
    if not ok then self.notice, self.phase = pending, "blocked" return end
    self.pending, self.phase = pending, "result"
    if pending.won then ctx.play(self.game, "Slots_Reward")
    else ctx.play(self.game, "Slots_Stop_Wheel") end
  end

  function Screen:nextMatch()
    local rankUp = self.pending and self.pending.rankUp
    local exhibitionWon = self.pending and self.pending.kind == "EXHIBITION"
      and self.pending.won == true
    Service.acknowledge()
    if exhibitionWon then
      self:close()
      if rankUp and ctx.showRankUp then ctx.showRankUp(self.game) end
      return
    end
    if rankUp and ctx.showRankUp then
      self:close(); ctx.showRankUp(self.game); return
    end
    local pending, reason = Service.current(self.game,
      function(maximum) return love.math.random(1, maximum) end)
    self.pending, self.notice, self.phase = pending, reason, pending and "bet" or "blocked"
    self.selected, self.betIndex = 1, 1
    self.images = loadImages(self.game, pending)
    if pending then
      self.hp = { pending.match.fighters[1].maxHP, pending.match.fighters[2].maxHP }
    end
  end

  function Screen:update(dt)
    local input = self.game.input
    if self.phase == "bet" then
      if input:wasPressed("up") or input:wasPressed("down") then
        self.selected = 3 - self.selected; self.notice = nil
        ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("right") then
        self.betIndex = self.betIndex < #self.bets and self.betIndex + 1 or 1
        self.notice = nil; ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("left") then
        self.betIndex = self.betIndex > 1 and self.betIndex - 1 or #self.bets
        self.notice = nil; ctx.play(self.game, "Press_AB")
      elseif input:wasPressed("a") then self:startBattle()
      elseif input:wasPressed("b") then self:close() end
    elseif self.phase == "intro" then
      self.elapsed = (self.elapsed or 0) + math.min(0.05, dt or 1 / 60)
      if self.elapsed >= Rules.INTRO_TIME then
        self.phase, self.actionTimer, self.actionIndex = "battle", 0, 1
        self.currentAction = self.pending.match.actions[1]
      end
    elseif self.phase == "battle" then
      self.actionTimer = self.actionTimer + math.min(0.05, dt or 1 / 60)
      if self.actionTimer >= Rules.ACTION_TIME then
        local action = self.currentAction
        if action then self.hp[action.defender] = action.defenderHP end
        self.actionIndex, self.actionTimer = self.actionIndex + 1, 0
        self.currentAction = self.pending.match.actions[self.actionIndex]
        if not self.currentAction then self:finishBattle() end
      end
    elseif self.phase == "result" then
      if input:wasPressed("a") then self:nextMatch()
      elseif input:wasPressed("b") then
        local rankUp = self.pending and self.pending.rankUp
        Service.acknowledge()
        self:close()
        if rankUp and ctx.showRankUp then ctx.showRankUp(self.game) end
      end
    elseif input:wasPressed("b") then self:close() end
  end

  function Screen:draw()
    View.draw(self, mod.ui.Font, ctx.coins(self.game), Rules)
  end

  return Screen
end
