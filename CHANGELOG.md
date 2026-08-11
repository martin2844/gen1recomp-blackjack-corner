# Changelog

## Unreleased

## [0.5.2] - 2026-08-11

### Changed

- The Celadon Rocket broker now offers `PAWN HOUSE` at any money or casino
  balance, provided the Coin Case has room for the complete payout.
- Pawning the Pallet family home adds 10,000 coins to the current balance
  instead of replacing it. The one-use transfer, 30,000-coin buyback, Rocket
  battle, and house restoration remain unchanged.
- Confirmation and manual-testing copy now describe the transaction directly;
  the previous service names remain as compatibility aliases and existing save
  fields migrate without a rewrite.

### Fixed

- Custom Coin Case caps below 10,000 now refuse the house transaction rather
  than silently exceeding the configured limit.

## [0.5.1] - 2026-08-11

### Changed

- Replaced the hand-authored Arena lift, VIP furniture atlas, and overworld pit
  with a native Rocket status terminal, a persistent walkable staircase, and
  two underground floors built entirely from the imported `LOBBY` and `GYM`
  tilesets.
- Rebuilt B1 around permanent Rocket staff, native counters, roulette tables,
  cabinet banks, six playable original slot-machine seats, and palette cycling
  through Recomp's normal key-`2` control.
- Rebuilt B2 as Rocket's illicit fifth League chamber, with solid spectator
  islands, native statues, a real B1/B2 door, and the Elite Four's short
  entrance walk.
- Redesigned the High Roller status screen with fixed columns, abbreviated
  late-game values, clearer progress and badge requirements, and a dedicated
  favorite-game or banked-reward row.
- Arena controls now use the original game's triangle glyphs: up/down select a
  fighter and left/right change the wager.
- Refined Blackjack and Hold'em card art with distinct club and spade
  silhouettes, conventional inverted lower pips, and denser ten-card layouts.

### Fixed

- The complete Lounge-to-B1-to-B2 route now uses physical warps and valid
  collision, preventing double transitions, basement exit loops, floating
  patrons, and trapped return tiles.
- Arena staff no longer remove or modify the player's party. Saves created by
  the retired development check-in mechanic still recover an exact held party
  once without overwriting a live team.
- A v0.5.0 save already inside B1 or B2 now marks the replacement staircase as
  revealed before returning upstairs, preventing the player from landing
  inside the closed status terminal.
- Static staff and spectator dialogue now consistently describe house-owned
  fighters instead of the retired party-custody mechanic.
- Release packaging excludes every new native QA driver, including the card
  suit visual audit.

## [0.5.0] - 2026-08-10

### Added

- A concealed lift in the expanded Celadon Lounge for Gamble Mode players who
  earn KINGPIN at 4,000 reputation with all eight badges.
- A separate Rocket VIP lobby and underground spectator arena with a bookie,
  animated crowd, dedicated exits, original dialogue, and a locally generated
  eight-piece battle pit.
- House-owned Pokemon battle betting with posted decimal odds derived from
  imported species stats, levels, curated moves, accuracy, STAB, Gen I type
  matchups, and the original physical/special split.
- STREET, ELITE, and RARE fighter tiers driven by arena reputation, progressing
  from ordinary opponents to Lapras, Snorlax, Aerodactyl, Gyarados, Dragonite,
  and Alakazam.
- Persistent arena tickets that commit fighters, odds, outcome, animation,
  wager, and High Roller round before a fight; reload and repeated settlement
  cannot reroll a loss or duplicate coins and reputation.
- A purpose-built native-resolution fight board with sprites, HP bars, attack
  lunges, misses, immunities, damage callouts, crowd reactions, and readable
  win/loss results.
- A Red/Blue manual Arena gate and deterministic 35-case native driver,
  covering access, navigation, wagers, odds, persistence, results, defaults,
  fighter tiers, schema migration, and existing casino regressions.
