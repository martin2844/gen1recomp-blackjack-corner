# Blackjack Corner

[![Latest release](https://img.shields.io/github/v/release/martin2844/gen1recomp-blackjack-corner)](https://github.com/martin2844/gen1recomp-blackjack-corner/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Blackjack Corner turns Pokemon Gen 1 into a living casino remix for the
[Pokemon Gen 1 Recompilation Project](https://github.com/bryanthaboi/gen1recomp).
Its optional Gamble Mode reaches from Oak's Lab to every Gym: the starter is
random, the rival rolls separately, Gym TMs become themed mystery cases, and
post-Gym case challengers appear across Kanto. Pallet Town gains its own gloomy
casino, while compact regional branches put blackjack, Hold'em, and a local
machine in Viridian, Pewter, Cerulean, Vermilion, Lavender, Fuchsia, Saffron,
and Cinnabar. Celadon's expanded floor remains the main destination, with
blackjack, house-banked Texas Hold'em, Crash, Tube Flyer,
Prize Cases, animated horse racing, Plinko, Pokemon pawning, shinies, rare
items, and a one-time Master Ball. Gamble Mode's final High Roller rank now
opens a Rocket status terminal that verifies KINGPIN clearance, retracts, and
reveals a physical staircase into an underground Pokemon battle-betting arena.
The final chapter follows evidence from that pit to Cinnabar, returns for a
fixed Dragonite-versus-Mewtwo exhibition, and ends with an irreversible choice
to expose Rocket or become the house champion.

The v0.7.3 release is certified on Pokemon Red and Blue. Pokemon Yellow support
is available but remains experimental until its distinct one-ball Oak flow has
its own native release gate. The mod contains no ROM or ROM-derived artwork;
world and shiny graphics are generated locally from the player's imported game
data.

## Version 0.7.3 prize-aware Gym Leaders

- Every Gym Case reward now gets a bespoke follow-up from the leader whose
  badge themed the case. The script covers all 80 prizes across all eight Gyms.
- The reaction reflects both the exact prize and its rarity: modest supplies
  get a dry consolation, Pokemon receive species-specific advice or a playful
  roast, and epic or gold pulls get a suitably bigger response.
- Each leader keeps a distinct voice. Brock turns pulls into lessons, Misty is
  playfully blunt, Surge issues field orders, Erika is gently cutting, Koga
  speaks like a disciplined ninja, Sabrina is deadpan and prophetic, Blaine
  treats rewards as quiz answers, and Giovanni evaluates their power.
- Classic reward flavor survives inside the new system. Pulling TM11 prompts
  Misty's BUBBLEBEAM lesson; pulling HORSEA earns praise for being cute and a
  friendly warning that it is "a little mid."
- Dialogue is delivery-safe. A full Bag, party, or PC keeps the exact reward
  pending without triggering the leader; the comment appears only after a
  successful retry.

## Version 0.7.2 Nuzlocke compatibility

- Nuzlocke 2's post-Oak World Building dialogue now waits until Oak's intro
  screen has closed. Starting a new game with both mods enabled no longer
  leaves an opaque white screen on top of the game.
- The compatibility handoff is scoped to an active, successfully loaded
  Nuzlocke mod. Blackjack Corner's standalone new-game flow and the older
  Nuzlocke setup remain unchanged.
- The fix is regression-tested and native-tested on Pokemon Red and Blue.

## Version 0.7.1 settings and onboarding

- Blackjack Corner now has a permanent **MODS > Blackjack Corner > OPTIONS**
  page. It controls the default Gamble Mode answer, repeat table introductions,
  reveal speed, and paid shiny-upgrade offers.
- The per-save Gamble Mode decision now appears on a clean screen before Oak's
  first appearance. The global default only moves the YES/NO cursor; it never
  skips confirmation or rewrites an existing campaign.
- Relaxed, Normal, and Fast reveal speeds apply to deterministic presentation
  in starter and prize reels, horse racing, Plinko, and the Underground Arena.
  Crash and Tube Flyer keep their original real-time physics.
- The core page stays available when a dedicated shiny renderer is installed;
  without one, Blackjack Corner appends its four bundled shiny presentation
  controls to the same scrolling page.
- The settings and pre-Oak flow are native-tested on Red and Blue, including
  process-restart persistence, Reset Defaults, Pokemon Randomizer v0.46.4,
  external shiny-provider composition, table guards, real ordinary prize
  delivery, every Arena story intro, and deterministic production-screen
  pacing with identical results and payouts at every speed.

## Version 0.7.0 casino network expansion

- Gamble Mode now composes with `pokemon_randomizer`: when both are enabled,
  Blackjack Corner owns Oak's roulette and both rolled starters, while the
  Randomizer keeps control of wild encounters and ordinary trainer teams.
  With Gamble Mode disabled, the Randomizer's saved starter-ball flow remains
  intact.
- Every Kanto city now has a gambling floor: Pallet and Celadon retain their
  large casinos, and eight compact native-tile branches add blackjack,
  Hold'em, coin sales, a local machine, a named exterior sign, and dialogue
  written for that city.
- Cinnabar's branch shares the Lab trade room without removing its original
  NPC interaction surface; the seven replaced houses contain flavor or
  tutorial dialogue only and do not gate story progression or award items.
- Each Gym Case now has a ten-slot badge theme with ten distinct identities:
  Rock, Water, Electric, Grass, Venom, Psychic, Fire, and Earth Pokemon, TMs,
  stones, and supplies. Nidoran filler and inherited earlier-Gym pools are
  gone, and the reel never places an identical prize in adjacent slots.
- Eight optional CASE ACE trainers appear after their matching badges. Their
  complete teams sit above the nearby Gym Leader's level cap, remain retryable
  after a loss, and award one replay-safe themed case after the first win.

## Version 0.6.0 final Gamble Mode chapter

The Arena is now the start of Gamble Mode's ending rather than its last
standalone table. Arena participation reveals three persistent records, a
Cinnabar Lab handler and Mansion researcher authenticate Series 3, and the
return match posts a fixed Dragonite L62 versus Mewtwo L65 card. Its complete
odds, result, wager, and animation are committed before the fight, so reloads
cannot reroll a loss.

Winning summons Giovanni in the physical B2 chamber. EXPOSE and CHAMPION each
show their consequences and require a second confirmation. EXPOSE closes only
future Rocket loans; CHAMPION awards 25,000 coins once, banking any amount that
does not fit under the 1,000,000 Coin Case cap. Both endings permanently change
the High Roller title and selected dialogue across Pallet, Celadon, Cinnabar,
the underground floors, and an occupied family home while keeping all games,
prizes, routes, healing, pawns, old-debt repayment, and house recovery open.

## Version 0.5.2 economy polish

The Celadon Rocket broker now lets Gamble Mode players pawn the Pallet family
home once at any balance. The deal adds 10,000 coins instead of replacing the
current Coin Case balance, requires room for the full payout, and retains the
30,000-coin buyback plus Rocket battle recovery route.

## Version 0.5.1 Arena polish

This patch rebuilds the complete Underground Arena route from native ROM tiles:
a Rocket status terminal reveals a physical staircase, B1 becomes a permanent
casino checkpoint with six playable original slot seats, and B2 takes the form
of Rocket's illicit fifth League chamber. It also redesigns the High Roller
status panel, clarifies Arena controls, distinguishes clubs from spades, and
keeps players upgrading from v0.5.0 out of the closed terminal.

## Version 0.5 campaign highlights

| Area | What the release adds |
| --- | --- |
| Adventure | Optional save-scoped Gamble Mode changes the starter, rival team, all eight Gym Leader rewards, and adds eight post-Gym CASE ACE battles |
| Pallet Town | A new early-game casino with blackjack, Hold'em, horse racing, Plinko, Prize Cases, coin sales, pawning, gamblers, and hidden coins |
| Celadon | A dedicated 20x18 lounge with two tables, three front cabinets, and a rear Horse Racing and Plinko arcade |
| Eight games | Blackjack, Hold'em, Crash, Tube Flyer, Prize Case, animated horse racing, Plinko, and the Underground Arena |
| Services | Bulk coin purchases and a pawn broker that stores up to five exact party Pokemon for later redemption |
| Rewards | Version-exclusive Pokemon, starters, fossils, shiny upgrades, rare TMs, Surfing Pikachu, Dragonite, Mew, and Master Balls |
| Economy | A 1,000,000-coin Coin Case used consistently by the new games, original slots, and hidden coin pickups |
| Atmosphere | A casino in every Kanto city, regional dialogue and signs, ten central-floor gamblers/staff, and hidden coin pickups |
| Code quality | Small per-game modules under `games/`, supporting systems under `other/`, automated rule/integration coverage, and a Red/Blue native release gate |

## v0.5 Gamble campaign

Version 0.5 bundles the complete first High Roller progression arc without
changing the always-available base casino expansion:

- all eight paid casino games feed one exactly-once High Roller reputation
  ledger;
- Rookie, Regular, High Roller, VIP, and KINGPIN ranks combine reputation requirements
  with story-safe badge ceilings;
- excess reputation remains banked until the required badge is earned;
- rank-ups grant one-time coin rewards and get a dedicated pixel presentation;
- the Start menu exposes a compact High Roller panel with rank progress,
  results, lifetime wagers, and cold streaks;
- casino patrons and staff react to rank and sustained losses;
- a native Rocket terminal in the Celadon Lounge grants clearance at
  KINGPIN—4,000 REP and all eight badges—then reveals a staircase into Rocket
  Casino B1;
- permanent Rocket staff guard the physical pit door without taking or
  modifying the player's party;
- AI-controlled Pokemon fight using real species stats, levels, moves,
  accuracy, Gen I types, STAB, and physical/special rules;
- posted decimal odds include a visible house margin while controlled
  randomness keeps an underdog capable of winning;
- STREET, ELITE, and RARE cards expand the house fighter pool as arena
  reputation grows, without ever using the player's party;
- exact fighters, odds, wager, simulated outcome, animation plan, and High
  Roller token are saved before the fight so restarting cannot reroll a loss
  or duplicate a payout;
- old saves lazily receive a versioned campaign record while existing game,
  pawn, case, party, and currency state stays intact.
- a Rocket loan shark in the Celadon Lounge offers larger fixed-fee loans as
  the player climbs from Rookie to VIP;
- only one loan can be active, with its principal, fees, due badge, and status
  visible on demand;
- debt can be repaid with casino coins or ordinary money, and missing a badge
  deadline applies one fixed late fee instead of real-time interest;
- party Pokemon can be pawned directly toward debt without changing the exact
  five-ticket redemption ledger; appraisal surplus remains in the Coin Case;
- default brings Rocket collectors to Pallet and Celadon and freezes only paid
  Prize Cases and the luxury prize counters—games, travel, healing, story,
  clerks, and pawn redemption remain available;
- the Pallet family home can be pawned once at any money or casino balance with
  10,000 free Coin Case space, adding 10,000 coins in exchange for Team Rocket
  taking possession;
- the occupied home gains Rocket tenants, surveillance dialogue, authentic
  Rocket Hideout/Silph Co equipment derived from the imported game, and a
  relocated Mom upstairs who still heals the party;
- reclaiming the home requires an explicit 30,000-coin deed buyback and a
  retryable Rocket battle, after which the original house is fully restored;
- Red and Blue native runs verify the switch and staircase, permanent staff,
  two new maps, readable odds, live fight animation, result settlement, disk
  persistence, fighter tiers, default behavior, and every return path.

The implementation and internal milestone train are mapped in
[docs/GAMBLE_MODE_ROADMAP.md](docs/GAMBLE_MODE_ROADMAP.md). Human UI/E2E signoff
uses the supervised drivers and matrix in [`tests/manual`](tests/manual); the
public release record is
[tests/manual/releases/v0.7.3.md](tests/manual/releases/v0.7.3.md), with the
detailed Arena phase gate retained in
[tests/manual/V0.7_IN_GAME_TESTING.md](tests/manual/V0.7_IN_GAME_TESTING.md).

## Screenshots

### Casino network, Randomizer compatibility, and themed cases

<table>
  <tr>
    <td width="50%"><img src="assets/screenshots/randomizer-starter-roulette.png" alt="Oak's Gamble Mode starter roulette while Pokemon Randomizer is active"><br><sub>Gamble Mode reclaims Oak's cabinet while the real Randomizer continues to own wild encounters and ordinary trainers.</sub></td>
    <td width="50%"><img src="assets/screenshots/gym-water-case-reel.png" alt="Misty's Water Case reel with Water and Ice themed prizes"><br><sub>Every Gym now spins a distinct ten-prize pool built around its leader.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="assets/screenshots/regional-casino-viridian.png" alt="The compact Viridian Casino branch"><br><sub>Eight signed regional branches bring Blackjack, Hold'em, coins, and local games across Kanto.</sub></td>
    <td width="50%"><img src="assets/screenshots/regional-casino-cinnabar.png" alt="The Cinnabar Casino inside the Pokemon Lab trade room"><br><sub>Cinnabar's experimental floor preserves its scientists and native Lab route.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="assets/screenshots/regional-case-ace-cerulean.png" alt="Cerulean's post-Gym CASE ACE challenger"><br><sub>Eight badge-gated CASE ACEs offer stronger optional fights and one replay-safe themed case.</sub></td>
    <td width="50%"></td>
  </tr>
</table>

### Final Gamble Mode chapter

<table>
  <tr>
    <td width="50%"><img src="assets/screenshots/gamble-story-rumor-clue.png" alt="A hidden Arena record pointing toward Cinnabar"><br><sub>Arena participation unlocks persistent records hidden in native props and dialogue.</sub></td>
    <td width="50%"><img src="assets/screenshots/gamble-story-cinnabar-handler.png" alt="The Cinnabar Lab Rocket handler"><br><sub>A Lab handler and Mansion researcher authenticate the engineered exhibition.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="assets/screenshots/gamble-story-series-3.png" alt="Series 3 Dragonite versus Mewtwo betting card"><br><sub>Series 3 commits Dragonite, Mewtwo, posted odds, and its full result before animation.</sub></td>
    <td width="50%"><img src="assets/screenshots/gamble-story-giovanni-choice.png" alt="Giovanni's EXPOSE or CHAMPION ending choice"><br><sub>Giovanni offers two irreversible endings, each behind a separate consequence confirmation.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="assets/screenshots/gamble-story-expose-status.png" alt="High Roller panel after exposing Rocket"><br><sub>EXPOSE becomes a permanent High Roller title and changes the casino's response.</sub></td>
    <td width="50%"><img src="assets/screenshots/gamble-story-champion-reward.png" alt="Giovanni transferring the Champion reward"><br><sub>CHAMPION transfers 25,000 coins exactly once and banks any cap overflow.</sub></td>
  </tr>
</table>

### Underground Arena

<table>
  <tr>
    <td width="50%"><img src="assets/screenshots/underground-arena-concealed-lift.png" alt="Native Rocket status terminal concealing the Arena staircase"><br><sub>The terminal scans casino status before retracting to reveal the hidden route.</sub></td>
    <td width="50%"><img src="assets/screenshots/underground-arena-vip-lobby.png" alt="Rocket Casino B1 built from native Celadon Game Corner tiles"><br><sub>The staircase descends into a native-tile Rocket casino checkpoint.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="assets/screenshots/underground-arena-spectator-floor.png" alt="Rocket Casino B2 built as a native Elite Four chamber"><br><sub>House fighters meet inside Rocket's illicit fifth League chamber.</sub></td>
    <td width="50%"><img src="assets/screenshots/underground-arena-posted-odds.png" alt="Arena board showing two fighters and posted decimal odds"><br><sub>Choose a fighter and stake after reviewing the posted odds.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="assets/screenshots/underground-arena-live-battle.png" alt="An animated arena match with HP bars and move text"><br><sub>Moves, misses, damage, HP, and crowd reactions animate live.</sub></td>
    <td width="50%"><img src="assets/screenshots/underground-arena-winning-result.png" alt="Arena winning ticket result and payout"><br><sub>Winning and losing tickets settle once at their posted price.</sub></td>
  </tr>
  <tr>
    <td width="33%"><img src="assets/screenshots/underground-arena-street-card.png" alt="Street tier arena match"><br><sub>STREET</sub></td>
    <td width="33%"><img src="assets/screenshots/underground-arena-elite-card.png" alt="Elite tier arena match"><br><sub>ELITE</sub></td>
    <td width="33%"><img src="assets/screenshots/underground-arena-rare-card.png" alt="Rare tier arena match"><br><sub>RARE</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="assets/screenshots/underground-arena-kingpin-rank-up.png" alt="The one-time Kingpin High Roller rank-up"><br><sub>All eight badges and 4,000 REP earn the final KINGPIN rank.</sub></td>
    <td width="50%"><img src="assets/screenshots/underground-arena-long-fight.png" alt="A long arena match with fitted move text"><br><sub>Long matches retain readable move and damage captions.</sub></td>
  </tr>
</table>

### Expanded Casino Floor

![The expanded Casino Lounge with blackjack, Texas Hold'em, and three arcade machines](assets/screenshots/expanded-casino-floor.png)

### Games and Services

<table>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/pawn-broker-introduction.png" alt="The Pokemon pawn broker offering coins at the original Game Corner counter">
      <br><sub>Meet the pawn broker behind the original Game Corner counter.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/pawn-broker-appraisals.png" alt="Pawn Pokemon menu showing individual coin appraisals and five storage slots">
      <br><sub>Compare appraisals and manage up to five recoverable Pokemon.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/holdem-straight-win.png" alt="Texas Hold'em result screen showing a winning straight">
      <br><sub>Play progressive house-banked Hold'em through showdown.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/tube-flyer-gameplay.png" alt="Tube Flyer in progress between green tubes">
      <br><sub>Guide Tube Flyer through gaps for one coin per tube.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/crash-wager-selection.png" alt="Crash wager screen with four coin choices">
      <br><sub>Choose a Crash wager before launching the multiplier.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/crash-cash-out.png" alt="Crash result after a successful cash-out">
      <br><sub>Cash out before the hidden crash point.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/prize-case-entry.png" alt="Prize Case start screen">
      <br><sub>Open a 500-coin case containing rare Pokemon and items.</sub>
    </td>
    <td width="50%">
      <img src="assets/screenshots/prize-case-opening.png" alt="Prize Case rarity-colored reel">
      <br><sub>Watch the reel slow onto its selected reward.</sub>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="assets/screenshots/prize-case-reward.png" alt="Prize Case reward screen">
      <br><sub>Collect Pokemon, rare TMs, supplies, or the jackpot.</sub>
    </td>
    <td width="50%"></td>
  </tr>
</table>

### Dedicated Blackjack Lounge

![The player standing in the dedicated Blackjack Lounge](assets/screenshots/blackjack-lounge.png)

<table>
  <tr>
    <td width="50%"><img src="assets/screenshots/blackjack-bet-selection.png" alt="Blackjack bet selection"><br><sub>Choose a 10, 50, 100, or 500-coin bet.</sub></td>
    <td width="50%"><img src="assets/screenshots/blackjack-hand-actions.png" alt="Live blackjack hand"><br><sub>Play using Hit, Stand, or Double.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="assets/screenshots/blackjack-win-result.png" alt="Blackjack win screen"><br><sub>Each result explains the hand and payout.</sub></td>
    <td width="50%"><img src="assets/screenshots/shiny-upgrade-choice.png" alt="Normal and shiny prize choices"><br><sub>Upgrade any Pokemon prize to a persistent shiny.</sub></td>
  </tr>
  <tr>
    <td width="50%"><img src="assets/screenshots/coin-clerk-bulk-purchases.png" alt="Bulk coin purchases"><br><sub>Buy larger coin bundles in one exchange.</sub></td>
    <td width="50%"><img src="assets/screenshots/pokemon-prize-list.png" alt="Expanded Pokemon prize list"><br><sub>Browse clean, level-free prize rows.</sub></td>
  </tr>
</table>

## Install

1. Download `blackjack_corner-0.7.3.zip` from the
   [latest release](https://github.com/martin2844/gen1recomp-blackjack-corner/releases/latest).
   Use the named mod ZIP, not GitHub's automatic source-code archives.
2. Open Gen1Recomp and choose **MODS > Import mod .zip**.
3. Select the downloaded ZIP, enable **Blackjack Corner**, and start the game.
4. Start a new game. Blackjack Corner asks about **Gamble Mode before Oak
   appears**: answer **YES** for the full-adventure remix, or **NO** to keep
   normal story progression while retaining the casino expansion.
5. Gamble Mode starts with a Coin Case and 100 coins. Pallet's new southwest
   casino is immediately available; Celadon's double-door leads to the larger
   Casino Lounge later in the adventure.

Requires Gen1Recomp Mod API 2 and an engine version in the range
`>=0.0.0-0 <2.0.0`.

## Settings

Open **MODS > Blackjack Corner > OPTIONS** to configure the mod. These choices
live in the global mod profile; Gamble Mode itself is still confirmed
separately for every new save.

| Setting | Values | Effect |
| --- | --- | --- |
| Gamble Default | No / Yes | Preselects the answer on the pre-Oak Gamble Mode prompt without skipping confirmation |
| Table Intros | On / Off | Shows or skips repeat rules cards before ordinary casino games; story-critical Arena dialogue is always kept |
| Reveal Speed | Relaxed / Normal / Fast | Changes reels, starter roulette, horse racing, Plinko, and Arena animation pace without changing Crash or Tube Flyer difficulty |
| Shiny Upgrades | On / Off | Shows or hides the extra-cost shiny choice at Pokemon prize counters |

When Blackjack Corner supplies its bundled shiny renderer, the same page also
contains **Shiny Animation**, **Shiny Chime**, **Battle Markers**, and
**Shiny Colors**. Core settings remain present when a dedicated shiny mod is
installed.

## Features

### Optional Gamble Mode

Blackjack Corner asks whether to enable Gamble Mode on a clean screen before
Professor Oak first appears. The choice belongs to that save: choosing **NO**
leaves Oak's starter selection and all Gym TM rewards untouched, while choosing
**YES** lets Oak introduce the complete remix.

- The player starts with a Coin Case and 100 coins.
- Oak's Lab replaces the gift Poké Balls with a three-piece roulette cabinet.
- The player's starter is drawn from every base-stage, non-legendary Gen 1
  species. Unevolved species that never evolve are valid, so the result can
  range from Caterpie or Magikarp to Lapras, Snorlax, or Aerodactyl.
- Every roll can be kept for free or rerolled for ¥1,000. A reroll spends
  ordinary money rather than casino coins, and the current Pokemon remains
  available until the player confirms KEEP.
- Magikarp and Abra remain possible, but receive Tackle or Confusion at level 5
  so an unlucky spin cannot make the opening battle unwinnable.
- The rival receives a separate roll and cannot receive the exact same result.
  Their starter follows its evolution line as later rival teams gain levels.
- Oak becomes a witty gambling evangelist who replaces the three-Pokemon
  choice speech and encourages both the player and rival to trust the wheel.
- Every Gym Leader still awards the correct badge, but the direct TM is
  replaced by one animated Gym Case.

Gamble Mode is selected only during a new-game introduction. Existing saves
are never silently converted.

### Gym Leader prize cases

Each of the eight badges unlocks one persistent, zero-cost Gym Case. Its reel
contains exactly one final reward:

- Every leader owns a ten-reward pool with no duplicate identities. Brock mixes
  Rock Pokemon and Rock/Ground tools, Misty Water and Ice rewards, Surge
  Electric rewards, Erika Grass rewards, Koga poison and discipline items,
  Sabrina Psychic rewards, Blaine Fire rewards, and Giovanni elite Earth and
  boss prizes.
- The leader delivers their badge dialogue in the Gym before the case opens,
  then personally invites the player to spin with dialogue written for their
  personality; no TM explanation is shown over the case screen.
- Nidoran filler and repeated progressive unlocks are removed. Every visible
  slot belongs to the leader's theme, and adjacent reel cards cannot repeat.
- The selected reward is saved as soon as the reel begins. If the Bag, party,
  and PC cannot accept it, **GYM CASE** appears in the Start menu so the exact
  same prize can be claimed later.
- A Gym Case never charges coins and never replaces the leader's badge or
  post-battle progression.

### Regional casinos and CASE ACE trainers

Pallet and Celadon remain the flagship floors. Viridian, Pewter, Cerulean,
Vermilion, Lavender, Fuchsia, Saffron, and Cinnabar now each advertise a
compact branch in a story-neutral interior. Every branch offers blackjack,
Texas Hold'em, bulk coin sales, and one regional arcade game, with local hosts
and patrons commenting on schools, fossils, Misty, sailors, ghosts, the Safari
Zone, Silph, or Cinnabar experiments.

After each badge, a stronger CASE ACE appears in the surrounding city. These
are optional fixed encounters—not random ambushes and never Gym replacements.
Their weakest party member is above the nearby leader's strongest Pokemon;
winning once creates a persistent themed case, while losses and interrupted
delivery remain retryable without duplicating the reward.

### Pallet Town mini-casino

A new building in Pallet's southwest clearing creates an intentionally seedy
early-game casino floor. It is available immediately in Gamble Mode and
contains everything needed to enter the economy without waiting for Celadon:

- A live race terminal, an animated Plinko board, and a 500-coin Prize Case.
- Full blackjack and Texas Hold'em tables with dedicated dealers, using the
  same rules, progressive wagering, and Coin Case balance as Celadon.
- A bulk coin clerk using the original exchange rate.
- A Rocket pawn broker who accepts party Pokemon under the same five-ticket,
  30%-redemption rules as Celadon.
- Four wandering patrons with original dialogue about bad systems, hidden
  debts, and Pokemon they regret pawning.
- Three one-time hidden coin pickups on the floor.

#### Animated horse racing

- Choose COMET, LUCKY, DUSK, or GHOST and wager 10, 50, 100, or 500 coins.
- The terminal posts each runner's real 2x, 3x, 5x, or 8x payout before the
  ticket is placed.
- Four pixel horses run simultaneously for six seconds with changing visible
  leads and a fixed result chosen from the posted weighted odds.
- Only the selected winning horse pays. Losing tickets pay zero and are
  recorded separately from wins.

#### Plinko

- Choose a 10, 50, 100, or 500-coin drop.
- A visible ball bounces through eight animated peg rows into one of nine
  buckets.
- Center outcomes pay 0.20x, intermediate buckets pay 0.65x, 1.50x, or 3.50x,
  and the two rare outside buckets pay 9.00x.
- All 256 left/right paths are represented, for an overall 4.375% house edge.

### Living casino floors

The original Game Corner, the separate Casino Lounge, and Pallet Casino now
share a larger cast without replacing vanilla NPCs. Debtors, dreamers, card
counters, cold-streak regulars, clerks, and pawn brokers move around the
floors and tell their own short stories. Eight additional one-time coin
pickups reward looking down while everyone else watches the machines.

### A larger two-table Casino Lounge

- A new double-door in the original Game Corner opens into a separate casino
  room instead of crowding the slot-machine floor.
- The 20x18-cell lounge has separate blackjack and Texas Hold'em tables,
  dedicated dealers, spectators, a long central aisle, and a reciprocal exit.
- Crash, Tube Flyer, and Prize Case remain between the tables; a new rear
  arcade adds animated Horse Racing and Plinko terminals inside Celadon too.
- Both tables are compact four-tile-wide assemblies with distinct green and
  blue felt, betting marks, cards, chips, and fully interactive front rails.
- Either table's dealer can explain the game and open its screen.
- Table graphics are built locally from authored pixel primitives and ship no
  copied Pokemon ROM art.

### Underground Battle Arena

Gamble Mode players who reach **KINGPIN**—4,000 High Roller REP and all eight
badges—can use a native Rocket status terminal on the west side of the Celadon
Lounge. Its two-cabinet facade covers the entire route, scans the player's
casino clearance, then retracts to reveal a walkable staircase into Rocket
Casino B1 and its separate B2 spectator floor:

- The lobby is a real checkpoint rather than a dialogue teleport. Permanent
  Rocket staff flank the counter while the player walks through a physical
  door into the pit; the player's party stays untouched.
- Both underground maps now use unmodified ROM tilesets and block IDs. B1 uses
  `LOBBY` blocks from the Celadon Game Corner and Diner for its machine banks,
  seats, counters, signs and roulette tables; B2 uses the same `GYM` blocks as
  Lorelei and Bruno for its ceremonial floor, spectator pockets, statues and
  League-style south entrance. No custom VIP atlas, furniture sprite or ring
  sprite is registered.
- The guarded B1 threshold is a real ROM door/warp. B2 then uses the Elite
  Four's familiar short walk-in pattern, so no invisible coordinate trigger can
  double-transition or strand the player between basement floors.
- Six B1 cabinet positions reuse the original Coin Case checks and native
  `SlotMachine` screen from their native seat cells. Red and Blue recolor both
  floors through Recomp's normal palette cycle on key `2`.

- The arena posts two house-owned Pokemon, their levels, and decimal odds
  before any wager is accepted. The player's party is never eligible.
- Match strength uses imported species base stats, level-scaled battle stats,
  curated moves, accuracy, Gen I type effectiveness, STAB, and the original
  physical/special type split.
- A 6% house margin is built into the posted prices, but an underdog can still
  win. The outcome is never changed after a ticket is placed.
- Wagers range from 50 to 10,000 coins. Any ticket whose maximum posted return
  would overflow the 1,000,000-coin Coin Case is refused before charging.
- STREET cards use ordinary fighters, ELITE adds stronger evolved Pokemon at
  250 arena REP, and RARE adds Lapras, Snorlax, Aerodactyl, Gyarados,
  Dragonite, and Alakazam at 900 arena REP.
- The complete ticket and animation plan are persisted before the fight.
  Reloading resumes the same match; settlement, payout, and reputation remain
  exactly once even after repeated inputs.
- A later Rocket Credit default blocks new luxury wagers, but a ticket already
  paid for always remains accessible and settleable.

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

- Every Pokemon prize offers **NORMAL** and **SHINY** purchase choices by
  default; **SHINY UPGRADES** can hide the paid shiny choice.
- Purchased shinies receive canonical Gen II-compatible shiny DVs rather than
  a temporary cosmetic flag, so their status persists in the save.
- With no dedicated shiny mod installed, all 151 Generation I species receive
  locally derived Pokemon Crystal palettes, an entrance animation and chime,
  a clear battle marker, and a Crystal-style status-screen icon.
- The fallback exposes separate **SHINY ANIMATION**, **SHINY CHIME**,
  **BATTLE MARKERS**, and **SHINY COLORS** settings. The existing sparkle
  preference is preserved as the animation setting.
- Ordinary members of the same species retain their normal artwork.

Blackjack Corner dynamically defers to a supported dedicated renderer when
one is installed, including **Gen II Shiny Indicators**, **SHINY_POKEMON**,
and the Crystal/Gen II shiny visual packs. This prevents duplicate sprite
hooks, markers, animations, and chimes.

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
| Horse Racing | Selection | Up / Down | Choose a runner |
| Horse Racing | Selection | Left / Right | Change the wager |
| Horse Racing | Selection | A | Place the ticket and start the race |
| Plinko | Selection | Left / Right | Change the wager |
| Plinko | Selection | A | Pay and drop the ball |
| Any machine | Ready / Result | B | Leave |

### Gamble Mode screens

| Screen | Control | Action |
| --- | --- | --- |
| Starter Roulette | Left / Right or Up / Down | Choose KEEP or SPIN ¥1000 |
| Starter Roulette | A | Confirm the highlighted option |
| Starter Roulette | B | Safely keep the current roll |
| Gym Case | A after the reel | Accept the reward and close the one-use case |
| Saved Gym Case | Start menu > GYM CASE | Retry delivery of the exact saved reward |

## Compatibility and limitations

- Blackjack Corner needs the Coin Case for table games, arcade machines,
  prize redemption, and the pawn broker.
- Gamble Mode is a new-save choice. It cannot be enabled retroactively from
  the options menu, and declining it leaves story rewards untouched.
- The Underground Arena is a Gamble Mode campaign destination and requires
  KINGPIN. The city casino network and seven earlier games remain available
  without it; CASE ACE trainers, Gym Cases, and story changes remain Gamble-only.
- Blackjack does not include splits, insurance, or surrender.
- Texas Hold'em is a custom house-banked game, not multiplayer poker.
- Nuzlocke 1.x and Nuzlocke 2's pre-game setup can share the new-game flow.
  Blackjack Corner defers Nuzlocke's post-Oak World Building dialogue until
  Oak has fully left, preventing the completed intro from becoming a white,
  input-blocking screen.
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
  horse_racing/ rules.lua  screen.lua  view.lua
  plinko/       rules.lua  screen.lua  view.lua
  battle_arena/ rules.lua  service.lua  screen.lua  view.lua
  starter_roulette/ rules.lua  screen.lua  view.lua
  shared/       ui.lua
other/
  gamble/       mode.lua  gym_cases.lua  state.lua  arena_world.lua
                arena_security.lua  arena_story.lua  story_world.lua
    reputation/ service.lua  screen.lua
    credit/     service.lua  ui.lua  world.lua  house_service.lua  house_world.lua
  pawn/         rules.lua
  prizes/       catalog.lua
  shiny/        fallback.lua
  coin_case.lua lounge.lua pallet_casino.lua services.lua ui.lua world_helpers.lua
main.lua        composition, registration, and hooks only
```

Modules are loaded through `mod:read()` so the layout remains compatible with
both unpacked development installs and packaged mod ZIPs.

Clone this repository into a Gen1Recomp checkout so it is located at
`mods/blackjack_corner`, then run these commands from the Gen1Recomp root:

```sh
python3 tools/modkit.py validate mods/blackjack_corner --base fixture
python3 tools/modkit.py lint mods/blackjack_corner
mods/blackjack_corner/tests/run_all.sh
```

The release workflow publishes an installable ZIP and SHA-256 checksum on
each release commit to `main`. Version numbers are sourced from
`manifest.json`.

## Credits and license

- Built for the [Pokemon Gen 1 Recompilation Project](https://github.com/bryanthaboi/gen1recomp).
- Original Pokemon Red disassembly and research by
  [pret/pokered](https://github.com/pret/pokered) contributors.
- Bundled fallback palette and presentation logic is adapted from
  [Gen II Shiny Indicators](https://github.com/Deftones565/gen1recomp-mod-shiny-indicators)
  by Deftones565; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- Blackjack Corner is maintained by [martin2844](https://github.com/martin2844).

Released under the [MIT License](LICENSE). Pokemon and related names are
trademarks of their respective owners. This is an unofficial fan-made mod and
is not affiliated with or endorsed by Nintendo, Game Freak, or The Pokemon
Company.
