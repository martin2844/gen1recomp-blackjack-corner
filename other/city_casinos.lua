return function(World)
local CityCasinos = {}

CityCasinos.locations = {
  {
    key = "VIRIDIAN", city = "VIRIDIAN CITY", exterior = "VIRIDIAN_CITY",
    interior = "VIRIDIAN_SCHOOL_HOUSE", sourceWarp = 3,
    sign = { x = 17, y = 17, text = "TEXT_VIRIDIANCITY_SIGN" }, palette = "SLOTS1",
    welcome = "VIRIDIAN CASINO!\fProbability class\nis always in session.",
    patron = "I studied POTION\nprices all morning.\fThen lost the lot\non one hand.",
    special = "plinko",
  },
  {
    key = "PEWTER", city = "PEWTER CITY", exterior = "PEWTER_CITY",
    interior = "PEWTER_SPEECH_HOUSE", sourceWarp = 6,
    sign = { x = 25, y = 23, text = "TEXT_PEWTERCITY_SIGN" }, palette = "SLOTS2",
    welcome = "PEWTER CASINO!\fHard tables.\nRock-solid odds.",
    patron = "They would not take\nmy fossil as a bet.\fProbably saved my\nancestors.",
    special = "crash",
  },
  {
    key = "CERULEAN", city = "CERULEAN CITY", exterior = "CERULEAN_CITY",
    interior = "CERULEAN_BADGE_HOUSE", sourceWarp = 9, alternateWarp = 10,
    sign = { x = 23, y = 19, text = "TEXT_CERULEANCITY_SIGN" }, palette = "SLOTS1",
    welcome = "CERULEAN CASINO!\fA current of coins\nruns through here.",
    patron = "MISTY likes bold\ntrainers.\fThe dealer likes them\neven more.",
    special = "tube",
  },
  {
    key = "VERMILION", city = "VERMILION CITY", exterior = "VERMILION_CITY",
    interior = "VERMILION_PIDGEY_HOUSE", sourceWarp = 5,
    sign = { x = 27, y = 3, text = "TEXT_VERMILIONCITY_SIGN" }, palette = "SLOTS2",
    welcome = "VERMILION CASINO!\fSailors bet before\nthe tide turns.",
    patron = "My ship left at six.\fMy winning horse\narrives any minute.",
    special = "horse",
  },
  {
    key = "LAVENDER", city = "LAVENDER TOWN", exterior = "LAVENDER_TOWN",
    interior = "LAVENDER_CUBONE_HOUSE", sourceWarp = 5,
    sign = { x = 11, y = 9, text = "TEXT_LAVENDERTOWN_SIGN" }, palette = "SLOTS1",
    welcome = "LAVENDER CASINO!\fQuiet tables.\nRestless luck.",
    patron = "They say the house\nalways comes back.\fIn LAVENDER, that\nsounds different.",
    special = "case",
  },
  {
    key = "FUCHSIA", city = "FUCHSIA CITY", exterior = "FUCHSIA_CITY",
    interior = "FUCHSIA_MEETING_ROOM", sourceWarp = 7,
    sign = { x = 15, y = 23, text = "TEXT_FUCHSIACITY_SIGN1" }, palette = "SLOTS2",
    welcome = "FUCHSIA CASINO!\fSafari rules: no\nbait, rocks or refunds.",
    patron = "I caught nothing in\nthe SAFARI ZONE.\fHere, the coins catch\nme.",
    special = "plinko",
  },
  {
    key = "SAFFRON", city = "SAFFRON CITY", exterior = "SAFFRON_CITY",
    interior = "SAFFRON_PIDGEY_HOUSE", sourceWarp = 4,
    sign = { x = 17, y = 5, text = "TEXT_SAFFRONCITY_SIGN" }, palette = "SLOTS1",
    welcome = "SAFFRON CASINO!\fSILPH clocks stop.\nThe tables do not.",
    patron = "I can see the future.\fIt keeps asking for\none more bet.",
    special = "horse",
  },
  {
    key = "CINNABAR", city = "CINNABAR ISLAND", exterior = "CINNABAR_ISLAND",
    interior = "CINNABAR_LAB_TRADE_ROOM", sourceWarp = 3,
    sign = { x = 9, y = 5, text = "TEXT_CINNABARISLAND_SIGN" },
    palette = "SLOTS2", preserveObjects = true,
    welcome = "CINNABAR CASINO!\fExperimental odds.\nResults may ignite.",
    patron = "A hot streak is just\na losing streak\nbefore peer review.",
    special = "case",
  },
}

