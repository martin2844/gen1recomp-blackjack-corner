package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function loadRule(path)
  path = "mods/blackjack_corner/" .. path
  local file = assert(io.open(path, "r"))
  local chunk = assert(load(file:read("*a"), "@" .. path))
  file:close()
  return chunk()
end

local Horse = loadRule("games/horse_racing/rules.lua")
local Plinko = loadRule("games/plinko/rules.lua")
local Roulette = loadRule("games/starter_roulette/rules.lua")

T.eq(Horse.chooseWinner(function() return 1 end), 1,
  "the favorite owns the first weighted slice")
T.eq(Horse.chooseWinner(function() return 43 end), 2,
  "the second horse begins after the favorite's weight")
T.eq(Horse.chooseWinner(function() return 100 end), 4,
  "the long shot owns the final weighted slice")
local race = Horse.new(function(maximum) return maximum end)
T.eq(race.winner, 4, "a deterministic race records its weighted winner")
T.check(not Horse.update(race, Horse.DURATION - 0.1),
  "the race remains live before its six-second finish")
T.check(Horse.update(race, 0.1), "the race ends at its configured duration")
T.eq(Horse.positions(race)[4], 1, "the winner visibly reaches the line")
T.eq(Horse.payout(50, 4, 4), 400, "the 8x long shot pays posted odds")
T.eq(Horse.payout(50, 1, 4), 0, "a losing horse pays nothing")

local drop = Plinko.new(function() return 2 end)
T.eq(drop.slot, 9, "eight right bounces land in the far-right bucket")
local row, offset = Plinko.ball(drop)
T.eq(row, 0, "a new Plinko ball begins above the first peg row")
T.eq(offset, 0, "a new Plinko ball begins on the board centerline")
T.check(not Plinko.update(drop, Plinko.DURATION - 0.1),
  "a Plinko drop remains animated before its duration")
T.check(Plinko.update(drop, 0.1), "a Plinko drop settles at its duration")
row, offset = Plinko.ball(drop)
T.eq(row, Plinko.ROWS, "a settled Plinko ball reaches the bucket row")
T.eq(offset, Plinko.ROWS, "eight right bounces animate into the outside bucket")
T.eq(Plinko.payout(100, 9), 900, "the edge bucket pays 9x")
T.eq(Plinko.payout(10, 5), 2, "the center bucket returns only 0.2x")
local expected = 0
local binomial = { 1, 8, 28, 56, 70, 56, 28, 8, 1 }
for index, ways in ipairs(binomial) do
  expected = expected + ways * Plinko.MULTIPLIERS_X100[index]
end
T.check(expected / 25600 < 1 and expected / 25600 > 0.94,
  "Plinko keeps a small house edge across every possible path")

local pokemon = {
  BULBASAUR = { dex = 1, baseStats = {}, evolutions = {
    { species = "IVYSAUR", method = "LEVEL", level = 16 } } },
  IVYSAUR = { dex = 2, baseStats = {}, evolutions = {
    { species = "VENUSAUR", method = "LEVEL", level = 32 } } },
  VENUSAUR = { dex = 3, baseStats = {}, evolutions = {} },
  MAGIKARP = { dex = 129, baseStats = {}, evolutions = {
    { species = "GYARADOS", method = "LEVEL", level = 20 } } },
  GYARADOS = { dex = 130, baseStats = {}, evolutions = {} },
  MEW = { dex = 151, baseStats = {}, evolutions = {} },
}
local pool = Roulette.pool(pokemon)
T.same(pool, { "BULBASAUR", "MAGIKARP" },
  "starter roulette includes first stages, excludes evolutions and legendaries")
T.eq(Roulette.choose(pool, function() return 2 end), "MAGIKARP",
  "the roulette can genuinely hand out a risky starter")
T.eq(Roulette.choose(pool, function() return 1 end, "BULBASAUR"), "MAGIKARP",
  "the rival rerolls an exact duplicate")
T.eq(Roulette.FALLBACK_MOVES.MAGIKARP, "TACKLE",
  "a Magikarp starter cannot softlock the opening battle")
T.eq(Roulette.FALLBACK_MOVES.ABRA, "CONFUSION",
  "an Abra starter cannot softlock the opening battle")
T.eq(Roulette.evolveForLevel(pokemon, "BULBASAUR", 15), "BULBASAUR",
  "the rival starter remains basic below its evolution level")
T.eq(Roulette.evolveForLevel(pokemon, "BULBASAUR", 40), "VENUSAUR",
  "the rival's random starter follows its full level evolution line")
local strip = Roulette.strip(pool, "MAGIKARP", function() return 1 end)
T.eq(#strip, Roulette.STRIP_LENGTH, "the starter roulette builds a complete reel")
T.eq(strip[Roulette.WINNER_INDEX], "MAGIKARP",
  "the visible starter reel is locked to its predetermined result")

T.finish("gamble_rules")
