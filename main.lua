local function loadLocal(mod, relative)
  local source = assert(mod:read(relative), "missing " .. relative)
  local chunk, err = load(source, "@" .. mod.path .. "/" .. relative)
  assert(chunk, err)
  return chunk()
end

return function(mod)
  local paths = {
    blackjack = "games/blackjack/", holdem = "games/holdem/",
    crash = "games/crash/", tube = "games/tube_flyer/",
    case = "games/prize_case/",
  }
  local Rules = loadLocal(mod, paths.blackjack .. "rules.lua")
  local BlackjackView = loadLocal(mod, paths.blackjack .. "view.lua")
  local HoldemRules = loadLocal(mod, paths.holdem .. "rules.lua")
  local HoldemView = loadLocal(mod, paths.holdem .. "view.lua")
  local CrashRules = loadLocal(mod, paths.crash .. "rules.lua")
  local FlappyRules = loadLocal(mod, paths.tube .. "rules.lua")
  local CaseRules = loadLocal(mod, paths.case .. "rules.lua")
  local ArcadeUI = loadLocal(mod, "games/shared/ui.lua")
  local CrashView = loadLocal(mod, paths.crash .. "view.lua")(ArcadeUI)
  local TubeView = loadLocal(mod, paths.tube .. "view.lua")(ArcadeUI)
  local CaseView = loadLocal(mod, paths.case .. "view.lua")(ArcadeUI)
  local Catalog = loadLocal(mod, "other/prizes/catalog.lua")
  local Pawn = loadLocal(mod, "other/pawn/rules.lua")
  local Services = loadLocal(mod, "other/services.lua")
  local UIFactory = loadLocal(mod, "other/ui.lua")
  local CoinCase = loadLocal(mod, "other/coin_case.lua")
  local Lounge = loadLocal(mod, "other/lounge.lua")
  local Stats = require("src.pokemon.Stats")
  local Sound = require("src.core.Sound")

  local ids = {
    blackjack = "BlackjackCornerTable",
    holdem = "BlackjackCornerHoldemTable",
    pokemon = "BlackjackCornerPokemonPrizes",
    item = "BlackjackCornerItemPrizes",
    crash = "BlackjackCornerCrash",
    tube = "BlackjackCornerTubeFlyer",
    case = "BlackjackCornerPrizeCase",
    lounge = "BLACKJACK_LOUNGE",
  }
  local config = {
    coinCap = 1000000,
    coinBundle = 50,
    coinBundlePrice = 1000,
    masterBallKey = "master_ball_redeemed",
    pawnLedgerKey = "pawned_pokemon",
  }
  local blackjackBets, holdemBets = { 10, 50, 100, 500 }, { 10, 50, 100, 500 }

  mod.options:define({
    { key = "shiny_sparkles", label = "SHINY SPARKLES", type = "toggle", default = true },
  })
  mod.content.constants:patch("coinCap", config.coinCap)
  CoinCase.installSlotCompatibility(config.coinCap)
  CoinCase.installHiddenCoinCompatibility(config.coinCap)

  local Service = Services(mod, Catalog, Pawn, config)
  local UI = UIFactory(mod, Service, Catalog, Pawn, config)
  local function play(game, name) Sound.play(game.data, name) end
  local common = {
    mod = mod, coins = Service.coins, coinCap = config.coinCap,
    close = UI.close, play = play,
  }
  local function context(extra)
    local out = {}
    for key, value in pairs(common) do out[key] = value end
    for key, value in pairs(extra) do out[key] = value end
    return out
  end

  local Blackjack = loadLocal(mod, paths.blackjack .. "screen.lua")(context({
    rules = Rules, view = BlackjackView, bets = blackjackBets,
  }))
  local Holdem = loadLocal(mod, paths.holdem .. "screen.lua")(context({
    rules = HoldemRules, view = HoldemView, cardView = BlackjackView,
    bets = holdemBets,
  }))
  local Crash = loadLocal(mod, paths.crash .. "screen.lua")(context({
    rules = CrashRules, view = CrashView,
  }))
  local TubeFlyer = loadLocal(mod, paths.tube .. "screen.lua")(context({
    rules = FlappyRules, view = TubeView,
  }))
  local PrizeCase = loadLocal(mod, paths.case .. "screen.lua")(context({
    rules = CaseRules, view = CaseView,
    rewardPool = function(game) return Service.caseRewardPool(game, CaseRules) end,
    giveReward = Service.giveCaseReward,
  }))

  for screen, class in pairs({
    [ids.blackjack] = Blackjack, [ids.holdem] = Holdem,
    [ids.crash] = Crash, [ids.tube] = TubeFlyer, [ids.case] = PrizeCase,
  }) do mod.content.screens:register(screen, { new = class.new }) end
  mod.content.screens:register(ids.pokemon, { new = UI.pokemonMenu })
  mod.content.screens:register(ids.item, { new = UI.itemMenu })

  for _, tableDef in ipairs({
    { id = "BLACKJACK", file = "blackjack" },
    { id = "HOLDEM", file = "holdem" },
  }) do
    for piece = 1, 8 do
      mod.content.sprites:register(("SPRITE_%s_TABLE_%02d"):format(tableDef.id, piece), {
        image = ("save/mod-derived/blackjack_corner/world/%s_table_%02d.png")
          :format(tableDef.file, piece), frames = 1, trueColor = true,
      })
    end
  end
  for _, machine in ipairs({ "crash", "flappy", "case" }) do
    for piece = 1, 2 do
      mod.content.sprites:register(("SPRITE_ARCADE_%s_%02d")
        :format(machine:upper(), piece), {
          image = ("save/mod-derived/blackjack_corner/world/%s_machine_%02d.png")
            :format(machine, piece), frames = 1, trueColor = true,
        })
    end
  end
  Lounge.register(mod, ids.lounge)

  mod.content.map_scripts:register("GAME_CORNER", { talk = {
    TEXT_GAMECORNER_CLERK1 = UI.coinClerk,
    TEXT_GAMECORNER_CLERK = UI.coinClerk,
    TEXT_PAWN_BROKER = UI.pawnBroker,
    TEXT_BLACKJACK_LOUNGE_SIGN = function(game, _, _, done)
      UI.text(game, "CASINO LOUNGE\nTwo tables open!", done)
    end,
  } })

  local function open(game, message, screen, done)
    UI.openAfterMessage(game, message, screen, done)
  end
  mod.content.map_scripts:register(ids.lounge, { talk = {
    TEXT_BLACKJACK_TABLE = function(game, _, _, done)
      open(game, "Welcome to the\nBLACKJACK table!\fPlace your bet and\nplay to 21.",
        ids.blackjack, done)
    end,
    TEXT_BLACKJACK_DEALER = function(game, _, _, done)
      open(game, "The table is open.\fClosest to 21\nwins the hand.", ids.blackjack, done)
    end,
    TEXT_HOLDEM_TABLE = function(game, _, _, done)
      open(game, "TEXAS HOLD'EM!\fChoose a starting\nbet, then DEAL.\fBet or CHECK on\neach round.",
        ids.holdem, done)
    end,
    TEXT_HOLDEM_DEALER = function(game, _, _, done)
      open(game, "Bet before FLOP,\nafter FLOP,\fand at RIVER.\fBest five-card hand\nwins.",
        ids.holdem, done)
    end,
    TEXT_CASINO_HOSTESS = function(game, _, _, done)
      UI.text(game, "Welcome to the\nCASINO LOUNGE!\fBLACKJACK left,\nHOLD'EM right.", done)
    end,
    TEXT_BLACKJACK_PATRON = function(game, _, _, done)
      UI.text(game, "I always double\ndown on eleven!", done)
    end,
    TEXT_HOLDEM_PATRON = function(game, _, _, done)
      UI.text(game, "Four times before\nthe FLOP is bold!\fWait too long and\nyou can only bet 1x.", done)
    end,
    TEXT_CRASH_MACHINE = function(game, _, _, done)
      open(game, "CRASH!\fMultiplier climbs.\nCash out before it drops!", ids.crash, done)
    end,
    TEXT_FLAPPY_MACHINE = function(game, _, _, done)
      open(game, "TUBE FLYER!\f10 coins to play.\nEach tube pays 1.", ids.tube, done)
    end,
    TEXT_CASE_MACHINE = function(game, _, _, done)
      open(game, "PRIZE CASE!\f500 coins opens\none mystery prize.", ids.case, done)
    end,
  } })

  mod.content.map_scripts:register("GAME_CORNER_PRIZE_ROOM", { talk = {
    TEXT_GAMECORNERPRIZEROOM_PRIZE_VENDOR_1 = function(game, _, _, done)
      open(game, "Exchange coins for\nPOKEMON prizes?", ids.pokemon, done)
    end,
    TEXT_GAMECORNERPRIZEROOM_PRIZE_VENDOR_2 = function(game, _, _, done)
      open(game, "Normal or SHINY?\nYou choose!", ids.pokemon, done)
    end,
    TEXT_GAMECORNERPRIZEROOM_PRIZE_VENDOR_3 = function(game, _, _, done)
      open(game, "Rare items for\nGame Corner coins!", ids.item, done)
    end,
  } })

  local shinyArt = {}
  for name in ([=[
    ABRA KADABRA ALAKAZAM CLEFAIRY WIGGLYTUFF NIDORINA NIDOQUEEN NIDORINO NIDOKING
    DRATINI DRAGONAIR DRAGONITE PORYGON BULBASAUR IVYSAUR VENUSAUR
    CHARMANDER CHARMELEON CHARIZARD SQUIRTLE WARTORTLE BLASTOISE
    OMANYTE OMASTAR KABUTO KABUTOPS AERODACTYL SANDSHREW SANDSLASH
    VULPIX NINETALES MEOWTH PERSIAN BELLSPROUT WEEPINBELL VICTREEBEL
    PINSIR MAGMAR EKANS ARBOK ODDISH GLOOM VILEPLUME MANKEY PRIMEAPE
    GROWLITHE ARCANINE SCYTHER ELECTABUZZ
  ]=]):gmatch("%S+") do shinyArt[name] = true end
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    path = next(path, ctx)
    if not (ctx and ctx.mon and shinyArt[ctx.species] and Stats.isShiny(ctx.mon.dvs)) then
      return path
    end
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

  mod.exports.rules, mod.exports.view = Rules, BlackjackView
  mod.exports.holdem_rules, mod.exports.holdem_view = HoldemRules, HoldemView
  mod.exports.catalog = Catalog
  mod.exports.buyPokemon, mod.exports.buyItem = Service.buyPokemon, Service.buyItem
  mod.exports.buyCoins, mod.exports.coinOffers = Service.buyCoins, Service.coinOffers
  mod.exports.pawn, mod.exports.pawnLedger = Pawn, Service.pawnLedger
  mod.exports.pawnPokemon, mod.exports.redeemPokemon =
    Service.pawnPokemon, Service.redeemPokemon
  mod.exports.crash_rules, mod.exports.flappy_rules = CrashRules, FlappyRules
  mod.exports.case_rules, mod.exports.giveCaseReward = CaseRules, Service.giveCaseReward
end
