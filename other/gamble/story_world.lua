return function(World)
local StoryWorld = {}

StoryWorld.PEOPLE = {
  {
    mapId = "CINNABAR_LAB_METRONOME_ROOM",
    name = "BLACKJACK_CORNER_CINNABAR_HANDLER",
    text = "TEXT_BLACKJACK_CORNER_CINNABAR_HANDLER",
    sprite = "SPRITE_ROCKET", x = 5, y = 5, range = "DOWN",
  },
  {
    mapId = "POKEMON_MANSION_B1F",
    name = "BLACKJACK_CORNER_MANSION_RESEARCHER",
    text = "TEXT_BLACKJACK_CORNER_MANSION_RESEARCHER",
    sprite = "SPRITE_SCIENTIST", x = 16, y = 19, range = "DOWN",
  },
  {
    mapId = "ROCKET_BATTLE_ARENA",
    name = "BLACKJACK_CORNER_GIOVANNI",
    text = "TEXT_BLACKJACK_CORNER_GIOVANNI",
    sprite = "SPRITE_GIOVANNI", x = 10, y = 6, range = "DOWN",
  },
}

function StoryWorld.register(mod)
  StoryWorld.mod = mod
  for _, person in ipairs(StoryWorld.PEOPLE) do
    local map = mod.content.maps:get(person.mapId)
    if map then
      mod.content.maps:patch(person.mapId, { objects = { __append = {
        {
          index = World.nextObjectIndex(map), name = person.name, hidden = true,
          movement = "STAY", range = person.range,
          sprite = person.sprite, text = person.text,
          x = person.x, y = person.y,
        },
      } } })
    end
  end
end

function StoryWorld.sync(game, story, reload)
  local state = story.snapshot(game)
  local stages = story.STAGES
  local handlerVisible = state and state.stage ~= stages.RUMORS
  local researcherVisible = state and (state.stage == stages.INVESTIGATION
    or state.stage == stages.INVITATION)
  local giovanniVisible = state and (state.stage == stages.CHOICE
    or state.stage == stages.EXPOSED or state.stage == stages.CHAMPION)
  game.save.objectToggles = game.save.objectToggles or {}
  World.setObjectVisible(game.save, StoryWorld.PEOPLE[1].mapId,
    StoryWorld.PEOPLE[1].name, handlerVisible == true)
  World.setObjectVisible(game.save, StoryWorld.PEOPLE[2].mapId,
    StoryWorld.PEOPLE[2].name, researcherVisible == true)
  World.setObjectVisible(game.save, StoryWorld.PEOPLE[3].mapId,
    StoryWorld.PEOPLE[3].name, giovanniVisible == true)
  if reload and StoryWorld.mod and StoryWorld.mod.world then
    local current = StoryWorld.mod.world:current()
    if current and current.mapId == StoryWorld.PEOPLE[3].mapId then
      StoryWorld.mod.world:invalidateMap(current.mapId)
    end
  end
  return handlerVisible == true, researcherVisible == true,
    giovanniVisible == true
end

return StoryWorld
end
