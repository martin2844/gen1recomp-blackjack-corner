# Casino network in-game testing plan

This gate covers the randomizer handoff, eight regional branches, themed Gym
Cases, and post-Gym CASE ACE encounters. Run every row on Red and Blue with a
fresh identity. Yellow remains experimental and should receive a separate
one-ball starter pass before its support status changes.

## Starter/randomizer compatibility

- [ ] `COMPAT-01` Enable `pokemon_randomizer` with wild encounters, trainers,
  and starters randomized; then start a new Gamble Mode save and enter Oak's
  Lab. The three-piece cabinet opens Blackjack Corner's roulette rather than
  the Randomizer's three starter-ball offers.
- [ ] `COMPAT-02` Complete the player and rival rolls. Both starters follow
  Gamble Mode's saved results and the Lab rival battle remains reachable. Then
  confirm one wild encounter and one non-rival trainer still use the active
  Randomizer seed.
- [ ] `COMPAT-03` Start another randomized save with Gamble Mode disabled.
  Oak's three starter balls use the Randomizer's saved species, level, and
  rival counterpick exactly as they do without Blackjack Corner installed.

## Regional casino route

Visit Pallet, Viridian, Pewter, Cerulean, Vermilion, Lavender, Celadon,
Fuchsia, Saffron, and Cinnabar.

- [ ] `CITY-01` Every city has a readable named casino sign and an unobstructed
  entrance. Seven regional branches open directly from the overworld;
  Cinnabar's sign points through the Pokemon Lab to its preserved trade room.
- [ ] `CITY-02` Every compact branch has readable local dialogue, blackjack,
  Hold'em, coin sales, and its advertised local machine.
- [ ] `CITY-03` Every table/machine can be approached, opened, cancelled, and
  reopened; no cabinet, NPC, wall, or double-door cell traps the player.
- [ ] `CITY-04` Exit both door cells in every branch and re-enter after a disk
  save/restore. The correct city and doorway are preserved.
- [ ] `CITY-05` In Cerulean, verify both original exterior doors return to the
  correct casino exit. In Cinnabar, enter through the Lab and verify its
  ordinary entrance plus the original scientist/trades still work before and
  after using all casino services.
- [ ] `CITY-06` Progress the ordinary story through every affected city.
  Required Gyms, marts, Centers, routes, Oak flow, Safari Zone, Silph, Lab,
  Mansion, and Fly destinations remain available.

## Themed Gym Cases

- [ ] `GYM-01` Beat all eight leaders in separate prepared saves. Their speech
  names or evokes Rock, Water, Electric, Grass, Venom, Psychic, Fire, or Earth
  and opens the case over the visible Gym scene.
- [ ] `GYM-02` Audit at least three full reels per leader. Every card belongs
  to that leader's theme, no Nidoran filler appears, and identical prizes never
  occupy adjacent reel slots.
- [ ] `GYM-03` Confirm each pool can surface Pokemon, TMs, and supporting
  items; Giovanni's Master Ball remains extremely rare rather than guaranteed.
- [ ] `GYM-04` Fill the relevant storage before delivery, save/reload, free
  space, and retry from Start. The exact reward survives and is delivered once.

## CASE ACE encounters

- [ ] `ACE-01` Before each matching badge, confirm the city's CASE ACE is
  absent and does not block the casino door, sign, NPCs, or route.
- [ ] `ACE-02` Earn the badge and re-enter the city. The challenger appears,
  uses local pre-battle dialogue, and every team member is above the nearby
  leader's maximum level.
- [ ] `ACE-03` Lose each fight once. Normal blackout/recovery works and the
  trainer remains available without granting or queuing a case.
- [ ] `ACE-04` Win each fight. The loss line appears on the battle screen, the
  overworld reward dialogue follows, and one matching themed case opens.
- [ ] `ACE-05` Save/reload before case delivery, deliver it, then revisit and
  trigger an ordinary map victory hook. No second case, payout, or queue entry
  is created.
- [ ] `ACE-06` Disable Gamble Mode in a separate new save. No CASE ACE appears;
  all city casinos remain usable as base-mod content.

## Release evidence

- [x] Record host/mod SHAs and ROM SHA-1s.
- [x] Capture one exterior and one interior screenshot per regional branch.
- [ ] Capture one themed reel and one CASE ACE reward flow per badge.
- [x] Run the full Lua suite, imported validation, lint, pack inspection, and
  the two automated native release drivers before signing a release checklist.

## v0.7.0 executed native gate

On 2026-08-12, `casino_network_audit.lua` passed on imported Red and Blue. It
physically entered and exited every branch (including Cinnabar through the
Lab), opened and cancelled Blackjack, Hold'em, and the local machine through
their overworld objects, verified all eight post-badge CASE ACE objects, audited
all eight unique ten-prize Gym pools, and captured the themed Water Case reel.
The run produced 16 exterior/interior branch screenshots per ROM.

`randomizer_compat_audit.lua` also passed against the real
`pokemon_randomizer` v0.46.4 on Red and Blue with Gamble Mode enabled, plus a
separate Red handoff with Gamble Mode disabled. The native hook chain retained
randomized wild encounters and ordinary trainer parties while Oak's physical
cabinet opened Blackjack Corner's roulette only in Gamble Mode.

Rows above that require eight full Gym victories, eight battle losses/wins, or
per-case storage recovery remain intentionally unchecked; automated service and
integration coverage protects those invariants, but this document does not
mislabel them as supervised play.
