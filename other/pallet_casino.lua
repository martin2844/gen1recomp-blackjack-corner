local PalletCasino = {}

local function cloneList(rows)
  local out = {}
  for index, original in ipairs(rows or {}) do
    if type(original) == "table" then
      local row = {}
      for key, value in pairs(original) do row[key] = value end
      out[index] = row
    else
      out[index] = original
    end
  end
  return out
end

local function appendNpc(objects, name, sprite, text, x, y, movement, range)
  objects[#objects + 1] = {
    index = #objects + 1, name = name, sprite = sprite, text = text,
    x = x, y = y, movement = movement or "STAY", range = range or "DOWN",
  }
end

function PalletCasino.register(mod, ids)
  local pallet = mod.content.maps:get("PALLET_TOWN")
  if pallet and pallet.tileset == "OVERWORLD" and pallet.width == 10
      and pallet.height == 9 then
    local blocks = cloneList(pallet.blocks)
    -- A second small lab-style facade in Pallet's southwest clearing.
    blocks[52], blocks[53], blocks[54] = 0x0c, 0x0d, 0x0e
    blocks[62], blocks[63], blocks[64] = 0x10, 0x3a, 0x00
    -- The original pond begins immediately below the new door. Replace its
    -- northwest block with lawn so the warp has a reachable dry landing.
    blocks[73] = 0x01
    local warps = cloneList(pallet.warps)
    local entryWarp = #warps + 1
    warps[#warps + 1] = { x = 4, y = 13, destMap = ids.pallet, destWarp = 1 }
    local signs = cloneList(pallet.signs)
    signs[#signs + 1] = { x = 3, y = 12, text = "TEXT_PALLET_CASINO_SIGN" }
    mod.content.maps:patch("PALLET_TOWN", {
      blocks = blocks, warps = warps, signs = signs,
    })

    local objects = {}
    for _, machine in ipairs({
      { id = "HORSE", x = 5, text = "TEXT_HORSE_RACING" },
      { id = "PLINKO", x = 9, text = "TEXT_PLINKO" },
      { id = "CASE", x = 13, text = "TEXT_CASE_MACHINE" },
    }) do
      for piece = 1, 2 do objects[#objects + 1] = {
        index = #objects + 1, name = machine.id .. "_MACHINE_" .. piece,
        movement = "STAY", range = "DOWN",
        sprite = ("SPRITE_ARCADE_%s_%02d"):format(machine.id, piece),
        x = machine.x, y = 2 + piece, text = piece == 2 and machine.text or nil,
      } end
    end
    appendNpc(objects, "PALLET_CASINO_PAWN", "SPRITE_ROCKET",
      "TEXT_PALLET_CASINO_PAWN", 2, 3)
    appendNpc(objects, "PALLET_CASINO_CLERK", "SPRITE_CLERK",
      "TEXT_PALLET_CASINO_CLERK", 17, 3)
    appendNpc(objects, "PALLET_BLACKJACK_DEALER", "SPRITE_GAMBLER",
      "TEXT_PALLET_BLACKJACK_TABLE", 4, 9)
    appendNpc(objects, "PALLET_HOLDEM_DEALER", "SPRITE_GAMBLER",
      "TEXT_PALLET_HOLDEM_TABLE", 15, 9)
    for _, tableDef in ipairs({
      { id = "BLACKJACK", x = 2, text = "TEXT_PALLET_BLACKJACK_TABLE" },
      { id = "HOLDEM", x = 14, text = "TEXT_PALLET_HOLDEM_TABLE" },
    }) do
      for piece = 1, 8 do
        local column, line = (piece - 1) % 4, math.floor((piece - 1) / 4)
        objects[#objects + 1] = {
          index = #objects + 1,
          name = ("PALLET_%s_TABLE_%02d"):format(tableDef.id, piece),
          movement = "STAY", range = "DOWN",
          sprite = ("SPRITE_%s_TABLE_%02d"):format(tableDef.id, piece),
          x = tableDef.x + column, y = 10 + line,
          text = line == 1 and tableDef.text or nil,
        }
      end
    end
    appendNpc(objects, "PALLET_CASINO_GRANNY", "SPRITE_GRANNY",
      "TEXT_PALLET_CASINO_GRANNY", 2, 14, "WALK", "LEFT_RIGHT")
    appendNpc(objects, "PALLET_CASINO_GAMBLER", "SPRITE_GAMBLER",
      "TEXT_PALLET_CASINO_GAMBLER", 7, 14, "WALK", "UP_DOWN")
    appendNpc(objects, "PALLET_CASINO_YOUNGSTER", "SPRITE_YOUNGSTER",
      "TEXT_PALLET_CASINO_YOUNGSTER", 12, 14, "WALK", "LEFT_RIGHT")
    appendNpc(objects, "PALLET_CASINO_LOSER", "SPRITE_GENTLEMAN",
      "TEXT_PALLET_CASINO_LOSER", 17, 14, "WALK", "UP_DOWN")

    local palletBlocks = { 63, 64, 64, 64, 64, 64, 64, 64, 64, 63 }
    for _ = 2, 8 do
      for _ = 1, 10 do palletBlocks[#palletBlocks + 1] = 32 end
    end
    for _, block in ipairs({ 27, 27, 27, 27, 61, 27, 27, 27, 27, 27 }) do
      palletBlocks[#palletBlocks + 1] = block
    end

    mod.content.maps:register(ids.pallet, {
      id = ids.pallet, label = "PalletCasino", index = 1101,
      tileset = "LOBBY", width = 10, height = 9, blocks = palletBlocks,
      borderBlock = 15, palette = "SLOTS2", connections = {}, signs = {},
      objects = objects,
      warps = {
        { x = 8, y = 17, destMap = "PALLET_TOWN", destWarp = entryWarp },
        { x = 9, y = 17, destMap = "PALLET_TOWN", destWarp = entryWarp },
      },
    })
  end

  -- Add more human stories without replacing any vanilla patrons.
  mod.content.maps:patch("GAME_CORNER", { objects = { __append = {
    { index = 13, name = "CASINO_DEBTOR", sprite = "SPRITE_GENTLEMAN",
      text = "TEXT_CASINO_DEBTOR", x = 4, y = 8, movement = "WALK", range = "LEFT_RIGHT" },
    { index = 14, name = "CASINO_DREAMER", sprite = "SPRITE_YOUNGSTER",
      text = "TEXT_CASINO_DREAMER", x = 12, y = 8, movement = "WALK", range = "UP_DOWN" },
    { index = 15, name = "CASINO_REGULAR", sprite = "SPRITE_GRANNY",
      text = "TEXT_CASINO_REGULAR", x = 16, y = 15, movement = "WALK", range = "LEFT_RIGHT" },
  } } })
  local lounge = mod.content.maps:get(ids.lounge)
  local nextLoungeIndex = 1
  for _, object in ipairs(lounge and lounge.objects or {}) do
    nextLoungeIndex = math.max(nextLoungeIndex, (tonumber(object.index) or 0) + 1)
  end
  mod.content.maps:patch(ids.lounge, { objects = { __append = {
    { index = nextLoungeIndex, name = "LOUNGE_COLD_STREAK", sprite = "SPRITE_FISHER",
      text = "TEXT_LOUNGE_COLD_STREAK", x = 3, y = 14, movement = "WALK", range = "LEFT_RIGHT" },
    { index = nextLoungeIndex + 1, name = "LOUNGE_CARD_COUNTER", sprite = "SPRITE_GIRL",
      text = "TEXT_LOUNGE_CARD_COUNTER", x = 10, y = 14, movement = "WALK", range = "UP_DOWN" },
    { index = nextLoungeIndex + 2, name = "LOUNGE_LAST_CHIP", sprite = "SPRITE_MIDDLE_AGED_MAN",
      text = "TEXT_LOUNGE_LAST_CHIP", x = 16, y = 14, movement = "WALK", range = "LEFT_RIGHT" },
  } } })

  mod.content.field:patch("hiddenCoins", {
    PALLET_CASINO = {
      { x = 1, y = 7, coins = 20 }, { x = 10, y = 15, coins = 50 },
      { x = 18, y = 14, coins = 20 },
    },
    GAME_CORNER = { __append = {
      { x = 6, y = 8, coins = 50 }, { x = 13, y = 9, coins = 100 },
    } },
    [ids.lounge] = {
      { x = 1, y = 10, coins = 50 }, { x = 10, y = 15, coins = 100 },
      { x = 18, y = 14, coins = 50 },
    },
  })
end

return PalletCasino