- A one-time last-resort bailout for Gamble Mode saves with exactly zero money
  and zero coins. It grants 10,000 coins in exchange for the Pallet family
  home, with the full consequence and 30,000-coin recovery cost confirmed
  before anything changes.
- A persistent Rocket occupation of Red's house: Mom moves upstairs without
  losing her healing service, Rocket tenants discuss the deed and Oak
  surveillance, and authentic Rocket Hideout/Silph Co equipment is derived at
  install time from the player's imported game to change the downstairs
  atmosphere without shipping ROM pixels.
- A recoverable family-home quest. Paying the 30,000-coin deed price reveals a
  retryable Rocket trainer battle; winning restores the original home and Mom
  while preserving any separate credit debt or default.
- Dedicated supervised drivers for the bailout, occupied home, and house
  battle, plus a full Red/Blue in-game test plan covering navigation,
  dialogue, economy boundaries, battle loss, save/reload, and restoration.
- A visible Rocket Credit loan shark in the Celadon
  Lounge with rank-based offers, fixed fees, and one active loan at a time.
- Repayment using either casino coins or ordinary money, with fees paid before
  principal and every default remaining fully recoverable.
- Badge-milestone deadlines and one-time late fees. Debt never grows with
  real time, repeated menu opens, or repeated milestone checks.
- A voluntary `PAWN & PAY` route at the Rocket broker. The appraisal pays the
  live debt first, any surplus remains in the Coin Case, and the exact Pokemon
  stays on the existing redeemable pawn ticket.
- Recoverable Rocket collector appearances in Pallet and Celadon after a
  default, with dialogue directing the player back to the loan shark.
- Default-only luxury restrictions for new paid Prize Cases and Celadon's
  Pokemon/item counters. Casino games, travel, healing, story progress, coin
  sales, ordinary pawning, and redemption remain available.
- Ordered save migrations that carry legacy campaign, debt, family-home, and
  Arena state forward without discarding future-owned fields.
- A schema-versioned persistent Gamble Mode campaign
  state with additive placeholders for reputation, debt, house ownership, and
  the underground arena.
- Shared High Roller reputation across Blackjack, Hold'em, Crash, Tube Flyer,
  Prize Case, Horse Racing, Plinko, and the Arena, including lifetime wager
  and per-game win/loss/draw statistics.
- Rookie, Regular, High Roller, VIP, and KINGPIN progression with badge
  ceilings, banked reputation, and one-time coin rewards.
- A native-resolution High Roller status panel in the Start menu with rank,
  progress, badge requirements, aggregate results, lifetime wagers, losing
  streaks, and one-time rank-up presentations.
- Rank- and losing-streak-aware dialogue for patrons and staff in both casino
  destinations.
- A supervised manual QA framework with isolated LÖVE identities, scripted
  save setup, screenshots, explicit keyboard handoff, a Red/Blue test matrix,
  and a v0.5 release checklist.

### Fixed

- Arena results now use the same matchup probability as the posted odds, so
  the advertised house margin survives real outcomes instead of making
  favorites a reliable coin farm.
- KINGPIN now retains top-tier Rocket Credit and casino dialogue, and a rank
  unlocked at the Lounge lift is presented before the lift descends.
- The native odds gate now uses a deterministic sample and requires both
  favorite and underdog wins; bookie reopen checks use the real interaction.
- Local mod packages now exclude tests, native drivers, release evidence, and
  screenshot galleries just like the GitHub release archive.
- Pull requests and releases now run ROM-free validation, lint, the complete
  Lua suite, and a release-shaped package check before publication.
- Casino payout credit now has one shared cap-aware path, so Blackjack and
  Hold'em statistics report only coins actually delivered near the 1M limit.
- Non-resumable game screens now use transient reputation rounds and veto F1
  saves while a wager is live, preventing interrupted rounds from losing a bet
  or leaking orphaned pending tokens into campaign saves.
- Game Corner object IDs now allocate through shared world helpers, preventing
  patrons from aliasing objects added by earlier content mods.
