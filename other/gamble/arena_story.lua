return function(mod, opts)
  local Story = {
    CLUES = assert(opts.state.STORY_CLUES),
    STAGES = assert(opts.state.STORY_STAGES),
    TARGET = 3,
  }
  local store = opts.state.new(mod, opts.active)
  local requirements = {
    [Story.CLUES.FRAME] = 0,
    [Story.CLUES.MANIFEST] = 3,
    [Story.CLUES.CHART] = 6,
  }

  local function count(clues)
    local total = 0
    for _, id in pairs(Story.CLUES) do
      if clues[id] then total = total + 1 end
    end
    return total
  end

  local function snapshot(campaign)
    if not campaign then return nil end
    return {
      stage = campaign.story.stage,
      clues = opts.state.copy(campaign.story.clues),
      clueCount = count(campaign.story.clues),
      clueTarget = Story.TARGET,
      matchesPlayed = campaign.arena.matchesPlayed,
    }
  end

  function Story.snapshot()
    return snapshot(store.load(false))
  end

  function Story.discover(_, clueId)
    local requiredMatches = requirements[clueId]
    if requiredMatches == nil then
      return false, Story.snapshot(), "UNKNOWN CLUE"
    end
    local campaign = store.load(false)
    if not campaign or not campaign.arena.stairsRevealed then
      return false, snapshot(campaign), "ARENA LOCKED"
    end
    if campaign.story.clues[clueId] then
      return false, snapshot(campaign), "ALREADY FOUND"
    end
    if campaign.arena.matchesPlayed < requiredMatches then
      return false, snapshot(campaign), "NOT READY"
    end

    campaign.story.clues[clueId] = true
    local advanced = count(campaign.story.clues) == Story.TARGET
      and campaign.story.stage == Story.STAGES.RUMORS
    if advanced then campaign.story.stage = Story.STAGES.LEAD end
    store.save(campaign)
    return true, snapshot(campaign), advanced and "LEAD COMPLETE" or "CLUE FOUND"
  end

  function Story.resetForQA()
    local campaign = store.load(true)
    if not campaign then return false end
    campaign.story = opts.state.defaults().story
    store.save(campaign)
    return true
  end

  return Story
end
