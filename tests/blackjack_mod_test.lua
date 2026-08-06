package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")
local Stats = require("src.pokemon.Stats")

local data = T.fixtures.fresh()
local lobby = {}
for key, value in pairs(data.tilesets[T.fixtures.ids.tileset]) do lobby[key] = value end
lobby.id = "LOBBY"
data.tilesets.LOBBY = lobby
local blocks = {}
for i = 1, 90 do blocks[i] = 31 end
data.maps.GAME_CORNER = {
  id = "GAME_CORNER", label = "GameCorner", index = 135,
  tileset = "LOBBY", width = 10, height = 9,
  blocks = blocks, borderBlock = 15, connections = {}, signs = {},
  warps = {
    { x = 15, y = 17, destMap = "LAST_MAP", destWarp = 8 },
    { x = 16, y = 17, destMap = "LAST_MAP", destWarp = 8 },
    { x = 17, y = 4, destMap = "FIXTURE_MAP", destWarp = 2 },
  },
  objects = {
    { index = 7, name = "GAMECORNER_GYM_GUIDE", movement = "STAY", range = "LEFT",
      sprite = "SPRITE_FIXTURE", text = "TEXT_GAMECORNER_GYM_GUIDE", x = 8, y = 14 },
    { index = 8, name = "GAMECORNER_GAMBLER", movement = "STAY", range = "RIGHT",
      sprite = "SPRITE_FIXTURE", text = "TEXT_GAMECORNER_GAMBLER", x = 11, y = 15 },
  },
}