- Luxury authorization synchronizes badge deadlines before admitting the
  player, so a newly defaulted Rocket loan cannot use prizes or Arena wagers.
- Paid Prize Case claims now persist until delivery, so full storage cannot
  refund the wager while retaining free reputation; retries keep the exact
  reward and never charge or settle twice.
- Rank rewards that do not fit in the Coin Case remain banked and are delivered
  automatically when space becomes available.
- Per-game discovery bonuses now reset once per rank, Crash treats a 1.00x
  cashout as a draw, and real game results carry rank-ups into acknowledgement.
- Campaign sanitation now rejects invalid ranks and preserves unknown future
  top-level and nested fields instead of destructively downgrading saves.
- Every paid game now uses a persistent round token so retries and repeated
  result callbacks cannot award reputation twice.
- Progressive Blackjack and Hold'em bets add to the same campaign wager rather
  than looking like separate rounds.
- Paid Prize Cases settle reputation when the immutable reel prize is chosen;
  delivery retries and Gym Cases cannot duplicate or incorrectly earn it.
- Reputation banked behind a badge ceiling now ranks up immediately when a
  newly earned badge removes that ceiling.
- Native 160x144 review caught and removed clipped High Roller goal copy and
  an unsupported plus glyph from the rank-up presentation.

## [0.4.1] - 2026-08-10

### Changed

- The built-in shiny fallback now derives canonical Pokemon Crystal palettes
  for all 151 Generation I species from the player's imported sprite cache.
- Dedicated shiny mods load first and retain complete control. Blackjack
  Corner only activates its bundled Gen II indicator when no supported shiny
  provider is installed.
- The fallback adds configurable entrance sparkles, a synthesized chime,
  battle markers, and a Crystal-style status-screen icon.

### Fixed

- Shiny Pokemon no longer appear with a tiny black dot where the old
  white-on-white battle sparkle left only its center outline visible.

## [0.4.0] - 2026-08-09

### Changed

- Gym Case TM weights are rebalanced for variety. The current leader's TM is
  still featured, but Brock's Bide chance falls from roughly 43% to 15%.
- The starter roulette now pauses on each roll and lets the player either keep
  that Pokemon or spend ¥1,000 for another spin. The Pokemon is not awarded
  until KEEP is confirmed, and unaffordable rerolls are visibly disabled.
- Gamble Mode rewrites Oak's complete laboratory introduction: he no longer
  mentions three Pokemon, treats choosing as boring, and enthusiastically
  encourages both the player and rival to gamble for their starters.
- The Celadon Casino Lounge now spans 20x18 walk cells. Its original tables
  and three cabinets remain up front, while Horse Racing and Plinko anchor a
  new rear arcade with redistributed patrons and hidden coins.
- Pallet Casino now spans 20x18 walk cells and adds dedicated blackjack and
  Texas Hold'em tables, so five casino games are playable from Pallet.
- All eight Gym Leaders now introduce their Gamble Mode case rewards in their
  own voices before the reel opens, replacing the original direct-TM pitch.

### Fixed

- The starter confirmation screen now keeps its result text and CONTINUE
  button fully inside the visible Game Boy frame.
- Pallet Casino now has a dry, walkable landing between its door and the
  original pond, making the exterior warp reachable without Surf.
- Pallet Casino's complete pond bank now sits one block farther south, giving
  the entrance a clean two-block forecourt and a continuous bordered shoreline.
- Gym reward dialogue now finishes over the visible leader and Gym before the
  opaque Gym Case opens, instead of rendering the text box on top of the reel.

## [0.3.0] - 2026-08-08

### Added

- An optional, save-scoped **Gamble Mode** choice during Professor Oak's new
  game introduction. Declining it preserves the ordinary starter and Gym TM
  progression.
- A 100-coin opening stake and permanent Coin Case when Gamble Mode begins.
- A starter roulette in Oak's Lab that replaces the three gift balls, draws
  from all valid base-stage non-legendary species, and gives the rival a
  separate random starter whose evolution tracks later battle levels.
