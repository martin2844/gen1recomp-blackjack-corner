return function(mod, Service, Catalog, Pawn, config)
  local UI = {}

  local function balanceBox(game)
    local Font = mod.ui.Font
    return { draw = function()
      Font.drawBox(11, 0, 9, 7)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw("MONEY", 96, 16)
      local money = ("¥%d"):format(tonumber(game.save.money) or 0)
      Font.draw(money, 152 - Font.width(money), 24)
      Font.draw("COIN", 96, 32)
      local count = tostring(Service.coins(game))
      Font.draw(count, 152 - Font.width(count), 40)
      love.graphics.setColor(1, 1, 1, 1)
    end }
  end

  function UI.text(game, message, onDone)
    game.stack:push(mod.ui.TextBox.new(game, message, onDone))
  end

  function UI.close(game, state)
    if game.stack:top() == state then game.stack:pop() end
  end

  function UI.openAfterMessage(game, message, screen, done, showMessage)
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      UI.text(game, "A COIN CASE is\nrequired!", done)
      return
    end
    local function launch()
      mod.ui.push(game, screen, { onClose = done })
    end
    if showMessage == false then launch() else UI.text(game, message, launch) end
  end

  local function buyCoins(game, done)
    local coinBox = balanceBox(game)
    game.stack:push(coinBox)
    local function finish()
      UI.close(game, coinBox)
      if done then done() end
    end
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      UI.text(game, "You don't have a\nCOIN CASE!", finish)
      return
    end
    if Service.coins(game) >= config.coinCap then
      UI.text(game, "Oops! Your COIN\nCASE is full.", finish)
      return
    end
    if (tonumber(game.save.money) or 0) < config.coinBundlePrice then
      UI.text(game, "You can't afford\nthe coins!", finish)
      return
    end
    UI.text(game, "¥1000 buys 50\nGame Corner coins.\fHow many would\nyou like?", function()
      local rows = {}
      for _, offer in ipairs(Service.coinOffers(game)) do
        rows[#rows + 1] = { label = offer.label, right = "¥" .. offer.cost,
          value = offer }
      end
      local list
      list = mod.ui.ListMenu.new(game, "BUY COINS", rows, {
        wrap = true,
        footer = ("MONEY ¥%d\nCOIN %d"):format(
          tonumber(game.save.money) or 0, Service.coins(game)),
        onChoose = function(item)
          list:close()
          local _, message = Service.buyCoins(game, item.value.amount)
          UI.text(game, message, finish)
        end,
        onCancel = finish,
      })
      game.stack:push(list)
    end)
  end

  local function cashOutCoins(game, done)
    local coinBox = balanceBox(game)
    game.stack:push(coinBox)
    local function finish()
      UI.close(game, coinBox)
      if done then done() end
    end
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      UI.text(game, "You don't have a\nCOIN CASE!", finish)
      return
    end
    local offers = Service.cashOutOffers(game)
    if #offers == 0 then
      local message = Service.coins(game) < config.coinBundle
        and ("You need at least\n%d coins."):format(config.coinBundle)
        or "Your wallet can't\nhold another ¥1000."
      UI.text(game, message, finish)
      return
    end
    UI.text(game, "50 coins cash out\nfor ¥1000.\fHow many would\nyou like?", function()
      local rows = {}
      for _, offer in ipairs(offers) do
        rows[#rows + 1] = { label = offer.label, right = "¥" .. offer.payout,
          value = offer }
      end
      local list
      list = mod.ui.ListMenu.new(game, "CASH OUT", rows, {
        wrap = true,
        footer = ("MONEY ¥%d\nCOIN %d"):format(
          tonumber(game.save.money) or 0, Service.coins(game)),
        onChoose = function(item)
          list:close()
          local _, message = Service.cashOutCoins(game, item.value.amount)
          UI.text(game, message, finish)
        end,
        onCancel = finish,
      })
      game.stack:push(list)
    end)
  end

  local function localPokemonPrizes()
    local GameVersion = require("src.core.GameVersion")
    local prizes = {}
    for _, prize in ipairs(Catalog.pokemon(GameVersion.get())) do
      if prize.cost <= 800 or prize.species == "DRATINI" then
        prizes[#prizes + 1] = prize
      end
    end
    return prizes
  end

  function UI.coinClerk(game, _, _, done)
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      UI.text(game, "You don't have a\nCOIN CASE!", done)
      return
    end
    local openMenu
    local function openPrizes()
      game.stack:push(UI.pokemonMenu(game, {
        title = "LOCAL PRIZES",
        prizes = localPokemonPrizes(),
        onClose = openMenu,
      }))
    end
    function openMenu()
      game.stack:push(mod.ui.Menu.new(game, {
        { label = "BUY COINS", onSelect = function() buyCoins(game, openMenu) end },
        { label = "CASH OUT", onSelect = function() cashOutCoins(game, openMenu) end },
        { label = "REDEEM POKEMON", onSelect = openPrizes },
        { label = "LEAVE", onSelect = done },
      }, { tx = 1, ty = 2, maxVisible = 4, onCancel = done }))
    end
    openMenu()
  end

  function UI.pawnBroker(game, _, _, done)
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      UI.text(game, "No COIN CASE?\nNo business.", done)
      return
    end
    local openMenu
    local function showPawnList()
      local party = game.save.party or {}
      if #party <= 1 then
        UI.text(game, "You must keep one\nPOKEMON with you.", openMenu)
        return
      end
      local rows = {}
      for index, mon in ipairs(party) do
        local def = game.data.pokemon[mon.species]
        if def then rows[#rows + 1] = { label = Service.monName(game, mon),
          right = tostring(Pawn.value(mon, def)), value = index } end
      end
      local list
      list = mod.ui.ListMenu.new(game, "PAWN POKEMON", rows, {
        pageJump = true,
        footer = ("COINS %d  HELD %d/%d"):format(
          Service.coins(game), #Service.pawnLedger(), Pawn.LIMIT),
        onChoose = function(item)
          local mon = party[item.value]
          local def = mon and game.data.pokemon[mon.species]
          if not def then return end
          local name, value = Service.monName(game, mon), Pawn.value(mon, def)
          local prompt = ("Pawn %s for\n%d coins?"):format(name, value)
          if #Service.pawnLedger() >= Pawn.LIMIT then
            local oldest = Service.pawnLedger()[1]
            prompt = prompt .. ("\fOLDEST %s\nWILL BE SOLD."):format(oldest.name)
          end
          list:close()
          game.stack:push(mod.ui.TextBox.new(game, prompt, nil, {
            choice = function(yes)
              if not yes then openMenu(); return end
              local ok, entry, sold = Service.pawnPokemon(game, item.value)
              if not ok then UI.text(game, entry, openMenu); return end
              local message = ("%s pawned.\nYou got %d coins."):format(entry.name, entry.value)
              if sold then message = message .. ("\f%s was sold off.")
                :format(sold.name or "The oldest POKEMON") end
              UI.text(game, message, openMenu)
            end,
          }))
        end,
        onCancel = openMenu,
      })
      game.stack:push(list)
    end

    local function showRedeemList()
      local ledger = Service.pawnLedger()
      if #ledger == 0 then UI.text(game, "Nothing is in\npawn.", openMenu); return end
      local rows = {}
      for index, entry in ipairs(ledger) do rows[#rows + 1] = {
        label = entry.name or Service.monName(game, entry.mon),
        right = tostring(entry.redeem or Pawn.redeemCost(entry.value)), value = index }
      end
      local list
      list = mod.ui.ListMenu.new(game, "REDEEM POKEMON", rows, {
        pageJump = true,
        footer = ("COINS %d  HELD %d/%d"):format(
          Service.coins(game), #ledger, Pawn.LIMIT),
        onChoose = function(item)
          local entry = ledger[item.value]
          if not entry then return end
          local cost = entry.redeem or Pawn.redeemCost(entry.value)
          list:close()
          game.stack:push(mod.ui.TextBox.new(game,
            ("Pay %d coins to\nget %s back?"):format(cost, entry.name or "POKEMON"), nil, {
              choice = function(yes)
                if not yes then openMenu(); return end
                local ok, result, paid, destination = Service.redeemPokemon(game, item.value)
                if not ok then UI.text(game, result, openMenu); return end
                UI.text(game, ("%s returned to\nyour %s for %d.")
                  :format(result.name, destination, paid), openMenu)
              end,
            }))
        end,
        onCancel = openMenu,
      })
      game.stack:push(list)
    end

    function openMenu()
      game.stack:push(mod.ui.Menu.new(game, {
        { label = "PAWN POKEMON", onSelect = showPawnList },
        { label = "REDEEM", onSelect = showRedeemList },
        { label = "LEAVE", onSelect = done },
      }, { tx = 2, ty = 3, maxVisible = 3, onCancel = done }))
    end
    UI.text(game, "Need coins?\nI take POKEMON.\fBuy them back for\n30% more.", openMenu)
  end

  local function finishPrize(game, list, ok, message, done, mon)
    if ok then UI.close(game, list) end
    local function afterMessage()
      if mon then Service.askNickname(game, mon, done)
      elseif done then done() end
    end
    UI.text(game, message, ok and afterMessage or nil)
  end

  function UI.pokemonMenu(game, opts)
    local GameVersion = require("src.core.GameVersion")
    local rows = {}
    for _, prize in ipairs((opts and opts.prizes)
        or Catalog.pokemon(GameVersion.get())) do
      local def = game.data.pokemon[prize.species]
      if def then rows[#rows + 1] = { label = def.name or prize.species,
        right = tostring(prize.cost), value = prize } end
    end
    local list
    list = mod.ui.ListMenu.new(game, (opts and opts.title) or "POKEMON PRIZES", rows, {
      pageJump = true, footer = ("COINS %d"):format(Service.coins(game)),
      onChoose = function(item)
        local prize = item.value
        local choices = {
          { label = "NORMAL " .. prize.cost, onSelect = function()
              local ok, msg, mon = Service.buyPokemon(game, prize, false)
              finishPrize(game, list, ok, msg, opts and opts.onClose, mon)
            end },
        }
        if not config.shinyUpgrades or config.shinyUpgrades() then
          choices[#choices + 1] = {
            label = "SHINY " .. (prize.cost + Catalog.SHINY_SURCHARGE),
            onSelect = function()
              local ok, msg, mon = Service.buyPokemon(game, prize, true)
              finishPrize(game, list, ok, msg, opts and opts.onClose, mon)
            end,
          }
        end
        choices[#choices + 1] = { label = "CANCEL" }
        game.stack:push(mod.ui.Menu.new(game, choices,
          { tx = 3, ty = 4, maxVisible = #choices }))
      end,
      onCancel = opts and opts.onClose,
    })
    return list
  end

  function UI.itemMenu(game, opts)
    local rows = {}
    for _, prize in ipairs(Catalog.ITEMS) do
      local sold = prize.once and mod.save:get(config.masterBallKey, false)
      local def = game.data.items[prize.item]
      if def then rows[#rows + 1] = {
        label = (def.name or prize.item) .. (sold and " (SOLD)" or ""),
        right = sold and "--" or tostring(prize.cost), value = prize } end
    end
    local list
    list = mod.ui.ListMenu.new(game, "ITEM PRIZES", rows, {
      pageJump = true, footer = ("COINS %d"):format(Service.coins(game)),
      onChoose = function(item)
        game.stack:push(mod.ui.ChoiceBox.new(game, function(yes)
          if not yes then return end
          local ok, msg = Service.buyItem(game, item.value)
          finishPrize(game, list, ok, msg, opts and opts.onClose)
        end))
      end,
      onCancel = opts and opts.onClose,
    })
    return list
  end

  return UI
end
