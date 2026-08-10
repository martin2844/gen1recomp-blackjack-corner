return function(World)
local Lounge = {}

function Lounge.register(mod, mapId)
  local gameCorner = mod.content.maps:get("GAME_CORNER")
  if not (gameCorner and type(gameCorner.blocks) == "table"
      and gameCorner.tileset == "LOBBY"
      and gameCorner.width == 10 and gameCorner.height == 9) then return end

  local blocks = {}
  for index, block in ipairs(gameCorner.blocks) do blocks[index] = block end
  blocks[82] = 61

  local warps = World.cloneList(gameCorner.warps)
  local entryWarp = #warps + 1
  warps[#warps + 1] = { x = 2, y = 17, destMap = mapId, destWarp = 1 }
  warps[#warps + 1] = { x = 3, y = 17, destMap = mapId, destWarp = 2 }

  local signs = World.cloneList(gameCorner.signs)
  signs[#signs + 1] = { x = 2, y = 16, text = "TEXT_BLACKJACK_LOUNGE_SIGN" }

  local objects = World.cloneList(gameCorner.objects)
  local nextIndex = World.nextObjectIndex(objects)
  objects[#objects + 1] = { index = nextIndex, name = "GAMECORNER_PAWN_BROKER",
    movement = "STAY", range = "DOWN", sprite = "SPRITE_ROCKET",
    text = "TEXT_PAWN_BROKER", x = 8, y = 6 }
  mod.content.maps:patch("GAME_CORNER", {
    blocks = blocks, warps = warps, signs = signs, objects = objects,
  })

  local loungeObjects = {
    { index = 1, name = "BLACKJACK_DEALER", movement = "STAY", range = "DOWN",
      sprite = "SPRITE_GAMBLER", text = "TEXT_BLACKJACK_DEALER", x = 4, y = 3 },
    { index = 2, name = "HOLDEM_DEALER", movement = "STAY", range = "DOWN",
      sprite = "SPRITE_GAMBLER", text = "TEXT_HOLDEM_DEALER", x = 15, y = 3 },
    { index = 3, name = "CASINO_HOSTESS", movement = "STAY", range = "RIGHT",
      sprite = "SPRITE_BEAUTY", text = "TEXT_CASINO_HOSTESS", x = 1, y = 8 },
    { index = 4, name = "BLACKJACK_PATRON", movement = "STAY", range = "LEFT",
      sprite = "SPRITE_GENTLEMAN", text = "TEXT_BLACKJACK_PATRON", x = 8, y = 8 },
    { index = 5, name = "HOLDEM_PATRON", movement = "STAY", range = "RIGHT",
      sprite = "SPRITE_GENTLEMAN", text = "TEXT_HOLDEM_PATRON", x = 18, y = 8 },
    { index = 6, name = "ROCKET_LOAN_SHARK", movement = "STAY", range = "LEFT",
      sprite = "SPRITE_ROCKET", text = "TEXT_ROCKET_CREDIT", x = 18, y = 12 },
  }
  for _, machine in ipairs({
    { id = "CRASH", x = 8, y = 2, text = "TEXT_CRASH_MACHINE" },
    { id = "FLAPPY", x = 10, y = 2, text = "TEXT_FLAPPY_MACHINE" },
    { id = "CASE", x = 12, y = 2, text = "TEXT_CASE_MACHINE" },
    { id = "HORSE", x = 6, y = 10, text = "TEXT_HORSE_RACING" },
    { id = "PLINKO", x = 13, y = 10, text = "TEXT_PLINKO" },
  }) do
    for piece = 1, 2 do loungeObjects[#loungeObjects + 1] = {
      index = #loungeObjects + 1,
      name = ("%s_MACHINE_%02d"):format(machine.id, piece),
      movement = "STAY", range = "DOWN",
      sprite = ("SPRITE_ARCADE_%s_%02d"):format(machine.id, piece),
      x = machine.x, y = machine.y + piece,
      text = piece == 2 and machine.text or nil,
    } end
  end
  for _, tableDef in ipairs({
    { id = "BLACKJACK", x = 2, text = "TEXT_BLACKJACK_TABLE" },
    { id = "HOLDEM", x = 14, text = "TEXT_HOLDEM_TABLE" },
  }) do
    for piece = 1, 8 do
      local column, line = (piece - 1) % 4, math.floor((piece - 1) / 4)
      loungeObjects[#loungeObjects + 1] = {
        index = #loungeObjects + 1,
        name = ("%s_TABLE_%02d"):format(tableDef.id, piece),
        movement = "STAY", range = "DOWN",
        sprite = ("SPRITE_%s_TABLE_%02d"):format(tableDef.id, piece),
        x = tableDef.x + column, y = 4 + line,
        text = line == 1 and tableDef.text or nil,
      }
    end
  end

  mod.content.maps:register(mapId, {
    id = mapId, label = "CasinoLounge", index = 1100,
    tileset = "LOBBY", width = 10, height = 9,
    blocks = World.casinoFloorBlocks(),
    borderBlock = 15, palette = "SLOTS1", connections = {}, signs = {},
    objects = loungeObjects,
    warps = {
      { x = 8, y = 17, destMap = "GAME_CORNER", destWarp = entryWarp },
      { x = 9, y = 17, destMap = "GAME_CORNER", destWarp = entryWarp + 1 },
    },
  })
end

return Lounge
end
