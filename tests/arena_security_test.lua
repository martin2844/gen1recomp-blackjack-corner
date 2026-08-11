package.path = "./?.lua;./?/init.lua;" .. package.path

local T = require("tests.modkit")

local function loadModule(relative)
  return assert(loadfile("mods/blackjack_corner/" .. relative))()
end

local State = loadModule("other/gamble/state.lua")
local SecurityFactory = loadModule("other/gamble/arena_security.lua")

local enabled = true
local saved = { gamble_campaign = State.defaults() }
local mod = { save = {
  get = function(_, key) return saved[key] end,
  set = function(_, key, value) saved[key] = value end,
} }
local security = SecurityFactory(mod, {
  state = State, active = function() return enabled end,
  lobbyMap = "ROCKET_ARENA_LOBBY", arenaMap = "ROCKET_BATTLE_ARENA",
})

T.check(not security.snapshot().stairsRevealed,
  "the concealed route begins behind the Lounge status terminal")
T.check(security.revealStairs(), "terminal clearance persists the open stairwell")
T.check(security.snapshot().stairsRevealed,
  "the revealed stairwell survives a campaign reload")

local original = {
  { species = "PIKACHU", level = 32, moves = { { id = "SURF", pp = 15 } } },
  { species = "CHARIZARD", level = 41, hp = 99 },
}
local game = { save = { party = State.copy(original) } }
local ok, count = security.entered(game, "ROCKET_BATTLE_ARENA",
  "ROCKET_ARENA_LOBBY")
T.check(ok and count == 0 and #game.save.party == 2,
  "ordinary arena entry leaves the complete live party untouched")
T.eq(game.save.party[1].moves[1].pp, 15,
  "arena entry preserves nested move state")
T.eq(saved.gamble_campaign.arena.heldParty, nil,
  "the static staff never creates a party-vault record")
T.eq(security.checkIn, nil,
  "the retired party check-in API is no longer exposed")

-- Recover a save written by the retired mechanic exactly once.
saved.gamble_campaign.arena.heldParty = State.copy(original)
saved.gamble_campaign.arena.securityExit = true
game.save.party = {}
ok, count = security.entered(game, "ROCKET_ARENA_LOBBY",
  "ROCKET_BATTLE_ARENA")
T.check(ok and count == 2 and #game.save.party == 2,
  "legacy custody restores the complete party at the next map boundary")
T.eq(game.save.party[1].moves[1].pp, 15,
  "legacy recovery preserves nested move state")
T.eq(saved.gamble_campaign.arena.heldParty, nil,
  "legacy recovery clears the obsolete vault record")
T.check(not saved.gamble_campaign.arena.securityExit,
  "legacy recovery clears the obsolete return-pass flag")

-- A public v0.5.0 save could already be below Celadon when the lift was
-- replaced by the physical staircase. Booting in either old underground map
-- must open the new return route before the player walks upstairs.
saved.gamble_campaign = State.sanitize({
  schema = 3, arena = { unlocked = true },
})
ok = security.entered(game, "ROCKET_ARENA_LOBBY", nil)
T.check(ok and security.snapshot().stairsRevealed,
  "a schema-three save booting in B1 keeps its route upstairs open")
saved.gamble_campaign = State.sanitize({
  schema = 3, arena = { unlocked = true },
})
ok = security.entered(game, "BLACKJACK_LOUNGE", "ROCKET_BATTLE_ARENA")
T.check(ok and security.snapshot().stairsRevealed,
  "a schema-three save leaving B2 cannot return into the closed terminal")

-- Never overwrite an unexpected live party. Keep the old vault record until
-- an empty destination is available, then recover it without duplication.
saved.gamble_campaign.arena.heldParty = { { species = "EEVEE" } }
game.save.party = { { species = "DITTO" } }
ok = security.recoverLegacyParty(game)
T.check(not ok and game.save.party[1].species == "DITTO",
  "legacy recovery never overwrites live Pokemon")
T.check(saved.gamble_campaign.arena.heldParty ~= nil,
  "a conflicted legacy party remains recoverable")
game.save.party = {}
ok, count = security.recoverLegacyParty(game)
T.check(ok and count == 1 and game.save.party[1].species == "EEVEE",
  "legacy recovery succeeds once the live party is empty")

enabled = false
T.eq(security.snapshot(), nil, "base mode never exposes arena route state")

T.finish("arena_security")
