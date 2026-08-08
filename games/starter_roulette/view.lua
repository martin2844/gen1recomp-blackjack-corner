return function(UI)
  local View, C = {}, UI.colors
  local theme = { base = C.blueLight, header = C.gold, action = C.greenLight }

  local function label(pokemonData, species)
    local def = pokemonData and pokemonData[species]
    return (def and def.name) or species or "?"
  end

  local function card(Font, pokemonData, species, x, winner)
    UI.color(winner and C.gold or C.outline); UI.rect("fill", x, 37, 48, 60)
    UI.color(C.paper); UI.rect("fill", x + 2, 39, 44, 56)
    UI.color(C.green); love.graphics.circle("fill", x + 24, 61, 13)
    UI.color(C.paper); UI.rect("fill", x + 11, 59, 26, 4)
    UI.color(C.outline); love.graphics.circle("fill", x + 24, 61, 4)
    local name = label(pokemonData, species)
    while #name > 1 and Font.width(name) > 42 do name = name:sub(1, -2) end
    UI.color(C.ink); Font.draw(name, x + math.floor((48 - Font.width(name)) / 2), 82)
  end

  function View.draw(state, Font, pokemonData, Rules)
    UI.frame("STARTER ROULETTE", Font, nil, theme)
    if state.phase == "spinning" then
      UI.panel(5, 30, 150, 74, C.cream)
      love.graphics.setScissor(7, 32, 146, 70)
      for index, species in ipairs(state.strip or {}) do
        local x = 56 + (index - 1) * Rules.CARD_STEP - (state.reelOffset or 0)
        if x > -50 and x < 160 then card(Font, pokemonData, species, x, false) end
      end
      love.graphics.setScissor()
      UI.color(C.red); UI.rect("fill", 78, 27, 4, 9); UI.rect("fill", 78, 99, 4, 9)
      UI.color(C.ink); UI.centered(Font, "OAK'S RANDOMIZER", 113)
      UI.centered(Font, "NO TAKEBACKS", 128)
    else
      card(Font, pokemonData, state.playerStarter, 56, true)
      UI.color(C.ink); UI.centered(Font,
        state.phase == "result" and "YOUR STARTER!" or "STORAGE ERROR", 106)
      UI.centered(Font, state.message or label(pokemonData, state.playerStarter), 118)
      if state.phase == "result" then
        UI.centered(Font, "RIVAL: " .. label(pokemonData, state.rivalStarter), 128)
        UI.centered(Font, "A CONTINUE", 137)
      end
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  return View
end
