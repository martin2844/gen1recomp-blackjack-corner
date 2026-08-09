return function(mod, opts)
  local Credit, text = opts.credit, opts.text
  local UI = {}

  local function closeWith(game, message, done)
    text(game, message, done)
  end

  function UI.broker(game, _, _, done)
    Credit.syncMilestones(game)
    local state = Credit.snapshot(game)
    if not state then
      text(game, "No campaign,\nno credit.", done)
      return
    end

    local function statement(nextStep)
      local current = Credit.snapshot(game)
      if current.total == 0 then
        text(game, ("You're clear.\f%s rank gets\n%d coins for %d.")
          :format(current.rank:gsub("_", " "), current.offer.coins,
            current.offer.coins + current.offer.fee), nextStep)
      else
        local due = current.dueBadge > 8 and "FINAL NOTICE"
          or ("BEFORE BADGE %d"):format(current.dueBadge)
        text(game, ("%s\fPRINCIPAL %d\nFEES %d\fOWED %d\n%s")
          :format(current.status, current.principal, current.fees,
            current.total, due), nextStep)
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
            closeWith(game, message, openMenu)
          end,
        }))
    end

    local openMenu
    function openMenu()
      local current = Credit.snapshot(game)
      local rows = {}
      if current.total == 0 then
        rows[#rows + 1] = { label = "TAKE " .. current.offer.coins,
          onSelect = function()
            game.stack:push(mod.ui.TextBox.new(game,
              ("Borrow %d coins?\fFixed fee: %d\nTotal: %d")
                :format(current.offer.coins, current.offer.fee,
                  current.offer.coins + current.offer.fee), nil, {
                choice = function(yes)
                  if not yes then openMenu(); return end
                  local _, message = Credit.borrow(game)
                  closeWith(game, message, openMenu)
                end,
              }))
          end }
      else
        rows[#rows + 1] = { label = "PAY COINS",
          onSelect = function() payCoins(openMenu) end }
        rows[#rows + 1] = { label = "PAY MONEY",
          onSelect = function() payMoney(openMenu) end }
      end
      rows[#rows + 1] = { label = "STATEMENT",
        onSelect = function() statement(openMenu) end }
      rows[#rows + 1] = { label = "LEAVE", onSelect = done }
      game.stack:push(mod.ui.Menu.new(game, rows, {
        tx = 2, ty = 3, maxVisible = 4, onCancel = done,
      }))
    end

    text(game, state.status == "DEFAULT"
      and "Rocket credit.\fYou're late.\nLet's talk numbers."
      or "Rocket credit.\fFast coins. Fixed\nfee. No surprises.", openMenu)
  end

  return UI
end
