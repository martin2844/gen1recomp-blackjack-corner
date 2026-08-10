-- Crystal's shiny palettes, applied to the player's own imported Gen I art.
-- Adapted from Gen II Shiny Indicators v1.5.3 by Deftones565 under the MIT
-- grant recorded in THIRD_PARTY_NOTICES.md. No Pokemon pixels are shipped.
local STEMS = "bulbasaur,ivysaur,venusaur,charmander,charmeleon,charizard,squirtle,wartortle,blastoise,caterpie,metapod,butterfree,weedle,kakuna,beedrill,pidgey,pidgeotto,pidgeot,rattata,raticate,spearow,fearow,ekans,arbok,pikachu,raichu,sandshrew,sandslash,nidoranf,nidorina,nidoqueen,nidoranm,nidorino,nidoking,clefairy,clefable,vulpix,ninetales,jigglypuff,wigglytuff,zubat,golbat,oddish,gloom,vileplume,paras,parasect,venonat,venomoth,diglett,dugtrio,meowth,persian,psyduck,golduck,mankey,primeape,growlithe,arcanine,poliwag,poliwhirl,poliwrath,abra,kadabra,alakazam,machop,machoke,machamp,bellsprout,weepinbell,victreebel,tentacool,tentacruel,geodude,graveler,golem,ponyta,rapidash,slowpoke,slowbro,magnemite,magneton,farfetchd,doduo,dodrio,seel,dewgong,grimer,muk,shellder,cloyster,gastly,haunter,gengar,onix,drowzee,hypno,krabby,kingler,voltorb,electrode,exeggcute,exeggutor,cubone,marowak,hitmonlee,hitmonchan,lickitung,koffing,weezing,rhyhorn,rhydon,chansey,tangela,kangaskhan,horsea,seadra,goldeen,seaking,staryu,starmie,mr.mime,scyther,jynx,electabuzz,magmar,pinsir,tauros,magikarp,gyarados,lapras,ditto,eevee,vaporeon,jolteon,flareon,porygon,omanyte,omastar,kabuto,kabutops,aerodactyl,snorlax,articuno,zapdos,moltres,dratini,dragonair,dragonite,mewtwo,mew"

-- The two middle 5-bit colors from Pokemon Crystal, expanded with n << 3 and
-- packed as RRGGBBRRGGBB in National-Dex order. White and black stay fixed.
local COLORS = "a0e058f85030a0e058f8c04890c858f8b018f8c030f88010f8a878b84868a078a840a87068b84088c8f068b8409098f870a8388080a0d8c030f86088e09868c07000f878b878f800b8d828d038e8a0d82068883888a0684038d8f0e060a09840a89828987028f8a070788810b0b898a08868b8c878d08018f0d000c06808808050c08838a0b868485828909858a050f0f88800a01058a898a0c09810808050584078809020a83008d888e0288808f888f0307850f880f858684090a8f8884078a0b8f8b820c86888f87848b8f868c8409000f868c8409000f8c008b08008d8b0c88888b8f888f848c018f888f848c018d878f0508830e86098387800f8d020409058f8a828688860f8a818407868d89818706808f8a8489080287088f85828b08078f88830a89858206030d89858206030d8f8b060d01090f8e050e048d8a898f85058a0e050683888f098b058a08038b88830808030b8a038a86800c08878988808d040884040e84880d04050f858c0d0408878e0c050a04898e0c050a04898989818a810a87870583040487080583830c8708858486020a0a038a050a8b0e038984898a0b8187060f89898f840986888a0f828a000c08878786838b87060805838c87860983818b89880986860b098a08850d8b058d08800f8a850f890900098a098a03838788090905858a0807060a008e0b800908000f8c008908000a098b0e83828a098a090587080980858505078a048506818c08838a84820a060e05820f88088f02838585048d8400098f800e87860b878a820705838c068d8900050f048c8905068a8a0b0907820a8b048606858a0a0884810e0a0a0884810e0b8c830986048988840c07048b0b0b858784890a87870782088a8286840688088604018f8c0b048e0487080a0c84860b880a0c84860b8b07888785868b0a8a8606088d8c89868980890f000883030808098185818f860c06078f8f858d85020e8e89800f07000a8d890d0b0109080984068f0e848585858f8f858f888980088c000e04800701078f848d8f8c80090a000f870f0c02070b8b848585878f0d870487050c8c000808000c8a040d85028f868f88058f888b0e04860d89898a8607068d8a8f87850c0c8b000787830f08808c048007018d86058c8b89850605858c8e010605878b8c0a070905098a058507850b048b86048a8d8b0584838f898d0f86868b0f89800f82000f85870a80800a898c07058c0a898f8a078f888987098007098a8b078780090c0f83858d0"

