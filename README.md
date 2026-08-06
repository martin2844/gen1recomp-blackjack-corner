# Blackjack Corner

[![Latest release](https://img.shields.io/github/v/release/martin2844/gen1recomp-blackjack-corner)](https://github.com/martin2844/gen1recomp-blackjack-corner/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Blackjack Corner turns Celadon Game Corner into a larger casino destination
for the [Pokemon Gen 1 Recompilation Project](https://github.com/bryanthaboi/gen1recomp).
It adds a dedicated blackjack lounge, a full pixel-art card game, larger coin
exchanges, expanded version-aware Pokemon prizes, persistent shiny upgrades,
rare items, and a one-time Master Ball.

The mod supports Pokemon Red, Blue, and Yellow. It contains no ROM or
ROM-derived artwork; world and shiny graphics are generated locally from the
player's imported game data.

## Install

1. Download `blackjack_corner-0.1.0.zip` from the
   [latest release](https://github.com/martin2844/gen1recomp-blackjack-corner/releases/latest).
   Use the named mod ZIP, not GitHub's automatic source-code archives.
2. Open Gen1Recomp and choose **MODS > Import mod .zip**.
3. Select the downloaded ZIP, enable **Blackjack Corner**, and start the game.
4. Bring the Coin Case to Celadon Game Corner. The new double-door at the
   lower-left leads to the Blackjack Lounge.

Requires Gen1Recomp Mod API 2 and an engine version in the range
`>=0.0.0-0 <2.0.0`.

## Features

### A dedicated Blackjack Lounge

- A new double-door in the original Game Corner opens into a separate casino
  room instead of crowding the slot-machine floor.
- The lounge has an authored wide green table, centered dealer, spectators,
  betting marks, chips, deck, open approach lane, and reciprocal exit.
- The complete front rail is interactive, and the dealer can also open the
  table.
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
- Payouts safely respect the original 9,999-coin Coin Case limit.
- Persistent internal counts for hands played, hands won, and blackjacks.

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
and never exceeds 9,999 coins.

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

## Compatibility and limitations

- Blackjack Corner needs the Coin Case for blackjack and prize redemption.
- Splits, insurance, and surrender are not included in version 0.1.0.
- Mods or total conversions that replace the Celadon Game Corner, Prize Room,
  or their scripts may conflict even if the launcher cannot detect it.
- Save a backup before combining large content mods.

## Development

Clone this repository into a Gen1Recomp checkout so it is located at
`mods/blackjack_corner`, then run these commands from the Gen1Recomp root:

```sh
python3 tools/modkit.py validate mods/blackjack_corner --base fixture
python3 tools/modkit.py lint mods/blackjack_corner
luajit mods/blackjack_corner/tests/blackjack_rules_test.lua
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
