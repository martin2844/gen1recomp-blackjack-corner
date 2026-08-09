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
    case = "games/prize_case/", horse = "games/horse_racing/",
    plinko = "games/plinko/", roulette = "games/starter_roulette/",
  }
  local Rules = loadLocal(mod, paths.blackjack .. "rules.lua")
  local BlackjackView = loadLocal(mod, paths.blackjack .. "view.lua")
  local HoldemRules = loadLocal(mod, paths.holdem .. "rules.lua")
  local HoldemView = loadLocal(mod, paths.holdem .. "view.lua")
  local CrashRules = loadLocal(mod, paths.crash .. "rules.lua")
  local FlappyRules = loadLocal(mod, paths.tube .. "rules.lua")
  local CaseRules = loadLocal(mod, paths.case .. "rules.lua")
  local HorseRules = loadLocal(mod, paths.horse .. "rules.lua")
  local PlinkoRules = loadLocal(mod, paths.plinko .. "rules.lua")
  local RouletteRules = loadLocal(mod, paths.roulette .. "rules.lua")
  local ArcadeUI = loadLocal(mod, "games/shared/ui.lua")
  local CrashView = loadLocal(mod, paths.crash .. "view.lua")(ArcadeUI)
  local TubeView = loadLocal(mod, paths.tube .. "view.lua")(ArcadeUI)
  local CaseView = loadLocal(mod, paths.case .. "view.lua")(ArcadeUI)
  local HorseView = loadLocal(mod, paths.horse .. "view.lua")(ArcadeUI)
  local PlinkoView = loadLocal(mod, paths.plinko .. "view.lua")(ArcadeUI)
  local RouletteView = loadLocal(mod, paths.roulette .. "view.lua")(ArcadeUI)
  local Catalog = loadLocal(mod, "other/prizes/catalog.lua")
  local Pawn = loadLocal(mod, "other/pawn/rules.lua")
  local Services = loadLocal(mod, "other/services.lua")
  local UIFactory = loadLocal(mod, "other/ui.lua")
  local CoinCase = loadLocal(mod, "other/coin_case.lua")
  local Lounge = loadLocal(mod, "other/lounge.lua")
  local GambleMode = loadLocal(mod, "other/gamble/mode.lua")
  local GymCases = loadLocal(mod, "other/gamble/gym_cases.lua")
  local CampaignState = loadLocal(mod, "other/gamble/state.lua")
  local ReputationRules = loadLocal(mod, "other/gamble/reputation/rules.lua")
  local ReputationService = loadLocal(mod, "other/gamble/reputation/service.lua")
  local ReputationScreen = loadLocal(mod, "other/gamble/reputation/screen.lua")
  local PalletCasino = loadLocal(mod, "other/pallet_casino.lua")
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
    horse = "BlackjackCornerHorseRacing",
    plinko = "BlackjackCornerPlinko",
    roulette = "BlackjackCornerStarterRoulette",
    gymCase = "BlackjackCornerGymCase",
    highRoller = "BlackjackCornerHighRoller",
    lounge = "BLACKJACK_LOUNGE",
    pallet = "PALLET_CASINO",
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
  local Progress
  local function play(game, name) Sound.play(game.data, name) end
  local common = {
    mod = mod, coins = Service.coins, coinCap = config.coinCap,
    close = UI.close, play = play,
    beginRound = function(gameId, stake)
      return Progress and Progress.beginRound(gameId, stake) or nil
    end,
    increaseStake = function(token, stake)
      return Progress and Progress.increaseStake(token, stake) or false
    end,
    settleRound = function(game, token, result, returned)
      if not Progress then return false end
      return Progress.settleRound(game, token, result, returned)
    end,
    showRankUp = function(game)
      mod.ui.push(game, ids.highRoller)
    end,
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
  local HorseRacing = loadLocal(mod, paths.horse .. "screen.lua")(context({
    rules = HorseRules, view = HorseView,
  }))
  local Plinko = loadLocal(mod, paths.plinko .. "screen.lua")(context({
    rules = PlinkoRules, view = PlinkoView,
  }))

  local Gamble = GambleMode.install(mod, {
    rules = RouletteRules, service = Service, screenId = ids.roulette,
    text = UI.text,
  })
  Progress = ReputationService(mod, {
    state = CampaignState, rules = ReputationRules,
    active = Gamble.active, coinCap = config.coinCap,
  })
  local HighRoller = ReputationScreen({
    mod = mod, ui = ArcadeUI, rules = ReputationRules,
    progress = Progress, close = UI.close,
  })
  local StarterRoulette = loadLocal(mod, paths.roulette .. "screen.lua")({
    mod = mod, rules = RouletteRules, view = RouletteView,
    close = UI.close, play = play, complete = Gamble.complete,
  })
  local Gym = GymCases.install(mod, { active = Gamble.active, screenId = ids.gymCase })
  local GymCase = loadLocal(mod, paths.case .. "screen.lua")(context({
    rules = GymCases.rules(CaseRules), view = CaseView, cost = 0,
    title = "GYM CASE", autoOpen = true, oneShot = true,
    counterKey = "gym_cases_opened", rewardPool = Gym.pool,
    giveReward = Service.giveCaseReward, onChosen = Gym.onChosen,
    onDelivered = Gym.onDelivered,
  }))

  for screen, class in pairs({
    [ids.blackjack] = Blackjack, [ids.holdem] = Holdem,
    [ids.crash] = Crash, [ids.tube] = TubeFlyer, [ids.case] = PrizeCase,
    [ids.horse] = HorseRacing, [ids.plinko] = Plinko,
    [ids.roulette] = StarterRoulette, [ids.gymCase] = GymCase,
    [ids.highRoller] = HighRoller,
  }) do mod.content.screens:register(screen, { new = class.new }) end
  mod.content.screens:register(ids.pokemon, { new = UI.pokemonMenu })
  mod.content.screens:register(ids.item, { new = UI.itemMenu })

  mod.events:on("intro.oak_speech.answered", function(ev)
    if ev.saveKey == "gamble_mode" and ev.value == true then Progress.ensure() end
  end)
  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" or not Gamble.active() then return out end
    Progress.ensure()
    return mod.ui.insertBefore(out, "SAVE", {
      label = "HIGH ROLLER",
      onSelect = function() mod.ui.push(game, ids.highRoller) end,
    })
  end)

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
  for _, machine in ipairs({ "crash", "flappy", "case", "horse", "plinko" }) do
    for piece = 1, 2 do
      mod.content.sprites:register(("SPRITE_ARCADE_%s_%02d")
        :format(machine:upper(), piece), {
          image = ("save/mod-derived/blackjack_corner/world/%s_machine_%02d.png")
            :format(machine, piece), frames = 1, trueColor = true,
        })
    end
  end
  for piece = 1, 3 do
    mod.content.sprites:register(("SPRITE_STARTER_ROULETTE_%02d"):format(piece), {
      image = ("save/mod-derived/blackjack_corner/world/starter_roulette_%02d.png")
        :format(piece), frames = 1, trueColor = true,
    })
  end
  Lounge.register(mod, ids.lounge)
  PalletCasino.register(mod, ids)

  mod.content.map_scripts:register("GAME_CORNER", { talk = {
    TEXT_GAMECORNER_CLERK1 = UI.coinClerk,
    TEXT_GAMECORNER_CLERK = UI.coinClerk,
    TEXT_PAWN_BROKER = UI.pawnBroker,
    TEXT_CASINO_DEBTOR = function(game, _, _, done)
      UI.text(game, "I had a winning\nsystem yesterday.\fToday I sold my\nBIKE to test it.", done)
    end,
    TEXT_CASINO_DREAMER = function(game, _, _, done)
      UI.text(game, "One jackpot and\nI'm leaving town.\fThat's what I said\nlast month.", done)
    end,
    TEXT_CASINO_REGULAR = function(game, _, _, done)
      UI.text(game, "The floor hides\ncoins sometimes.\fPeople stare at\nscreens, not down.", done)
    end,
    TEXT_BLACKJACK_LOUNGE_SIGN = function(game, _, _, done)
      UI.text(game, "CASINO LOUNGE\nTables up front.\fLive arcade in\nthe back!", done)
    end,
  } })

  local function open(game, message, screen, done)
    UI.openAfterMessage(game, message, screen, done)
  end
  local function reactiveText(game, ordinary, regular, vip, cold)
    local state = Progress.snapshot(game)
    if not state then return ordinary end
    if cold and state.currentLossStreak >= 5 then return cold end
    if vip and (state.rank == "VIP" or state.rank == "HIGH_ROLLER") then return vip end
    if regular and state.rank == "REGULAR" then return regular end
    return ordinary
  end
  local function reactiveTalk(ordinary, regular, vip, cold)
    return function(game, _, _, done)
      UI.text(game, reactiveText(game, ordinary, regular, vip, cold), done)
    end
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
    TEXT_CASINO_HOSTESS = reactiveTalk(
      "Welcome to the\nCASINO LOUNGE!\fTables up front.\nArcade in back.",
      "Back again?\fThe dealers know\nyour face now.",
      "Welcome, HIGH\nROLLER.\fYour favorite table\nis waiting.",
      "Rough streak?\fThe house always\nremembers a return."),
    TEXT_BLACKJACK_PATRON = reactiveTalk(
      "I always double\ndown on eleven!",
      "A REGULAR, huh?\fDon't start giving\nme advice.",
      "They polish your\nseat before you sit.",
      "Five losses?\fMaybe double down\non going home."),
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
    TEXT_HORSE_RACING = function(game, _, _, done)
      open(game, "LIVE RACE TV!\fPick a runner and\nback it with coins.", ids.horse, done)
    end,
    TEXT_PLINKO = function(game, _, _, done)
      open(game, "PLINKO!\fDrop the ball.\nTrust the pegs.", ids.plinko, done)
    end,
    TEXT_LOUNGE_COLD_STREAK = reactiveTalk(
      "Seven cold hands.\fThe eighth has to\nturn around... right?",
      "They call you a\nREGULAR now.\fCareful. That's how\nit starts.",
      "A VIP!\fTell the house I\nnever complained.",
      "That look...\fYou know the cold\nstreak too."),
    TEXT_LOUNGE_CARD_COUNTER = function(game, _, _, done)
      UI.text(game, "I count every card.\fThen panic and bet\nthe wrong table.", done)
    end,
    TEXT_LOUNGE_LAST_CHIP = function(game, _, _, done)
      UI.text(game, "This is my last\nchip.\fI've said that\nthree times tonight.", done)
    end,
  } })

  mod.content.map_scripts:register("PALLET_TOWN", { talk = {
    TEXT_PALLET_CASINO_SIGN = function(game, _, _, done)
      UI.text(game, "PALLET CASINO\nLuck starts here.\fRegret starts\ninside.", done)
    end,
  } })
  mod.content.map_scripts:register(ids.pallet, { talk = {
    TEXT_PALLET_BLACKJACK_TABLE = function(game, _, _, done)
      open(game, "PALLET BLACKJACK!\fGet closer to 21\nthan the dealer.", ids.blackjack, done)
    end,
    TEXT_PALLET_HOLDEM_TABLE = function(game, _, _, done)
      open(game, "PALLET HOLD'EM!\fBeat the house with\nyour best five cards.", ids.holdem, done)
    end,
    TEXT_HORSE_RACING = function(game, _, _, done)
      open(game, "LIVE RACE TV!\fPick a runner and\nback it with coins.", ids.horse, done)
    end,
    TEXT_PLINKO = function(game, _, _, done)
      open(game, "PLINKO!\fDrop the ball.\nTrust the pegs.", ids.plinko, done)
    end,
    TEXT_CASE_MACHINE = function(game, _, _, done)
      open(game, "PRIZE CASE!\f500 coins opens\none mystery prize.", ids.case, done)
    end,
    TEXT_PALLET_CASINO_PAWN = UI.pawnBroker,
    TEXT_PALLET_CASINO_CLERK = UI.coinClerk,
    TEXT_PALLET_CASINO_GRANNY = reactiveTalk(
      "I came for milk.\fThat was six hours\nago.",
      "Oh, they know you\nhere already.",
      "A big player from\nour little town!",
      "Dear, take a walk.\fLuck needs room\nto find you."),
    TEXT_PALLET_CASINO_GAMBLER = reactiveTalk(
      "COMET is safe.\fSafe bets are how\nthey get you.",
      "REGULAR already?\fPallet raises them\nfast.",
      "VIP odds are still\nhouse odds, friend.",
      "Cold tables spread.\fMaybe don't stand\nso close."),
    TEXT_PALLET_CASINO_YOUNGSTER = function(game, _, _, done)
      UI.text(game, "Mom thinks I'm at\nPROF.OAK's lab.\fDon't tell her.", done)
    end,
    TEXT_PALLET_CASINO_LOSER = function(game, _, _, done)
      UI.text(game, "I pawned my best\nPOKEMON.\fThirty percent feels\nvery far away.", done)
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
  mod.exports.horse_rules, mod.exports.plinko_rules = HorseRules, PlinkoRules
  mod.exports.roulette_rules, mod.exports.roulette_view = RouletteRules, RouletteView
  mod.exports.gamble = Gamble
  mod.exports.gym_cases = Gym
  mod.exports.campaign_state = CampaignState
  mod.exports.reputation_rules = ReputationRules
  mod.exports.reputation = Progress
end
