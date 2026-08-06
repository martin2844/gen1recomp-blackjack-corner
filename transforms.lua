-- Generate per-instance shiny art from the player's imported cache. The mod
-- ships this recipe, never ROM-derived pixels.
local SPECIES = {
  "abra", "kadabra", "alakazam", "clefairy", "wigglytuff", "nidorina", "nidoqueen",
  "nidorino", "nidoking", "dratini", "dragonair", "dragonite", "porygon",
  "bulbasaur", "ivysaur", "venusaur", "charmander", "charmeleon", "charizard",
  "squirtle", "wartortle", "blastoise", "omanyte", "omastar", "kabuto",
  "kabutops", "aerodactyl", "sandshrew", "sandslash", "vulpix", "ninetales",
  "meowth", "persian", "bellsprout", "weepinbell", "victreebel", "pinsir",
  "magmar", "ekans", "arbok", "oddish", "gloom", "vileplume", "mankey",
  "primeape", "growlithe", "arcanine", "scyther", "electabuzz",
}

local GOLD = {
  { 248, 248, 224 },
  { 248, 216, 88 },
  { 208, 120, 32 },
  { 64, 32, 64 },
}

-- Build a ROM-clean 80x32 overworld table from authored pixels, then slice
-- it into ten ordinary 16x16 overworld sprites. Keeping each cell separate
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
  fill(image, inset, y, 80 - inset * 2, 1, c)
end

local function bodyInset(y)
  if y <= 18 then return 0 end
  return math.min(15, math.floor((y - 18) * 1.35))
end

local function surfaceInset(y)
  if y <= 14 then return 1 end
  return math.min(18, 1 + (y - 14) * 2)
end

local function circle(image, cx, cy, radius, c)
  for y = -radius, radius do
    for x = -radius, radius do
      if x * x + y * y <= radius * radius then pixel(image, cx + x, cy + y, c) end
    end
  end
end

local function buildTable(ctx)
  local c = TABLE_COLORS
  local image = ctx.blank(80, 32, 0, 0, 0, 0)

  -- Deep wooden cabinet and its curved front apron.
  for y = 5, 30 do row(image, y, bodyInset(y), c.outline) end
  for y = 7, 28 do row(image, y, bodyInset(y) + 2, c.woodDark) end
  for y = 8, 25 do row(image, y, bodyInset(y) + 3, c.wood) end
  fill(image, 5, 9, 70, 2, c.woodLight)

  -- Cream rail wrapping a green, semicircular felt surface.
  for y = 1, 24 do row(image, y, surfaceInset(y), c.outline) end
  for y = 2, 22 do row(image, y, surfaceInset(y) + 1, c.rail) end
  for y = 4, 20 do row(image, y, surfaceInset(y) + 3, c.feltDark) end
  for y = 5, 18 do row(image, y, surfaceInset(y) + 4, c.felt) end
  fill(image, 7, 5, 66, 1, c.feltLight)

  -- Betting boxes, deck, and three chip stacks make the purpose legible
  -- before the player ever opens the minigame.
  for _, box in ipairs({ {29, 8}, {39, 8}, {34, 15}, {44, 15} }) do
    fill(image, box[1], box[2], 6, 5, c.rail)
    fill(image, box[1] + 1, box[2] + 1, 4, 3, c.felt)
  end
  fill(image, 64, 6, 7, 9, c.outline)
  fill(image, 63, 5, 7, 8, c.card)
  fill(image, 63, 11, 7, 2, c.red)
  for _, chip in ipairs({ {15, 10}, {24, 18}, {56, 18} }) do
    circle(image, chip[1], chip[2], 3, c.rail)
    circle(image, chip[1], chip[2], 2, c.red)
    pixel(image, chip[1], chip[2], c.card)
  end

  for piece = 0, 9 do
    local part = ctx.blank(16, 16, 0, 0, 0, 0)
    local column, line = piece % 5, math.floor(piece / 5)
    ctx.blit(part, image, 0, 0, column * 16, line * 16, 16, 16)
    ctx.writeImage(part, ("world/table_%02d.png"):format(piece + 1))
  end
end

return function(ctx)
  for _, species in ipairs(SPECIES) do
    local paths = {
      "battle/front/" .. species .. ".png",
      "battle/back/" .. species .. "b.png",
    }
    for _, source in ipairs(paths) do
      if ctx.exists(source) then
        ctx.writeImage(ctx.recolor(ctx.readImage(source), GOLD), "shiny/" .. source)
      end
    end
  end
  buildTable(ctx)
end
