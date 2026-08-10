return function(World)
local CreditWorld = {}

CreditWorld.COLLECTORS = {
  {
    mapId = "PALLET_TOWN", name = "PALLETTOWN_ROCKET_COLLECTOR",
    text = "TEXT_PALLETTOWN_ROCKET_COLLECTOR", x = 7, y = 14,
    range = "RIGHT",
  },
  {
    mapId = "CELADON_CITY", name = "CELADONCITY_ROCKET_COLLECTOR",
    text = "TEXT_CELADONCITY_ROCKET_COLLECTOR", x = 29, y = 22,
    range = "LEFT",
  },
}

function CreditWorld.register(mod)
  for _, collector in ipairs(CreditWorld.COLLECTORS) do
    local map = mod.content.maps:get(collector.mapId)
    if map then
      mod.content.maps:patch(collector.mapId, { objects = { __append = {
        {
          index = World.nextObjectIndex(map), name = collector.name, hidden = true,
          movement = "STAY", range = collector.range,
          sprite = "SPRITE_ROCKET", text = collector.text,
          x = collector.x, y = collector.y,
        },
      } } })
    end
  end
end

-- Object toggles are normal save data. Updating inactive maps here makes the
-- collector appear on the player's next entry without reloading the current
-- map underneath a menu or dialogue stack.
function CreditWorld.sync(game, credit)
  local state = credit.snapshot(game)
  local visible = state ~= nil and state.status == "DEFAULT"
  game.save.objectToggles = game.save.objectToggles or {}
  for _, collector in ipairs(CreditWorld.COLLECTORS) do
    local toggles = game.save.objectToggles[collector.mapId] or {}
    game.save.objectToggles[collector.mapId] = toggles
    toggles[collector.name] = visible
  end
  return visible
end

return CreditWorld
end