- Eight persistent Gym Cases. Every Gym Leader still awards their badge, but
  their direct TM becomes a one-prize animated case containing unlocked Gym
  TMs or increasingly valuable Pokemon.
- Failed Gym Case delivery remains claimable from the Start menu instead of
  losing the selected reward when the Bag or Pokemon storage is full.
- A dedicated Pallet Town mini-casino with a new exterior, reciprocal indoor
  warp, horse-racing terminal, Plinko board, Prize Case machine, bulk coin
  clerk, and Pokemon pawn broker.
- Animated four-runner horse racing with distinct win probabilities, posted
  2x/3x/5x/8x payouts, 10/50/100/500-coin wagers, visible lead changes, and
  genuine losing tickets.
- An animated eight-row Plinko game with 256 possible paths, nine payout
  buckets from 0.20x to 9.00x, four wager sizes, and a 4.375% house edge.
- Ten new gamblers, debtors, dreamers, and casino workers spread across the
  Game Corner, Casino Lounge, and Pallet Casino, each with original dialogue.
- Eight additional one-time hidden coin pickups across all three casino
  floors.
- New generated world sprites for horse racing, Plinko, and Oak's three-piece
  starter roulette cabinet.
- Integration coverage for Oak's mode prompt, starting economy, lab art, and
  a complete Gym Leader reward replacement path.

### Changed

- The mod now expands the full adventure when Gamble Mode is enabled rather
  than operating only as a Celadon destination.
- Oak explicitly explains that there is no starter choice, and the rival
  acknowledges their own independent spin.
- Existing saves and new games that decline Gamble Mode retain vanilla story
  progression while still having access to the Celadon casino expansion.
- The automated suite now covers 506 assertions across game rules, UI,
  services, maps, saves, and engine integration.

### Fixed

- Yellow's single starter-ball layout now uses the center roulette cabinet
  piece instead of the left edge.
- Gamble Mode uses a version-neutral Oak's Lab rival exit, preventing Yellow's
  Pikachu-only cry and disobedience scene from playing for a random starter.
- Level-5 Magikarp and Abra rolls receive Tackle or Confusion respectively, so
  their missing damaging moves cannot trap a new save before Poké Balls exist.
- A failed zero-cost Gym Case claim no longer displays a misleading coin
  refund; it clearly reports that the exact claim was saved.
- The starter roulette header no longer renders an empty Coin Case counter.
- Returning to the title and declining Gamble Mode now restores Oak's ordinary
  gift-ball sprites instead of leaking roulette art from the previous save.
- Disabling the mod now makes its engine-level Gym reward wrapper fall through
  cleanly to the original reward path.
- Long roulette species names and maximum Plinko payouts now fit inside their
  pixel cards and result panel without clipping.

## [0.2.0] - 2026-08-07

### Added

- A 1,000,000-coin Coin Case limit across the mod's purchases, wagers, payouts,
  prize refunds, and pawn transactions.
- Compatibility for the original slot machines, including high-balance-safe
  payouts and a compact four-character credit counter up to `1.0M`.
- House-banked Texas Hold'em with real best-five-of-seven hand evaluation.
- Progressive Play wagering across all three streets: check or bet 3x/4x
  before the flop, continue with 2x after the flop, then check or bet 1x at
  the river.
- One clear starting bet, standard best-hand comparison against the house,
  and 1:1 payouts across all committed wagers.
- A dedicated blue-felt Hold'em screen with hole cards, five community cards,
  staged controls, showdown hands, and net results.
- A second dealer and interactive poker table in the casino lounge.
- A shady Pokemon pawn broker at the original Game Corner counter.
- Stat-, level-, and rarity-based appraisals paid in Game Corner coins, with
  exact Pokemon restoration for a 30% redemption premium.
- Five persistent pawn slots with an explicit first-pawned-first-sold warning
  when adding a sixth Pokemon.
- Safe party/PC redemption and protections for the final party member, full
  Coin Cases, and full Pokemon storage.
