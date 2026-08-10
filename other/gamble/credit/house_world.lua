local HouseWorld = {
  MAP_DOWNSTAIRS = "REDS_HOUSE_1F",
  MAP_UPSTAIRS = "REDS_HOUSE_2F",
  MOM_DOWNSTAIRS = "REDSHOUSE1F_MOM",
  MOM_UPSTAIRS = "REDSHOUSE2F_GAMBLE_MOM",
  TENANT = "REDSHOUSE1F_ROCKET_TENANT",
  OBSERVER = "REDSHOUSE1F_ROCKET_OBSERVER",
  CHALLENGE = "REDSHOUSE1F_ROCKET_CHALLENGE",
  FURNITURE = {
    "REDSHOUSE1F_ROCKET_FURNITURE_01",
    "REDSHOUSE1F_ROCKET_FURNITURE_02",
    "REDSHOUSE1F_ROCKET_FURNITURE_03",
  },
}

local function nextIndex(map)
  local index = 1
  for _, object in ipairs(map.objects or {}) do
    index = math.max(index, (tonumber(object.index) or 0) + 1)
  end
  return index
end

local function append(objects, index, row)
  row.index, row.hidden = index, true
  row.movement, row.range = row.movement or "STAY", row.range or "NONE"
  objects[#objects + 1] = row
  return index + 1
end

function HouseWorld.register(mod)
  local downstairs = mod.content.maps:get(HouseWorld.MAP_DOWNSTAIRS)
  if downstairs then
    local rows, index = {}, nextIndex(downstairs)
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
    for piece, position in ipairs({ { 1, 2 }, { 6, 2 }, { 1, 5 } }) do
      index = append(rows, index, {
        name = HouseWorld.FURNITURE[piece],
        sprite = ("SPRITE_ROCKET_FURNITURE_%02d"):format(piece),
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
        index = nextIndex(upstairs), name = HouseWorld.MOM_UPSTAIRS,
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

  for piece = 1, 3 do
    mod.content.sprites:register(("SPRITE_ROCKET_FURNITURE_%02d"):format(piece), {
      image = ("save/mod-derived/blackjack_corner/world/rocket_furniture_%02d.png")
        :format(piece), frames = 1, trueColor = true,
    })
  end
end

local function setToggle(save, mapId, name, visible)
  save.objectToggles = save.objectToggles or {}
  save.objectToggles[mapId] = save.objectToggles[mapId] or {}
  save.objectToggles[mapId][name] = visible and true or false
end

function HouseWorld.sync(game, house)
  local state = house.snapshot(game)
  if not state then return false end
  local occupied = state.status == "ROCKET_OWNED"
    or state.status == "BUYBACK_PAID"
  setToggle(game.save, HouseWorld.MAP_DOWNSTAIRS,
    HouseWorld.MOM_DOWNSTAIRS, not occupied)
  setToggle(game.save, HouseWorld.MAP_UPSTAIRS,
    HouseWorld.MOM_UPSTAIRS, occupied)
  setToggle(game.save, HouseWorld.MAP_DOWNSTAIRS,
    HouseWorld.TENANT, state.status == "ROCKET_OWNED")
  setToggle(game.save, HouseWorld.MAP_DOWNSTAIRS,
    HouseWorld.OBSERVER, occupied)
  setToggle(game.save, HouseWorld.MAP_DOWNSTAIRS,
    HouseWorld.CHALLENGE, state.status == "BUYBACK_PAID")
  for _, name in ipairs(HouseWorld.FURNITURE) do
    setToggle(game.save, HouseWorld.MAP_DOWNSTAIRS, name, occupied)
  end
  return occupied
end

function HouseWorld.challengeSaveId()
  if not HouseWorld.challengeIndex then return nil end
  return HouseWorld.MAP_DOWNSTAIRS .. "_obj_" .. HouseWorld.challengeIndex
end

return HouseWorld
