local Stats = require("src.pokemon.Stats")
local GameVersion = require("src.core.GameVersion")
local Pokemon = require("src.pokemon.Pokemon")
local Party = require("src.pokemon.Party")
local Boxes = require("src.pokemon.Boxes")
local Bag = require("src.inventory.Bag")
local BattleState = require("src.battle.BattleState")

return function(mod, Catalog, Pawn, config)
  local Service = {}
  local coinCap = config.coinCap

  local function moneyCap(game)
    local constants = game and game.data and game.data.constants
    return math.max(0, math.floor(tonumber(constants and constants.moneyCap)
      or tonumber(config.moneyCap) or 999999))
  end

  function Service.coins(game)
    return math.max(0, tonumber(game.save.coins) or 0)
  end

  function Service.creditCoins(game, requested)
    local current = math.floor(Service.coins(game))
    local amount = math.max(0, math.floor(tonumber(requested) or 0))
    local delivered = math.min(amount, math.max(0, coinCap - current))
    game.save.coins = current + delivered
    return delivered
  end

  function Service.coinOffers(game)
    local current = Service.coins(game)
    local money = math.max(0, tonumber(game.save.money) or 0)
    if current >= coinCap or money < config.coinBundlePrice then return {} end
    local packs = math.min(math.floor(money / config.coinBundlePrice),
      math.ceil((coinCap - current) / config.coinBundle))
    local maximum = math.min(coinCap - current, packs * config.coinBundle)
    local offers, seen = {}, {}
    local function add(amount, label)
      offers[#offers + 1] = {
        amount = amount,
        cost = math.ceil(amount / config.coinBundle) * config.coinBundlePrice,
        label = label or (tostring(amount) .. " COINS"),
      }
      seen[amount] = true
    end
    for _, amount in ipairs({ 50, 250, 500, 1000 }) do
      if amount <= maximum then add(amount) end
    end
    if maximum > 0 and not seen[maximum] then add(maximum, "MAX " .. maximum) end
    return offers
  end

  function Service.buyCoins(game, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      return false, "You don't have a\nCOIN CASE!"
    end
    if Service.coins(game) >= coinCap then return false, "Your COIN CASE\nis full." end
    if amount <= 0 or amount > coinCap - Service.coins(game) then
      return false, "That many coins\nwon't fit."
    end
    local cost = math.ceil(amount / config.coinBundle) * config.coinBundlePrice
    if (tonumber(game.save.money) or 0) < cost then
      return false, "You can't afford\nthat many coins."
    end
    game.save.money = game.save.money - cost
    game.save.coins = Service.coins(game) + amount
    return true, ("Thanks! Here are\nyour %d coins!"):format(amount), cost
  end

  function Service.cashOutOffers(game)
    local coins = math.floor(Service.coins(game))
    local money = math.max(0, math.floor(tonumber(game.save.money) or 0))
    local bundle = math.max(1, math.floor(tonumber(config.coinBundle) or 50))
    local price = math.max(1, math.floor(tonumber(config.coinBundlePrice) or 1000))
    local packs = math.min(math.floor(coins / bundle),
      math.floor(math.max(0, moneyCap(game) - money) / price))
    local maximum = packs * bundle
    if maximum <= 0 then return {} end

    local offers, seen = {}, {}
    local function add(amount, label)
      offers[#offers + 1] = {
        amount = amount,
        payout = math.floor(amount / bundle) * price,
        label = label or (tostring(amount) .. " COINS"),
      }
      seen[amount] = true
    end
    for _, amount in ipairs({ 50, 250, 500, 1000 }) do
      if amount <= maximum and amount % bundle == 0 then add(amount) end
    end
    if not seen[maximum] then add(maximum, "MAX " .. maximum) end
    return offers
  end

  function Service.cashOutCoins(game, amount)
    amount = math.floor(tonumber(amount) or 0)
    local bundle = math.max(1, math.floor(tonumber(config.coinBundle) or 50))
    local price = math.max(1, math.floor(tonumber(config.coinBundlePrice) or 1000))
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      return false, "You don't have a\nCOIN CASE!"
    end
    if amount <= 0 or amount % bundle ~= 0 then
      return false, ("Cash-outs use\n%d-coin bundles."):format(bundle)
    end
    local current = math.floor(Service.coins(game))
    if current < amount then return false, "You don't have\nthat many coins." end
    local money = math.max(0, math.floor(tonumber(game.save.money) or 0))
    local payout = math.floor(amount / bundle) * price
    if payout > math.max(0, moneyCap(game) - money) then
      return false, "That payout won't\nfit in your wallet."
    end
    game.save.coins = current - amount
    game.save.money = money + payout
    return true, ("Cashed out %d\ncoins for ¥%d!"):format(amount, payout), payout
  end

  local function shinyDVs()
    return { hp = 0, attack = 10, defense = 10, speed = 10, special = 10 }
  end

  function Service.givePokemon(game, prize, shiny)
    local mon = Pokemon.new(game.data, prize.species, prize.level)
    for _, moveId in ipairs(prize.moves or {}) do
      local known = false
      for _, move in ipairs(mon.moves) do
        if move.id == moveId then known = true; break end
      end
      if not known then
        if #mon.moves >= 4 then table.remove(mon.moves, 1) end
        local move = game.data.moves[moveId]
        mon.moves[#mon.moves + 1] = { id = moveId, pp = move and move.pp or 0 }
      end
    end
    if shiny then
      mon.dvs = shinyDVs()
      mon.stats = Stats.calc(game.data.pokemon[prize.species], mon.level,
        mon.dvs, mon.statExp)
      mon.hp = mon.stats.hp
    end
    BattleState.stampOT(game.save, mon)
    game.save.party = game.save.party or {}
    local inParty = Party.add(game.save.party, mon)
    local boxNum = not inParty and Boxes.deposit(game.save, mon) or nil
    if not inParty and not boxNum then return false end
    local dex = game.save.pokedex
    if dex then
      dex.seen[prize.species], dex.owned[prize.species] = true, true
    end
    return true, inParty and "party" or ("BOX " .. tostring(boxNum)), mon
  end

  function Service.askNickname(game, mon, onDone)
    local stack = game and game.stack
    if not (mon and stack and stack.push) then
      if onDone then onDone() end
      return false
    end
    local def = game.data.pokemon[mon.species]
    local displayName = (def and def.name) or mon.species or "POKEMON"
    local label = game.data.text and game.data.text._DoYouWantToNicknameText
    local text = label and label:gsub("\t", "\n")
      :gsub("{RAM:?[%w_]*}", displayName)
      or ("Do you want to\ngive a nickname\nto %s?"):format(displayName)
    stack:push(mod.ui.TextBox.new(game, text, nil, {
      choice = function(yes)
        if not yes then
          if onDone then onDone() end
          return
        end
        stack:push(mod.ui.NamingScreen.new(game, {
          title = "NICKNAME?", maxLen = 10,
          onDone = function(name)
            if name and #name > 0 then mon.nickname = name end
            if onDone then onDone() end
          end,
        }))
      end,
    }))
    return true
  end

  function Service.buyPokemon(game, prize, shiny)
    if config.luxuryAllowed then
      local allowed, message = config.luxuryAllowed(game)
      if not allowed then return false, message end
    end
    local cost = prize.cost + (shiny and Catalog.SHINY_SURCHARGE or 0)
    if Service.coins(game) < cost then return false, "Sorry, you need\nmore coins." end
    local ok, destination, mon = Service.givePokemon(game, prize, shiny)
    if not ok then return false, "Your party and PC\nboxes are full." end
    game.save.coins = Service.coins(game) - cost
    local name = game.data.pokemon[prize.species].name or prize.species
    return true, (shiny and "SHINY " or "") .. name
      .. " was sent\nto your " .. destination .. "!", mon
  end

  function Service.buyItem(game, prize)
    if config.luxuryAllowed then
      local allowed, message = config.luxuryAllowed(game)
      if not allowed then return false, message end
    end
    if prize.once and mod.save:get(config.masterBallKey, false) then
      return false, "The MASTER BALL\nprize is sold out."
    end
    if Service.coins(game) < prize.cost then return false, "Sorry, you need\nmore coins." end
    if not Bag.add(game.save, prize.item, 1, game.data) then
      return false, "You don't have\nenough room."
    end
    game.save.coins = Service.coins(game) - prize.cost
    if prize.once then mod.save:set(config.masterBallKey, true) end
    local item = game.data.items[prize.item]
    return true, "Here you go!\n" .. ((item and item.name) or prize.item) .. " is yours."
  end

  function Service.pawnLedger()
    local ledger = mod.save:get(config.pawnLedgerKey, {})
    return type(ledger) == "table" and ledger or {}
  end

  function Service.monName(game, mon)
    local def = mon and game.data.pokemon[mon.species]
    return (mon and mon.nickname) or (def and def.name)
      or (mon and mon.species) or "POKEMON"
  end

  function Service.pawnQuote(game, partyIndex)
    local party = game.save.party or {}
    local mon = party[partyIndex]
    if #party <= 1 then return nil, "You must keep one\nPOKEMON with you." end
    if not mon then return nil, "That POKEMON is\nno longer here." end
    local def = game.data.pokemon[mon.species]
    if not def then return nil, "I can't value\nthat POKEMON." end
    local value = Pawn.value(mon, def)
    return {
      index = partyIndex,
      mon = mon,
      name = Service.monName(game, mon),
      value = value,
      redeem = Pawn.redeemCost(value),
    }
  end

  function Service.pawnPokemon(game, partyIndex, reservedCoins)
    local party = game.save.party or {}
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      return false, "You need a\nCOIN CASE."
    end
    local quote, message = Service.pawnQuote(game, partyIndex)
    if not quote then return false, message end
    local routed = math.min(quote.value,
      math.max(0, math.floor(tonumber(reservedCoins) or 0)))
    local payout = quote.value - routed
    if Service.coins(game) + payout > coinCap then
      return false, "Your COIN CASE\nneeds more room."
    end
    local ledger, sold = Service.pawnLedger()
    while #ledger >= Pawn.LIMIT do sold = table.remove(ledger, 1) end
    table.remove(party, partyIndex)
    local entry = { mon = quote.mon, value = quote.value, redeem = quote.redeem,
      name = quote.name }
    ledger[#ledger + 1] = entry
    mod.save:set(config.pawnLedgerKey, ledger)
    game.save.coins = Service.coins(game) + payout
    return true, entry, sold, routed
  end

  function Service.redeemPokemon(game, ledgerIndex)
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      return false, "You need a\nCOIN CASE."
    end
    local ledger = Service.pawnLedger()
    local entry = ledger[ledgerIndex]
    if not (entry and type(entry.mon) == "table") then
      return false, "That pawn ticket\nis no good."
    end
    local cost = math.max(0, math.floor(tonumber(entry.redeem)
      or Pawn.redeemCost(entry.value)))
    if Service.coins(game) < cost then return false, "You need more\ncoins for that." end
    game.save.party = game.save.party or {}
    local destination
    if Party.add(game.save.party, entry.mon) then destination = "party"
    else
      local boxNum = Boxes.deposit(game.save, entry.mon)
      if not boxNum then return false, "Your party and PC\nboxes are full." end
      destination = "BOX " .. tostring(boxNum)
    end
    game.save.coins = Service.coins(game) - cost
    table.remove(ledger, ledgerIndex)
    mod.save:set(config.pawnLedgerKey, ledger)
    return true, entry, cost, destination
  end

  function Service.caseRewardPool(game, CaseRules)
    return CaseRules.pool(Catalog.pokemon(GameVersion.get()), game.data.pokemon)
  end

  function Service.giveCaseReward(game, reward)
    if reward.kind == "pokemon" then
      local ok, destination, mon = Service.givePokemon(game, reward, false)
      if not ok then return false, "STORAGE FULL" end
      Service.askNickname(game, mon)
      return true, reward.label, destination, mon
    end
    if not Bag.add(game.save, reward.id, reward.quantity or 1, game.data) then
      return false, "BAG FULL"
    end
    return true, reward.label
  end

  return Service
end