- Three generated center-lounge arcade cabinets with separate Crash, Tube
  Flyer, and Prize Case screens.
- A wager-and-cash-out Crash game with a hidden house-edged crash point,
  continuously rising multiplier, four wager sizes, and persistent records.
- A 10-coin flying game with deterministic tube physics, immediate one-coin
  payouts per passed tube, best scores, and safe Coin Case limits.
- A 500-coin case-opening reel with rarity colors, a premium Pokemon roster,
  rare items and TMs, and a roughly 0.1% Master Ball chance.
- Transactional case rewards that use party/PC delivery and refund the full
  opening price if the selected reward cannot be stored.

### Improved

- Replaced low-tier Prize Case Pokemon with starters, fossils, Dragonite,
  Mew, and a special Pikachu that arrives knowing Surf.
- Styled the Master Ball reel card as a gold-and-black jackpot and slowed the
  case reel and Crash multiplier growth for clearer decision timing.
- Refactored the runtime into per-game `games/` modules and supporting
  `other/` services, reducing `main.lua` to composition and registration.
- Rebuilt all three arcade screens around bright, machine-specific Game Boy
  palettes so the engine's black tile font remains legible in every state.
- Crash now presents all four wagers at once with a clear selection, a visual
  launch preview, and a light graph surface.
- Tube Flyer gained readable top-HUD scoring, capped pipe openings, a clearer
  bird silhouette, and a compact result ribbon that preserves the playfield.
- Prize Case gained icon-led reel cards, shorter readable reel labels, stronger
  winner markers, and compact opening/result panels without a dark backdrop.
- Expanded the lounge from 14x10 to 20x12 walk cells for two distinct games,
  more breathing room, and a central circulation aisle.
- Reduced both overworld tables from five to four tiles wide and gave each
  game its own locally generated table art.
- Added concise in-world guidance for progressive Hold'em decisions and
  standard best-hand payouts.
- Verify each wager independently, so a player with exactly one starting bet
  can check every street and still reach showdown.
- Early bets now reveal only the next street instead of skipping directly to
  showdown, and unaffordable bets never block the free Check action.
- Removed the Ultimate Hold'em Ante, Blind, bonus-paytable, and dealer-
  qualification rules that conflicted with the multi-street game.

### Fixed

- Original slot payouts now cross the old 9,999-coin boundary instead of
  silently losing the next payout coin.
- Hidden Game Corner coin pickups preserve five- and six-digit balances
  instead of clamping them back to 9,999.
- Prize Case reel positioning and winner highlighting now share the same
  configured winning-card index.

## [0.1.0] - 2026-08-06

### Added

- Playable blackjack using the existing Game Corner coin balance.
- Pixel-drawn cards, chips, casino table, action states, and round feedback.
- Expanded Red- and Blue-aware Pokemon prize catalogues.
- Persistent shiny upgrades with locally derived gold battle art.
- Rare item prizes and a one-time 9,999-coin Master Ball redemption.
- Larger 50, 250, 500, 1,000, and capacity-aware MAX coin purchases.
- Red-, Blue-, and Yellow-aware prize catalogues with starters, fossils, and
  opposite-version species.
- Safe party/PC delivery and failure handling that never charges for a prize
  the player cannot receive.

### Improved

- Removed level suffixes from Pokemon prize rows so long names no longer
  collide with their prices.
- Failed prize purchases now return to the catalogue instead of closing it.
- Replaced the borrowed octagonal dining table with a wide, green semicircular
  blackjack table, centered dealer, betting marks, chips, deck, and a fully
  interactive front edge.
- Moved the table into a dedicated Blackjack Lounge with its own double-door,
  spectators, open circulation space, and reciprocal Game Corner warps.
- Expanded the coin clerk with 50, 250, 500, 1,000, and capacity-aware MAX
  purchases at the original exchange rate.
- Card pips, court cards, silhouettes, and color rendering were rebuilt for the
  real 160x144 game pipeline.
