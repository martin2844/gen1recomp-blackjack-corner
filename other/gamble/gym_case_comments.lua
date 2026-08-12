-- Prize-specific Gym Leader reactions shown after a Gym Case is delivered.
-- Keeping the copy separate from reward/economy logic makes the full script
-- easy to review without turning gym_cases.lua into a wall of dialogue.
local Comments = {}

local TIER_LINES = {
  common = "A SAFE PULL.",
  pokemon = "A SOLID PULL.",
  rare = "A RARE PULL!",
  epic = "AN EPIC PULL!",
  gold = "JACKPOT!",
}

local BY_BADGE = {
  BOULDERBADGE = {
    ["pokemon:GEODUDE"] = "GEODUDE is steady.\nNot glamorous, but\nneither is a wall.",
    ["pokemon:ONIX"] = "ONIX has presence.\nNow teach it that\nsize isn't skill.",
    ["pokemon:RHYHORN"] = "RHYHORN is stubborn.\nGood. A trainer\nshould be tougher.",
    ["pokemon:OMANYTE"] = "OMANYTE is ancient.\nStudy its patience,\nnot just its shell.",
    ["item:TM_BIDE"] = "TM34 is BIDE.\nTake the hit, then\nreturn it double.\fThat's the lesson.",
    ["item:TM_ROCK_SLIDE"] = "TM48 is ROCK SLIDE.\nReliable, heavy,\nand hard to ignore.",
    ["item:TM_DIG"] = "TM28 is DIG.\nEven solid trainers\nneed an exit plan.",
    ["item:MOON_STONE"] = "A MOON STONE.\nSome strength waits\nfor the right moment.",
    ["item:X_DEFEND"] = "X DEFEND. Sensible.\nNot every victory\nneeds to look flashy.",
    ["item:SUPER_POTION"] = "A SUPER POTION.\nUseful, if less solid\nthan a new partner.",
  },
  CASCADEBADGE = {
    ["pokemon:PSYDUCK"] = "PSYDUCK looks lost.\nHonestly, it may be\nmore confused than you.",
    ["pokemon:POLIWAG"] = "POLIWAG is small,\nbut that spiral has\nreal potential.",
    ["pokemon:STARYU"] = "STARYU is stylish.\nFinally, the case\nshows some taste.",
    ["pokemon:HORSEA"] = "HORSEA is cute.\nA little mid, maybe,\nbut definitely cute.\fTrain it well and\nprove me wrong.",
    ["pokemon:LAPRAS"] = "LAPRAS? Okay, wow.\nThat's not a splash.\nThat's a tidal wave.",
    ["item:TM_BUBBLEBEAM"] = "TM11 is BUBBLEBEAM.\nTeach it to a\nWATER POKEMON.\fPreferably one that\ncan keep up.",
    ["item:TM_WATER_GUN"] = "TM12 is WATER GUN.\nBasic, but basic still\nbeats missing.",
    ["item:TM_ICE_BEAM"] = "TM13 is ICE BEAM.\nCool pull. Literally.\nDon't waste it.",
    ["item:WATER_STONE"] = "A WATER STONE.\nEvolution on demand.\nNo pressure, right?",
    ["item:SUPER_POTION"] = "A SUPER POTION.\nNot exciting, but it\nwill keep you afloat.",
  },
  THUNDERBADGE = {
    ["pokemon:PIKACHU"] = "PIKACHU REPORTING!\nSmall unit. High volts.\nDo not underestimate.",
    ["pokemon:MAGNEMITE"] = "MAGNEMITE ACQUIRED!\nDisciplined. Efficient.\nNo complaints.",
    ["pokemon:VOLTORB"] = "VOLTORB IS LIVE!\nWatch your step unless\nyou enjoy explosions.",
    ["pokemon:ELECTABUZZ"] = "ELECTABUZZ!\nHeavy shock trooper.\nNow that's firepower.",
    ["pokemon:JOLTEON"] = "JOLTEON! ELITE SPEED!\nThe case just promoted\nyou, soldier.",
    ["item:TM_THUNDERBOLT"] = "TM24: THUNDERBOLT!\nAccurate, powerful,\nbattle approved.",
    ["item:TM_THUNDER"] = "TM25: THUNDER!\nMaximum voltage.\nAccuracy is your war.",
    ["item:TM_THUNDER_WAVE"] = "TM45: THUNDER WAVE!\nStop the enemy first.\nAsk questions later.",
    ["item:THUNDER_STONE"] = "THUNDER STONE!\nEvolution orders have\narrived. Execute them.",
    ["item:X_SPEED"] = "X SPEED!\nNot glorious, but slow\nsoldiers lose battles.",
  },
  RAINBOWBADGE = {
    ["pokemon:ODDISH"] = "ODDISH is modest.\nLovely things often\nbegin underground.",
    ["pokemon:BELLSPROUT"] = "BELLSPROUT bends well.\nGrace can be stronger\nthan it appears.",
    ["pokemon:EXEGGCUTE"] = "EXEGGCUTE. Six minds,\nand somehow still one\nvery odd expression.",
    ["pokemon:TANGELA"] = "TANGELA is mysterious.\nUntangling it may take\nlonger than training it.",
    ["pokemon:PARAS"] = "PARAS is... charming.\nDo mind the mushrooms.\nThey seem ambitious.",
    ["item:TM_MEGA_DRAIN"] = "TM21 is MEGA DRAIN.\nTake only what you need.\nUsually.",
    ["item:TM_SOLARBEAM"] = "TM22 is SOLARBEAM.\nA whole garden's light\nin one attack.",
    ["item:TM_DOUBLE_TEAM"] = "TM32 is DOUBLE TEAM.\nWhy be graceful once\nwhen you can be eight?",
    ["item:LEAF_STONE"] = "A LEAF STONE.\nA quiet little push\ntoward something grand.",
    ["item:FULL_HEAL"] = "A FULL HEAL.\nPractical things can\nstill be beautiful.",
  },
  SOULBADGE = {
    ["pokemon:KOFFING"] = "KOFFING hides danger\nbehind a foolish grin.\nAn effective disguise.",
    ["pokemon:GRIMER"] = "GRIMER lacks elegance.\nPoison seldom asks for\npermission.",
    ["pokemon:VENONAT"] = "VENONAT sees what others\nmiss. Train its eyes\nas well as its fangs.",
    ["pokemon:SCYTHER"] = "SCYTHER is a true blade.\nSwift, silent, and far\nsharper than luck.",
    ["pokemon:PINSIR"] = "PINSIR has no subtlety.\nSometimes the direct\ntechnique is enough.",
    ["item:TM_TOXIC"] = "TM06 is TOXIC.\nOne drop becomes defeat.\nUse it with discipline.",
    ["item:TM_RAGE"] = "TM20 is RAGE.\nAnger is a weapon only\nwhen you command it.",
    ["item:TM_REST"] = "TM44 is REST.\nEven a ninja knows when\nto vanish and recover.",
    ["item:FULL_HEAL"] = "A FULL HEAL.\nThe antidote is less\nromantic than poison.",
    ["item:MAX_REVIVE"] = "A MAX REVIVE.\nA second life is rarer\nthan a second chance.",
  },
  MARSHBADGE = {
    ["pokemon:ABRA"] = "ABRA already knew.\nIt was waiting for you\nbefore the reel stopped.",
    ["pokemon:DROWZEE"] = "DROWZEE saw your dreams.\nIt refuses to tell me\nif they were tasteful.",
    ["pokemon:MR_MIME"] = "MR.MIME. A silent mind\nbehind an invisible wall.\nUseful company.",
    ["pokemon:JYNX"] = "JYNX is unusual.\nYou will understand it\nbefore others do.",
    ["pokemon:SLOWPOKE"] = "SLOWPOKE arrived late.\nThe vision was accurate,\nif not punctual.",
    ["item:TM_PSYWAVE"] = "TM46 is PSYWAVE.\nIts power fluctuates.\nSo does your judgment.",
    ["item:TM_PSYCHIC_M"] = "TM29 is PSYCHIC.\nI foresaw this pull.\nYou may look impressed.",
    ["item:TM_TELEPORT"] = "TM30 is TELEPORT.\nA perfect technique for\nleaving awkward rooms.",
    ["item:PP_UP"] = "A PP UP.\nMore endurance. Less need\nfor desperate thoughts.",
    ["item:MAX_REVIVE"] = "A MAX REVIVE.\nEven fate occasionally\npermits a correction.",
  },
  VOLCANOBADGE = {
    ["pokemon:GROWLITHE"] = "GROWLITHE! Hot pull!\nLoyal, brave, and better\nat quizzes than it looks.",
    ["pokemon:PONYTA"] = "PONYTA! A fiery ride.\nQuestion one: can you\nkeep up with it?",
    ["pokemon:MAGMAR"] = "MAGMAR! Now we're cooking!\nCareful, it considers\nroom temperature cold.",
    ["pokemon:VULPIX"] = "VULPIX! Six tails now,\nmore later. That's what\nI call extra credit!",
    ["pokemon:CHARMANDER"] = "CHARMANDER! Correct!\nA starter from a case?\nThat's a blazing answer.",
    ["item:TM_FIRE_BLAST"] = "TM38 is FIRE BLAST!\nFive points of flame,\none very correct answer.",
    ["item:FIRE_STONE"] = "A FIRE STONE!\nWhat evolves with it?\nNo hints. Study!",
    ["item:TM_REFLECT"] = "TM33 is REFLECT!\nThe smart answer when\nfirepower isn't enough.",
    ["item:TM_SUBSTITUTE"] = "TM50 is SUBSTITUTE!\nWhy take the test when\na doll can take it?",
    ["item:RARE_CANDY"] = "A RARE CANDY!\nInstant growth, zero study.\nI have mixed feelings.",
  },
  EARTHBADGE = {
    ["pokemon:DUGTRIO"] = "DUGTRIO. Three workers,\none salary. Team Rocket\nwould approve.",
    ["pokemon:PERSIAN"] = "PERSIAN suits success.\nAt last, the machine\nshows refinement.",
    ["pokemon:KANGASKHAN"] = "KANGASKHAN protects its own.\nA strength even money\ncannot easily purchase.",
    ["pokemon:RHYDON"] = "RHYDON is raw authority.\nDirect it well, or stay\nout of its way.",
    ["pokemon:TAUROS"] = "TAUROS cannot be bribed.\nControl that temper and\nyou control the room.",
    ["item:TM_EARTHQUAKE"] = "TM26 is EARTHQUAKE.\nReal power makes the\nwhole room take notice.",
    ["item:TM_FISSURE"] = "TM27 is FISSURE.\nOne opening. One ending.\nDo not miss.",
    ["item:TM_DIG"] = "TM28 is DIG.\nEvery organization needs\na discreet escape route.",
    ["item:TM_TRI_ATTACK"] = "TM49 is TRI ATTACK.\nThree threats make for\nan efficient negotiation.",
    ["item:MASTER_BALL"] = "A MASTER BALL.\nThe house has lost its\nbest kept secret.\fDo not make me regret\nletting you leave with it.",
  },
}

