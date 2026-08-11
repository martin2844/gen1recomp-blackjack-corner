return function(mod, opts)
  local Credit, text = opts.credit, opts.text
  local House = opts.house
  local UI = {}

  local function closeWith(game, message, done)
    text(game, message, done)
  end

  function UI.broker(game, _, _, done)
    Credit.syncMilestones(game)
    if opts.syncWorld then opts.syncWorld(game) end
    local state = Credit.snapshot(game)
    if not state then
      text(game, "No campaign,\nno credit.", done)
      return
    end

    local function statement(nextStep)
      local current = Credit.snapshot(game)
      local home = House and House.snapshot(game)
      local homePage = ""
      if home and home.status ~= "FAMILY_HOME" then
        local labels = {
          ROCKET_OWNED = "ROCKET OWNED",
          BUYBACK_PAID = "DEED PAID\nBATTLE PENDING",
          RESTORED = "FAMILY HOME\nRESTORED",
        }
        homePage = "\fHOME: " .. (labels[home.status] or home.status)
      end
      if current.total == 0 then
        local copy = current.newLoansAllowed
          and ("You're clear.\f%s rank gets\n%d coins for %d.")
            :format(current.rank:gsub("_", " "), current.offer.coins,
              current.offer.coins + current.offer.fee)
          or "You're clear.\fNew ROCKET credit\nis closed to you."
        text(game, copy .. homePage, nextStep)
      elseif current.total > 0 then
        local due = current.dueBadge > 8 and "FINAL NOTICE"
          or ("BEFORE BADGE %d"):format(current.dueBadge)
        text(game, ("%s\fPRINCIPAL %d\nFEES %d\fOWED %d\n%s")
          :format(current.status, current.principal, current.fees,
            current.total, due) .. homePage, nextStep)
      end
    end

    local function payCoins(openMenu)
      local current = Credit.snapshot(game)
      local available = math.max(0, tonumber(game.save.coins) or 0)
      local rows, seen = {}, {}
      for _, amount in ipairs({ 50, 250, 1000,
        math.min(available, current.total) }) do
        amount = math.floor(amount)
        if amount > 0 and amount <= available and amount <= current.total
            and not seen[amount] then
          rows[#rows + 1] = { label = tostring(amount) .. " COINS", value = amount }
          seen[amount] = true
        end
      end
      if #rows == 0 then text(game, "No coins to pay.", openMenu); return end
      local list
      list = mod.ui.ListMenu.new(game, "PAY COINS", rows, {
        footer = ("OWE %d  HAVE %d"):format(current.total, available),
        onChoose = function(item)
          list:close()
          local _, message = Credit.repayCoins(game, item.value)
          if opts.syncWorld then opts.syncWorld(game) end
          closeWith(game, message, openMenu)
        end,
        onCancel = openMenu,
      })
      game.stack:push(list)
    end

    local function payMoney(openMenu)
      local current = Credit.snapshot(game)
      local affordable = math.floor(math.max(0, tonumber(game.save.money) or 0)
        / opts.rules.MONEY_PER_COIN)
      local amount = math.min(affordable, current.total)
      if amount <= 0 then
        text(game, "Not enough money\nto make a payment.", openMenu)
        return
      end
      local cost = amount * opts.rules.MONEY_PER_COIN
      game.stack:push(mod.ui.TextBox.new(game,
        ("Pay ¥%d toward\n%d casino coins?"):format(cost, amount), nil, {
          choice = function(yes)
            if not yes then openMenu(); return end
            local _, message = Credit.repayMoney(game, amount)
            if opts.syncWorld then opts.syncWorld(game) end
            closeWith(game, message, openMenu)
          end,
        }))
    end

    local function pawnAndPay(openMenu)
      local party = game.save.party or {}
      if #party <= 1 then
        text(game, "You must keep one\nPOKEMON with you.", openMenu)
        return
      end
      local rows = {}
      for index = 1, #party do
        local quote = opts.pawnQuote and opts.pawnQuote(game, index)
        if quote then rows[#rows + 1] = {
          label = quote.name, right = tostring(quote.value), value = quote,
        } end
      end
      if #rows == 0 then text(game, "Nothing here can\nbe appraised.", openMenu); return end
      local list
      list = mod.ui.ListMenu.new(game, "PAWN TO PAY", rows, {
        pageJump = true,
        footer = ("OWE %d  HELD %d/%d"):format(
          Credit.snapshot(game).total, #opts.pawnLedger(), opts.pawnLimit),
        onChoose = function(item)
          local quote = item.value
          local prompt = ("Pawn %s?\nValue %d.")
            :format(quote.name, quote.value)
          if #opts.pawnLedger() >= opts.pawnLimit then
            local oldest = opts.pawnLedger()[1]
            prompt = prompt .. ("\fOLDEST %s\nWILL BE SOLD.")
              :format(oldest.name or "The oldest POKEMON")
          end
          list:close()
          game.stack:push(mod.ui.TextBox.new(game, prompt, nil, {
            choice = function(yes)
              if not yes then openMenu(); return end
              local _, message = Credit.pawnAndRepay(
                game, quote.index, opts.pawnPokemon)
              if opts.syncWorld then opts.syncWorld(game) end
              closeWith(game, message, openMenu)
            end,
          }))
        end,
        onCancel = openMenu,
      })
      game.stack:push(list)
    end

    local function pawnHome(openMenu)
      game.stack:push(mod.ui.TextBox.new(game,
        "TEAM ROCKET pays\n10000 coins now.\fThey take your Pallet\nfamily home.\fBuyback is 30000\nplus one battle.\fPawn the family\nhome?", nil, {
          choice = function(yes)
            if not yes then openMenu(); return end
            local _, message = House.pawnHome(game)
            if opts.syncWorld then opts.syncWorld(game) end
            closeWith(game, message, openMenu)
          end,
        }))
    end

    local function buyBackHome(openMenu)
      game.stack:push(mod.ui.TextBox.new(game,
        ("Pay %d coins\nfor family deed?\fBeat one ROCKET\nto reclaim it.")
          :format(House.BUYBACK_COST), nil, {
          choice = function(yes)
            if not yes then openMenu(); return end
            local _, message = House.buyBack(game)
            if opts.syncWorld then opts.syncWorld(game) end
            closeWith(game, message, openMenu)
          end,
        }))
    end

    local openMenu
    function openMenu()
      local current = Credit.snapshot(game)
      local rows = {}
      if current.total == 0 and current.newLoansAllowed then
        rows[#rows + 1] = { label = "TAKE " .. current.offer.coins,
          onSelect = function()
            game.stack:push(mod.ui.TextBox.new(game,
              ("Borrow %d coins?\fFixed fee: %d\nTotal: %d")
                :format(current.offer.coins, current.offer.fee,
                  current.offer.coins + current.offer.fee), nil, {
                choice = function(yes)
                  if not yes then openMenu(); return end
                  local _, message = Credit.borrow(game)
                  if opts.syncWorld then opts.syncWorld(game) end
                  closeWith(game, message, openMenu)
                end,
              }))
          end }
      elseif current.total > 0 then
        rows[#rows + 1] = { label = "PAY COINS",
          onSelect = function() payCoins(openMenu) end }
        rows[#rows + 1] = { label = "PAY MONEY",
          onSelect = function() payMoney(openMenu) end }
        rows[#rows + 1] = { label = "PAWN TO PAY",
          onSelect = function() pawnAndPay(openMenu) end }
      end
      if House then
        local home = House.snapshot(game)
        if home and home.status == "FAMILY_HOME"
            and not home.bailoutClaimed then
          rows[#rows + 1] = { label = "PAWN HOUSE",
            onSelect = function() pawnHome(openMenu) end }
        elseif home and home.status == "ROCKET_OWNED" then
          rows[#rows + 1] = { label = "BUYBACK " .. House.BUYBACK_COST,
            onSelect = function() buyBackHome(openMenu) end }
        elseif home and home.status == "BUYBACK_PAID" then
          rows[#rows + 1] = { label = "HOUSE BATTLE",
            onSelect = function()
              text(game, "The deed is paid.\fA Rocket waits in\nyour Pallet home.", openMenu)
            end }
        end
      end
      rows[#rows + 1] = { label = "STATEMENT",
        onSelect = function() statement(openMenu) end }
      rows[#rows + 1] = { label = "LEAVE", onSelect = done }
      game.stack:push(mod.ui.Menu.new(game, rows, {
        tx = 2, ty = 3, maxVisible = 6, onCancel = done,
      }))
    end

    text(game, not state.newLoansAllowed and state.total == 0
      and "You exposed ROCKET.\fNo new loans.\nOld business stands."
      or state.status == "DEFAULT"
      and "Rocket credit.\fYou're late.\nLet's talk numbers."
      or "Rocket credit.\fFast coins. Fixed\nfee. No surprises.", openMenu)
  end

  return UI
end
