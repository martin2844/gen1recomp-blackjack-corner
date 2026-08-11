return function(UI)
  local View, C = {}, UI.colors
  local theme = { base = { 0.12, 0.10, 0.16 }, header = C.red, action = C.gold }
  local ARROW_CODE = 0xED

  -- Gen I ships one solid triangle glyph. Rotating that exact font tile keeps
  -- all four directions crisp and native instead of falling back to letters
  -- or unsupported Unicode arrows.
  local function arrow(Font, x, y, angle)
    love.graphics.push()
    love.graphics.translate(x + 4, y + 4)
    love.graphics.rotate(angle)
    Font.drawCode(ARROW_CODE, -4, -4)
    love.graphics.pop()
  end

  local function controlHint(Font)
    arrow(Font, 24, 130, -math.pi / 2)
    arrow(Font, 32, 130, math.pi / 2)
    Font.draw("PICK", 44, 130)
    arrow(Font, 92, 130, math.pi)
    arrow(Font, 100, 130, 0)
    Font.draw("BET", 112, 130)
  end

  local function drawCrowd()
    UI.color({ 0.07, 0.06, 0.10 }); UI.rect("fill", 7, 56, 146, 14)
    for col = 0, 14 do
        local x, y = 8 + col * 10, 58
        UI.color(col % 3 == 0 and C.purple or C.outline)
        UI.rect("fill", x + 2, y, 4, 4)
        UI.rect("fill", x, y + 4, 8, 6)
    end
    UI.color(C.gold); UI.rect("fill", 7, 68, 146, 2)
  end

  local function hpBar(x, y, width, current, maximum)
    local ratio = math.max(0, math.min(1, current / math.max(1, maximum)))
    UI.color(C.outline); UI.rect("fill", x, y, width, 6)
    local color = ratio > 0.5 and C.green or (ratio > 0.2 and C.gold or C.red)
    UI.color(color); UI.rect("fill", x + 1, y + 1,
      math.floor((width - 2) * ratio), 4)
  end

  local function fighterImage(state, index, x, y, width, height, mirror, offset)
    local image = state.images and state.images[index]
    if not image then
      UI.color(index == 1 and C.redLight or C.blueLight)
      UI.rect("fill", x + 10, y + 10, width - 20, height - 16)
      return
    end
    local iw, ih = image:getDimensions()
    local scale = math.min(width / iw, height / ih)
    local drawW, drawH = iw * scale, ih * scale
    local dx, dy = x + math.floor((width - drawW) / 2), y + height - drawH
    dx = dx + (offset or 0)
    love.graphics.setColor(1, 1, 1, 1)
    if mirror then love.graphics.draw(image, dx + drawW, dy, 0, -scale, scale)
    else love.graphics.draw(image, dx, dy, 0, scale, scale) end
  end

  local function matchup(state, Font, Rules, interactive)
    local match = state.pending.match
    local left, right = match.fighters[1], match.fighters[2]
    UI.color({ 0.07, 0.06, 0.10 }); UI.rect("fill", 7, 25, 146, 88)
    UI.color(interactive and state.selected == 1 and C.goldLight or C.blueLight)
    UI.rect("fill", 8, 27, 144, 13)
    UI.color(interactive and state.selected == 2 and C.goldLight or C.blueLight)
    UI.rect("fill", 8, 42, 144, 13)
    local leftLabel = "1 " .. left.name:sub(1, 8)
    local rightLabel = "2 " .. right.name:sub(1, 8)
    UI.color(C.ink)
    Font.draw(leftLabel, 10, 29)
    Font.draw(rightLabel, 10, 44)
    if interactive then
      local lo, ro = Rules.formatOdds(match.odds[1]), Rules.formatOdds(match.odds[2])
      Font.draw(lo, 150 - Font.width(lo), 29)
      Font.draw(ro, 150 - Font.width(ro), 44)
    else
      hpBar(96, 30, 54, state.hp[1], left.maxHP)
      hpBar(96, 45, 54, state.hp[2], right.maxHP)
    end
    drawCrowd()
    UI.color({ 0.26, 0.18, 0.24 }); UI.rect("fill", 8, 70, 144, 43)
    UI.color(C.cream); UI.rect("fill", 8, 111, 144, 2)
    UI.color(C.cream)
    Font.draw("L" .. left.level, 11, 72)
    local rightLevel = "L" .. right.level
    Font.draw(rightLevel, 149 - Font.width(rightLevel), 72)
    local leftOffset, rightOffset = 0, 0
    if state.phase == "battle" and state.currentAction then
      local pulse = math.sin(math.min(1, state.actionTimer / Rules.ACTION_TIME) * math.pi)
      if state.currentAction.attacker == 1 then leftOffset = math.floor(pulse * 5)
      else rightOffset = -math.floor(pulse * 5) end
    end
    fighterImage(state, 1, 11, 75, 64, 35, true, leftOffset)
    fighterImage(state, 2, 84, 75, 64, 35, false, rightOffset)
  end

  local function attackLabel(Font, name, move)
    name, move = tostring(name or ""), tostring(move or "ATTACK")
    local line = name .. " " .. move
    while #name > 0 and Font.width(line) > 140 do
      name = name:sub(1, #name - 1)
      line = name ~= "" and (name .. " " .. move) or move
    end
    return line
  end

  function View.draw(state, Font, coinCount, Rules)
    UI.frame("ROCKET ARENA", Font, coinCount, theme)
    if not state.pending then
      UI.panel(10, 35, 140, 70, C.paper)
      UI.color(C.ink); UI.centered(Font, state.notice or "NO MATCH POSTED", 62)
      UI.centered(Font, "B EXIT", 89)
      return
    end

    if state.phase == "bet" then
      matchup(state, Font, Rules, true)
      local bet = state.bets[state.betIndex] or 0
      UI.button(Font, "A BET " .. bet, 106, coinCount >= bet, theme)
      UI.color(C.blueLight); UI.rect("fill", 8, 128, 144, 12)
      UI.color(C.ink)
      if state.notice then UI.centered(Font, state.notice, 130)
      else controlHint(Font) end
    elseif state.phase == "intro" then
      matchup(state, Font, Rules, false)
      UI.color(C.blueLight); UI.rect("fill", 8, 115, 144, 25)
      UI.color(C.ink); UI.centered(Font, "MATCH START", 119)
      UI.centered(Font, "NO REFUNDS", 130)
    elseif state.phase == "battle" then
      matchup(state, Font, Rules, false)
      local action = state.currentAction
      local line = "THE CROWD ROARS"
      if action then
        local name = state.pending.match.fighters[action.attacker].name
        if action.suddenDeath then line = "SUDDEN DEATH"
        elseif action.missed then line = name .. " MISSED"
        elseif action.immune then line = "NO EFFECT"
        else line = attackLabel(Font, name, action.move) end
      end
      UI.color(C.blueLight); UI.rect("fill", 8, 115, 144, 25)
      UI.color(C.ink); UI.centered(Font, line, 119)
      if action and action.damage > 0 then
        UI.centered(Font, tostring(action.damage) .. " DAMAGE", 130)
      else UI.centered(Font, "WATCH THE FIGHT", 130) end
    else
      matchup(state, Font, Rules, false)
      UI.panel(16, 86, 128, 50, C.paper)
      local winner = state.pending.match.fighters[state.pending.match.winner].name
      UI.color(C.ink); UI.centered(Font, winner .. " WINS", 93)
      UI.centered(Font, state.pending.won and ("PAID " .. state.pending.payout)
        or "WAGER LOST", 105)
      UI.centered(Font, state.pending.won and "THE HOUSE NOTICED" or "NEXT FIGHT?", 117)
      UI.centered(Font, "A NEXT  B EXIT", 128)
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  return View
end
