-- Pure odds and animation state for the four-runner video horse race.
local Race = {}

Race.BETS = { 10, 50, 100, 500 }
Race.DURATION = 6
Race.HORSES = {
  { name = "COMET", weight = 42, payout = 2, color = "red" },
  { name = "LUCKY", weight = 28, payout = 3, color = "green" },
  { name = "DUSK", weight = 18, payout = 5, color = "purple" },
  { name = "GHOST", weight = 12, payout = 8, color = "blue" },
}

function Race.chooseWinner(random)
  local total = 0
  for _, horse in ipairs(Race.HORSES) do total = total + horse.weight end
  local roll = random and random(total) or math.random(total)
  roll = math.max(1, math.min(total, math.floor(roll)))
  for index, horse in ipairs(Race.HORSES) do
    roll = roll - horse.weight
    if roll <= 0 then return index end
  end
  return #Race.HORSES
end

function Race.new(random)
  random = random or function(maximum) return math.random(maximum) end
  local winner = Race.chooseWinner(random)
  local finish = {}
  for index = 1, #Race.HORSES do
    finish[index] = index == winner and 1 or (78 + random(18)) / 100
  end
  return { winner = winner, finish = finish, elapsed = 0 }
end

function Race.positions(race)
  local progress = math.max(0, math.min(1, (race.elapsed or 0) / Race.DURATION))
  local eased = progress * progress * (3 - 2 * progress)
  local positions = {}
  for index, target in ipairs(race.finish) do
    local surge = math.sin(progress * 18 + index * 1.7) * (1 - progress) * 0.025
    positions[index] = math.max(0, math.min(target, eased * target + surge))
  end
  if progress >= 1 then positions[race.winner] = 1 end
  return positions
end

function Race.update(race, dt)
  race.elapsed = math.min(Race.DURATION, (race.elapsed or 0) + math.max(0, dt or 0))
  return race.elapsed >= Race.DURATION
end

function Race.payout(bet, selected, winner)
  if selected ~= winner then return 0 end
  return math.floor(math.max(0, tonumber(bet) or 0) * Race.HORSES[winner].payout)
end

return Race
