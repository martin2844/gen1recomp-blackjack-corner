return function(UI)
  local View, C = {}, UI.colors
  local theme = { base = C.blueLight, header = C.purple, action = C.gold }

  local function horse(x, y, color, stride)
    UI.color(color); UI.rect("fill", x + 2, y, 8, 5)
    UI.rect("fill", x + 8, y - 2, 4, 4)
    UI.color(C.ink); UI.rect("fill", x + 10, y - 1, 1, 1)
    UI.rect("fill", x, y + 1, 3, 2)
    if stride then
      UI.rect("fill", x + 3, y + 5, 2, 3); UI.rect("fill", x + 8, y + 5, 2, 2)
    else
      UI.rect("fill", x + 4, y + 5, 2, 2); UI.rect("fill", x + 9, y + 5, 2, 3)
    end
  end

  local function track(state, Font, Rules)
    UI.panel(8, 29, 144, 76, C.paper)
    local positions = state.race and Rules.positions(state.race) or { 0, 0, 0, 0 }
    for index, def in ipairs(Rules.HORSES) do
      local y = 37 + (index - 1) * 16
      UI.color(C.muted); UI.rect("fill", 33, y + 8, 108, 1)
      UI.color(C.ink); Font.draw(tostring(index), 13, y + 1)
      UI.color(C.gold); UI.rect("fill", 139, y - 1, 2, 12)
      local color = C[def.color] or C.red
      horse(33 + math.floor(94 * positions[index]), y, color,
        math.floor((state.race and state.race.elapsed or 0) * 8 + index) % 2 == 0)
    end
  end

  function View.draw(state, Font, coinCount, Rules)
    UI.frame("RACE TV", Font, coinCount, theme)
    if state.phase == "bet" then
      UI.panel(8, 29, 144, 70, C.paper)
      for index, horseDef in ipairs(Rules.HORSES) do
        local y = 35 + (index - 1) * 15
        if index == state.horseIndex then
          UI.color(C.goldLight); UI.rect("fill", 11, y - 2, 137, 13)
        end
        UI.color(C.ink)
        Font.draw((index == state.horseIndex and ">" or " ") .. horseDef.name, 14, y)
        local odds = tostring(horseDef.payout) .. "X"
        Font.draw(odds, 143 - Font.width(odds), y)
      end
      local bet = Rules.BETS[state.betIndex]
      UI.button(Font, "A BET " .. bet, 103, coinCount >= bet, theme)
      UI.color(C.ink); UI.centered(Font, state.notice or "UP DOWN HORSE", 126)
      UI.centered(Font, "L/R BET  B EXIT", 136)
    else
      track(state, Font, Rules)
      if state.phase == "racing" then
        UI.color(C.ink); UI.centered(Font, "COME ON " .. Rules.HORSES[state.horseIndex].name .. "!", 113)
      else
        local winner = Rules.HORSES[state.race.winner].name
        UI.color(C.ink); UI.centered(Font, winner .. " WINS!", 111)
        UI.centered(Font, state.payout > 0 and ("PAID " .. state.payout) or "YOU LOST", 122)
        UI.centered(Font, "A AGAIN  B EXIT", 134)
      end
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  return View
end
