-- Native-scale visual regression for the shared Blackjack/Hold'em card art.
return function(game)
  local U = dofile("tests/drivers/util.lua")
  local shotDir = assert(os.getenv("SHOT_DIR"), "SHOT_DIR is required")
  local loader = assert(game.mods)
  local View = assert(loader.exports.blackjack_corner.view)
  local C = View.colors
  local suits, xs = { "H", "D", "C", "S" }, { 10, 50, 90, 130 }

  local function centered(text, y, color)
    View.glyph(text, math.floor((160 - View.glyphWidth(text)) / 2), y, color)
  end

  local screen = { isOpaque = true }
  function screen:sgbPalettes()
    return { require("src.render.PaletteFX").trueColorZone(0, 0, 19, 17) }
  end
  function screen:draw()
    love.graphics.clear(C.feltDark[1], C.feltDark[2], C.feltDark[3], 1)
    centered("ACE SUITS", 4, C.gold)
    for index, suit in ipairs(suits) do
      View.drawCard({ rank = "A", suit = suit }, xs[index], 13, false, false)
    end
    centered("TEN SUITS", 49, C.gold)
    for index, suit in ipairs(suits) do
      View.drawCard({ rank = "10", suit = suit }, xs[index], 58, false, false)
    end
    centered("C CLUB   S SPADE", 96, C.paper)
    centered("THREE LOBES  ONE POINT", 108, C.paperShade)
    love.graphics.setColor(1, 1, 1, 1)
  end

  game.stack:push(screen)
  U.wait(30)
  assert(U.shot(game, shotDir .. "/card-suit-comparison.png"))
  U.log("CARD SUIT AUDIT COMPLETE")
  while true do coroutine.yield() end
end
