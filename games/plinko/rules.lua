-- Pure path and payout rules for an eight-row Plinko board.
local Plinko = {}

Plinko.BETS = { 10, 50, 100, 500 }
Plinko.ROWS = 8
Plinko.DURATION = 3.2
Plinko.MULTIPLIERS_X100 = { 900, 350, 150, 65, 20, 65, 150, 350, 900 }

function Plinko.new(random)
  random = random or function(maximum) return math.random(maximum) end
  local path, rights = {}, 0
  for row = 1, Plinko.ROWS do
    local right = random(2) == 2
    path[row] = right and 1 or -1
    if right then rights = rights + 1 end
  end
  return { path = path, slot = rights + 1, elapsed = 0 }
end

function Plinko.update(drop, dt)
  drop.elapsed = math.min(Plinko.DURATION, (drop.elapsed or 0) + math.max(0, dt or 0))
  return drop.elapsed >= Plinko.DURATION
end

function Plinko.ball(drop)
  local progress = math.max(0, math.min(1, (drop.elapsed or 0) / Plinko.DURATION))
  local exact = progress * Plinko.ROWS
  local row = math.min(Plinko.ROWS, math.floor(exact))
  local fraction = exact - row
  local offset = 0
  for index = 1, row do offset = offset + drop.path[index] end
  if row < Plinko.ROWS then offset = offset + drop.path[row + 1] * fraction end
  return row + fraction, offset
end

function Plinko.payout(bet, slot)
  local x100 = Plinko.MULTIPLIERS_X100[slot] or 0
  return math.floor(math.max(0, tonumber(bet) or 0) * x100 / 100)
end

return Plinko
