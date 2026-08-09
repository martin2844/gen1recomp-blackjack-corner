return function(mod)
  mod.hooks:wrap("pokemon.sprite", function(next, path, ctx)
    return next(path, ctx)
  end)
  mod.hooks:wrap("battle.overlay", function(next, battle)
    return next(battle)
  end)
  mod.exports.fixture = true
end
