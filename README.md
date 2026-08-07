# Blackjack Corner

[![Latest release](https://img.shields.io/github/v/release/martin2844/gen1recomp-blackjack-corner)](https://github.com/martin2844/gen1recomp-blackjack-corner/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Blackjack Corner turns Celadon Game Corner into a larger casino destination
for the [Pokemon Gen 1 Recompilation Project](https://github.com/bryanthaboi/gen1recomp).
It adds a larger two-table casino lounge, full pixel-art blackjack and
house-banked Texas Hold'em, larger coin exchanges, expanded version-aware
Pokemon prizes, a shady Pokemon pawn broker, persistent shiny upgrades, rare
items, a one-time Master Ball, and three original arcade machines.

The mod supports Pokemon Red, Blue, and Yellow. It contains no ROM or
ROM-derived artwork; world and shiny graphics are generated locally from the
player's imported game data.

## Version 0.2 highlights

| Area | What the release adds |
| --- | --- |
| Casino | A dedicated 20x12 lounge with separate blackjack and Hold'em tables plus three center-floor arcade cabinets |
| Table games | Blackjack with 3:2 naturals and a house-banked Hold'em game with optional 4x/3x, 2x, and 1x street bets |
| Arcade | Crash, Tube Flyer, and a 500-coin weighted Prize Case with premium Pokemon and item jackpots |
| Services | Bulk coin purchases and a pawn broker that stores up to five exact party Pokemon for later redemption |
| Rewards | Version-exclusive Pokemon, starters, fossils, shiny upgrades, rare TMs, Surfing Pikachu, Dragonite, Mew, and Master Balls |
| Economy | A 1,000,000-coin Coin Case used consistently by the new games, original slots, and hidden coin pickups |
| Code quality | Small per-game modules under `games/`, supporting systems under `other/`, and 407 automated checks |

## Screenshots

### Expanded Casino Floor

![The expanded Casino Lounge with blackjack, Texas Hold'em, and three arcade machines](assets/screenshots/expanded-casino-floor.png)

### New Games and Services

<table>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/pawn-broker-introduction.png" alt="The Pokemon pawn broker offering coins at the original Game Corner counter">
      <br><sub>Meet the pawn broker behind the original Game Corner counter.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/pawn-broker-appraisals.png" alt="Pawn Pokemon menu showing individual coin appraisals and five storage slots">
      <br><sub>Compare individual appraisals and manage up to five recoverable Pokemon.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/holdem-straight-win.png" alt="Texas Hold'em result screen showing a winning straight">
      <br><sub>Play progressive, house-banked Hold'em through the showdown.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/tube-flyer-gameplay.png" alt="Tube Flyer in progress with the bird flying between green tubes">
      <br><sub>Guide Tube Flyer through gaps and earn one coin per tube.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/crash-wager-selection.png" alt="Crash wager screen with 10, 50, 100, and 500 coin choices">
      <br><sub>Choose a Crash wager before launching the multiplier.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/crash-cash-out.png" alt="Crash result screen showing a successful cash-out at 1.20x">
      <br><sub>Cash out before the hidden crash point to secure the payout.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/prize-case-entry.png" alt="Prize Case start screen advertising a 500 coin case">
      <br><sub>Open a 500-coin case containing rare Pokemon and items.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/prize-case-opening.png" alt="Prize Case rarity-colored reward reel while a case is opening">
      <br><sub>Watch the rarity-colored reel slow onto its selected reward.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/prize-case-reward.png" alt="Prize Case reward screen awarding TM Substitute">
      <br><sub>Collect premium Pokemon, rare TMs, supplies, or the Master Ball jackpot.</sub>
    </td>
    <td width="50%"></td>
  </tr>
</table>

### Dedicated Blackjack Lounge

![The player standing in the dedicated Blackjack Lounge in Celadon Game Corner](assets/screenshots/blackjack-lounge.png)

<table>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/blackjack-bet-selection.png" alt="Blackjack bet selection with four pixel-art betting chips">
      <br><sub>Choose a 10, 50, 100, or 500-coin bet.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/blackjack-hand-actions.png" alt="A live blackjack hand with Hit, Stand, and Double actions">
      <br><sub>Play a hand using Hit, Stand, or Double.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/blackjack-win-result.png" alt="Blackjack win screen after the dealer busts">
      <br><sub>Distinct results explain each hand and payout.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/shiny-upgrade-choice.png" alt="Pokemon Prize Corner offering normal and shiny redemption choices">
      <br><sub>Upgrade any Pokemon prize to a persistent shiny.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/coin-clerk-bulk-purchases.png" alt="Game Corner coin clerk offering larger bulk coin purchases">
      <br><sub>Buy larger coin bundles without repeating the original exchange.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/pokemon-prize-list.png" alt="Expanded Pokemon prize list with aligned names and coin prices">
      <br><sub>Browse expanded prizes with clean, level-free price rows.</sub>
    </td>
  </tr>
</table>

## Install

1. Download the named `blackjack_corner-<version>.zip` asset from the
   [latest release](https://github.com/martin2844/gen1recomp-blackjack-corner/releases/latest).
   Use the named mod ZIP, not GitHub's automatic source-code archives.
2. Open Gen1Recomp and choose **MODS > Import mod .zip**.
3. Select the downloaded ZIP, enable **Blackjack Corner**, and start the game.
4. Bring the Coin Case to Celadon Game Corner. The new double-door at the
   lower-left leads to the Casino Lounge.

Requires Gen1Recomp Mod API 2 and an engine version in the range
`>=0.0.0-0 <2.0.0`.

## Features

### A larger two-table Casino Lounge

- A new double-door in the original Game Corner opens into a separate casino
  room instead of crowding the slot-machine floor.
- The 20x12-cell lounge has separate blackjack and Texas Hold'em tables,
  dedicated dealers, spectators, a central aisle, and a reciprocal exit.
- Both tables are compact four-tile-wide assemblies with distinct green and
  blue felt, betting marks, cards, chips, and fully interactive front rails.
- Either table's dealer can explain the game and open its screen.
- Table graphics are built locally from authored pixel primitives and ship no
  copied Pokemon ROM art.

### Playable blackjack

- A shuffled 52-card deck with standard ace handling.
- Bets of 10, 50, 100, or 500 Game Corner coins.
- Hit, stand, and double down actions. Double down is available on the first
  two cards when the player can cover the additional stake.
- Dealer stands on soft 17.
- Blackjack pays 3:2, ordinary wins pay 1:1, and pushes return the stake.
- Dealer naturals, player naturals, busts, pushes, and dealer busts have
  distinct outcomes.
- Payouts safely respect the expanded 1,000,000-coin Coin Case limit.
- Persistent internal counts for hands played, hands won, and blackjacks.

### Texas Hold'em against the house

The second table is a progressive, house-banked Texas Hold'em game. It is
heads-up against the dealer rather than multiplayer poker.

- A shuffled 52-card deck, two private cards each, and a shared five-card
  board evaluated as the best five-card hand out of seven.
- Every hand begins with one starting bet.
- Before the flop, check or add a **3x** or **4x** Play wager.
- After seeing the three-card flop, play continues: check or add **2x**.
- After seeing the turn and river, check for a free showdown or add **1x**.
- The best five-card hand wins, even if it is only a high card.
- A win pays every committed wager 1:1. An exact tie returns every wager.

Starting-bet choices are 10, 50, 100, or 500 coins. Choosing 10 costs 10 coins
to deal. Every later bet is optional; unaffordable buttons are disabled while
Check remains available. Betting the maximum on all three streets risks eight
times the starting bet. Payouts respect the Coin Case's 1,000,000-coin capacity.
The mod records Hold'em hands, wins, and royal flushes in its save data.

### Pixel-art card presentation

- Purpose-built 160x144 true-color casino screen inspired by modern card-game
  presentation while retaining Gen 1's hard pixel edges.
- Individually drawn ranks, suits, pips, court-card silhouettes, card backs,
  chips, table markings, buttons, and outcome banners.
- Hidden dealer hole card, readable overlapping hands, animated card movement,
  disabled action states, result pulses, and Game Corner sound effects.

### Faster coin purchases

The original coin clerk now offers 50, 250, 500, and 1,000 coins at once, plus
a capacity-aware **MAX** option. Every selection preserves the original
exchange rate of ¥1,000 for 50 coins, checks the player's money and Coin Case,
and never exceeds the mod's expanded 1,000,000-coin limit. Native recompilation
saves preserve the full balance; exporting back to a cartridge-format `.sav`
necessarily clamps it to that format's original 9,999-coin maximum.

The original slot machines and hidden Game Corner coin pickups are patched to
cross the old 9,999 boundary without dropping or truncating coins.

### Pokemon pawn broker

A shady Rocket behind the original Game Corner counter exchanges party
Pokemon for coins and keeps them available for later redemption.

- Appraisals combine the species' base stats, the Pokemon's current stats and
  level, and rarity based on its catch rate.
- Redeeming a Pokemon costs its original pawn value plus 30%.
- The exact Pokemon is stored, including nickname, DVs, stats, moves, PP,
  original trainer data, and other individual state.
- Redeemed Pokemon return to the party when possible or the PC when the party
  is full. No coins are charged if all storage is full.
- One Pokemon must always remain in the party, and the Coin Case must have
  enough free space to accept the complete appraisal.
- Up to five pawned Pokemon remain recoverable. Pawning a sixth permanently
  sells the oldest pawn first, after an explicit confirmation warning.

### Three center-floor arcade machines

Three distinct two-tile cabinets stand between the blackjack and Hold'em
dealers. Each opens a purpose-built 160x144 screen with hard pixel edges,
limited Game Boy-inspired palettes, cabinet sounds, and persistent records.

#### Crash

- Choose a 10, 50, 100, or 500-coin wager and launch at 1.00x.
- The multiplier climbs continuously; press A to cash out before the hidden
  crash point.
- The crash distribution uses a 3% house edge, includes immediate 1.00x
  crashes, and caps extreme rounds at 50.00x.
- Successful payouts use the multiplier visible at the instant of cash-out
  and floor fractional coins.

#### Tube Flyer

- Every flight costs exactly 10 coins.
- Press A or Up to flap through continuously scrolling tube gaps.
- Every completely passed tube immediately adds one coin, so earned coins are
  preserved even when the bird later crashes or the player quits the flight.
- Score, paid coins, and the best flight are tracked independently.

#### Prize Case

- Opening one case costs 500 coins.
- A 25-card rarity-colored reel spins for 3.75 seconds and eases onto the
  reward selected by the weighted loot table before the animation begins.
- The premium Pokemon pool contains Bulbasaur, Charmander, Squirtle, Omanyte,
  Kabuto, Aerodactyl, Dragonite, Mew, and a special Pikachu that knows Surf.
- The item pool includes Rare Candy, PP Up, two Max Revives, three rare TMs,
  and a gold-and-black Master Ball jackpot card.
- Approximate odds are 27.0% Rare Candy, 20.8% PP Up, 18.7% Max Revives,
  20.8% combined TMs, 12.5% Pokemon, and 0.1% Master Ball.
- Pokemon use the same safe party/PC delivery as the Prize Corner. If the
  selected item or Pokemon cannot be stored, the full 500 coins are refunded.

### Expanded Pokemon Prize Corner

All Pokemon can be bought normally or upgraded to shiny for 2,500 additional
coins. Levels remain part of the awarded Pokemon but are intentionally hidden
from the in-game price list so long names never collide with prices.

Shared prizes in every supported version:

| Pokemon | Level | Coins |
| --- | ---: | ---: |
| Abra | 10 | 250 |
| Clefairy | 12 | 750 |
| Dratini | 20 | 3,500 |
| Porygon | 25 | 7,000 |
| Bulbasaur | 15 | 4,000 |
| Charmander | 15 | 4,000 |
| Squirtle | 15 | 4,000 |
| Omanyte | 20 | 5,000 |
| Kabuto | 20 | 5,000 |
| Aerodactyl | 25 | 6,500 |

Additional prizes in Pokemon Red supply Blue-version species and familiar
Game Corner headliners:

| Pokemon | Level | Coins |
| --- | ---: | ---: |
| Nidorina | 17 | 1,200 |
| Scyther | 25 | 4,500 |
| Sandshrew | 15 | 800 |
| Vulpix | 18 | 1,200 |
| Meowth | 18 | 1,200 |
| Bellsprout | 15 | 800 |
| Pinsir | 25 | 4,000 |
| Magmar | 25 | 4,500 |

Additional prizes in Pokemon Blue supply Red-version species and familiar
Game Corner headliners:

| Pokemon | Level | Coins |
| --- | ---: | ---: |
| Nidorino | 17 | 1,200 |
| Pinsir | 25 | 4,000 |
| Ekans | 15 | 800 |
| Oddish | 15 | 800 |
| Mankey | 18 | 1,200 |
| Growlithe | 18 | 1,200 |
| Scyther | 25 | 4,500 |
| Electabuzz | 25 | 4,500 |

Pokemon Yellow adds Vulpix at level 18 for 1,000 coins, Wigglytuff at level
22 for 2,680, Scyther at level 30 for 4,500, and Pinsir at level 30 for 4,000.

Prize Pokemon update the Pokedex and go to the party when space is available
or the active PC box otherwise. If both party and storage are full, the sale
is refused and no coins are taken.

### Persistent shiny Pokemon

- Every Pokemon prize offers **NORMAL** and **SHINY** purchase choices.
- Purchased shinies receive canonical Gen II-compatible shiny DVs rather than
  a temporary cosmetic flag, so their status persists in the save.
- Supported prize families receive locally derived casino-gold battle art.
- Optional battle sparkles can be enabled or disabled with the mod's
  **SHINY SPARKLES** setting.
- Ordinary members of the same species retain their normal artwork.

The first release uses a shared casino-gold treatment instead of each
species' canonical Gen II shiny palette.

### Item Prize Corner

| Item | Coins | Availability |
| --- | ---: | --- |
| TM Dragon Rage | 3,300 | Repeatable |
| TM Hyper Beam | 5,500 | Repeatable |
| TM Substitute | 7,700 | Repeatable |
| Rare Candy | 1,500 | Repeatable |
| PP Up | 2,500 | Repeatable |
| Max Revive | 2,000 | Repeatable |
| Master Ball | 9,999 | Once per save |

The Master Ball visibly becomes sold out after redemption. Item purchases are
also rejected without charging coins when the Bag has no room.

## Controls

### Blackjack

| Screen | Control | Action |
| --- | --- | --- |
| Bet selection | Left / Right | Change the stake |
| Bet selection | A | Deal |
| Bet selection | B | Leave the table |
| Playing | Left / Right | Choose Hit, Stand, or Double |
| Playing | A | Confirm the selected action |
| Playing | B | Stand immediately |
| Result | A | Start another hand |
| Result | B | Leave the table |

### Arcade machines

| Machine | Stage | Control | Action |
| --- | --- | --- | --- |
| Crash | Wager | Left / Right | Change the wager |
| Crash | Wager | A | Launch |
| Crash | Running | A | Cash out immediately |
| Tube Flyer | Ready | A | Pay 10 coins and start |
| Tube Flyer | Flying | A / Up | Flap |
| Tube Flyer | Flying | B | End the flight and keep earned coins |
| Prize Case | Ready | A | Pay 500 coins and open |
| Any machine | Ready / Result | B | Leave |

### Texas Hold'em

| Stage | Control | Action |
| --- | --- | --- |
| Bet-size selection | Left / Right | Change the size of each starting wager |
| Bet-size selection | A | Pay the shown start cost and deal |
| Bet-size selection | B | Leave the table |
| Any decision | Left / Right | Choose an available action |
| Any decision | A | Confirm Check or Bet |
| Any street | B | Check immediately |
| Result | A | Start another hand |
| Result | B | Leave the table |

## Compatibility and limitations

- Blackjack Corner needs the Coin Case for table games, arcade machines,
  prize redemption, and the pawn broker.
- Blackjack does not include splits, insurance, or surrender.
- Texas Hold'em is a custom house-banked game, not multiplayer poker.
- Mods or total conversions that replace the Celadon Game Corner, Prize Room,
  or their scripts may conflict even if the launcher cannot detect it.
- Save a backup before combining large content mods.

## Development

The runtime is organized by feature instead of accumulating logic in the
entrypoint:

```text
games/
  blackjack/    rules.lua  screen.lua  view.lua
  holdem/       rules.lua  screen.lua  view.lua
  crash/        rules.lua  screen.lua  view.lua
  tube_flyer/   rules.lua  screen.lua  view.lua
  prize_case/   rules.lua  screen.lua  view.lua
  shared/       ui.lua
other/
  pawn/         rules.lua
  prizes/       catalog.lua
  coin_case.lua lounge.lua services.lua ui.lua
main.lua        composition, registration, and hooks only
```

Modules are loaded through `mod:read()` so the layout remains compatible with
both unpacked development installs and packaged mod ZIPs.

Clone this repository into a Gen1Recomp checkout so it is located at
`mods/blackjack_corner`, then run these commands from the Gen1Recomp root:

```sh
python3 tools/modkit.py validate mods/blackjack_corner --base fixture
python3 tools/modkit.py lint mods/blackjack_corner
luajit mods/blackjack_corner/tests/blackjack_rules_test.lua
luajit mods/blackjack_corner/tests/holdem_rules_test.lua
luajit mods/blackjack_corner/tests/pawn_test.lua
luajit mods/blackjack_corner/tests/arcade_rules_test.lua
luajit mods/blackjack_corner/tests/blackjack_mod_test.lua
```

The release workflow publishes an installable ZIP and SHA-256 checksum on
each release commit to `main`. Version numbers are sourced from
`manifest.json`.

## Credits and license

- Built for the [Pokemon Gen 1 Recompilation Project](https://github.com/bryanthaboi/gen1recomp).
- Original Pokemon Red disassembly and research by
  [pret/pokered](https://github.com/pret/pokered) contributors.
- Blackjack Corner is maintained by [martin2844](https://github.com/martin2844).

Released under the [MIT License](LICENSE). Pokemon and related names are
trademarks of their respective owners. This is an unofficial fan-made mod and
is not affiliated with or endorsed by Nintendo, Game Freak, or The Pokemon
Company.
