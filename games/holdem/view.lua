-- Pixel-native house-banked Texas Hold'em presentation for the 160x144 canvas.
local View = {}

local C = {
  ink = { 0.08, 0.07, 0.10 },
  felt = { 0.035, 0.20, 0.27 },
  feltDark = { 0.02, 0.10, 0.16 },
  feltLight = { 0.07, 0.33, 0.40 },
  gold = { 0.94, 0.67, 0.18 },
  goldDark = { 0.40, 0.22, 0.06 },
  cream = { 1.00, 0.94, 0.70 },
  paper = { 0.94, 0.88, 0.67 },
  red = { 0.66, 0.10, 0.17 },
  disabled = { 0.30, 0.39, 0.43 },
}

local function color(value, alpha)
  love.graphics.setColor(value[1], value[2], value[3], alpha or 1)
end

local function rect(mode, x, y, w, h)
  love.graphics.rectangle(mode, math.floor(x), math.floor(y), w, h)
end

local function centered(Font, text, y)
  Font.draw(text, math.floor((160 - Font.width(text)) / 2), y)
end

local function centeredGlyph(CardView, text, y, shade, scale)
  scale = scale or 1
  CardView.glyph(text,
    math.floor((160 - CardView.glyphWidth(text, scale)) / 2), y, shade, scale)
end

local function tableSurface()
  color(C.goldDark); rect("fill", 0, 0, 160, 144)
  color(C.gold); rect("fill", 0, 2, 160, 3); rect("fill", 0, 139, 160, 3)
  color(C.feltDark); rect("fill", 3, 5, 154, 134)
  color(C.felt); rect("fill", 6, 7, 148, 129)
  color(C.feltLight, 0.35)
  for y = 9, 133, 8 do
    for x = 8 + (y % 16 == 9 and 0 or 4), 150, 8 do rect("fill", x, y, 1, 1) end
  end
  color(C.goldDark); rect("line", 8, 8, 144, 126)
end

local function chip(x, y, active)
  color(C.ink, 0.55); love.graphics.circle("fill", x + 1, y + 2, active and 12 or 10)
  color(active and C.gold or C.paper); love.graphics.circle("fill", x, y, active and 12 or 10)
  color(active and C.red or C.goldDark); love.graphics.circle("fill", x, y, active and 9 or 7)
  color(C.cream); love.graphics.circle("line", x, y, active and 7 or 5)
  for angle = 0, 7 do
    local radians = angle * math.pi / 4
    local radius = active and 10 or 8
    rect("fill", x + math.floor(math.cos(radians) * radius),
      y + math.floor(math.sin(radians) * radius), 2, 2)
  end
end

local function button(Font, x, y, width, label, selected, enabled)
  local fill = enabled and (selected and C.gold or C.paper) or C.disabled
  color(C.ink, 0.6); rect("fill", x + 1, y + 1, width, 15)
  color(fill); rect("fill", x, y, width, 14)
  color(selected and C.cream or C.goldDark); rect("line", x, y, width, 14)
  color(enabled and C.ink or C.feltDark)
  Font.draw(label, x + math.floor((width - Font.width(label)) / 2), y + 3)
end

local function cardSlot(x, y, visible)
  color(visible and C.gold or C.feltLight, visible and 0.8 or 0.45)
  rect("line", x + 1, y + 1, 18, 27)
  if not visible then
    rect("fill", x + 8, y + 12, 4, 5)
    color(C.felt); rect("fill", x + 9, y + 13, 2, 3)
  end
end

local function drawCards(CardView, cards, xs, y, hidden)
  for i, x in ipairs(xs) do
    local card = cards and cards[i]
    if card then CardView.drawCard(card, x, y, hidden, false) else cardSlot(x, y, false) end
  end
end

local function drawBetScreen(state, Font, CardView, stakes, coinCount)
  local stake = stakes[state.betIndex]
  centeredGlyph(CardView, "CHOOSE BET", 31, C.cream, 2)
  local xs = { 24, 61, 99, 136 }
  for i, stake in ipairs(stakes) do
    chip(xs[i], 64, i == state.betIndex)
    local label = tostring(stake)
    CardView.glyph(label,
      xs[i] - math.floor(CardView.glyphWidth(label, 2) / 2), 79,
      i == state.betIndex and C.gold or C.paper, 2)
  end
  if state.notice then
    centeredGlyph(CardView, state.notice, 99, C.cream, 2)
  end
  button(Font, 16, 112, 88, "DEAL " .. stake, true,
    coinCount >= stake)
  CardView.glyph("B EXIT", 118, 116, C.paper)
end

local function resultText(round)
  if round.result == "win" then return "YOU WIN" end
  if round.result == "push" then return "PUSH" end
  return "HOUSE WINS"
end

function View.draw(state, Font, Rules, CardView, coinCount, stakes)
  tableSurface()
  CardView.glyph("HOLD EM", 8, 8, C.cream, 2)
  local coinLabel = "COINS " .. tostring(coinCount)
  CardView.glyph(coinLabel, 152 - CardView.glyphWidth(coinLabel), 10, C.gold)

  if state.phase == "bet" then
    drawBetScreen(state, Font, CardView, stakes, coinCount)
    love.graphics.setColor(1, 1, 1, 1)
    return
  end

  local round = state.round
  local done = round.state == "done"
  CardView.glyph("HOUSE", 8, 27, C.paper)
  drawCards(CardView, round.dealer, { 54, 78 }, 17, not done)

  drawCards(CardView, round.board, { 24, 47, 70, 93, 116 }, 47, false)
  CardView.glyph("YOU", 8, 91, C.paper)
  drawCards(CardView, round.player, { 54, 78 }, 78, false)

  if state.phase == "result" then
    local stake = Rules.totalStake(round)
    local delta = round.payout - stake
    local deltaText = tostring(delta)
    color(C.gold); rect("fill", 12, 110, 136, 22)
    color(C.ink); centered(Font, resultText(round) .. "  " .. deltaText, 113)
    local detail = round.playerEval and round.playerEval.name or "NO SHOWDOWN"
    centered(Font, detail, 122)
    centeredGlyph(CardView, "A AGAIN   B EXIT", 134, C.paper)
  else
    local info = ("START %d  BETS %d"):format(round.start, round.play)
    centeredGlyph(CardView, info, 108, C.paper)
    local actions = state.actions or {}
    local gap = 3
    local width = math.floor((154 - gap * (#actions - 1)) / math.max(1, #actions))
    for i, action in ipairs(actions) do
      button(Font, 3 + (i - 1) * (width + gap), 119, width, action.label,
        state.actionIndex == i, action.enabled ~= false)
    end
    if state.notice then
      centeredGlyph(CardView, state.notice, 134, C.cream)
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return View
