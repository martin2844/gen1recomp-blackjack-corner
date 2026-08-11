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
}

function StoryWorld.register(mod)
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

function StoryWorld.sync(game, story)
  local state = story.snapshot(game)
  local stages = story.STAGES
  local handlerVisible = state and state.stage ~= stages.RUMORS
  local researcherVisible = state and (state.stage == stages.INVESTIGATION
    or state.stage == stages.INVITATION)
  game.save.objectToggles = game.save.objectToggles or {}
  World.setObjectVisible(game.save, StoryWorld.PEOPLE[1].mapId,
    StoryWorld.PEOPLE[1].name, handlerVisible == true)
  World.setObjectVisible(game.save, StoryWorld.PEOPLE[2].mapId,
    StoryWorld.PEOPLE[2].name, researcherVisible == true)
  return handlerVisible == true, researcherVisible == true
end

return StoryWorld
end