-- A reward selected by an older release remains an immutable claim even when
-- its old pool entry no longer belongs to this badge. Name that exact reward
-- instead of silently skipping the new post-case reaction.
local LEGACY_LINES = {
  BOULDERBADGE = "%s survived an older\nreel. A solid prize\ndoesn't need polish.",
  CASCADEBADGE = "%s? Old reel.\nNot exactly WATER,\nbut luck has no taste.",
  THUNDERBADGE = "%s! LEGACY ISSUE!\nUnexpected equipment\nis still equipment.",
  RAINBOWBADGE = "%s, from an older\nseason. Even luck has\nroots that linger.",
  SOULBADGE = "%s crossed time\nunseen. An old prize\nmay still strike true.",
  MARSHBADGE = "%s. An earlier path\nleft it here. I saw\nthat possibility too.",
  VOLCANOBADGE = "%s! Bonus question:\nwhy was it in this\nold case? Nobody knows!",
  EARTHBADGE = "%s, from an older\narrangement. Power does\nnot expire with policy.",
}

local function rewardKey(reward)
  if type(reward) ~= "table" then return nil end
  local identity = reward.id or reward.species
  if not reward.kind or not identity then return nil end
  return tostring(reward.kind) .. ":" .. tostring(identity)
end

local function twoLinePages(text)
  local pages = {}
  for markedPage in (tostring(text or "") .. "\f"):gmatch("(.-)\f") do
    local lines = {}
    for line in (markedPage .. "\n"):gmatch("(.-)\n") do
      line = line:gsub("^%s+", ""):gsub("%s+$", "")
      while #line > 18 do
        local cut = 18
        for index = 18, 1, -1 do
          if line:sub(index, index) == " " then cut = index - 1; break end
        end
        lines[#lines + 1] = line:sub(1, cut)
        line = line:sub(cut + 1):gsub("^%s+", "")
      end
      lines[#lines + 1] = line
    end
    for index = 1, #lines, 2 do
      pages[#pages + 1] = lines[index]
        .. (lines[index + 1] and "\n" .. lines[index + 1] or "")
    end
  end
  return table.concat(pages, "\f")
end

function Comments.forReward(entry, reward)
  local badge = entry and entry.badge
  local gym = badge and BY_BADGE[badge]
  if not gym or type(reward) ~= "table" then return nil end
  local body = gym[rewardKey(reward)]
  if not body then
    local label = tostring(reward.label or reward.id or reward.species or "OLD PRIZE")
      :gsub("_", " ")
    body = (LEGACY_LINES[badge] or "%s came from an older reel."):format(label)
  end
  local leader = entry.leader or badge or "GYM LEADER"
  local tier = TIER_LINES[reward.tier] or TIER_LINES.rare
  return twoLinePages(tostring(leader) .. ": " .. tier)
    .. "\f" .. twoLinePages(body)
end

Comments.byBadge = BY_BADGE
Comments.tierLines = TIER_LINES
Comments.legacyLines = LEGACY_LINES
Comments.twoLinePages = twoLinePages

return Comments
