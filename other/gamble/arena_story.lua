return function(mod, opts)
  local Story = {
    CLUES = assert(opts.state.STORY_CLUES),
    STAGES = assert(opts.state.STORY_STAGES),
    TARGET = 3,
    CINNABAR_TARGET = 2,
  }
  local store = opts.state.new(mod, opts.active)
  local requirements = {
    [Story.CLUES.FRAME] = 0,
    [Story.CLUES.MANIFEST] = 3,
    [Story.CLUES.CHART] = 6,
  }
  local stageOrder = {
    [Story.STAGES.RUMORS] = 1,
    [Story.STAGES.LEAD] = 2,
    [Story.STAGES.INVESTIGATION] = 3,
    [Story.STAGES.INVITATION] = 4,
    [Story.STAGES.CHOICE] = 5,
  }

  local arenaClues = {
    Story.CLUES.FRAME, Story.CLUES.MANIFEST, Story.CLUES.CHART,
  }
  local cinnabarClues = {
    Story.CLUES.LAB_ARCHIVE, Story.CLUES.MANSION_LOG,
  }

  local function count(clues, ids)
    local total = 0
    for _, id in ipairs(ids) do
      if clues[id] then total = total + 1 end
    end
    return total
  end

  local function snapshot(campaign)
    if not campaign then return nil end
    return {
      stage = campaign.story.stage,
      clues = opts.state.copy(campaign.story.clues),
      clueCount = count(campaign.story.clues, arenaClues),
      clueTarget = Story.TARGET,
      cinnabarClueCount = count(campaign.story.clues, cinnabarClues),
      cinnabarClueTarget = Story.CINNABAR_TARGET,
      matchesPlayed = campaign.arena.matchesPlayed,
      exhibition = opts.state.copy(campaign.story.exhibition),
    }
  end

  function Story.snapshot()
    return snapshot(store.load(false))
  end

  function Story.discover(_, clueId)
    local requiredMatches = requirements[clueId]
    local mansionLog = clueId == Story.CLUES.MANSION_LOG
    if requiredMatches == nil and not mansionLog then
      return false, Story.snapshot(), "UNKNOWN CLUE"
    end
    local campaign = store.load(false)
    if not campaign or not campaign.arena.stairsRevealed then
      return false, snapshot(campaign), "ARENA LOCKED"
    end
    if campaign.story.clues[clueId] then
      return false, snapshot(campaign), "ALREADY FOUND"
    end
    if mansionLog and (stageOrder[campaign.story.stage] or 0)
        < stageOrder[Story.STAGES.INVESTIGATION] then
      return false, snapshot(campaign), "WRONG STAGE"
    end
    if requiredMatches and campaign.arena.matchesPlayed < requiredMatches then
      return false, snapshot(campaign), "NOT READY"
    end

    campaign.story.clues[clueId] = true
    local advanced = count(campaign.story.clues, arenaClues) == Story.TARGET
      and campaign.story.stage == Story.STAGES.RUMORS
    if advanced then campaign.story.stage = Story.STAGES.LEAD end
    local invited = count(campaign.story.clues, cinnabarClues)
      == Story.CINNABAR_TARGET
      and campaign.story.stage == Story.STAGES.INVESTIGATION
    if invited then campaign.story.stage = Story.STAGES.INVITATION end
    store.save(campaign)
    return true, snapshot(campaign), invited and "INVITATION READY"
      or advanced and "LEAD COMPLETE" or "CLUE FOUND"
  end

  function Story.beginCinnabar()
    local campaign = store.load(false)
    if not campaign then return false, nil, "GAMBLE MODE OFF" end
    if campaign.story.stage == Story.STAGES.INVESTIGATION
        or campaign.story.stage == Story.STAGES.INVITATION then
      return false, snapshot(campaign), "ALREADY CONTACTED"
    end
    if campaign.story.stage ~= Story.STAGES.LEAD then
      return false, snapshot(campaign), "NO CINNABAR LEAD"
    end
    campaign.story.stage = Story.STAGES.INVESTIGATION
    campaign.story.clues[Story.CLUES.LAB_ARCHIVE] = true
    store.save(campaign)
    return true, snapshot(campaign), "INVESTIGATION STARTED"
  end

  function Story.exhibitionAvailable()
    local campaign = store.load(false)
    return campaign ~= nil
      and campaign.story.stage == Story.STAGES.INVITATION
  end

  function Story.settleExhibition(_, matchId, won)
    local campaign = store.load(false)
    if not campaign then return false, nil, "GAMBLE MODE OFF" end
    if campaign.story.stage ~= Story.STAGES.INVITATION
        and campaign.story.stage ~= Story.STAGES.CHOICE then
      return false, snapshot(campaign), "NO EXHIBITION INVITATION"
    end
    matchId = math.max(0, math.floor(tonumber(matchId) or 0))
    local exhibition = campaign.story.exhibition
    if matchId < 1 then return false, snapshot(campaign), "INVALID MATCH" end
    if matchId <= exhibition.lastMatchId then
      return false, snapshot(campaign), "ALREADY SETTLED"
    end
    exhibition.lastMatchId = matchId
    exhibition.attempts = exhibition.attempts + 1
    if won then
      exhibition.wins = exhibition.wins + 1
      campaign.story.stage = Story.STAGES.CHOICE
    end
    store.save(campaign)
    return true, snapshot(campaign), won and "GIOVANNI SUMMONED"
      or "EXHIBITION LOST"
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
