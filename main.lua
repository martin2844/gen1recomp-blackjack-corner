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
    arena = "games/battle_arena/",
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
  local ArenaRules = loadLocal(mod, paths.arena .. "rules.lua")
  local ShinyFallback = loadLocal(mod, "other/shiny/fallback.lua")
  local ArcadeUI = loadLocal(mod, "games/shared/ui.lua")
  local CrashView = loadLocal(mod, paths.crash .. "view.lua")(ArcadeUI)
  local TubeView = loadLocal(mod, paths.tube .. "view.lua")(ArcadeUI)
  local CaseView = loadLocal(mod, paths.case .. "view.lua")(ArcadeUI)
  local HorseView = loadLocal(mod, paths.horse .. "view.lua")(ArcadeUI)
  local PlinkoView = loadLocal(mod, paths.plinko .. "view.lua")(ArcadeUI)
  local RouletteView = loadLocal(mod, paths.roulette .. "view.lua")(ArcadeUI)
  local ArenaView = loadLocal(mod, paths.arena .. "view.lua")(ArcadeUI)
  local Catalog = loadLocal(mod, "other/prizes/catalog.lua")
  local Pawn = loadLocal(mod, "other/pawn/rules.lua")
  local Services = loadLocal(mod, "other/services.lua")
  local UIFactory = loadLocal(mod, "other/ui.lua")
  local CoinCase = loadLocal(mod, "other/coin_case.lua")
  local WorldHelpers = loadLocal(mod, "other/world_helpers.lua")
  local Lounge = loadLocal(mod, "other/lounge.lua")(WorldHelpers)
  local GambleMode = loadLocal(mod, "other/gamble/mode.lua")
  local GymCases = loadLocal(mod, "other/gamble/gym_cases.lua")
  local CampaignState = loadLocal(mod, "other/gamble/state.lua")
  local ReputationRules = loadLocal(mod, "other/gamble/reputation/rules.lua")
  local ReputationService = loadLocal(mod, "other/gamble/reputation/service.lua")
  local ReputationScreen = loadLocal(mod, "other/gamble/reputation/screen.lua")
  local CreditRules = loadLocal(mod, "other/gamble/credit/rules.lua")
  local CreditService = loadLocal(mod, "other/gamble/credit/service.lua")
  local CreditUIFactory = loadLocal(mod, "other/gamble/credit/ui.lua")
  local CreditWorld = loadLocal(mod, "other/gamble/credit/world.lua")(WorldHelpers)
  local HouseService = loadLocal(mod, "other/gamble/credit/house_service.lua")
  local HouseWorld = loadLocal(mod, "other/gamble/credit/house_world.lua")(WorldHelpers)
  local ArenaServiceFactory = loadLocal(mod, paths.arena .. "service.lua")
  local ArenaWorld = loadLocal(mod, "other/gamble/arena_world.lua")(WorldHelpers)
  local ArenaSecurityFactory = loadLocal(mod, "other/gamble/arena_security.lua")
  local ArenaStoryFactory = loadLocal(mod, "other/gamble/arena_story.lua")
  local StoryWorld = loadLocal(mod, "other/gamble/story_world.lua")(WorldHelpers)
  local PalletCasino = loadLocal(mod, "other/pallet_casino.lua")(WorldHelpers)
  local CityCasinos = loadLocal(mod, "other/city_casinos.lua")(WorldHelpers)
  local CaseChallengers = loadLocal(mod,
    "other/gamble/case_challengers.lua")(WorldHelpers)
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
    arena = "BlackjackCornerBattleArena",
    arenaLobby = ArenaWorld.LOBBY,
    arenaMap = ArenaWorld.ARENA,
  }
  local config = {
    coinCap = 1000000,
    coinBundle = 50,
    coinBundlePrice = 1000,
    masterBallKey = "master_ball_redeemed",
    pawnLedgerKey = "pawned_pokemon",
  }
  local blackjackBets, holdemBets = { 10, 50, 100, 500 }, { 10, 50, 100, 500 }

  mod.content.constants:patch("coinCap", config.coinCap)
  CoinCase.installSlotCompatibility(config.coinCap)
  CoinCase.installHiddenCoinCompatibility(config.coinCap)

  local Service = Services(mod, Catalog, Pawn, config)
  local UI = UIFactory(mod, Service, Catalog, Pawn, config)
  local Progress, Credit, Arena, ArenaSecurity, ArenaStory
  local function play(game, name) Sound.play(game.data, name) end
  local common = {
    mod = mod, coins = Service.coins, coinCap = config.coinCap,
    creditPayout = Service.creditCoins,
    close = UI.close, play = play,
    beginRound = function(gameId, stake, durable)
      return Progress and Progress.beginRound(gameId, stake, durable) or nil
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
    canOpen = function(game)
      return not Credit or Credit.luxuryAllowed(game)
    end,
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
  ArenaStory = ArenaStoryFactory(mod, {
    state = CampaignState, active = Gamble.active, coinCap = config.coinCap,
  })
  Credit = CreditService(mod, {
    state = CampaignState, rules = CreditRules, active = Gamble.active,
    coinCap = config.coinCap, badgeCount = ReputationRules.badgeCount,
    rank = function(game)
      local snapshot = Progress.snapshot(game)
      return snapshot and snapshot.rank or "ROOKIE"
    end,
    newLoansAllowed = function()
      local story = ArenaStory.snapshot()
      return not story or story.ending.choice ~= ArenaStory.ENDINGS.EXPOSE
    end,
  })
  local House = HouseService(mod, {
    state = CampaignState, active = Gamble.active, coinCap = config.coinCap,
  })
  Arena = ArenaServiceFactory(mod, {
    state = CampaignState, rules = ArenaRules, active = Gamble.active,
    coinCap = config.coinCap,
    rank = function(game)
      local snapshot = Progress.snapshot(game)
      return snapshot and snapshot.rank or "ROOKIE"
    end,
    allowed = function(game) return Credit.luxuryAllowed(game) end,
    beginRound = common.beginRound, settleRound = common.settleRound,
    exhibition = ArenaStory.exhibitionAvailable,
    settleExhibition = function(game, matchId, won)
      local ok, state, reason = ArenaStory.settleExhibition(game, matchId, won)
      StoryWorld.sync(game, ArenaStory, ok and won)
      return ok, state, reason
    end,
  })
  ArenaSecurity = ArenaSecurityFactory(mod, {
    state = CampaignState, active = Gamble.active,
    lobbyMap = ids.arenaLobby, arenaMap = ids.arenaMap,
  })
  config.luxuryAllowed = Credit.luxuryAllowed
  local function syncCampaignWorld(game)
    local reward, rewardPending = ArenaStory.deliverEndingReward(game)
    local collectors = CreditWorld.sync(game, Credit)
    local occupied = HouseWorld.sync(game, House)
    local arena = ArenaWorld.sync(game, ArenaSecurity)
    local story = StoryWorld.sync(game, ArenaStory)
    return collectors, occupied, arena, story, reward, rewardPending
  end
  local CreditUI = CreditUIFactory(mod, {
    credit = Credit, rules = CreditRules, text = UI.text,
    house = House,
    pawnPokemon = Service.pawnPokemon, pawnQuote = Service.pawnQuote,
    pawnLedger = Service.pawnLedger, pawnLimit = Pawn.LIMIT,
    syncWorld = syncCampaignWorld,
  })
  local HighRoller = ReputationScreen({
    mod = mod, ui = ArcadeUI, rules = ReputationRules,
    progress = Progress, story = ArenaStory, close = UI.close,
  })
  local StarterRoulette = loadLocal(mod, paths.roulette .. "screen.lua")({
    mod = mod, rules = RouletteRules, view = RouletteView,
    close = UI.close, play = play, complete = Gamble.complete,
  })
  local BattleArena = loadLocal(mod, paths.arena .. "screen.lua")(context({
    rules = ArenaRules, view = ArenaView, service = Arena,
  }))
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
    [ids.arena] = BattleArena,
  }) do mod.content.screens:register(screen, { new = class.new }) end
  mod.content.screens:register(ids.pokemon, { new = UI.pokemonMenu })
  mod.content.screens:register(ids.item, { new = UI.itemMenu })

  mod.events:on("intro.oak_speech.answered", function(ev)
    if ev.saveKey == "gamble_mode" and ev.value == true then Progress.ensure() end
  end)
  mod.hooks:wrap("save.write", function(next, game)
    if not Progress.canSave(game) then return false end
    return next(game)
  end)
  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" or not Gamble.active() then return out end
    Progress.ensure()
    Credit.syncMilestones(game)
    syncCampaignWorld(game)
    return mod.ui.insertBefore(out, "SAVE", {
      label = "HIGH ROLLER",
      onSelect = function() mod.ui.push(game, ids.highRoller) end,
    })
  end)

  local function reconcileArenaRoute(game, mapId, fromMapId)
    if not game then return end
    -- Recover saves made by the retired party-vault mechanic before doing any
    -- active-campaign world work. New visits never remove the live party.
    ArenaSecurity.entered(game, mapId, fromMapId)
    if not Gamble.active() then return end
    ArenaWorld.sync(game, ArenaSecurity)
    StoryWorld.sync(game, ArenaStory)
  end
  -- Reconcile before the destination spawns so both permanent staff objects
  -- are already visible on the first frame.
  mod.events:on("map.exited", function(ev)
    local game = require("src.core.Game")
    reconcileArenaRoute(game, ev and ev.toMapId, ev and ev.mapId)
  end)
  -- Also reconcile boot/debug warps and old saves that begin inside the route.
  mod.events:on("map.entered", function(ev)
    local game = require("src.core.Game")
    reconcileArenaRoute(game, ev and ev.mapId, ev and ev.fromMapId)
  end)
  mod.events:on("game.ready", function(ev)
    local game = ev and ev.game
    local current = mod.world:current()
    if game and current then reconcileArenaRoute(game, current.mapId, nil) end
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
  CreditWorld.register(mod)
  HouseWorld.register(mod)
  ArenaWorld.register(mod, ids.lounge)
  StoryWorld.register(mod)
  CityCasinos.register(mod)

  local function endingChoice()
    local story = ArenaStory.snapshot()
    return story and story.ending and story.ending.choice or nil
  end

  mod.content.map_scripts:register("GAME_CORNER", { talk = {
    TEXT_GAMECORNER_CLERK1 = UI.coinClerk,
    TEXT_GAMECORNER_CLERK = UI.coinClerk,
    TEXT_PAWN_BROKER = UI.pawnBroker,
    TEXT_CASINO_DEBTOR = function(game, _, _, done)
      local ending = endingChoice()
      UI.text(game, ending == ArenaStory.ENDINGS.EXPOSE
        and "ROCKET odds leaked.\fTurns out my system\nwas their system."
        or ending == ArenaStory.ENDINGS.CHAMPION
          and "The CHAMPION walks\nwith us?\fMaybe my luck just\nchanged."
        or "I had a winning\nsystem yesterday.\fToday I sold my\nBIKE to test it.", done)
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
  local function openLuxury(game, message, screen, done)
    local allowed, frozen = Credit.luxuryAllowed(game)
    if not allowed then UI.text(game, frozen, done); return end
    open(game, message, screen, done)
  end
  CityCasinos.registerScripts(mod, {
    ids = ids, text = UI.text, coinClerk = UI.coinClerk,
    open = open, openLuxury = openLuxury,
  })
  local Challengers = CaseChallengers.register(mod, {
    active = Gamble.active, gym = Gym, text = UI.text,
    openCase = function(game, entry, location)
      local definition = Gym.definitions[entry.badge]
      UI.text(game, location.won .. "\fA themed CASE waits.\nGive it one spin.", function()
        mod.ui.push(game, ids.gymCase, { caseData = entry, autoOpen = true,
          oneShot = true, title = (definition and definition.theme or "GYM") .. " CASE" })
      end)
    end,
  })
  local function reactiveText(game, ordinary, regular, vip, cold,
      exposed, champion)
    local state = Progress.snapshot(game)
    if not state then return ordinary end
    local ending = endingChoice()
    if ending == ArenaStory.ENDINGS.EXPOSE and exposed then return exposed end
    if ending == ArenaStory.ENDINGS.CHAMPION and champion then return champion end
    if cold and state.currentLossStreak >= 5 then return cold end
    if vip and ReputationRules.atLeast(state.rank, "HIGH_ROLLER") then return vip end
    if regular and state.rank == "REGULAR" then return regular end
    return ordinary
  end
  local function reactiveTalk(ordinary, regular, vip, cold, exposed, champion)
    return function(game, _, _, done)
      UI.text(game, reactiveText(game, ordinary, regular, vip, cold,
        exposed, champion), done)
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
      "Rough streak?\fThe house always\nremembers a return.",
      "You brought light\ndownstairs.\fSome guests preferred\nthe dark.",
      "Welcome, CHAMPION.\fYour table is always\nreserved."),
    TEXT_BLACKJACK_PATRON = reactiveTalk(
      "I always double\ndown on eleven!",
      "A REGULAR, huh?\fDon't start giving\nme advice.",
      "They polish your\nseat before you sit.",
      "Five losses?\fMaybe double down\non going home."),
    TEXT_HOLDEM_PATRON = function(game, _, _, done)
      UI.text(game, "Four times before\nthe FLOP is bold!\fWait too long and\nyou can only bet 1x.", done)
    end,
    TEXT_ROCKET_CREDIT = CreditUI.broker,
    TEXT_CRASH_MACHINE = function(game, _, _, done)
      open(game, "CRASH!\fMultiplier climbs.\nCash out before it drops!", ids.crash, done)
    end,
    TEXT_FLAPPY_MACHINE = function(game, _, _, done)
      open(game, "TUBE FLYER!\f10 coins to play.\nEach tube pays 1.", ids.tube, done)
    end,
    TEXT_CASE_MACHINE = function(game, _, _, done)
      openLuxury(game, "PRIZE CASE!\f500 coins opens\none mystery prize.", ids.case, done)
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
    TEXT_ARENA_TERMINAL = function(game, _, _, done)
      local route = ArenaSecurity.snapshot()
      if route and route.stairsRevealed then
        UI.text(game, "The terminal has\nretracted.\fCold air climbs\nfrom below.", done)
        return
      end
      local allowed, reason = Arena.access(game)
      if not allowed then
        UI.text(game, "ROCKET STATUS\nTERMINAL\fSCANNING PLAYER...\fCLEARANCE DENIED.\f"
          .. reason, done)
        return
      end
      local function reveal()
        UI.text(game, "ROCKET STATUS\nTERMINAL\fSCANNING PLAYER...\fKINGPIN VERIFIED.\fWELCOME, HIGH ROLLER.\fGears grind inside\nthe floor...\fA staircase opens\nbelow CELADON.", function()
          ArenaSecurity.revealStairs()
          if done then done() end
          ArenaWorld.sync(game, ArenaSecurity, true)
        end)
      end
      local function presentRankUps()
        local progress = Progress.snapshot(game)
        if progress and #progress.pendingRankUps > 0 then
          mod.ui.push(game, ids.highRoller, { onClose = presentRankUps })
        else
          reveal()
        end
      end
      -- A badge ceiling can make KINGPIN become reachable at this exact
      -- interaction. Never let the terminal silently consume that one-time rank
      -- introduction before the player sees it.
      local progress = Progress.snapshot(game)
      if progress and #progress.pendingRankUps > 0 then
        UI.text(game, "ROCKET STATUS\nTERMINAL\fCLEARANCE UPDATE!", presentRankUps)
      else
        reveal()
      end
    end,
  } })

  local function arenaClue(game, clueId, foundText, waitingText, knownText, done)
    local added, state, reason = ArenaStory.discover(game, clueId)
    if reason == "NOT READY" or not state then
      UI.text(game, waitingText, done)
      return
    end
    local text = added and foundText or knownText
    text = text .. ("\fCLUES %d OF %d."):format(
      state.clueCount, state.clueTarget)
    if reason == "LEAD COMPLETE" then
      text = text .. "\fThe three records\nmatch.\fArena Pokemon came\nfrom CINNABAR.\fA Rocket seal marks\nLAB WEST WING."
    end
    UI.text(game, text, done)
  end

  mod.content.map_scripts:register(ids.arenaLobby, { talk = {
    TEXT_ARENA_GREETER = function(game, _, _, done)
      local story = ArenaStory.snapshot(game)
      if story and story.stage == ArenaStory.STAGES.EXPOSED then
        UI.text(game, "You chose EXPOSE.\fThe lift stays open.\nThe welcome is gone.", done)
      elseif story and story.stage == ArenaStory.STAGES.CHAMPION then
        UI.text(game, "HOUSE CHAMPION.\fGreatness waits\nwherever you stand.", done)
      elseif story and story.stage == ArenaStory.STAGES.LEAD then
        UI.text(game, "A HANDLER EXPECTS\nYOU IN CINNABAR.\fAsk about the\nLAB WEST WING.\fForget who sent you.", done)
      else
        UI.text(game, "GREATNESS WAITS\nBELOW.\fWelcome, KINGPIN.", done)
      end
    end,
    TEXT_ARENA_DOORMAN = function(game, _, _, done)
      local story = ArenaStory.snapshot(game)
      if story and story.stage == ArenaStory.STAGES.EXPOSED then
        UI.text(game, "Orders say the pit\nstays open.\fOrders say I stop\nsmiling.", done)
      elseif story and story.stage == ArenaStory.STAGES.CHAMPION then
        UI.text(game, "Your pit, CHAMPION.\fThe board is live.", done)
      elseif story and story.stage == ArenaStory.STAGES.LEAD then
        UI.text(game, "WEST WING burned\ndown twice.\fCINNABAR still logs\nevery visitor.", done)
      else
        UI.text(game, "HOUSE FIGHTERS.\nONLY.\fThe betting floor is\nstraight ahead.", done)
      end
    end,
    TEXT_ARENA_CASHIER = function(game, _, _, done)
      local state = Arena.snapshot(game)
      UI.text(game, ("THE BOARD IS LIVE.\f%s CARD\nFIGHTS %d  WINS %d\fLIMIT %d COINS")
        :format(state.tier.label, state.matchesPlayed, state.wins,
          state.wagerLimit), done)
    end,
    TEXT_ARENA_EXIT = function(game, _, _, done)
      UI.text(game, "Stairs lead back\nto the bright lie\nupstairs.", done)
    end,
    TEXT_ARENA_NERVOUS = function(game, _, _, done)
      UI.text(game, "I sold my NUGGET\non the favorite.\fThe favorite had\na glass jaw.", done)
    end,
    TEXT_ARENA_VETERAN = function(game, _, _, done)
      local state = Arena.snapshot(game)
      if state.wins > state.losses then
        UI.text(game, "This room knows you.\fThe house is\nstudying you too.", done)
      else
        UI.text(game, "Odds tell you what\nthe house fears.\fNot what it knows.", done)
      end
    end,
    TEXT_ARENA_HOSTESS = function(game, _, _, done)
      local ending = endingChoice()
      UI.text(game, ending == ArenaStory.ENDINGS.EXPOSE
        and "No more free tea.\fThe games remain.\nHospitality doesn't."
        or ending == ArenaStory.ENDINGS.CHAMPION
          and "CHAMPION'S service.\fFresh tea.\nNo questions."
        or "Complimentary tea.\fTastes expensive.\nFixes nothing.", done)
    end,
    TEXT_ARENA_SOCIALITE = function(game, _, _, done)
      UI.text(game, "Upstairs they call\nthis bad taste.\fDown here: MA'AM.", done)
    end,
    TEXT_ARENA_BROKE_VIP = function(game, _, _, done)
      UI.text(game, "This couch costs\nmore than a house.\fGood. I don't own\none anymore.", done)
    end,
    TEXT_ARENA_LOBBY_TABLE = function(game, _, _, done)
      UI.text(game, "Crystal glasses.\fEach coaster bears\nTEAM ROCKET's R.", done)
    end,
    TEXT_ARENA_LOBBY_TROPHY = function(game, _, _, done)
      UI.text(game, "CELADON CUP, 1988.\fThe winner's name\nwas filed off.", done)
    end,
    TEXT_ARENA_RECEPTION_TROPHY = function(game, _, _, done)
      UI.text(game, "SOLID GOLD MEOWTH.\fThe eyes follow\nevery loose coin.", done)
    end,
    TEXT_ARENA_LOBBY_PAINTING = function(game, _, _, done)
      arenaClue(game, ArenaStory.CLUES.FRAME,
        "GIOVANNI smiles\nwithout his eyes.\fBehind the frame:\nTRANSFER SERIES 3.\fThe route begins at\nCINNABAR LAB.",
        "GIOVANNI smiles\nwithout his eyes.\fThe brass plaque\nis newly polished.",
        "Behind the painting:\nTRANSFER SERIES 3.\fRoute: CINNABAR\nto CELADON.", done)
    end,
    TEXT_ARENA_LOBBY_PC = function(game, _, _, done)
      local state = Arena.snapshot(game)
      local pending = state and state.pending
      if pending and pending.match then
        UI.text(game, ("PRIVATE NETWORK\fMATCH %d: POSTED\nODDS ENCRYPTED.\fPROPERTY OF R.")
          :format(pending.match.id), done)
      else
        UI.text(game, "PRIVATE NETWORK\fHOLDING ROOM FEED\nMedical records.\fACCESS DENIED.", done)
      end
    end,
  } })

  mod.content.map_scripts:register(ids.arenaMap, {
    onEnter = function(game, ow, fromMapId)
      -- Mirror the Elite Four entrance: the native south warp lands on its
      -- mat, then the room itself walks the player clear of the doorway.
      if fromMapId == ids.arenaLobby and ow.player.cellY >= 17 then
        ow:scriptMove(ow.player, "up", 2)
      end
    end,
    talk = {
    TEXT_ARENA_BOOKIE = function(game, _, _, done)
      local allowed, reason = Arena.access(game)
      if not allowed then UI.text(game, reason, done); return end
      local story = ArenaStory.snapshot(game)
      local invitation = story and story.stage == ArenaStory.STAGES.INVITATION
      local exposed = story and story.stage == ArenaStory.STAGES.EXPOSED
      local champion = story and story.stage == ArenaStory.STAGES.CHAMPION
      open(game, invitation
        and "SERIES 3 IS READY.\nGIOVANNI IS WATCHING.\fPick the fighter.\nWin his audience."
        or exposed and "You burned the ledger.\fThe board survives.\nOdds do not take sides."
        or champion and "Welcome, CHAMPION.\fThe public card is\nyours to command."
        or "NO TRAINER ORDERS.\nNO ITEMS.\nNO MERCY.\fPick the fighter.\nThe pit decides.",
        ids.arena, done)
    end,
    TEXT_BLACKJACK_CORNER_GIOVANNI = function(game, _, _, done)
      local story = ArenaStory.snapshot(game)
      if story and story.stage == ArenaStory.STAGES.CHOICE then
        local openChoice
        local function confirm(choice)
          local expose = choice == ArenaStory.ENDINGS.EXPOSE
          local warning = expose
            and "EXPOSE ROCKET?\nVIP perks end.\fTheir staff turns on\nyou.\fEvery game and route\nstays open.\fThis cannot be\nundone. Proceed?"
            or "JOIN THE HOUSE?\nBecome CHAMPION.\fRocket keeps control.\fA final reward and\nVIP title unlock.\fThis cannot be\nundone. Proceed?"
          game.stack:push(mod.ui.TextBox.new(game, warning, nil, {
            choice = function(yes)
              if not yes then openChoice(); return end
              local ok, _, reason = ArenaStory.chooseEnding(game, choice)
              if not ok then UI.text(game, reason, done); return end
              local _, _, _, _, credited, pending = syncCampaignWorld(game)
              local rewardText = ""
              if not expose then
                rewardText = ("\f%d coins transferred."):format(credited or 0)
                if (pending or 0) > 0 then
                  rewardText = rewardText .. ("\f%d coins BANKED."):format(pending)
                end
              end
              UI.text(game, expose
                and "Then let daylight in.\fThe ledgers leave\nwith you.\fROCKET will remember\nthis choice."
                or "A sensible wager.\fFrom now on, the\nhouse knows your name:\nCHAMPION." .. rewardText, done)
            end,
          }))
        end
        function openChoice()
          game.stack:push(mod.ui.Menu.new(game, {
            { label = "EXPOSE", onSelect = function()
                confirm(ArenaStory.ENDINGS.EXPOSE)
              end },
            { label = "CHAMPION", onSelect = function()
                confirm(ArenaStory.ENDINGS.CHAMPION)
              end },
            { label = "LEAVE", onSelect = done },
          }, { tx = 4, ty = 3, maxVisible = 3, onCancel = done }))
        end
        UI.text(game, "You beat SERIES 3.\fMost people wager\ncoins. You wagered\nyour judgment.\fNow decide what kind\nof winner you are.", openChoice)
      elseif story and story.stage == ArenaStory.STAGES.EXPOSED then
        UI.text(game, "You chose daylight.\fDo not confuse my\nrestraint with\nforgiveness.", done)
      elseif story and story.stage == ArenaStory.STAGES.CHAMPION then
        UI.text(game, "CHAMPION.\fThe house is watching.\nMake it profitable.", done)
      else
        UI.text(game, "The boss has no\nbusiness with you.", done)
      end
    end,
    TEXT_ARENA_TO_LOBBY = function(game, _, _, done)
      UI.text(game, "The lobby door is\nbehind you.", done)
    end,
    TEXT_ARENA_FAN_1 = function(game, _, _, done)
      UI.text(game, "Backed a RATICATE.\fIt fought like a\nDRAGON.\fPaid like one too.", done)
    end,
    TEXT_ARENA_FAN_2 = function(game, _, _, done)
      UI.text(game, "Stats set the odds.\fFear, noise, luck\ntear them apart.", done)
    end,
    TEXT_ARENA_FAN_3 = function(game, _, _, done)
      UI.text(game, "House fighters only.\fNo trainer orders.\nNo excuses either.", done)
    end,
    TEXT_ARENA_FAN_4 = function(game, _, _, done)
      arenaClue(game, ArenaStory.CLUES.MANIFEST,
        "Rare card tonight.\fI heard wings in\nthe holding room.\fA crate tag fell:\nCINNABAR WEST.",
        "Rare card tonight.\fI heard wings in\nthe holding room.\fBig wings.",
        "The crate tag reads:\nCINNABAR WEST.\fLIVE SPECIMEN.\nDO NOT OPEN.", done)
    end,
    TEXT_ARENA_FAN_5 = function(game, _, _, done)
      UI.text(game, "Three losses.\fNext bet is rent.\nAfter that, pride.", done)
    end,
    TEXT_ARENA_FAN_6 = function(game, _, _, done)
      arenaClue(game, ArenaStory.CLUES.CHART,
        "They heal winners\nbehind curtains.\fA torn chart says:\nCELL GROWTH TRIAL.\fDR. FUJI signed it.",
        "They heal winners\nbehind curtains.\fNobody asks about\nthe loser.",
        "The chart names\nDR. FUJI.\fIts subject number\nmatches the crate.", done)
    end,
    TEXT_ARENA_FAN_7 = function(game, _, _, done)
      local ending = endingChoice()
      UI.text(game, ending == ArenaStory.ENDINGS.EXPOSE
        and "Witnesses everywhere.\fBoss hates that\nmost of all."
        or ending == ArenaStory.ENDINGS.CHAMPION
          and "Clear the aisle.\fThe CHAMPION is\nwatching."
        or "Keep aisles clear.\fBoss hates spills,\ncheats, witnesses.", done)
    end,
    TEXT_ARENA_FAN_8 = function(game, _, _, done)
      UI.text(game, "Came for one fight.\fFour BADGES ago,\ndear.", done)
    end,
    TEXT_ARENA_PIT_TABLE = function(game, _, _, done)
      UI.text(game, "Cold tea.\nTorn tickets.\fTicket signed\nMR. FUJI.", done)
    end,
    TEXT_ARENA_PIT_TROPHY = function(game, _, _, done)
      local state = Arena.snapshot(game)
      UI.text(game, ("HOUSE CHAMPION\f%s DIVISION\nYOUR WINS: %d")
        :format(state.tier.label, state.wins), done)
    end,
    TEXT_ARENA_PIT_PAINTING = function(game, _, _, done)
      UI.text(game, "A volcanic island.\fThey scratched\nCINNABAR off the\nbrass frame.", done)
    end,
    TEXT_ARENA_PIT_PC = function(game, _, _, done)
      local state = Arena.snapshot(game)
      local last = state and state.pending and state.pending.match
      if last then
        UI.text(game, ("PIT CONTROL\fMATCH %d ARMED\nCAMERAS: 12\fDOORS: SEALED")
          :format(last.id), done)
      else
        UI.text(game, "PIT CONTROL\fCAMERAS: 12\nCAGES: 6\fDOORS: SEALED", done)
      end
    end,
    },
  })

  mod.content.map_scripts:register("CINNABAR_LAB_METRONOME_ROOM", { talk = {
    TEXT_BLACKJACK_CORNER_CINNABAR_HANDLER = function(game, _, _, done)
      local state = ArenaStory.snapshot(game)
      if state and state.stage == ArenaStory.STAGES.LEAD then
        local advanced = ArenaStory.beginCinnabar(game)
        StoryWorld.sync(game, ArenaStory)
        if advanced then
          UI.text(game, "KINGPIN.\nYou read too much.\fThis copy came from\nLAB ARCHIVE 3.\fFind its specimen\nlog in the MANSION\nbasement.", done)
          return
        end
      end
      if state and state.stage == ArenaStory.STAGES.INVESTIGATION then
        UI.text(game, "The matching log is\nin MANSION B1.\fA researcher waits\nnear the old diary.", done)
      elseif state and state.stage == ArenaStory.STAGES.INVITATION then
        UI.text(game, "Your invitation is\nauthenticated.\fReturn to the pit.\nDo not be late.", done)
      elseif state and state.stage == ArenaStory.STAGES.EXPOSED then
        UI.text(game, "The archive is public.\fThe Lab denies it.\nROCKET cannot.", done)
      elseif state and state.stage == ArenaStory.STAGES.CHAMPION then
        UI.text(game, "SERIES 3 answers\nto its CHAMPION now.\fThat is what the\nrecord will say.", done)
      else
        UI.text(game, "Wrong room.\fWrong questions.", done)
      end
    end,
  } })

  mod.content.map_scripts:register("POKEMON_MANSION_B1F", { talk = {
    TEXT_BLACKJACK_CORNER_MANSION_RESEARCHER = function(game, _, _, done)
      local added, state, reason = ArenaStory.discover(game,
        ArenaStory.CLUES.MANSION_LOG)
      StoryWorld.sync(game, ArenaStory)
      if added and reason == "INVITATION READY" then
        UI.text(game, "I kept one page:\nSERIES 3.\fADAPTIVE COMBAT\nRESPONSE.\fTRANSFER:\nCELADON PIT.\fYour exhibition\ninvitation is real.", done)
      elseif state and state.stage == ArenaStory.STAGES.INVITATION then
        UI.text(game, "I was never here.\fThe invitation takes\nyou back to CELADON.", done)
      else
        UI.text(game, "The basement keeps\nold failures.\fBring an authenticated\narchive request.", done)
      end
    end,
  } })

  mod.content.map_scripts:register("PALLET_TOWN", { talk = {
    TEXT_PALLET_CASINO_SIGN = function(game, _, _, done)
      UI.text(game, "PALLET CASINO\nLuck starts here.\fRegret starts\ninside.", done)
    end,
    TEXT_PALLETTOWN_ROCKET_COLLECTOR = function(game, _, _, done)
      Credit.noteCollector("PALLET_TOWN")
      UI.text(game, "Rocket credit.\fThe meter stopped.\nYour debt didn't.\fPay in Celadon.", done)
    end,
  } })
  mod.content.map_scripts:register("CELADON_CITY", { talk = {
    TEXT_CELADONCITY_ROCKET_COLLECTOR = function(game, _, _, done)
      Credit.noteCollector("CELADON_CITY")
      UI.text(game, "The boss sent me.\fNo battles. No drama.\nJust pay downstairs.", done)
    end,
  } })
  mod.content.map_scripts:register("REDS_HOUSE_1F", {
    talk = {
      TEXT_REDSHOUSE1F_ROCKET_TENANT = function(game, _, _, done)
        local ending = endingChoice()
        UI.text(game, ending == ArenaStory.ENDINGS.EXPOSE
          and "You exposed the pit.\fThe deed still says\nROCKET. Pay it."
          or ending == ArenaStory.ENDINGS.CHAMPION
            and "CHAMPION.\fNice property.\nStill ours."
          or "Nice place.\fCheap deed. Good view\nof OAK's lab.", done)
      end,
      TEXT_REDSHOUSE1F_ROCKET_OBSERVER = function(game, _, _, done)
        local ending = endingChoice()
        UI.text(game, ending == ArenaStory.ENDINGS.EXPOSE
          and "OAK knows we're here.\fSo does half of\nKANTO now."
          or ending == ArenaStory.ENDINGS.CHAMPION
            and "We watch OAK.\fNow we report to the\nCHAMPION too."
          or "This spot is great\nto keep OAK under\nwatch.", done)
      end,
    },
    onVictory = function(game)
      local id = HouseWorld.challengeSaveId()
      if id and game.save.defeatedTrainers and game.save.defeatedTrainers[id]
          and House.recordRocketVictory() then
        syncCampaignWorld(game)
        UI.text(game, "TEAM ROCKET lost.\fYour family home\nis restored!")
      end
    end,
  })
  mod.content.map_scripts:register("REDS_HOUSE_2F", { talk = {
    TEXT_REDSHOUSE2F_GAMBLE_MOM = {
      { "face_player" },
      { "show_text", "_BlackjackCornerDisplacedMomText" },
      { "heal_party" },
      { "play_once", "Music_PkmnHealed" },
      { "show_text", "_BlackjackCornerDisplacedMomHealedText" },
    },
  } })
  mod.content.text:register("_BlackjackCornerDisplacedMomText",
    "TEAM ROCKET calls\nit collateral.\fI call it\ntrespassing.\fRest a moment, dear.")
  mod.content.text:register("_BlackjackCornerDisplacedMomHealedText",
    "All better.\fNow win our home\nback when you're ready.")
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
      openLuxury(game, "PRIZE CASE!\f500 coins opens\none mystery prize.", ids.case, done)
    end,
    TEXT_PALLET_CASINO_PAWN = UI.pawnBroker,
    TEXT_PALLET_CASINO_CLERK = UI.coinClerk,
    TEXT_PALLET_CASINO_GRANNY = reactiveTalk(
      "I came for milk.\fThat was six hours\nago.",
      "Oh, they know you\nhere already.",
      "A big player from\nour little town!",
      "Dear, take a walk.\fLuck needs room\nto find you.",
      "You told the truth.\fPallet needed that\nmore than a jackpot.",
      "Our own CHAMPION!\fYour mother must be...\nwell, surprised."),
    TEXT_PALLET_CASINO_GAMBLER = reactiveTalk(
      "COMET is safe.\fSafe bets are how\nthey get you.",
      "REGULAR already?\fPallet raises them\nfast.",
      "VIP odds are still\nhouse odds, friend.",
      "Cold tables spread.\fMaybe don't stand\nso close.",
      "The Rocket book is\npublic now.\fStill lost my wager.",
      "CHAMPION!\fTell the house I was\nalways loyal."),
    TEXT_PALLET_CASINO_YOUNGSTER = function(game, _, _, done)
      UI.text(game, "Mom thinks I'm at\nPROF.OAK's lab.\fDon't tell her.", done)
    end,
    TEXT_PALLET_CASINO_LOSER = function(game, _, _, done)
      local ending = endingChoice()
      UI.text(game, ending == ArenaStory.ENDINGS.EXPOSE
        and "You exposed ROCKET.\fCan you expose my\npawn ticket next?"
        or ending == ArenaStory.ENDINGS.CHAMPION
          and "CHAMPION...\fAny chance my pawn\ngets mercy?"
        or "I pawned my best\nPOKEMON.\fThirty percent feels\nvery far away.", done)
    end,
  } })

  mod.content.map_scripts:register("GAME_CORNER_PRIZE_ROOM", { talk = {
    TEXT_GAMECORNERPRIZEROOM_PRIZE_VENDOR_1 = function(game, _, _, done)
      openLuxury(game, "Exchange coins for\nPOKEMON prizes?", ids.pokemon, done)
    end,
    TEXT_GAMECORNERPRIZEROOM_PRIZE_VENDOR_2 = function(game, _, _, done)
      openLuxury(game, "Normal or SHINY?\nYou choose!", ids.pokemon, done)
    end,
    TEXT_GAMECORNERPRIZEROOM_PRIZE_VENDOR_3 = function(game, _, _, done)
      openLuxury(game, "Rare items for\nGame Corner coins!", ids.item, done)
    end,
  } })

  -- Optional dependencies run first when installed. Let a dedicated shiny
  -- renderer own every hook; otherwise install the bundled Gen II fallback.
  local shinyProvider
  for _, providerId in ipairs({
    "shiny_indicators",
    "SHINY_POKEMON",
    "crystal_animated_sprites_with_shiny_visuals",
    "gen2_shiny_visuals",
    "shiny_visuals",
  }) do
    shinyProvider = mod:find(providerId)
    if shinyProvider then break end
  end
  if shinyProvider then
    ShinyFallback.disable()
    mod.exports.shiny_fallback = false
    mod.log:info("using external shiny provider %s", shinyProvider.id)
  else
    ShinyFallback.install(mod)
    mod.log:info("using bundled Gen II shiny indicator fallback")
  end
  mod.exports.shiny_provider = shinyProvider and shinyProvider.id or mod.id

  mod.exports.rules, mod.exports.view = Rules, BlackjackView
  mod.exports.holdem_rules, mod.exports.holdem_view = HoldemRules, HoldemView
  mod.exports.catalog = Catalog
  mod.exports.buyPokemon, mod.exports.buyItem = Service.buyPokemon, Service.buyItem
  mod.exports.buyCoins, mod.exports.coinOffers = Service.buyCoins, Service.coinOffers
  mod.exports.pawn, mod.exports.pawnLedger = Pawn, Service.pawnLedger
  mod.exports.pawnPokemon, mod.exports.pawnQuote, mod.exports.redeemPokemon =
    Service.pawnPokemon, Service.pawnQuote, Service.redeemPokemon
  mod.exports.crash_rules, mod.exports.flappy_rules = CrashRules, FlappyRules
  mod.exports.case_rules, mod.exports.giveCaseReward = CaseRules, Service.giveCaseReward
  mod.exports.horse_rules, mod.exports.plinko_rules = HorseRules, PlinkoRules
  mod.exports.roulette_rules, mod.exports.roulette_view = RouletteRules, RouletteView
  mod.exports.gamble = Gamble
  mod.exports.gym_cases = Gym
  mod.exports.city_casinos = CityCasinos
  mod.exports.case_challengers = Challengers
  mod.exports.campaign_state = CampaignState
  mod.exports.reputation_rules = ReputationRules
  mod.exports.reputation = Progress
  mod.exports.credit_rules = CreditRules
  mod.exports.credit = Credit
  mod.exports.credit_world = CreditWorld
  mod.exports.house = House
  mod.exports.house_world = HouseWorld
  mod.exports.arena_rules = ArenaRules
  mod.exports.arena = Arena
  mod.exports.arena_security = ArenaSecurity
  mod.exports.arena_world = ArenaWorld
  mod.exports.arena_story = ArenaStory
  mod.exports.story_world = StoryWorld
end
