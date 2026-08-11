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

| ID | State and action | Expected result | Evidence |
| --- | --- | --- | --- |
| CIN-01 | Visit the Lab and Mansion before `CINNABAR_LEAD` | Both story contacts are absent; native NPCs, items, trainers, signs, and routes are unchanged | Navigation + values |
| CIN-02 | Enter the Metronome Room after completing the lead | A native Rocket handler appears without blocking either exit or the room's scientists/PC | Image + navigation |
| CIN-03 | Talk to the handler | Stage becomes `CINNABAR_INVESTIGATION`; authenticated `LAB_ARCHIVE` is recorded once | Image + values |
| CIN-04 | Enter Mansion B1 after handler contact | A native scientist contact appears near the diary without blocking the Secret Key, items, trainer, diary, or exit | Image + navigation |
| CIN-05 | Talk to the Mansion contact | `MANSION_LOG` is recorded and stage becomes `EXHIBITION_INVITATION` exactly once | Image + values |
| CIN-06 | Revisit both contacts and save/reload on each map | Repeat dialogue appears; stage and both records persist with no duplicated transition | Image + values |
| CIN-07 | Complete the investigation with the family home in every state and with clear/active/default debt | Story progression does not rewrite debt, house, party, Bag, PC, pawns, or coins | Values |

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
through a real disk save/restore, opened the completed-lead greeter dialogue,
met the Cinnabar Lab handler, and recovered the Mansion B1 specimen log. The
native interactions passed `STORY-03`, `STORY-09`, `STORY-10`, `CIN-03`, and
`CIN-05` in both ROMs. Evidence is under:

- Red: `/tmp/blackjack-corner-v060/story-red`
- Blue: `/tmp/blackjack-corner-v060/story-blue`

The complete automated suite passes 1,602 assertions. The remaining fan
dialogue, participation pacing, repeat-contact, palette, route-integrity, and
economy permutations stay open until the whole Cinnabar chapter is present.
