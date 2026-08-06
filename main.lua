local function loadLocal(mod, relative)
  local source = assert(mod:read(relative), "missing " .. relative)
  local chunk, err = load(source, "@" .. mod.path .. "/" .. relative)
  assert(chunk, err)
  return chunk()
end

return function(mod)
  local Rules = loadLocal(mod, "rules.lua")
  local Catalog = loadLocal(mod, "catalog.lua")
  local BlackjackView = loadLocal(mod, "blackjack_view.lua")
  local Stats = require("src.pokemon.Stats")
  local GameVersion = require("src.core.GameVersion")
  local Pokemon = require("src.pokemon.Pokemon")
  local Party = require("src.pokemon.Party")
  local Boxes = require("src.pokemon.Boxes")
  local Bag = require("src.inventory.Bag")
  local BattleState = require("src.battle.BattleState")
  local Sound = require("src.core.Sound")

  local BLACKJACK_SCREEN = "BlackjackCornerTable"
  local POKEMON_SCREEN = "BlackjackCornerPokemonPrizes"
  local ITEM_SCREEN = "BlackjackCornerItemPrizes"
  local LOUNGE_MAP = "BLACKJACK_LOUNGE"
  local MASTER_BALL_KEY = "master_ball_redeemed"
  local BETS = { 10, 50, 100, 500 }
  local COIN_CAP = 9999
  local COIN_BUNDLE = 50
  local COIN_BUNDLE_PRICE = 1000
  local SHINY_ART = {}
  for name in ([=[
    ABRA KADABRA ALAKAZAM CLEFAIRY WIGGLYTUFF NIDORINA NIDOQUEEN NIDORINO NIDOKING
    DRATINI DRAGONAIR DRAGONITE PORYGON BULBASAUR IVYSAUR VENUSAUR
    CHARMANDER CHARMELEON CHARIZARD SQUIRTLE WARTORTLE BLASTOISE
    OMANYTE OMASTAR KABUTO KABUTOPS AERODACTYL SANDSHREW SANDSLASH
    VULPIX NINETALES MEOWTH PERSIAN BELLSPROUT WEEPINBELL VICTREEBEL
    PINSIR MAGMAR EKANS ARBOK ODDISH GLOOM VILEPLUME MANKEY PRIMEAPE
    GROWLITHE ARCANINE SCYTHER ELECTABUZZ
  ]=]):gmatch("%S+") do SHINY_ART[name] = true end

  mod.options:define({
    { key = "shiny_sparkles", label = "SHINY SPARKLES", type = "toggle", default = true },
  })

  for piece = 1, 10 do
    mod.content.sprites:register(("SPRITE_BLACKJACK_TABLE_%02d"):format(piece), {
      image = ("save/mod-derived/blackjack_corner/world/table_%02d.png"):format(piece),
      frames = 1,
      trueColor = true,
    })
  end

  local function coins(game)
    return math.max(0, tonumber(game.save.coins) or 0)
  end

  local function maxCoinPurchase(game)
    local current = coins(game)
    local money = math.max(0, tonumber(game.save.money) or 0)
    if current >= 9990 or money < COIN_BUNDLE_PRICE then return 0, 0 end
    local affordablePacks = math.floor(money / COIN_BUNDLE_PRICE)
    local capacityPacks = math.ceil((COIN_CAP - current) / COIN_BUNDLE)
    local packs = math.min(affordablePacks, capacityPacks)
    local amount = math.min(COIN_CAP - current, packs * COIN_BUNDLE)
    return amount, packs * COIN_BUNDLE_PRICE
  end

  local function coinOffers(game)
    local maxAmount = maxCoinPurchase(game)
    local offers, seen = {}, {}
    local function add(amount, label)
      local packs = math.ceil(amount / COIN_BUNDLE)
      offers[#offers + 1] = {
        amount = amount,
        cost = packs * COIN_BUNDLE_PRICE,
        label = label or (tostring(amount) .. " COINS"),
      }
      seen[amount] = true
    end
    for _, amount in ipairs({ 50, 250, 500, 1000 }) do
      if amount <= maxAmount then add(amount) end
    end
    if maxAmount > 0 and not seen[maxAmount] then add(maxAmount, "MAX " .. maxAmount) end
    return offers
  end

  local function buyCoins(game, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      return false, "You don't have a\nCOIN CASE!"
    end
    if coins(game) >= 9990 then return false, "Your COIN CASE\nis full." end
    if amount <= 0 or amount > COIN_CAP - coins(game) then
      return false, "That many coins\nwon't fit."
    end
    local cost = math.ceil(amount / COIN_BUNDLE) * COIN_BUNDLE_PRICE
    if (tonumber(game.save.money) or 0) < cost then
      return false, "You can't afford\nthat many coins."
    end
    game.save.money = game.save.money - cost
    game.save.coins = coins(game) + amount
    return true, ("Thanks! Here are\nyour %d coins!"):format(amount), cost
  end

  local function text(game, message, onDone)
    game.stack:push(mod.ui.TextBox.new(game, message, onDone))
  end

  local function closeTop(game, state)
    if game.stack:top() == state then game.stack:pop() end
  end

  local function play(game, name)
    Sound.play(game.data, name)
  end

  local function shinyDVs()
    return { hp = 0, attack = 10, defense = 10, speed = 10, special = 10 }
  end

  local function givePokemon(game, prize, shiny)
    local mon = Pokemon.new(game.data, prize.species, prize.level)
    if shiny then
      mon.dvs = shinyDVs()
      mon.stats = Stats.calc(game.data.pokemon[prize.species], mon.level,
        mon.dvs, mon.statExp)
      mon.hp = mon.stats.hp
    end
    BattleState.stampOT(game.save, mon)
    local party = game.save.party or {}
    game.save.party = party
    local addedToParty = Party.add(party, mon)
    local boxNum
    if not addedToParty then boxNum = Boxes.deposit(game.save, mon) end
    if not addedToParty and not boxNum then return false end
    local dex = game.save.pokedex
    if dex then
      dex.seen[prize.species] = true
      dex.owned[prize.species] = true
    end
    return true, addedToParty and "party" or ("BOX " .. tostring(boxNum))
  end

  local function buyPokemon(game, prize, shiny)
    local cost = prize.cost + (shiny and Catalog.SHINY_SURCHARGE or 0)
    if coins(game) < cost then return false, "Sorry, you need\nmore coins." end
    local ok, destination = givePokemon(game, prize, shiny)
    if not ok then return false, "Your party and PC\nboxes are full." end
    game.save.coins = coins(game) - cost
    local name = game.data.pokemon[prize.species].name or prize.species
    local adjective = shiny and "SHINY " or ""
    return true, adjective .. name .. " was sent\nto your " .. destination .. "!"
  end

  local function buyItem(game, prize)
    if prize.once and mod.save:get(MASTER_BALL_KEY, false) then
      return false, "The MASTER BALL\nprize is sold out."
    end
    if coins(game) < prize.cost then return false, "Sorry, you need\nmore coins." end
    if not Bag.add(game.save, prize.item, 1, game.data) then
      return false, "You don't have\nenough room."
    end
    game.save.coins = coins(game) - prize.cost
    if prize.once then mod.save:set(MASTER_BALL_KEY, true) end
    local itemDef = game.data.items[prize.item]
    local name = itemDef and itemDef.name or prize.item
    return true, "Here you go!\n" .. name .. " is yours."
  end

  -- ------- blackjack table screen

  local Blackjack = {}
  Blackjack.__index = Blackjack
  Blackjack.isOpaque = true

  function Blackjack.new(game, opts)
    return setmetatable({
      game = game,
      onClose = opts and opts.onClose,
      phase = "bet",
      betIndex = 1,
      actionIndex = 1,
      settled = false,
      cardAnim = 0,
      resultAge = 0,
    }, Blackjack)
  end

  function Blackjack:close()
    closeTop(self.game, self)
    if self.onClose then self.onClose() end
  end

  -- The blackjack table uses colors and pixel primitives directly rather
  -- than Game Boy shade indices. Keep this screen out of the SGB recolor
  -- pass; otherwise the felt collapses to black and the accents to red.
  function Blackjack:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end

  function Blackjack:recordRound()
    if self.settled or not self.round or self.round.state ~= "done" then return end
    self.settled = true
    self.game.save.coins = math.min(COIN_CAP, coins(self.game) + self.round.payout)
    mod.save:set("hands_played", mod.save:get("hands_played", 0) + 1)
    if self.round.result == "win" or self.round.result == "blackjack" then
      mod.save:set("hands_won", mod.save:get("hands_won", 0) + 1)
    end
    if self.round.result == "blackjack" then
      mod.save:set("blackjacks", mod.save:get("blackjacks", 0) + 1)
    end
    self.phase = "result"
    self.resultAge = 0
    play(self.game, (self.round.result == "win" or self.round.result == "blackjack")
      and "Slots_Reward" or "Slots_Stop_Wheel")
  end

  function Blackjack:deal()
    local bet = BETS[self.betIndex]
    if coins(self.game) < bet then
      self.notice = "NOT ENOUGH COINS"
      return
    end
    self.notice = nil
    play(self.game, "Slots_New_Spin")
    self.game.save.coins = coins(self.game) - bet
    self.round = Rules.newRound(bet, Rules.newDeck(function(n)
      return love.math.random(1, n)
    end))
    self.actionIndex = 1
    self.settled = false
    self.cardAnim = 0.18
    self.phase = "play"
    self:recordRound()
  end

  function Blackjack:canDouble()
    return Rules.canDouble(self.round) and coins(self.game) >= self.round.bet
  end

  function Blackjack:moveAction(direction)
    local nextIndex = self.actionIndex
    repeat
      nextIndex = ((nextIndex - 1 + direction) % 3) + 1
    until nextIndex ~= 3 or self:canDouble()
    self.actionIndex = nextIndex
  end

  function Blackjack:chooseAction()
    if self.actionIndex == 1 then
      Rules.hit(self.round)
      self.cardAnim = 0.18
    elseif self.actionIndex == 2 then
      Rules.stand(self.round)
    elseif self.actionIndex == 3 and self:canDouble() then
      self.game.save.coins = coins(self.game) - self.round.bet
      Rules.double(self.round)
      self.cardAnim = 0.18
    else
      self.notice = "DOUBLE UNAVAILABLE"
      return
    end
    if self.round.state == "playing" then play(self.game, "Slots_Stop_Wheel") end
    self:recordRound()
  end

  function Blackjack:update(dt)
    dt = dt or 1 / 60
    self.cardAnim = math.max(0, self.cardAnim - dt)
    if self.phase == "result" then self.resultAge = self.resultAge + dt end
    local input = self.game.input
    if self.phase == "bet" then
      if input:wasPressed("left") then
        self.betIndex = self.betIndex > 1 and self.betIndex - 1 or #BETS
        self.notice = nil
        play(self.game, "Press_AB")
      elseif input:wasPressed("right") then
        self.betIndex = self.betIndex < #BETS and self.betIndex + 1 or 1
        self.notice = nil
        play(self.game, "Press_AB")
      elseif input:wasPressed("a") then
        self:deal()
      elseif input:wasPressed("b") then
        self:close()
      end
    elseif self.phase == "play" then
      if input:wasPressed("left") then
        self:moveAction(-1)
        play(self.game, "Press_AB")
      elseif input:wasPressed("right") then
        self:moveAction(1)
        play(self.game, "Press_AB")
      elseif input:wasPressed("a") then
        self:chooseAction()
      elseif input:wasPressed("b") then
        Rules.stand(self.round)
        self:recordRound()
      end
    elseif self.phase == "result" then
      if input:wasPressed("a") then
        self.phase, self.round, self.notice = "bet", nil, nil
        self.resultAge = 0
        play(self.game, "Press_AB")
      elseif input:wasPressed("b") then
        self:close()
      end
    end
  end

  function Blackjack:draw()
    local lift = self.cardAnim > 0 and -math.max(1, math.ceil(self.cardAnim * 22)) or 0
    BlackjackView.draw({
      phase = self.phase,
      betIndex = self.betIndex,
      actionIndex = self.actionIndex,
      round = self.round,
      notice = self.notice,
      doubleEnabled = self.round and self:canDouble() or false,
      cardLift = lift,
      resultPulse = self.resultAge < 0.7 and ((self.resultAge * 10) % 2) or 0,
    }, mod.ui.Font, Rules, coins(self.game), BETS)
  end

  mod.content.screens:register(BLACKJACK_SCREEN, { new = Blackjack.new })

  -- ------- prize menus

  local function finishPrizeAttempt(game, list, ok, message, done)
    if ok then closeTop(game, list) end
    text(game, message, ok and done or nil)
  end

  local function pokemonMenu(game, opts)
    local items = {}
    for _, prize in ipairs(Catalog.pokemon(GameVersion.get())) do
      local def = game.data.pokemon[prize.species]
      if def then
        items[#items + 1] = {
          label = def.name or prize.species,
          right = tostring(prize.cost),
          value = prize,
        }
      end
    end
    local list
    list = mod.ui.ListMenu.new(game, "POKEMON PRIZES", items, {
      pageJump = true,
      footer = ("COINS %d"):format(coins(game)),
      onChoose = function(item)
        local prize = item.value
        local normalCost = prize.cost
        local shinyCost = prize.cost + Catalog.SHINY_SURCHARGE
        game.stack:push(mod.ui.Menu.new(game, {
          { label = "NORMAL " .. normalCost, onSelect = function()
              local ok, msg = buyPokemon(game, prize, false)
              finishPrizeAttempt(game, list, ok, msg, opts and opts.onClose)
            end },
          { label = "SHINY " .. shinyCost, onSelect = function()
              local ok, msg = buyPokemon(game, prize, true)
              finishPrizeAttempt(game, list, ok, msg, opts and opts.onClose)
            end },
          { label = "CANCEL" },
        }, { tx = 3, ty = 4, maxVisible = 3 }))
      end,
      onCancel = opts and opts.onClose,
    })
    return list
  end

  local function itemMenu(game, opts)
    local items = {}
    for _, prize in ipairs(Catalog.ITEMS) do
      local sold = prize.once and mod.save:get(MASTER_BALL_KEY, false)
      local def = game.data.items[prize.item]
      if def then
        items[#items + 1] = {
          label = (def.name or prize.item) .. (sold and " (SOLD)" or ""),
          right = sold and "--" or tostring(prize.cost),
          value = prize,
        }
      end
    end
    local list
    list = mod.ui.ListMenu.new(game, "ITEM PRIZES", items, {
      pageJump = true,
      footer = ("COINS %d"):format(coins(game)),
      onChoose = function(item)
        local prize = item.value
        game.stack:push(mod.ui.ChoiceBox.new(game, function(yes)
          if not yes then return end
          local ok, msg = buyItem(game, prize)
          finishPrizeAttempt(game, list, ok, msg, opts and opts.onClose)
        end))
      end,
      onCancel = opts and opts.onClose,
    })
    return list
  end

  mod.content.screens:register(POKEMON_SCREEN, { new = pokemonMenu })
  mod.content.screens:register(ITEM_SCREEN, { new = itemMenu })

  -- Give blackjack its own lounge instead of squeezing the table into the
  -- slot-machine bank. A new double-door in the Game Corner leads to a
  -- compact 14x10 room with a centered table, dealer, spectators, and a
  -- clean approach lane. The table remains a 5x2 entity assembly, so its
  -- front edge owns collision and interaction naturally.
  local gameCorner = mod.content.maps:get("GAME_CORNER")
  if gameCorner and type(gameCorner.blocks) == "table"
      and gameCorner.tileset == "LOBBY"
      and gameCorner.width == 10 and gameCorner.height == 9 then
    local blocks = {}
    for i, block in ipairs(gameCorner.blocks) do blocks[i] = block end
    blocks[82] = 61 -- lower-left double-door into the lounge

    local warps = {}
    for _, original in ipairs(gameCorner.warps or {}) do
      local warp = {}
      for key, value in pairs(original) do warp[key] = value end
      warps[#warps + 1] = warp
    end
    local entryWarp = #warps + 1
    warps[#warps + 1] = { x = 2, y = 17, destMap = LOUNGE_MAP, destWarp = 1 }
    warps[#warps + 1] = { x = 3, y = 17, destMap = LOUNGE_MAP, destWarp = 2 }
    local signs = {}
    for _, original in ipairs(gameCorner.signs or {}) do signs[#signs + 1] = original end
    signs[#signs + 1] = { x = 2, y = 16, text = "TEXT_BLACKJACK_LOUNGE_SIGN" }
    mod.content.maps:patch("GAME_CORNER", { blocks = blocks, warps = warps, signs = signs })

    local loungeObjects = {
      { index = 1, name = "BLACKJACK_DEALER", movement = "STAY", range = "DOWN",
        sprite = "SPRITE_GAMBLER", text = "TEXT_BLACKJACK_DEALER", x = 6, y = 3 },
      { index = 2, name = "BLACKJACK_HOSTESS", movement = "STAY", range = "RIGHT",
        sprite = "SPRITE_BEAUTY", text = "TEXT_BLACKJACK_HOSTESS", x = 2, y = 6 },
      { index = 3, name = "BLACKJACK_PATRON", movement = "STAY", range = "LEFT",
        sprite = "SPRITE_GENTLEMAN", text = "TEXT_BLACKJACK_PATRON", x = 11, y = 6 },
    }
    for piece = 1, 10 do
      local column, line = (piece - 1) % 5, math.floor((piece - 1) / 5)
      loungeObjects[#loungeObjects + 1] = {
        index = 3 + piece,
        name = ("BLACKJACK_TABLE_%02d"):format(piece),
        movement = "STAY",
        range = "DOWN",
        sprite = ("SPRITE_BLACKJACK_TABLE_%02d"):format(piece),
        x = 4 + column,
        y = 4 + line,
        text = line == 1 and "TEXT_BLACKJACK_TABLE" or nil,
      }
    end
    mod.content.maps:register(LOUNGE_MAP, {
      id = LOUNGE_MAP,
      label = "BlackjackLounge",
      index = 1100,
      tileset = "LOBBY",
      width = 7,
      height = 5,
      blocks = {
        63, 64, 64, 64, 64, 64, 63,
        32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32,
        32, 32, 32, 32, 32, 32, 32,
        27, 27, 27, 61, 27, 27, 27,
      },
      borderBlock = 15,
      palette = "SLOTS1",
      connections = {},
      signs = {},
      objects = loungeObjects,
      warps = {
        { x = 6, y = 9, destMap = "GAME_CORNER", destWarp = entryWarp },
        { x = 7, y = 9, destMap = "GAME_CORNER", destWarp = entryWarp + 1 },
      },
    })
  end

  local function openAfterMessage(game, message, screen, done)
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      text(game, "A COIN CASE is\nrequired!", done)
      return
    end
    text(game, message, function()
      mod.ui.push(game, screen, { onClose = done })
    end)
  end

  local function coinClerk(game, _, _, done)
    local Font = mod.ui.Font
    local coinBox = { draw = function()
      Font.drawBox(11, 0, 9, 7)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw("MONEY", 96, 16)
      local money = ("¥%d"):format(tonumber(game.save.money) or 0)
      Font.draw(money, 152 - Font.width(money), 24)
      Font.draw("COIN", 96, 32)
      local count = tostring(coins(game))
      Font.draw(count, 152 - Font.width(count), 40)
      love.graphics.setColor(1, 1, 1, 1)
    end }
    game.stack:push(coinBox)

    local function finish()
      closeTop(game, coinBox)
      if done then done() end
    end
    if not (game.save.inventory and game.save.inventory.COIN_CASE) then
      text(game, "You don't have a\nCOIN CASE!", finish)
      return
    end
    if coins(game) >= 9990 then
      text(game, "Oops! Your COIN\nCASE is full.", finish)
      return
    end
    if (tonumber(game.save.money) or 0) < COIN_BUNDLE_PRICE then
      text(game, "You can't afford\nthe coins!", finish)
      return
    end

    text(game, "¥1000 buys 50\nGame Corner coins.\fHow many would\nyou like?", function()
      local rows = {}
      for _, offer in ipairs(coinOffers(game)) do
        rows[#rows + 1] = {
          label = offer.label,
          right = "¥" .. offer.cost,
          value = offer,
        }
      end
      local list
      list = mod.ui.ListMenu.new(game, "BUY COINS", rows, {
        wrap = true,
        footer = ("MONEY ¥%d\nCOIN %d")
          :format(tonumber(game.save.money) or 0, coins(game)),
        onChoose = function(item)
          list:close()
          local ok, message = buyCoins(game, item.value.amount)
          text(game, message, finish)
        end,
        onCancel = finish,
      })
      game.stack:push(list)
    end)
  end

  mod.content.map_scripts:register("GAME_CORNER", {
    talk = {
      TEXT_GAMECORNER_CLERK1 = coinClerk,
      TEXT_GAMECORNER_CLERK = coinClerk,
      TEXT_BLACKJACK_LOUNGE_SIGN = function(game, _, _, done)
        text(game, "BLACKJACK LOUNGE\nNow open!", done)
      end,
    },
  })

  mod.content.map_scripts:register(LOUNGE_MAP, {
    talk = {
      TEXT_BLACKJACK_TABLE = function(game, _, _, done)
        openAfterMessage(game,
          "Welcome to the\nBLACKJACK table!\fPlace your bet and\nplay to 21.",
          BLACKJACK_SCREEN, done)
      end,
      TEXT_BLACKJACK_DEALER = function(game, _, _, done)
        openAfterMessage(game,
          "The table is open.\fClosest to 21\nwins the hand.",
          BLACKJACK_SCREEN, done)
      end,
      TEXT_BLACKJACK_HOSTESS = function(game, _, _, done)
        text(game, "Welcome to the\nBLACKJACK LOUNGE!", done)
      end,
      TEXT_BLACKJACK_PATRON = function(game, _, _, done)
        text(game, "I always double\ndown on eleven!", done)
      end,
    },
  })

  mod.content.map_scripts:register("GAME_CORNER_PRIZE_ROOM", {
    talk = {
      TEXT_GAMECORNERPRIZEROOM_PRIZE_VENDOR_1 = function(game, _, _, done)
        openAfterMessage(game, "Exchange coins for\nPOKEMON prizes?", POKEMON_SCREEN, done)
      end,
      TEXT_GAMECORNERPRIZEROOM_PRIZE_VENDOR_2 = function(game, _, _, done)
        openAfterMessage(game, "Normal or SHINY?\nYou choose!", POKEMON_SCREEN, done)
      end,
      TEXT_GAMECORNERPRIZEROOM_PRIZE_VENDOR_3 = function(game, _, _, done)
        openAfterMessage(game, "Rare items for\nGame Corner coins!", ITEM_SCREEN, done)
      end,
    },
  })

  -- Every purchased shiny has canonical Gen-II shiny DVs. The transform
  -- supplies a gold-toned derived sprite for the prize families, and this
  -- per-instance hook selects it without changing ordinary members of the
  -- same species.
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    path = next(path, ctx)
    if not (ctx and ctx.mon and SHINY_ART[ctx.species]
        and Stats.isShiny(ctx.mon.dvs)) then return path end
    local filename = type(path) == "string" and path:match("([^/]+)$")
    if not filename then return path end
    ctx.trueColor = true
    return ("save/mod-derived/blackjack_corner/shiny/battle/%s/%s")
      :format(ctx.side, filename)
  end)

  mod.hooks:wrap("battle.overlay", function(next, battle)
    next(battle)
    if not mod.options:get("shiny_sparkles") or not (love and love.graphics) then return end
    local function sparkle(mon, x, y)
      if not (mon and Stats.isShiny(mon.dvs)) then return end
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.polygon("fill", x, y - 4, x + 2, y - 1, x + 5, y,
        x + 2, y + 1, x, y + 4, x - 2, y + 1, x - 5, y, x - 2, y - 1)
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.rectangle("line", x - 2, y - 2, 4, 4)
      love.graphics.setColor(1, 1, 1, 1)
    end
    sparkle(battle.enemy and battle.enemy.mon, 145, 16)
    sparkle(battle.player and battle.player.mon, 15, 80)
  end)

  mod.exports.rules = Rules
  mod.exports.view = BlackjackView
  mod.exports.catalog = Catalog
  mod.exports.buyPokemon = buyPokemon
  mod.exports.buyItem = buyItem
  mod.exports.buyCoins = buyCoins
  mod.exports.coinOffers = coinOffers
end
