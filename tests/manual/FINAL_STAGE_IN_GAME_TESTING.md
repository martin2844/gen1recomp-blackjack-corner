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

| ID | State and action | Expected result | Evidence |
| --- | --- | --- | --- |
| EXH-01 | Return to the pit with `EXHIBITION_INVITATION` and an unpaid ordinary card | The ordinary posting is replaced by the dedicated Series 3 card without deducting coins | Image + values |
| EXH-02 | Inspect Series 3 before betting | Dragonite L62 and Mewtwo L65, odds, committed winner, action list, and `GIOVANNI AUDIENCE` reward are persisted together | Image + values |
| EXH-03 | Bet, save, and reload before/during animation | The exact match id, pair, odds, selected fighter, stake, winner, actions, and reward resume with no second deduction | Values + animation |
| EXH-04 | Win Series 3 | The normal payout settles once, story advances to `GIOVANNI_CHOICE`, and the result directs the player out to Giovanni | Image + values |
| EXH-05 | Leave the result screen after a win | Giovanni appears physically in B2 with readable introductory dialogue | Image + navigation |
| EXH-06 | Lose Series 3, acknowledge, and retry | The invitation remains active, the loss counts once, and the fixed Dragonite/Mewtwo pairing returns under a new durable ticket | Image + values |
| EXH-07 | Repeat settlement/reload around both results | Reputation, coins, Arena history, attempt count, and story stage never duplicate or regress | Values |

## Giovanni choice and endings

| ID | State and action | Expected result | Evidence |
| --- | --- | --- | --- |
| END-01 | Talk to Giovanni after the Series 3 win | A clear `EXPOSE` / `CHAMPION` / `LEAVE` menu appears and cancelling changes nothing | Image + values |
| END-02 | Select either ending | Its distinct loss/gain consequences appear before a second YES/NO confirmation | Image |
| END-03 | Confirm EXPOSE on Red and CHAMPION on Blue | The selected ending and stage save exactly once, with readable ending copy | Image + values |
| END-04 | Say NO, leave, reopen, then confirm | Cancellation is non-mutating and the full choice remains available | Values + navigation |
| END-05 | Attempt to select the other ending after confirmation and reload | Giovanni gives ending-specific repeat copy; the first choice cannot change | Image + values |

Ending-specific world reactions, service changes, rewards, and ordinary-story
route checks remain reserved for Chunk E.

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
`CIN-05` in both ROMs. It also opened the Series 3 card, selected the committed
winner, watched the battle settle, and met the summoned Giovanni, passing
`EXH-04` and `EXH-05` in both ROMs. Evidence is under:

- Red: `/tmp/blackjack-corner-v060/story-red`
- Blue: `/tmp/blackjack-corner-v060/story-blue`
- Red exhibition: `/tmp/blackjack-corner-v060/exhibition-red`
- Blue exhibition: `/tmp/blackjack-corner-v060/exhibition-blue`

The same driver selected EXPOSE on Red and CHAMPION on Blue, displayed the
branch-specific consequence copy, and passed `END-03` for both branches.

The complete automated suite passes 1,659 assertions. The remaining fan
dialogue, participation pacing, repeat-contact, palette, route-integrity, and
economy permutations plus the native loss/reload exhibition paths stay open
until the ending-world and balance pass is complete.
