-- Focused native route audit for the physical stair reveal, permanent staff,
-- native-ROM B1/B2 rooms, environmental dialogue, and an untouched party.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local SaveData = require("src.core.SaveData")
  local PaletteFX = require("src.render.PaletteFX")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  U.wait(10)
  PaletteFX.setMode("ogred")
  game.save.options.colors = "ogred"
  U.wait(20)

  local loader = assert(game.mods, "mod loader is unavailable")
  local api = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket
  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  local campaign = bucket.gamble_campaign
  campaign.reputation.points, campaign.reputation.rank = 4000, "KINGPIN"
  for _, rank in ipairs(api.reputation_rules.RANKS) do
    campaign.reputation.rankRewardsClaimed[rank.id] = true
  end
  for _, badge in ipairs(api.reputation_rules.BADGES) do
    game.save.inventory[badge] = 1
  end
  game.save.inventory.COIN_CASE, game.save.coins = 1, 50000
  if #(game.save.party or {}) == 0 then
    local Pokemon = require("src.pokemon.Pokemon")
    game.save.party = {
      Pokemon.new(game.data, "PIKACHU", 24),
      Pokemon.new(game.data, "CHARMANDER", 20),
    }
  end
  local originalParty = api.campaign_state.copy(game.save.party)
  local arenaAllowed, arenaReason = api.arena.access(game)
  assert(arenaAllowed, "arena fixture is locked: " .. tostring(arenaReason))

  -- A physical threshold must resolve through the map's native warp and
  -- initiate exactly one transition. The old route depended on an invisible
  -- world.stepped coordinate whose underlying tile was neither door nor warp.
  local arenaEntryTransitions = 0
  local startWarpTo = game.overworld.startWarpTo
  game.overworld.startWarpTo = function(ow, mapId, ...)
    if ow.map and ow.map.id == api.arena_world.LOBBY
        and mapId == api.arena_world.ARENA then
      arenaEntryTransitions = arenaEntryTransitions + 1
    end
    return startWarpTo(ow, mapId, ...)
  end

  local function waitMap(mapId)
    for _ = 1, 300 do
      if game.overworld and game.overworld.map.id == mapId
          and not game.overworld.transitioning then U.wait(10); return end
      U.wait(1)
    end
    local player = game.overworld and game.overworld.player
    error(("timed out entering %s (at %s %s,%s)"):format(mapId,
      tostring(game.overworld and game.overworld.map.id),
      tostring(player and player.cellX), tostring(player and player.cellY)))
  end
  local function mashUntil(predicate)
    for _ = 1, 300 do
      if predicate() then U.wait(10); return end
      U.tap(game, "a"); U.wait(3)
    end
    error("dialogue condition was not reached")
  end
  local function fullMapShot(path)
    local map = game.overworld.map
    local width, height = map.widthCells * 16, map.heightCells * 16
    local native = love.graphics.newCanvas(width, height)
    native:setFilter("nearest", "nearest")
    love.graphics.push("all")
    love.graphics.setCanvas(native)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 1)
    map.renderer:drawMapOnly(0, 0, width, height)
    -- Draw the same resolved sprite frames directly at world coordinates.
    -- Calling entity:draw here would enqueue the engine's screen-space
    -- palette replay and duplicate sprites after the canvas is scaled; using
    -- resolveImage gives this evidence frame one honest copy of every patron
    -- and player while the ordinary captures remain the movement proof.
    local SpriteRenderer = require("src.render.SpriteRenderer")
    local entities = {}
    for _, entity in ipairs(game.overworld.entities or {}) do
      entities[#entities + 1] = entity
    end
    table.sort(entities, function(a, b)
      if a.py ~= b.py then return a.py < b.py end
      return a.pikachuFollower == true and b.pikachuFollower ~= true
    end)
    for _, entity in ipairs(entities) do
      local sprite, px, py, facing, phase, flip = entity:pose()
      local frame = 0
      if sprite.def.frames > 1 then
        frame = (sprite.def.walker and phase == 1)
          and SpriteRenderer.WALK[facing] or SpriteRenderer.STAND[facing]
      end
      local image, quad = sprite:resolveImage(), sprite.frames[frame]
        or sprite.frames[0]
      if flip then
        love.graphics.draw(image, quad, math.floor(px) + 16,
          math.floor(py) - 4, 0, -1, 1)
      else
        love.graphics.draw(image, quad, math.floor(px), math.floor(py) - 4)
      end
    end
    love.graphics.setCanvas()
    local scaled = love.graphics.newCanvas(width * 4, height * 4)
    love.graphics.setCanvas(scaled)
    love.graphics.origin()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(native, 0, 0, 0, 4, 4)
    love.graphics.setCanvas()
    love.graphics.pop()
    local encoded = scaled:newImageData():encode("png")
    local file = assert(io.open(path, "wb"))
    file:write(encoded:getString())
    file:close()
    return true
  end

  U.teleport(game, "BLACKJACK_LOUNGE", 3, 12, "up")
  api.arena_world.sync(game, api.arena_security, true)
  U.wait(30)
  local terminal = game.overworld:npcAtCell(3, 11)
  assert(terminal and terminal.def
      and terminal.def.text == "TEXT_ARENA_TERMINAL",
    "status terminal is not interactable from the route")
  assert(U.shot(game, shotDir .. "/01-status-terminal.png"))
  U.tap(game, "a")
  mashUntil(function() return api.arena_security.snapshot().stairsRevealed end)
  assert(U.shot(game, shotDir .. "/02-revealed-staircase.png"))
  assert(fullMapShot(shotDir .. "/02a-full-native-secret-stair.png"))
  U.hold(game, "up", 24); waitMap(api.arena_world.LOBBY)
  assert(fullMapShot(shotDir .. "/03a-full-native-b1.png"))
  assert(U.shot(game, shotDir .. "/03-native-b1-lounges.png"))
  U.teleport(game, api.arena_world.LOBBY, 9, 6, "up")
  waitMap(api.arena_world.LOBBY)
  assert(U.shot(game, shotDir .. "/03b-native-b1-reception.png"))
  U.teleport(game, api.arena_world.LOBBY, 9, 9, "up")
  waitMap(api.arena_world.LOBBY)
  assert(U.shot(game, shotDir .. "/03c-native-b1-machines.png"))

  U.teleport(game, api.arena_world.LOBBY, 7, 4, "up")
  local greeter = game.overworld:npcAtCell(7, 2)
  assert(greeter and greeter.def.text == "TEXT_ARENA_GREETER",
    "B1's first Rocket is not the dedicated welcome guard")
  U.tap(game, "a"); U.wait(100)
  assert(U.shot(game, shotDir .. "/03d-b1-rocket-welcome.png"))
  for _ = 1, 6 do U.tap(game, "a"); U.wait(4) end

  U.teleport(game, api.arena_world.LOBBY, 12, 4, "up")
  local doorman = game.overworld:npcAtCell(12, 2)
  assert(doorman and doorman.def.text == "TEXT_ARENA_DOORMAN",
    "B1's second Rocket is not the fixed pit doorman")
  U.tap(game, "a"); U.wait(100)
  assert(U.shot(game, shotDir .. "/04-static-rocket-staff.png"))
  for _ = 1, 6 do U.tap(game, "a"); U.wait(4) end
  assert(#game.save.party == #originalParty,
    "talking to B1 staff removed Pokemon from the live party")
  local Warp = require("src.world.Warp")
  local nativeArenaDoor = Warp.onArrive(game.overworld.map, 9, 1)
  U.log("B1 ARENA THRESHOLD", "door="
    .. tostring(game.overworld.map:isDoorTileCell(9, 1)), "nativeWarp="
    .. tostring(nativeArenaDoor ~= nil), "tile="
    .. tostring(game.overworld.map:cellTile(9, 1)))
  assert(nativeArenaDoor ~= nil,
    "B1 arena door is still an invisible coordinate threshold")
  assert(game:writeSave(), "arena-route save failed")
  local disk = assert(SaveData.load(game.save.version))
  assert(#disk.party == #originalParty,
    "arena-route save removed Pokemon from the disk party")

  -- The right guard flanks the single authentic ROM door one cell to his left.
  -- Rejoin that physical aisle before walking through it.
  U.teleport(game, api.arena_world.LOBBY, 9, 5, "up")
  U.hold(game, "up", 120); waitMap(api.arena_world.ARENA)
  assert(arenaEntryTransitions == 1,
    ("B1 threshold started %d B2 transitions instead of one")
      :format(arenaEntryTransitions))
  assert(#game.save.party == #originalParty,
    "pit entry removed Pokemon from the live party")
  U.teleport(game, api.arena_world.ARENA, 12, 10, "left")
  waitMap(api.arena_world.ARENA)
  for _, entity in ipairs(game.overworld.entities or {}) do
    if entity.def and tostring(entity.def.name or ""):find("ARENA_FAN_", 1, true) then
      assert(game.overworld.map:cellTile(entity.cellX, entity.cellY) ~= 20,
        entity.def.name .. " is still standing on Lorelei ice")
    end
  end
  assert(fullMapShot(shotDir .. "/05a-full-native-b2.png"))
  assert(U.shot(game, shotDir .. "/05-native-b2-spectator-pit.png"))
  U.teleport(game, api.arena_world.ARENA, 15, 14, "left")
  U.tap(game, "a"); U.wait(80)
  U.tap(game, "a"); U.wait(80)
  assert(U.shot(game, shotDir .. "/06-pit-control-dialogue.png"))
  for _ = 1, 10 do U.tap(game, "a"); U.wait(2) end

  U.teleport(game, api.arena_world.ARENA, 9, 15, "down")
  U.hold(game, "down", 120); waitMap(api.arena_world.LOBBY)
  assert(#game.save.party == #originalParty,
    "returning to B1 changed the live party")
  for index, pokemon in ipairs(originalParty) do
    assert(game.save.party[index].species == pokemon.species,
      "party order changed at slot " .. index)
  end
  assert(game.overworld:npcAtCell(7, 2) and game.overworld:npcAtCell(12, 2),
    "B1's permanent Rocket staff disappeared after returning from B2")
  assert(U.shot(game, shotDir .. "/07-party-unchanged-lobby.png"))

  -- Complete the route instead of stopping after the B2-to-B1 return. This
  -- catches reciprocal-stair loops where the Lounge arrival cell is mistaken
  -- for a fresh descent into the basement.
  U.hold(game, "down", 300)
  U.wait(90)
  local exitMap = game.overworld and game.overworld.map.id
  local exitPlayer = game.overworld and game.overworld.player
  assert(exitMap == "BLACKJACK_LOUNGE",
    ("arena return looped into %s at %s,%s"):format(tostring(exitMap),
      tostring(exitPlayer and exitPlayer.cellX),
      tostring(exitPlayer and exitPlayer.cellY)))
  assert(not (exitPlayer.cellX == api.arena_world.STAIR_CELL.x
      and exitPlayer.cellY == api.arena_world.STAIR_CELL.y),
    "arena return left the player pinned on the basement stair trigger")
  assert(U.shot(game, shotDir .. "/08-back-in-celadon-lounge.png"))

  U.log("ARENA WORLD POLISH AUDIT COMPLETE")
  U.log("MANUAL CONTROL READY")
  while true do coroutine.yield() end
end
