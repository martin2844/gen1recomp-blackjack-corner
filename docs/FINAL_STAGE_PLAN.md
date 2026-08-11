# Final Gamble Mode Stage

Status: COMPLETE — RELEASE GATE PASSED  
Branch: `feat/v0.6-arena-story`  
Public target: `v0.6.0`  
Base release: `v0.5.2`

## Goal

Turn the Underground Arena from a standalone spectacle into the conclusion of
Gamble Mode. The ending must grow out of the systems already in the mod:
casino reputation opens the route, Arena participation exposes the operation,
Cinnabar explains the engineered fighters, and Giovanni forces a final choice.

The base Casino Expansion remains unchanged. Players who declined Gamble Mode
must never see the campaign state, clues, handlers, exhibition, or ending
consequences.

## Release shape

The final stage is built in five independently testable chunks. Each chunk must
leave saves loadable, the Arena playable, and all vanilla story routes open.

### A. Arena rumor trail

- Add schema-five story state without rewriting existing campaign fields.
- Hide three persistent records in existing Arena dialogue and props.
- Make the records appear through participation rather than arbitrary grinding:
  - the concealed Giovanni frame is available on entry;
  - the Cinnabar cage manifest appears after three Arena matches;
  - the signed Fuji chart appears after six Arena matches.
- Reading a record twice never advances twice.
- Completing all three records opens the `CINNABAR_LEAD` stage and changes
  permanent staff dialogue.

This chunk is implemented on the final-stage branch.

### B. Cinnabar contact

- Add a Rocket handler to an existing, reachable Cinnabar interior using native
  ROM tiles and sprites.
- Keep the ordinary Lab, Mansion, Gym, Center, Mart, Fly destination, and island
  exits untouched.
- Require the Arena lead before the handler reveals anything.
- Use two short investigative beats: a lab archive and a Mansion specimen log.
- Return the player to Celadon with an authenticated exhibition invitation.

Chunks A and B now have their state, services, native contacts, dialogue, and
automated coverage on the feature branch. Their focused Red/Blue route passes;
the cumulative repeat, palette, and compatibility permutations remain open
while the Giovanni finale is built.

### C. Engineered exhibition

- Add a dedicated exhibition card to the existing Arena board.
- Commit the complete fighter pair, odds, result, wager, and story reward before
  animation, using the same durable ticket guarantees as ordinary matches.
- Give engineered fighters visible but Gen-I-readable traits: unusual legal
  moves, tuned levels/stats, and special introductions—not invented types or
  impossible battle rules.
- Losing remains recoverable and cannot reroll the committed opponent.
- Winning summons Giovanni and moves the campaign to its choice stage.

Chunk C is implemented on the feature branch. The Series 3 card fixes
Dragonite against Mewtwo, persists its complete priced battle and Giovanni
audience reward before animation, survives service reloads, records losses as
recoverable attempts, and summons a native Giovanni actor after a win. Red and
Blue have passed the focused winning UI path; native loss/reload permutations
remain in the final cumulative gate.

### D. Giovanni finale

- Present two explicit, separately confirmed choices:
  - **EXPOSE**: release the evidence and damage Rocket control of the casinos;
  - **CHAMPION**: protect the operation and become its public house champion.
- Show the exact irreversible consequence before confirmation.
- Save the choice before any ending presentation.
- Never remove badges, essential items, travel, healing, existing prizes, or
  the ability to finish the ordinary Pokemon story.

Chunk D is implemented on the feature branch. Giovanni presents EXPOSE,
CHAMPION, and LEAVE through native UI; each irreversible branch shows its own
consequences and requires a second YES/NO confirmation. The committed ending
is monotonic and survives sanitation/reload. Red has passed EXPOSE and Blue has
passed CHAMPION through the physical B2 actor.

### E. Ending world and balance

- EXPOSE changes Rocket staff, selected gamblers, the Arena board, and luxury
  services while keeping all games available.
- CHAMPION changes VIP greetings, unlocks the final exhibition reward, and gives
  the player a permanent title without making the economy infinite.
