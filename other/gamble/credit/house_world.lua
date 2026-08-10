return function(World)
local HouseWorld = {
  MAP_DOWNSTAIRS = "REDS_HOUSE_1F",
  MAP_UPSTAIRS = "REDS_HOUSE_2F",
  MOM_DOWNSTAIRS = "REDSHOUSE1F_MOM",
  MOM_UPSTAIRS = "REDSHOUSE2F_GAMBLE_MOM",
  TENANT = "REDSHOUSE1F_ROCKET_TENANT",
  OBSERVER = "REDSHOUSE1F_ROCKET_OBSERVER",
  CHALLENGE = "REDSHOUSE1F_ROCKET_CHALLENGE",
  EQUIPMENT = {
    "REDSHOUSE1F_ROCKET_EQUIPMENT_01",
    "REDSHOUSE1F_ROCKET_EQUIPMENT_02",
    "REDSHOUSE1F_ROCKET_EQUIPMENT_03",
    "REDSHOUSE1F_ROCKET_EQUIPMENT_04",
    "REDSHOUSE1F_ROCKET_EQUIPMENT_05",
  },
}

local function append(objects, index, row)
  row.index, row.hidden = index, true
  row.movement, row.range = row.movement or "STAY", row.range or "NONE"
  objects[#objects + 1] = row
  return index + 1
end

function HouseWorld.register(mod)
  local downstairs = mod.content.maps:get(HouseWorld.MAP_DOWNSTAIRS)
  if downstairs then
    local rows, index = {}, World.nextObjectIndex(downstairs)
    index = append(rows, index, {
      name = HouseWorld.TENANT, sprite = "SPRITE_ROCKET",
      text = "TEXT_REDSHOUSE1F_ROCKET_TENANT", x = 5, y = 4, range = "LEFT",
    })
    index = append(rows, index, {
      name = HouseWorld.OBSERVER, sprite = "SPRITE_ROCKET",
      text = "TEXT_REDSHOUSE1F_ROCKET_OBSERVER", x = 2, y = 4, range = "RIGHT",
    })
    HouseWorld.challengeIndex = index
    index = append(rows, index, {
      name = HouseWorld.CHALLENGE, sprite = "SPRITE_ROCKET",
      text = "TEXT_REDSHOUSE1F_ROCKET_CHALLENGE", x = 5, y = 4,
      range = "LEFT", trainerClass = "OPP_ROCKET", trainerParty = 8,
    })
    -- Pieces 1-4 reconstruct a real two-cabinet Rocket Hideout machine bank;
    -- piece 5 is a separate Silph Co console. They stay on the perimeter so
    -- the door, stairs, Mom, PC path, and battle approach remain clear.
    for piece, position in ipairs({
      { 1, 1 }, { 2, 1 }, { 1, 2 }, { 2, 2 }, { 6, 2 },
    }) do
      index = append(rows, index, {
        name = HouseWorld.EQUIPMENT[piece],
        sprite = ("SPRITE_ROCKET_EQUIPMENT_%02d"):format(piece),
        x = position[1], y = position[2],
      })
    end
    mod.content.maps:patch(HouseWorld.MAP_DOWNSTAIRS,
      { objects = { __append = rows } })
  end

  local upstairs = mod.content.maps:get(HouseWorld.MAP_UPSTAIRS)
  if upstairs then
    mod.content.maps:patch(HouseWorld.MAP_UPSTAIRS, { objects = { __append = {
      {
        index = World.nextObjectIndex(upstairs), name = HouseWorld.MOM_UPSTAIRS,
        hidden = true, movement = "STAY", range = "RIGHT",
        sprite = "SPRITE_MOM", text = "TEXT_REDSHOUSE2F_GAMBLE_MOM",
        x = 2, y = 4,
      },
    } } })
  end

  mod.content.text:register("_BlackjackCornerHouseRocketBattleText",
    "The deed is paid.\fBeat me and TEAM\nROCKET clears out!")
  mod.content.text_pointers:patch("RedsHouse1F", {
    TEXT_REDSHOUSE1F_ROCKET_CHALLENGE = {
      text = "_BlackjackCornerHouseRocketBattleText",
    },
  })

  for piece = 1, #HouseWorld.EQUIPMENT do
    mod.content.sprites:register(("SPRITE_ROCKET_EQUIPMENT_%02d"):format(piece), {
      image = ("save/mod-derived/blackjack_corner/world/rocket_equipment_%02d.png")
        :format(piece), frames = 1,
    })
  end
end

function HouseWorld.sync(game, house)
  local state = house.snapshot(game)
  if not state then return false end
  local occupied = state.status == "ROCKET_OWNED"
    or state.status == "BUYBACK_PAID"
  World.setObjectVisible(game.save, HouseWorld.MAP_DOWNSTAIRS,
    HouseWorld.MOM_DOWNSTAIRS, not occupied)
  World.setObjectVisible(game.save, HouseWorld.MAP_UPSTAIRS,
    HouseWorld.MOM_UPSTAIRS, occupied)
  World.setObjectVisible(game.save, HouseWorld.MAP_DOWNSTAIRS,
    HouseWorld.TENANT, state.status == "ROCKET_OWNED")
  World.setObjectVisible(game.save, HouseWorld.MAP_DOWNSTAIRS,
    HouseWorld.OBSERVER, occupied)
  World.setObjectVisible(game.save, HouseWorld.MAP_DOWNSTAIRS,
    HouseWorld.CHALLENGE, state.status == "BUYBACK_PAID")
  for _, name in ipairs(HouseWorld.EQUIPMENT) do
    World.setObjectVisible(game.save, HouseWorld.MAP_DOWNSTAIRS, name, occupied)
  end
  return occupied
end

function HouseWorld.challengeSaveId()
  if not HouseWorld.challengeIndex then return nil end
  return HouseWorld.MAP_DOWNSTAIRS .. "_obj_" .. HouseWorld.challengeIndex
end

return HouseWorld
end