local function shinyByte(offset)
  return assert(tonumber(COLORS:sub(offset, offset + 1), 16))
end

-- Build two ROM-clean 64x32 overworld tables from authored pixels, then slice
-- each into eight ordinary 16x16 overworld sprites. Keeping each cell separate
-- gives the existing entity sorter and collision system exactly the shape
-- they already understand, while trueColor preserves the green felt in
-- every palette mode.
local TABLE_COLORS = {
  outline = { 0.07, 0.04, 0.06, 1 },
  woodDark = { 0.24, 0.07, 0.08, 1 },
  wood = { 0.48, 0.16, 0.16, 1 },
  woodLight = { 0.68, 0.27, 0.22, 1 },
  rail = { 0.96, 0.91, 0.70, 1 },
  feltDark = { 0.035, 0.24, 0.10, 1 },
  felt = { 0.08, 0.62, 0.17, 1 },
  feltLight = { 0.35, 0.84, 0.29, 1 },
  card = { 0.96, 0.91, 0.72, 1 },
  red = { 0.70, 0.10, 0.16, 1 },
}

local HOLDEM_COLORS = {
  outline = { 0.05, 0.04, 0.08, 1 },
  woodDark = { 0.16, 0.08, 0.18, 1 },
  wood = { 0.34, 0.16, 0.34, 1 },
  woodLight = { 0.58, 0.30, 0.46, 1 },
  rail = { 0.96, 0.82, 0.44, 1 },
  feltDark = { 0.02, 0.12, 0.20, 1 },
  felt = { 0.03, 0.34, 0.43, 1 },
  feltLight = { 0.12, 0.58, 0.62, 1 },
  card = { 0.96, 0.91, 0.72, 1 },
  red = { 0.70, 0.10, 0.16, 1 },
}

local MACHINE_COLORS = {
  outline = { 0.05, 0.04, 0.07, 1 },
  bodyDark = { 0.18, 0.11, 0.22, 1 },
  body = { 0.42, 0.23, 0.42, 1 },
  trim = { 0.94, 0.68, 0.19, 1 },
  screen = { 0.03, 0.16, 0.20, 1 },
  green = { 0.18, 0.76, 0.26, 1 },
  blue = { 0.18, 0.56, 0.76, 1 },
  red = { 0.78, 0.14, 0.20, 1 },
  paper = { 0.95, 0.91, 0.70, 1 },
}

local function pixel(image, x, y, c)
  if x >= 0 and y >= 0 and x < image:getWidth() and y < image:getHeight() then
    image:setPixel(x, y, c[1], c[2], c[3], c[4])
  end
end

local function fill(image, x, y, width, height, c)
  for py = y, y + height - 1 do
    for px = x, x + width - 1 do pixel(image, px, py, c) end
  end
end

local function row(image, y, inset, c)
  fill(image, inset, y, image:getWidth() - inset * 2, 1, c)
end

local function bodyInset(y)
  if y <= 18 then return 0 end
  return math.min(12, math.floor((y - 18) * 1.15))
end

local function surfaceInset(y)
  if y <= 14 then return 1 end
  return math.min(14, 1 + math.floor((y - 14) * 1.65))
end

local function circle(image, cx, cy, radius, c)
  for y = -radius, radius do
    for x = -radius, radius do
      if x * x + y * y <= radius * radius then pixel(image, cx + x, cy + y, c) end
    end
  end
end

