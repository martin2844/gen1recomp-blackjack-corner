# Final-stage in-game testing

This is the evolving native Red/Blue gate for public `v0.6.0`. Automated tests
prove state transitions and idempotency; these cases verify physical access,
dialogue, presentation, pacing, save/reload, and story continuity.

## Arena rumor trail

| ID | State and action | Expected result | Evidence |
| --- | --- | --- | --- |
| STORY-01 | Load a schema-four v0.5.2 save with Arena history | Story starts at `ARENA_RUMORS`; all old campaign and Pokemon state is unchanged | Values |
| STORY-02 | Decline Gamble Mode and inspect Arena/story APIs | No story state or clue is exposed | Values |
| STORY-03 | Reveal B1 and inspect Giovanni's painting | The frame yields `CINNABAR_FRAME`, shows CLUES 1 OF 3, and remains readable | Image + values |
| STORY-04 | Inspect the same painting again and reload | Repeat copy appears; count remains one | Image + values |
| STORY-05 | Talk to the wing spectator before three matches | Ordinary rumor dialogue appears; no manifest is awarded | Image + values |
| STORY-06 | Complete three matches and talk again | The Cinnabar West cage manifest appears exactly once | Image + values |
| STORY-07 | Talk to the medic spectator before six matches | Ordinary curtain dialogue appears; no chart is awarded | Image + values |
| STORY-08 | Complete six matches and talk again | The Fuji chart appears; all three records advance to `CINNABAR_LEAD` | Image + values |
| STORY-09 | Talk to both B1 guards after completing the lead | Staff direct the player to Cinnabar Lab's west wing in distinct, fitting dialogue | Image |
| STORY-10 | Save/reload in B1 and B2 after completion | Stage, three clues, Arena history, route, collision, and exits persist | Values + navigation |
| STORY-11 | Cycle palette key `2` during every new page | Text remains readable and world props retain native palette behavior | Image |

## Cinnabar contact

Reserved for Chunk B: handler access, Lab/Mansion clues, vanilla-route
regressions, invitation persistence, and return to Celadon.

## Engineered exhibition

Reserved for Chunk C: committed exhibition card, odds, win/loss/reload,
animation, reward delivery, and no-reroll guarantees.

## Giovanni choice and endings

Reserved for Chunks D-E: consequence copy, cancel behavior, both irreversible
choices, ending world reactions, services, rewards, and ordinary story access.

## Final signoff

- [ ] Every implemented row passes on Pokemon Red.
- [ ] Every implemented row passes on Pokemon Blue.
- [ ] All new dialogue fits native text boxes with no clipped choice.
- [ ] Schema-four migration and future-schema preservation pass.
- [ ] No Arena, casino, town, Gym, Lab, Mansion, healing, PC, or travel route is blocked.
- [ ] Complete automated suite, fixture/imported validation, ROM-content lint,
  release package inspection, and published checksum verification pass.

## 2026-08-11 foundation smoke

The focused `final_story_foundation.lua` driver passed on imported Pokemon Red
and Blue. It physically read the B1 painting, persisted the complete lead
through a real disk save/restore, and opened the completed-lead greeter
dialogue. Evidence is under:

- Red: `/tmp/blackjack-corner-v060/story-red`
- Blue: `/tmp/blackjack-corner-v060/story-blue`

The complete automated suite passes 1,588 assertions. The remaining fan
dialogue, participation pacing, palette, and navigation rows stay open until
the whole Cinnabar chapter is present.
