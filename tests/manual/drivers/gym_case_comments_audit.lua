-- Native Red/Blue gate for post-delivery Gym Leader reactions. Red forces
-- Misty's HORSEA roast; Blue forces her classic TM11 BUBBLEBEAM lesson.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local Screens = require("src.ui.Screens")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local version = (os.getenv("POKEPORT_VERSION") or "red"):lower()
  local loader = assert(game.mods, "mod loader is unavailable")
  local api = assert(loader.exports and loader.exports.blackjack_corner,
    "blackjack_corner is not loaded")
  local bucket = loader.modSave.blackjack_corner or {}
  loader.modSave.blackjack_corner = bucket

  bucket.gamble_mode = true
  bucket.gamble_campaign = api.campaign_state.defaults()
  bucket.gym_case_queue = {}
  game.save.inventory = game.save.inventory or {}
  game.save.party = game.save.party or {}
  game.save.boxes = game.save.boxes or {}
  game.save.currentBox = game.save.currentBox or 1
  game.save.pokedex = game.save.pokedex or { seen = {}, owned = {} }
  game.save.player = game.save.player or { name = "RED", id = 1 }
  game.save.options = game.save.options or {}
  game.save.options.textSpeed = 1

  local misty
  for _, object in ipairs(assert(game.data.maps.CERULEAN_GYM).objects or {}) do
    if object.trainerClass == "OPP_MISTY" then misty = object; break end
  end
  assert(misty, "Misty is missing from CERULEAN_GYM")
  U.teleport(game, "CERULEAN_GYM", misty.x,
    math.min(misty.y + 2, game.data.maps.CERULEAN_GYM.height * 2 - 1), "up")

  local reward = version == "blue" and {
    kind = "item", id = "TM_BUBBLEBEAM", quantity = 1,
    label = "TM BUBBLEBEAM", tier = "gold", weight = 120,
  } or {
    kind = "pokemon", species = "HORSEA", level = 22,
    label = "HORSEA", tier = "pokemon", weight = 100,
  }
  local entry = {
    id = "native:gym-comment:" .. version,
    badge = "CASCADEBADGE", order = 2, leader = "MISTY", reward = reward,
  }

  local function pageText(box)
    local lines = {}
    for _, page in ipairs(box.pages or {}) do
      for _, line in ipairs(page) do lines[#lines + 1] = line end
    end
    return table.concat(lines, " ")
  end

  U.wait(10)
  Screens.push(game, "BlackjackCornerGymCase", {
    caseData = entry, autoOpen = true, oneShot = true, title = "WATER CASE",
  })
  local case = game.stack:top()
  for _ = 1, 600 do
    if case.phase == "result" then break end
    U.wait(1)
  end
  assert(case.phase == "result", "Gym Case did not settle")
  assert(case.delivered and not case.claimSaved, "forced reward was not delivered")
  assert(U.shot(game, shotDir .. "/gym-case-result.png"))

  U.tap(game, "a")
  U.wait(5)
  local reaction = game.stack:top()
  assert(reaction and reaction.pages, "leader reaction did not open")
  local text = pageText(reaction):gsub("%s+", " ")
  U.log("REACTION", text)
  assert(text:find("MISTY", 1, true), "reaction does not identify Misty")
  if version == "blue" then
    assert(text:find("JACKPOT", 1, true)
        and text:find("BUBBLEBEAM", 1, true)
        and text:find("WATER POKEMON", 1, true),
      "Blue did not receive the gold TM11 lesson")
  else
    assert(text:find("SOLID PULL", 1, true)
        and text:find("HORSEA", 1, true)
        and text:find("mid", 1, true),
      "Red did not receive the HORSEA roast")
  end
  U.wait(100)
  assert(U.shot(game, shotDir .. "/gym-leader-rarity-header.png"))
  U.tap(game, "a")
  U.wait(100)
  assert(U.shot(game, shotDir .. "/gym-leader-prize-comment.png"))

  U.log("PASS", version:upper(), reward.id or reward.species,
    "exact prize and rarity reaction")
  U.log("GYM CASE COMMENT AUDIT COMPLETE")
  love.event.quit(0)
end