local run = T.sdk.loadMod("mods/blackjack_corner", { data = data, dev = true })
T.eq(#run.errors, 0, "blackjack mod loads cleanly")

local api = run.loader.exports.blackjack_corner
T.check(api and api.rules and api.catalog and api.view
    and api.buyCoins and api.coinOffers,
  "rules, catalogue, pixel view, and coin exchange are exported")
T.check(run.data.screens.BlackjackCornerTable ~= nil, "blackjack screen is registered")
T.check(run.data.screens.BlackjackCornerPokemonPrizes ~= nil,
  "Pokemon prize screen is registered")
T.check(run.data.screens.BlackjackCornerItemPrizes ~= nil,
  "item prize screen is registered")
T.check(run.data.maps.BLACKJACK_LOUNGE ~= nil,
  "blackjack has a dedicated lounge map")
T.eq(run.data.maps.GAME_CORNER.blocks[82], 61,
  "a double-door replaces one lower Game Corner floor block")
T.eq(run.data.maps.GAME_CORNER.blocks[75], 31,
  "the original slot-machine bank remains intact")
T.eq(#run.data.maps.GAME_CORNER.warps, 5,
  "the lounge entrance adds two reciprocal Game Corner warps")
T.eq(run.data.maps.GAME_CORNER.warps[4].destMap, "BLACKJACK_LOUNGE",
  "the first new door tile enters the lounge")
T.eq(run.data.maps.GAME_CORNER.warps[5].destWarp, 2,
  "the second new door tile preserves its side of the doorway")

local function objectNamed(mapId, name)
  for _, object in ipairs(run.data.maps[mapId].objects) do
    if object.name == name then return object end
  end
end

do
  local lounge = run.data.maps.BLACKJACK_LOUNGE
  T.eq(lounge.width, 7, "the lounge is fourteen walk cells wide")
  T.eq(lounge.height, 5, "the lounge is ten walk cells tall")
  T.eq(lounge.palette, "SLOTS1", "the lounge inherits the Game Corner palette")
  T.eq(lounge.warps[1].destWarp, 4, "the left exit returns to the left entrance tile")
  T.eq(lounge.warps[2].destWarp, 5, "the right exit returns to the right entrance tile")
  local dealer = objectNamed("BLACKJACK_LOUNGE", "BLACKJACK_DEALER")
  T.eq(dealer.x, 6, "the dealer is horizontally centered behind the lounge table")
  T.eq(dealer.y, 3, "the dealer stands one row behind the lounge table")
  local guide = objectNamed("GAME_CORNER", "GAMECORNER_GYM_GUIDE")
  T.eq(guide.x, 8, "the original Game Corner NPC layout is preserved")
  T.eq(guide.y, 14, "the Gym Guide remains in his canonical position")
  for piece = 1, 10 do
    local name = ("BLACKJACK_TABLE_%02d"):format(piece)
    local object = objectNamed("BLACKJACK_LOUNGE", name)
    T.check(object ~= nil, name .. " is present in the lounge table")
    T.check(run.data.sprites[("SPRITE_BLACKJACK_TABLE_%02d"):format(piece)] ~= nil,
      name .. " has a registered true-color sprite")
    if piece > 5 then
      T.eq(object.text, "TEXT_BLACKJACK_TABLE",
        name .. " opens blackjack across the front edge")
    end
  end
end

do
  local one = api.view.cardLayout(1)
  T.eq(one[1], 70, "a single pixel card is centered")
  local crowded = api.view.cardLayout(10)
  T.check(crowded[1] >= 0 and crowded[#crowded] + 20 <= 160,
    "a crowded hand remains inside the 160-pixel canvas")
  for i = 2, #crowded do
    T.check(crowded[i] > crowded[i - 1], "overlapped cards keep a readable order")
  end
end

local function contains(rows, species)
  for _, row in ipairs(rows) do if row.species == species then return true end end
  return false
end

local red = api.catalog.pokemon("red")
local blue = api.catalog.pokemon("blue")
for _, species in ipairs({ "SANDSHREW", "VULPIX", "MEOWTH", "BELLSPROUT", "PINSIR", "MAGMAR" }) do
  T.check(contains(red, species), "Red catalogue supplies Blue-exclusive " .. species)
end
for _, species in ipairs({ "EKANS", "ODDISH", "MANKEY", "GROWLITHE", "SCYTHER", "ELECTABUZZ" }) do
  T.check(contains(blue, species), "Blue catalogue supplies Red-exclusive " .. species)
end
for _, species in ipairs({ "BULBASAUR", "CHARMANDER", "SQUIRTLE", "OMANYTE", "KABUTO", "AERODACTYL", "DRATINI" }) do
  T.check(contains(red, species) and contains(blue, species), species .. " is sold in both versions")
end

local function gameWith(coins, money)
  return {
    data = run.data,
    save = {
      coins = coins,
      money = money or 0,
      inventory = {},
      party = {},
      flags = {},
      pokedex = { seen = {}, owned = {} },
      player = { name = "RED", id = 12345 },
    },
  }
end

do
  local game = gameWith(0, 20000)
  game.save.inventory.COIN_CASE = 1
  local offers = api.coinOffers(game)
  T.eq(#offers, 4, "the clerk offers four useful denominations at ¥20000")
  T.eq(offers[1].amount, 50, "the original 50-coin purchase remains available")
  T.eq(offers[2].amount, 250, "the clerk offers a five-pack shortcut")
  T.eq(offers[3].amount, 500, "the clerk offers a ten-pack shortcut")
  T.eq(offers[4].amount, 1000, "the clerk offers a thousand coins at once")
  local ok, _, cost = api.buyCoins(game, 500)
  T.check(ok, "a larger coin purchase succeeds")
  T.eq(cost, 10000, "larger purchases preserve the ¥1000-per-50 exchange rate")
  T.eq(game.save.money, 10000, "the larger exchange deducts its full price")
  T.eq(game.save.coins, 500, "the larger exchange adds all selected coins")
end

do
  local game = gameWith(9000, 100000)
  game.save.inventory.COIN_CASE = 1
  local offers = api.coinOffers(game)
  local maximum = offers[#offers]
  T.eq(maximum.label, "MAX 999", "MAX fills the exact remaining Coin Case space")
  T.eq(maximum.cost, 20000, "a partial final bundle keeps the standard pack price")
  local ok = api.buyCoins(game, maximum.amount)
  T.check(ok, "the calculated maximum can be purchased")
  T.eq(game.save.coins, 9999, "MAX reaches the hard Coin Case cap exactly")
end

do
  local game = gameWith(0, 10000)
  local ok = api.buyCoins(game, 250)
  T.check(not ok, "the larger exchange still requires a Coin Case")
  T.eq(game.save.money, 10000, "a rejected exchange takes no money")
  T.eq(game.save.coins, 0, "a rejected exchange gives no coins")
end

do
  local screen = run.data.screens.BlackjackCornerTable.new(gameWith(500), {})
  local zones = screen:sgbPalettes()
  T.eq(#zones, 1, "the blackjack screen owns one palette zone")
  T.eq(zones[1].colors, false,
    "the casino primitives bypass Game Boy shade remapping")
  T.eq(zones[1].w, 160, "the true-color zone covers the full native canvas")
  T.eq(zones[1].h, 144, "the true-color zone covers the full native height")
end

do
  local game = gameWith(9999)
  local prize = { species = "FIXMON_A", level = 20, cost = 3500 }
  local ok = api.buyPokemon(game, prize, true)
  T.check(ok, "a shiny prize can be purchased")
  T.eq(game.save.coins, 3999, "base price and shiny surcharge are deducted")
  T.eq(#game.save.party, 1, "the prize enters an available party slot")
  T.check(Stats.isShiny(game.save.party[1].dvs), "the purchased Pokemon has canonical shiny DVs")
  T.check(game.save.pokedex.owned.FIXMON_A, "the prize updates owned dex state")
end

do
  local game = gameWith(100)
  local ok = api.buyPokemon(game, { species = "FIXMON_A", level = 20, cost = 3500 }, false)
  T.check(not ok, "an unaffordable Pokemon is refused")
  T.eq(game.save.coins, 100, "a refused Pokemon does not consume coins")
  T.eq(#game.save.party, 0, "a refused Pokemon is not created")
end

do
  local game = gameWith(9999)
  local filler = { species = "FIXMON_A" }
  for _ = 1, 6 do game.save.party[#game.save.party + 1] = filler end
  game.save.boxes = {}
  game.save.currentBox = 1
  for box = 1, 12 do
    game.save.boxes[box] = {}
    for slot = 1, 20 do game.save.boxes[box][slot] = filler end
  end
  local ok = api.buyPokemon(game,
    { species = "FIXMON_A", level = 20, cost = 3500 }, true)
  T.check(not ok, "a Pokemon is refused when the party and every box are full")
  T.eq(game.save.coins, 9999, "a storage failure consumes no coins")
end

do
  local game = gameWith(9999)
  local master = { item = "MASTER_BALL", cost = 9999, once = true }
  local ok = api.buyItem(game, master)
  T.check(ok, "the Master Ball can be redeemed")
  T.eq(game.save.inventory.MASTER_BALL, 1, "the Master Ball reaches the bag")
  T.eq(game.save.coins, 0, "the ultimate prize costs 9999 coins")
  game.save.coins = 9999
  ok = api.buyItem(game, master)
  T.check(not ok, "the Master Ball cannot be redeemed twice")
  T.eq(game.save.coins, 9999, "a sold-out redemption consumes no coins")
end

run.release()
T.finish("blackjack_mod")
