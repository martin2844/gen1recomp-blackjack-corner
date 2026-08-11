return function(mod, opts)
  local State = assert(opts.state)
  local store = State.new(mod, opts.active)
  local underground = {
    [assert(opts.lobbyMap)] = true,
    [assert(opts.arenaMap)] = true,
  }
  local Security = {}

  local function campaign(create)
    return store.load(create)
  end

  function Security.snapshot()
    local value = campaign(false)
    if not value then return nil end
    return { stairsRevealed = value.arena.stairsRevealed }
  end

  function Security.revealStairs()
    local value = campaign(true)
    if not value then return false, "GAMBLE MODE OFF" end
    value.arena.stairsRevealed = true
    store.save(value)
    return true
  end

  -- Builds prior to the static-staff change could save the whole party in the
  -- arena record. Recover that legacy state once, but never create it again.
  function Security.recoverLegacyParty(game)
    local value = campaign(false)
    if not value then
      local raw = mod.save:get(State.KEY)
      if type(raw) == "table" and raw.arena and raw.arena.heldParty then
        value = State.sanitize(raw)
      end
    end
    if not value then return true, 0 end
    local held = value.arena.heldParty
    if not held then
      if value.arena.securityExit then
        value.arena.securityExit = false
        mod.save:set(State.KEY, State.sanitize(value))
      end
      return true, 0
    end
    local current = game.save and game.save.party or {}
    if type(current) ~= "table" or #current > 0 then
      return false, "PARTY SLOT CONFLICT"
    end
    game.save.party = State.copy(held)
    value.arena.heldParty = nil
    value.arena.securityExit = false
    mod.save:set(State.KEY, State.sanitize(value))
    return true, #game.save.party
  end

  function Security.entered(game, mapId, fromMapId)
    local recovered, count = Security.recoverLegacyParty(game)

    -- v0.5.0 could save inside the old lift-based Lobby or Arena. On upgrade,
    -- that player must retain an open route upstairs; otherwise the new
    -- physical return warp lands inside the terminal that covers the stairs.
    -- Seeing either underground map proves this campaign opened the route.
    if underground[mapId] or underground[fromMapId] then
      local value = campaign(false)
      if value and not value.arena.stairsRevealed then
        value.arena.stairsRevealed = true
        store.save(value)
      end
    end
    return recovered, count
  end

  return Security
end