local SPECIALS = {
  crash = { sprite = "CRASH" }, tube = { sprite = "FLAPPY" },
  case = { sprite = "CASE", luxury = true },
  horse = { sprite = "HORSE" }, plinko = { sprite = "PLINKO" },
}

local function addTable(objects, prefix, id, x, text)
  for piece = 1, 8 do
    local column, line = (piece - 1) % 4, math.floor((piece - 1) / 4)
    World.appendObject(objects, {
      name = ("%s_%s_TABLE_%02d"):format(prefix, id, piece),
      movement = "STAY", range = "DOWN",
      sprite = ("SPRITE_%s_TABLE_%02d"):format(id, piece),
      x = x + column, y = 3 + line,
      text = line == 1 and text or nil,
    })
  end
end

local function addMachine(objects, prefix, definition)
  for piece = 1, 2 do
    World.appendObject(objects, {
      name = ("%s_LOCAL_MACHINE_%02d"):format(prefix, piece),
      movement = "STAY", range = "DOWN",
      sprite = ("SPRITE_ARCADE_%s_%02d"):format(definition.sprite, piece),
      x = 5, y = piece,
      text = piece == 2 and "TEXT_CITY_CASINO_SPECIAL" or nil,
    })
  end
end

local function casinoObjects(location, original)
  local objects = {}
  addTable(objects, location.key, "BLACKJACK", 1, "TEXT_CITY_CASINO_BLACKJACK")
  addTable(objects, location.key, "HOLDEM", 7, "TEXT_CITY_CASINO_HOLDEM")
  addMachine(objects, location.key, assert(SPECIALS[location.special]))
  World.appendObject(objects, { name = location.key .. "_BLACKJACK_DEALER",
    sprite = "SPRITE_GAMBLER", text = "TEXT_CITY_CASINO_BLACKJACK",
    x = 2, y = 2, movement = "STAY", range = "DOWN" })
  World.appendObject(objects, { name = location.key .. "_HOLDEM_DEALER",
    sprite = "SPRITE_GAMBLER", text = "TEXT_CITY_CASINO_HOLDEM",
    x = 8, y = 2, movement = "STAY", range = "DOWN" })
  World.appendObject(objects, { name = location.key .. "_HOST",
    sprite = "SPRITE_BEAUTY", text = "TEXT_CITY_CASINO_HOST",
    x = 1, y = 7, movement = "STAY", range = "RIGHT" })
  World.appendObject(objects, { name = location.key .. "_CLERK",
    sprite = "SPRITE_CLERK", text = "TEXT_CITY_CASINO_CLERK",
    x = 10, y = 7, movement = "STAY", range = "LEFT" })
  World.appendObject(objects, { name = location.key .. "_PATRON",
    sprite = "SPRITE_GENTLEMAN", text = "TEXT_CITY_CASINO_PATRON",
    x = 10, y = 6, movement = "STAY", range = "LEFT" })

  if location.preserveObjects then
    local positions = { { 2, 7 }, { 4, 7 }, { 8, 7 } }
    for index, source in ipairs(original or {}) do
      local row = {}
      for key, value in pairs(source) do
        if key ~= "index" then row[key] = value end
      end
      local position = positions[index] or { 1 + index, 8 }
      row.x, row.y = position[1], position[2]
      World.appendObject(objects, row)
    end
  end
  return objects
end