- Both endings update Pallet, Celadon, Cinnabar, the family-home state, and the
  High Roller panel consistently.
- Rebalance Arena/story rewards against the 1,000,000 Coin Case cap.
- Complete supervised Red and Blue playthroughs and package validation.

Chunk E is implemented and release-tested. EXPOSE closes only future
Rocket loans while preserving repayment, every game, every prize service, and
all routes. CHAMPION grants a one-time 25,000-coin reward that credits only
available Coin Case space and keeps the remainder banked. Both endings now
change the High Roller title and selected dialogue in Pallet, Celadon,
Cinnabar, the Arena floors, and an occupied family home. Red completed EXPOSE
with an old debt and Blue completed CHAMPION at the Coin Case boundary. Both
branches passed cancellation, reload, immutable-choice, reactive-world, and
service-access checks alongside the cumulative 49-case credit/home and 37-case
Arena regressions on both ROMs.

## Persistent state

Schema five adds the Arena rumor trail; schema six extends the same sibling
document for the Cinnabar investigation; schema seven adds the exhibition
ledger; schema eight records the irreversible Giovanni decision; schema nine
adds cap-safe, exactly-once ending reward delivery:

```lua
story = {
  stage = "ROCKET_EXPOSED",
  clues = {
    CINNABAR_FRAME = true,
    CAGE_MANIFEST = true,
    FUJI_CHART = true,
    LAB_ARCHIVE = true,
    MANSION_LOG = true,
  },
  exhibition = {
    attempts = 1,
    wins = 1,
    lastMatchId = 42,
  },
  ending = {
    choice = "EXPOSE",
    rewardPending = 0,
    rewardClaimed = true,
  },
}
```

Later chunks extend this document only through ordered migrations. Story
services own chapter transitions; map dialogue may request a transition but
must not mutate the campaign table directly. Unknown future fields and future
schema numbers survive older builds.

Initial stages:

```text
ARENA_RUMORS
    |
    | three unique records + six Arena matches
    v
CINNABAR_LEAD
    |
    | meet the Lab handler and recover the Mansion log
    v
EXHIBITION_INVITATION
    |
    | win the committed Series 3 exhibition
    v
GIOVANNI_CHOICE
    |                 |
    | EXPOSE          | CHAMPION
    v                 v
ROCKET_EXPOSED    HOUSE_CHAMPION
```

Later stage names and their fields are added only in the chunk that implements
their complete transition and recovery behavior.

## Narrative voice

- Rocket staff are controlled, threatening, and economical with words.
- Gamblers reveal information accidentally through bragging, fear, and sunk
  costs rather than delivering exposition.
- Researchers speak clinically and avoid cartoon-villain confessions.
- Giovanni treats the player as a useful operator, not a chosen hero.
- Every text page must fit native Gen-I dialogue limits and remain readable in
  Red and Blue palettes.

## Release blockers

1. Story progress is opt-in, save-scoped, monotonic, and idempotent.
2. Schema-four saves retain every Arena result, balance, pawn, debt, home, Gym
   Case, party, Bag, and PC value.
3. No clue or ending can be earned in base mode.
4. Participation gates use completed Arena matches, never raw coin losses.
5. Exhibition matches preserve the Arena's commit-before-animation guarantee.
6. Final choice is explicit, irreversible, and confirmed with consequence copy.
7. Neither ending disables a game or required Pokemon route.
8. Every chunk adds automated tests and updates the manual matrix.
9. Red and Blue native UI/E2E signoff is mandatory before `v0.6.0`.

## Completed release gate

- 1,671 automated Lua assertions.
- 34 final-stage matrix rows exercised across Red and Blue, including every
  story transition and both ending-specific economy paths.
- 49 credit/home regression cases and 37 Arena regression cases passed per ROM.
- Fixture and imported Red/Blue validation, ROM-derived-content lint, and a
  64-file release-shaped package passed.
- Six final-stage screenshots are cataloged in `assets/screenshots/` and kept
  out of the install archive.
