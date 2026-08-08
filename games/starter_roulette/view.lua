return function(UI)
  local View, C = {}, UI.colors
  local theme = { base = C.blueLight, header = C.gold, action = C.greenLight }
  View.RESULT_BUTTON_Y = 113
  View.RESULT_BUTTON_HEIGHT = 22
  View.FRAME_CONTENT_BOTTOM = 138

  local function label(pokemonData, species)
    local def = pokemonData and pokemonData[species]
    return (def and def.name) or species or "?"
  end

  local function card(Font, pokemonData, species, x, y, height, winner)
    local width, centerY = 48, y + 24
    UI.color(winner and C.gold or C.outline); UI.rect("fill", x, y, width, height)
    UI.color(C.paper); UI.rect("fill", x + 2, y + 2, width - 4, height - 4)
    UI.color(C.green); love.graphics.circle("fill", x + 24, centerY, 11)
    UI.color(C.paper); UI.rect("fill", x + 12, centerY - 2, 24, 4)
    UI.color(C.outline); love.graphics.circle("fill", x + 24, centerY, 4)
    local name = label(pokemonData, species)
    while #name > 1 and Font.width(name) > 42 do name = name:sub(1, -2) end
    UI.color(C.ink)
    Font.draw(name, x + math.floor((width - Font.width(name)) / 2), y + height - 13)
  end

  local function choiceButton(Font, labelText, x, width, selected, enabled)
    local y = View.RESULT_BUTTON_Y
    UI.color(C.outline); UI.rect("fill", x, y + 2, width, 20)
    UI.color(not enabled and C.muted or selected and C.goldLight or C.blueLight)
    UI.rect("fill", x, y, width, 19)
    UI.color(C.paper); UI.rect("line", x + 3, y + 3, width - 6, 13)
    UI.color(C.ink)
    Font.draw(labelText, x + math.floor((width - Font.width(labelText)) / 2), y + 6)
  end

  function View.draw(state, Font, pokemonData, Rules)
    UI.frame("STARTER ROULETTE", Font, nil, theme)
    if state.phase == "spinning" then
      UI.panel(5, 30, 150, 74, C.cream)
      love.graphics.setScissor(7, 32, 146, 70)
      for index, species in ipairs(state.strip or {}) do
        local x = 56 + (index - 1) * Rules.CARD_STEP - (state.reelOffset or 0)
        if x > -50 and x < 160 then
          card(Font, pokemonData, species, x, 37, 60, false)
        end
      end
      love.graphics.setScissor()
      UI.color(C.red); UI.rect("fill", 78, 27, 4, 9); UI.rect("fill", 78, 99, 4, 9)
      UI.color(C.ink); UI.centered(Font, "OAK'S RANDOMIZER", 113)
      UI.centered(Font, "NO TAKEBACKS", 128)
    elseif state.phase == "offer" then
      card(Font, pokemonData, state.playerStarter, 56, 29, 55, true)
      UI.color(C.ink); UI.centered(Font, "KEEP THIS STARTER?", 88)
      if state.message then
        UI.color(C.red); UI.centered(Font, state.message, 100)
      else
        UI.centered(Font, "MONEY ¥" .. math.floor(state.game.save.money or 0), 100)
      end
      local canRespin = state:canRespin()
      choiceButton(Font, "KEEP", 8, 52, state.choice == 1, true)
      choiceButton(Font, "SPIN ¥1000", 64, 88, state.choice == 2, canRespin)
    else
      card(Font, pokemonData, state.playerStarter, 56, 29, 55, true)
      UI.color(C.ink)
      if state.phase == "result" then
        UI.centered(Font, "STARTER ACCEPTED!", 88)
        UI.centered(Font, "RIVAL: " .. label(pokemonData, state.rivalStarter), 100)
        UI.button(Font, "A CONTINUE", View.RESULT_BUTTON_Y, true, theme)
      else
        UI.centered(Font, "STORAGE ERROR", 92)
        UI.centered(Font, state.message or "NO STORAGE", 104)
        UI.button(Font, "A CLOSE", View.RESULT_BUTTON_Y, true, theme)
      end
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  return View
end