function CityCasinos.register(mod)
  for _, location in ipairs(CityCasinos.locations) do
    local interior = mod.content.maps:get(location.interior)
    local exterior = mod.content.maps:get(location.exterior)
    if interior and exterior then
      local exteriorWarps = World.cloneList(exterior.warps)
      for _, warpIndex in ipairs({ location.sourceWarp, location.alternateWarp }) do
        local warp = warpIndex and exteriorWarps[warpIndex]
        if warp and warp.destMap == location.interior then
          warp.destWarp = warpIndex == location.alternateWarp and 2 or 1
        end
      end
      local signs, foundSign = World.cloneList(exterior.signs), false
      for _, sign in ipairs(signs) do
        if sign.text == location.sign.text then
          sign.text, foundSign = "TEXT_REGIONAL_CASINO_SIGN", true
          break
        end
      end
      -- Custom fixtures and compatible map overhauls may omit the stock city
      -- placard. Keep the branch discoverable without duplicating a sign when
      -- the native one exists.
      if not foundSign then
        signs[#signs + 1] = { x = location.sign.x, y = location.sign.y,
          text = "TEXT_REGIONAL_CASINO_SIGN" }
      end
      mod.content.maps:patch(location.exterior, {
        warps = exteriorWarps, signs = signs,
      })

      local exits = { location.sourceWarp, location.alternateWarp or location.sourceWarp }
      local casinoWarps
      if location.preserveObjects then
        casinoWarps = {}
        for index = 1, 2 do
          local original = interior.warps and interior.warps[index]
          casinoWarps[index] = {
            x = 5 + index, y = 9,
            destMap = original and original.destMap or "CINNABAR_LAB",
            destWarp = original and original.destWarp or 3,
          }
        end
      else
        casinoWarps = {
          { x = 6, y = 9, destMap = "LAST_MAP", destWarp = exits[1] },
          { x = 7, y = 9, destMap = "LAST_MAP", destWarp = exits[2] },
        }
      end
      local casino = {
        tileset = "LOBBY", width = 6, height = 5,
        blocks = World.cityCasinoBlocks(), borderBlock = 15,
        palette = location.palette, connections = {}, signs = {},
        objects = casinoObjects(location, interior.objects),
        warps = casinoWarps,
      }
      -- The Cinnabar traders still resolve one flavor line through the ROM
      -- map label; keeping that label preserves every original trade-room
      -- interaction while the surrounding room becomes the casino branch.
      if not location.preserveObjects then
        casino.label = location.key:sub(1, 1)
          .. location.key:sub(2):lower() .. "Casino"
      end
      mod.content.maps:patch(location.interior, casino)
    end
  end
end

function CityCasinos.registerScripts(mod, opts)
  local screen = {
    blackjack = opts.ids.blackjack, holdem = opts.ids.holdem,
    crash = opts.ids.crash, tube = opts.ids.tube, case = opts.ids.case,
    horse = opts.ids.horse, plinko = opts.ids.plinko,
  }
  for _, location in ipairs(CityCasinos.locations) do
    local special = SPECIALS[location.special]
    mod.content.map_scripts:register(location.exterior, { talk = {
      TEXT_REGIONAL_CASINO_SIGN = function(game, _, _, done)
        local message = location.key == "CINNABAR"
          and "CINNABAR CASINO\fINSIDE POKéMON LAB.\nTRADE ROOM."
          or location.city .. "\nCASINO\fBLACKJACK, HOLD'EM\nAND LOCAL ACTION."
        opts.text(game, message, done)
      end,
    } })
    local script = { talk = {
      TEXT_CITY_CASINO_HOST = function(game, _, _, done)
        opts.text(game, location.welcome, done)
      end,
      TEXT_CITY_CASINO_PATRON = function(game, _, _, done)
        opts.text(game, location.patron, done)
      end,
      TEXT_CITY_CASINO_CLERK = opts.coinClerk,
      TEXT_CITY_CASINO_BLACKJACK = function(game, _, _, done)
        opts.open(game, location.city .. "\fBLACKJACK TABLE\nClosest to 21 wins.",
          screen.blackjack, done)
      end,
      TEXT_CITY_CASINO_HOLDEM = function(game, _, _, done)
        opts.open(game, location.city .. "\fTEXAS HOLD'EM\nBeat the house hand.",
          screen.holdem, done)
      end,
      TEXT_CITY_CASINO_SPECIAL = function(game, _, _, done)
        local message = ({
          crash = "CRASH!\fCash out before the\nmultiplier falls.",
          tube = "TUBE FLYER!\fTen coins in. One\ncoin per tube.",
          case = "PRIZE CASE!\fFive hundred coins.\nOne sealed prize.",
          horse = "LIVE RACE TV!\fStudy the odds and\nback a runner.",
          plinko = "PLINKO!\fPick a lane and\ntrust the pegs.",
        })[location.special]
        local opener = special.luxury and opts.openLuxury or opts.open
        opener(game, message, screen[location.special], done)
      end,
    } }
    if location.key == "VIRIDIAN" then
      -- This branch replaces the Trainer School. Its blackboard and notebook
      -- are base onInteract hooks rather than objects, so removing the room's
      -- objects alone would leave two invisible, school-themed interactions
      -- floating over the casino floor. Consume only those exact old cells.
      script.onInteract = function(_, _, x, y)
        return x == 3 and (y == 0 or y == 4)
      end
    end
    mod.content.map_scripts:register(location.interior, script)
  end
end

return CityCasinos
end
