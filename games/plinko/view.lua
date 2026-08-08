return function(UI)
  local View, C = {}, UI.colors
  local theme = { base = C.goldLight, header = C.green, action = C.redLight }

  local function board(state, Rules)
    UI.panel(11, 28, 138, 89, C.blueLight)
    for row = 0, Rules.ROWS - 1 do
      local y = 35 + row * 9
      for peg = 0, row do
        local x = 80 + (peg * 10) - row * 5
        UI.color(C.paper); love.graphics.circle("fill", x, y, 2)
        UI.color(C.outline); love.graphics.circle("line", x, y, 2)
      end
    end
    for slot = 1, 9 do
      local x = 35 + (slot - 1) * 11
      UI.color((slot == 1 or slot == 9) and C.red or C.gold)
      UI.rect("fill", x, 105, 9, 9)
    end
    if state.drop then
      local row, offset = Rules.ball(state.drop)
      local x, y = 80 + offset * 5, 31 + row * 9
      UI.color(C.red); love.graphics.circle("fill", x, y, 4)
      UI.color(C.paper); love.graphics.circle("fill", x - 1, y - 1, 1)
    else
      UI.color(C.red); love.graphics.circle("fill", 80, 31, 4)
    end
  end

  function View.draw(state, Font, coinCount, Rules)
    UI.frame("PLINKO", Font, coinCount, theme)
    board(state, Rules)
    if state.phase == "bet" then
      local bet = Rules.BETS[state.betIndex]
      UI.button(Font, "A DROP " .. bet, 117, coinCount >= bet, theme)
      UI.color(C.ink); UI.centered(Font, state.notice or "L/R BET  B EXIT", 137)
    elseif state.phase == "dropping" then
      UI.color(C.ink); UI.centered(Font, "BOUNCE...", 124)
    else
      local mult = Rules.MULTIPLIERS_X100[state.drop.slot] / 100
      UI.panel(23, 116, 114, 24, C.paper)
      UI.color(C.ink); UI.centered(Font,
        string.format("%gX  PAID %d", mult, state.payout), 120)
      UI.centered(Font, "A AGAIN  B EXIT", 131)
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  return View
end