local function buildTable(ctx, id, c)
  local width = 64
  local image = ctx.blank(width, 32, 0, 0, 0, 0)

  -- Deep wooden cabinet and its curved front apron.
  for y = 5, 30 do row(image, y, bodyInset(y), c.outline) end
  for y = 7, 28 do row(image, y, bodyInset(y) + 2, c.woodDark) end
  for y = 8, 25 do row(image, y, bodyInset(y) + 3, c.wood) end
  fill(image, 5, 9, width - 10, 2, c.woodLight)

  -- Cream rail wrapping a green, semicircular felt surface.
  for y = 1, 24 do row(image, y, surfaceInset(y), c.outline) end
  for y = 2, 22 do row(image, y, surfaceInset(y) + 1, c.rail) end
  for y = 4, 20 do row(image, y, surfaceInset(y) + 3, c.feltDark) end
  for y = 5, 18 do row(image, y, surfaceInset(y) + 4, c.felt) end
  fill(image, 7, 5, width - 14, 1, c.feltLight)

  if id == "blackjack" then
    for _, box in ipairs({ {20, 8}, {30, 8}, {25, 15}, {35, 15} }) do
      fill(image, box[1], box[2], 6, 5, c.rail)
      fill(image, box[1] + 1, box[2] + 1, 4, 3, c.felt)
    end
    fill(image, 51, 6, 7, 9, c.outline)
    fill(image, 50, 5, 7, 8, c.card)
    fill(image, 50, 11, 7, 2, c.red)
  else
    -- Five community-card boxes make the Hold'em table distinct at a glance.
    for x = 13, 45, 8 do
      fill(image, x, 7, 6, 8, c.outline)
      fill(image, x + 1, 8, 4, 6, c.card)
    end
    circle(image, 8, 12, 4, c.rail)
    circle(image, 8, 12, 2, c.feltDark)
  end
  for _, chip in ipairs(id == "blackjack"
      and { {10, 10}, {16, 18}, {46, 18} }
      or { {8, 19}, {53, 18}, {57, 11} }) do
    circle(image, chip[1], chip[2], 3, c.rail)
    circle(image, chip[1], chip[2], 2, c.red)
    pixel(image, chip[1], chip[2], c.card)
  end

  for piece = 0, 7 do
    local part = ctx.blank(16, 16, 0, 0, 0, 0)
    local column, line = piece % 4, math.floor(piece / 4)
    ctx.blit(part, image, 0, 0, column * 16, line * 16, 16, 16)
    ctx.writeImage(part, ("world/%s_table_%02d.png"):format(id, piece + 1))
  end
end

local function buildMachine(ctx, id, c)
  local image = ctx.blank(16, 32, 0, 0, 0, 0)
  fill(image, 1, 0, 14, 30, c.outline)
  fill(image, 2, 1, 12, 28, c.bodyDark)
  fill(image, 3, 2, 10, 26, c.body)
  fill(image, 2, 2, 12, 3, c.trim)
  fill(image, 3, 6, 10, 10, c.outline)
  fill(image, 4, 7, 8, 8, c.screen)

  if id == "crash" then
    pixel(image, 5, 13, c.green); pixel(image, 6, 12, c.green)
    pixel(image, 7, 11, c.green); pixel(image, 8, 9, c.green)
    pixel(image, 9, 8, c.green); pixel(image, 10, 8, c.red)
  elseif id == "flappy" then
    fill(image, 5, 7, 2, 3, c.green); fill(image, 5, 13, 2, 2, c.green)
    fill(image, 10, 7, 2, 5, c.green); fill(image, 10, 14, 2, 1, c.green)
    fill(image, 7, 10, 3, 2, c.trim); pixel(image, 9, 10, c.paper)
  elseif id == "horse" then
    fill(image, 4, 12, 7, 2, c.red); fill(image, 9, 10, 3, 3, c.red)
    fill(image, 5, 14, 2, 1, c.paper); fill(image, 9, 14, 2, 1, c.paper)
    fill(image, 4, 8, 8, 1, c.green)
  elseif id == "plinko" then
    for y = 8, 14, 2 do
      for x = 5 + ((y / 2) % 2), 11, 3 do pixel(image, x, y, c.paper) end
    end
    circle(image, 8, 7, 1, c.red)
  else
    for x = 4, 11, 3 do
      fill(image, x, 8, 2, 5, x == 10 and c.trim or c.paper)
    end
    fill(image, 4, 14, 8, 1, c.red)
  end

  fill(image, 4, 18, 8, 3, c.outline)
  fill(image, 5, 18, 3, 2, c.trim)
  circle(image, 10, 19, 1, c.red)
  fill(image, 3, 23, 10, 2, c.outline)
  fill(image, 5, 24, 6, 2, c.paper)
  fill(image, 2, 28, 12, 3, c.outline)

  for piece = 0, 1 do
    local part = ctx.blank(16, 16, 0, 0, 0, 0)
    ctx.blit(part, image, 0, 0, 0, piece * 16, 16, 16)
    ctx.writeImage(part, ("world/%s_machine_%02d.png"):format(id, piece + 1))
  end
