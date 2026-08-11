# Final Gamble Mode Stage

Status: IN PROGRESS  
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

This chunk is the foundation currently under implementation.

### B. Cinnabar contact

- Add a Rocket handler to an existing, reachable Cinnabar interior using native
  ROM tiles and sprites.
- Keep the ordinary Lab, Mansion, Gym, Center, Mart, Fly destination, and island
  exits untouched.
- Require the Arena lead before the handler reveals anything.
- Use two short investigative beats: a lab archive and a Mansion specimen log.
- Return the player to Celadon with an authenticated exhibition invitation.

### C. Engineered exhibition

- Add a dedicated exhibition card to the existing Arena board.
- Commit the complete fighter pair, odds, result, wager, and story reward before
  animation, using the same durable ticket guarantees as ordinary matches.
- Give engineered fighters visible but Gen-I-readable traits: unusual legal
  moves, tuned levels/stats, and special introductions—not invented types or
  impossible battle rules.
- Losing remains recoverable and cannot reroll the committed opponent.
- Winning summons Giovanni and moves the campaign to its choice stage.

### D. Giovanni finale

- Present two explicit, separately confirmed choices:
  - **EXPOSE**: release the evidence and damage Rocket control of the casinos;
  - **CHAMPION**: protect the operation and become its public house champion.
- Show the exact irreversible consequence before confirmation.
- Save the choice before any ending presentation.
- Never remove badges, essential items, travel, healing, existing prizes, or
  the ability to finish the ordinary Pokemon story.

### E. Ending world and balance

- EXPOSE changes Rocket staff, selected gamblers, the Arena board, and luxury
  services while keeping all games available.
- CHAMPION changes VIP greetings, unlocks the final exhibition reward, and gives
  the player a permanent title without making the economy infinite.
- Both endings update Pallet, Celadon, Cinnabar, the family-home state, and the
  High Roller panel consistently.
- Rebalance Arena/story rewards against the 1,000,000 Coin Case cap.
- Complete supervised Red and Blue playthroughs and package validation.

## Persistent state

Schema five adds one sibling document:

```lua
story = {
  stage = "ARENA_RUMORS",
  clues = {
    CINNABAR_FRAME = true,
    CAGE_MANIFEST = true,
    FUJI_CHART = true,
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
