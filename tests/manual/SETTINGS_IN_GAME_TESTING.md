# Blackjack Corner settings — in-game test plan

Run these checks on both Pokemon Red and Blue before the settings work is
included in a public release. Use a fresh identity for new-game checks and a
separate existing-save identity for compatibility checks.

## Options page

- [x] **SET-01** — `MODS > Blackjack Corner > OPTIONS` shows Gamble Default,
  Table Intros, Reveal Speed, Shiny Upgrades, and Reset Defaults.
- [x] **SET-02** — without an external shiny renderer, the four bundled shiny
  presentation rows follow the core rows and the list scrolls cleanly.
- [x] **SET-03** — with a supported external shiny renderer, the four core rows
  remain visible and no duplicate shiny-presentation controls appear.
- [x] **SET-04** — changing every row, restarting the game, and reopening the
  page preserves the selected values; Reset Defaults restores the documented
  defaults.

## New-game placement

- [x] **INTRO-01** — a new campaign shows the Gamble Mode question on a clean
  screen before Oak or his welcome text appears.
- [x] **INTRO-02** — Gamble Default `NO` preselects NO but still requires a
  confirmation; declining preserves the ordinary starter and Gym rewards.
- [x] **INTRO-03** — Gamble Default `YES` preselects YES but still requires a
  confirmation; accepting grants the Coin Case, 100 coins, and Oak's roulette.
- [x] **INTRO-04** — with Pokemon Randomizer enabled, its setup completes,
  Blackjack Corner asks before Oak, and both accepted configurations reach the
  overworld without skipping either setup.
- [x] **INTRO-05** — changing Gamble Default does not alter an existing save's
  stored Gamble Mode choice.

## Runtime behavior

- [x] **PLAY-01** — Table Intros `ON` shows the rules card before Blackjack;
  `OFF` opens the table directly. Missing-Coin-Case denial still appears.
- [x] **PLAY-02** — Table Intros `OFF` never skips the Underground Arena's
  invitation, ending-reactive, or exhibition dialogue.
- [x] **PLAY-03** — Relaxed, Normal, and Fast visibly change Prize Case,
  starter roulette, horse race, Plinko, and Arena pacing without changing the
  predetermined result or payout.
- [x] **PLAY-04** — Reveal Speed does not alter Crash growth or Tube Flyer
  physics/difficulty.
- [x] **PRIZE-01** — Shiny Upgrades `ON` offers NORMAL / SHINY / CANCEL;
  `OFF` offers NORMAL / CANCEL and ordinary purchase/delivery still works.

## Evidence

Record the host SHA, mod SHA, ROM SHA-1, external shiny/randomizer versions,
and screenshots of the core options page plus the pre-Oak prompt. Keep evidence
outside the repository so it cannot enter the release ZIP.

## Execution record

- Tester/date: Codex native LÖVE2D driver plus screenshot review, 2026-08-12.
- Host SHA: `6f75a64c461070b07af1f89ad97fcf2473694eb8`.
- Mod SHA: `acdfcd54acb6b55fecae14dc9ff9c5f4cf25b6c3`.
- ROM SHA-1s: Red `ea9bcae617fdf159b045185467ae58b2e4a48b9a`;
  Blue `d7037c83e1ae5b39bde3c30787637ba1d4c48ce2`.
- `settings_audit.lua` completed its seed/restart cycle on both ROMs. Red
  verified the YES default, Coin Case, 100-coin grant, and private starter
  roulette; Blue verified the NO default, restored Lab objects, native Misty
  badge/TM reward, and empty Gym Case queue. Both exercised the complete
  fallback page, Reset Defaults, table introductions, all three Arena story
  intros, and a real ordinary Pokemon purchase/delivery.
- Starter Roulette, paid Prize Case, Horse Racing, Plinko, and Battle Arena
  each ran to a real result under Relaxed, Normal, and Fast. Frame counts were
  strictly ordered while every seeded result and payout remained identical.
  Real Crash and Tube Flyer state snapshots remained byte-for-value identical
  across all three choices.
- The complete verify phase passed twice on the same Red and Blue identities,
  confirming that the two-phase driver restores its option preconditions and
  is repeatable.
- The compact external-provider page passed on both ROMs with Crystal Animated
  Sprites with Shiny Visuals 1.5.x. Its manifest range was adapted only in the
  disposable test harness because the pinned development host reports
  `0.0.0-dev`; the renderer source itself was unchanged.
- Pokemon Randomizer v0.46.4 completed its real new-game setup on both ROMs
  with Gamble Mode accepted and declined. Wild encounters and ordinary
  trainers remained randomized; the private starter roulette appeared only
  when Gamble Mode was accepted.
- External evidence: `/tmp/blackjack-settings-native/{red,blue}` plus the
  `*-external`, `*-randomizer`, and `*-randomizer-off` sibling directories.