end

local function buildRocketFurniture(ctx, c)
  local pieces = {}
  for piece = 1, 3 do pieces[piece] = ctx.blank(16, 16, 0, 0, 0, 0) end

  -- Surveillance terminal: a hideout-green monitor on a heavy purple desk.
  local monitor = pieces[1]
  fill(monitor, 1, 1, 14, 12, c.outline)
  fill(monitor, 2, 2, 12, 9, c.bodyDark)
  fill(monitor, 3, 3, 10, 6, c.screen)
  for _, point in ipairs({ { 5, 5 }, { 8, 4 }, { 10, 7 }, { 6, 7 } }) do
    pixel(monitor, point[1], point[2], c.green)
  end
  fill(monitor, 6, 10, 4, 2, c.trim)
  fill(monitor, 2, 13, 12, 2, c.body)

  -- Rocket filing cabinet with an unmistakable red R-like latch pattern.
  local cabinet = pieces[2]
  fill(cabinet, 2, 0, 12, 16, c.outline)
  fill(cabinet, 3, 1, 10, 14, c.body)
  for y = 2, 11, 5 do
    fill(cabinet, 4, y, 8, 4, c.bodyDark)
    fill(cabinet, 7, y + 1, 3, 1, c.paper)
  end
  fill(cabinet, 5, 12, 2, 2, c.red)
  fill(cabinet, 7, 12, 4, 1, c.red)
  pixel(cabinet, 9, 13, c.red)

  -- Reinforced contraband crate, low enough to read as furniture in-world.
  local crate = pieces[3]
  fill(crate, 1, 3, 14, 12, c.outline)
  fill(crate, 2, 4, 12, 10, c.bodyDark)
  fill(crate, 3, 5, 10, 8, c.body)
  fill(crate, 2, 7, 12, 2, c.trim)
  fill(crate, 7, 4, 2, 10, c.outline)
  fill(crate, 6, 8, 4, 3, c.red)
  fill(crate, 7, 9, 2, 1, c.paper)

  for piece, image in ipairs(pieces) do
    ctx.writeImage(image, ("world/rocket_furniture_%02d.png"):format(piece))
  end
end

return function(ctx)
  local shinyIndex = 0
  for stem in STEMS:gmatch("[^,]+") do
    shinyIndex = shinyIndex + 1
    local offset = (shinyIndex - 1) * 12 + 1
    local shades = {
      { 248, 248, 248 },
      { shinyByte(offset), shinyByte(offset + 2), shinyByte(offset + 4) },
      { shinyByte(offset + 6), shinyByte(offset + 8), shinyByte(offset + 10) },
      { 0, 0, 0 },
    }
    for _, source in ipairs({
      "battle/front/" .. stem .. ".png",
      "battle/back/" .. stem .. "b.png",
    }) do
      if ctx.exists(source) then
        ctx.writeImage(ctx.recolor(ctx.readImage(source), shades), "shiny/" .. source)
      end
    end
  end
  assert(shinyIndex == 151, "expected all 151 Gen I shiny palettes")
  buildTable(ctx, "blackjack", TABLE_COLORS)
  buildTable(ctx, "holdem", HOLDEM_COLORS)
  for _, id in ipairs({ "crash", "flappy", "case", "horse", "plinko" }) do
    buildMachine(ctx, id, MACHINE_COLORS)
  end
  buildRocketFurniture(ctx, MACHINE_COLORS)

  -- Three 16x16 pieces replace Oak's Poké Balls only in Gamble Mode.
  local roulette = ctx.blank(48, 16, 0, 0, 0, 0)
  fill(roulette, 0, 1, 48, 14, MACHINE_COLORS.outline)
  fill(roulette, 2, 3, 44, 10, MACHINE_COLORS.body)
  fill(roulette, 5, 5, 38, 6, MACHINE_COLORS.screen)
  for x = 8, 40, 8 do circle(roulette, x, 8, 3,
    x == 24 and MACHINE_COLORS.trim or MACHINE_COLORS.paper) end
  fill(roulette, 22, 2, 4, 12, MACHINE_COLORS.trim)
  for piece = 0, 2 do
    local part = ctx.blank(16, 16, 0, 0, 0, 0)
    ctx.blit(part, roulette, 0, 0, piece * 16, 0, 16, 16)
    ctx.writeImage(part, ("world/starter_roulette_%02d.png"):format(piece + 1))
  end
end
