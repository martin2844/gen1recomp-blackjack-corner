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
| STORY-09 | Talk to the B1 greeter after completing the lead | Staff direct the player to Cinnabar Lab's west wing in fitting dialogue | Image |
| STORY-10 | Save/reload after completing the lead | Stage and all three clues persist | Values |
| STORY-11 | Cycle palette key `2` on the completed-lead story page | Text remains readable and world props retain native palette behavior | Image |

## Cinnabar contact

| ID | State and action | Expected result | Evidence |
| --- | --- | --- | --- |
| CIN-01 | Synchronize the Lab and Mansion contacts before `CINNABAR_LEAD` | Both story contacts remain hidden | Values |
| CIN-02 | Load the Metronome Room after completing the lead | A native Rocket handler appears at its registered contact position | Image + values |
| CIN-03 | Talk to the handler | Stage becomes `CINNABAR_INVESTIGATION`; authenticated `LAB_ARCHIVE` is recorded once | Image + values |
| CIN-04 | Load Mansion B1 after handler contact | A native scientist contact appears at its registered diary position | Image + values |
| CIN-05 | Talk to the Mansion contact | `MANSION_LOG` is recorded and stage becomes `EXHIBITION_INVITATION` exactly once | Image + values |
| CIN-06 | Repeat the Mansion record and save/reload after the invitation | Stage and both records persist with no duplicated transition | Values |
| CIN-07 | Complete the investigation with clear debt and the family home intact | Story progression does not rewrite that debt or house state | Values |

## Engineered exhibition

| ID | State and action | Expected result | Evidence |
| --- | --- | --- | --- |
| EXH-01 | Return to the pit with `EXHIBITION_INVITATION` and an unpaid ordinary card | The ordinary posting is replaced by the dedicated Series 3 card without deducting coins | Image + values |
| EXH-02 | Inspect Series 3 before betting | Dragonite L62 and Mewtwo L65, odds, committed winner, action list, and `GIOVANNI AUDIENCE` reward are persisted together | Image + values |
| EXH-03 | Bet, save, and reload before/during animation | The exact match id, pair, odds, selected fighter, stake, winner, actions, and reward resume with no second deduction | Values + animation |
| EXH-04 | Win Series 3 | The normal payout settles once, story advances to `GIOVANNI_CHOICE`, and the result directs the player out to Giovanni | Image + values |
| EXH-05 | Leave the result screen after a win | Giovanni appears physically in B2 with readable introductory dialogue | Image + navigation |
| EXH-06 | Lose Series 3, acknowledge, and retry | The invitation remains active, the loss counts once, and the fixed Dragonite/Mewtwo pairing returns under a new durable ticket | Image + values |
| EXH-07 | Repeat settlement and disk-reload around the loss result | Reputation, coins, Arena history, attempt count, and story stage never duplicate or regress | Values |

## Giovanni choice and endings

| ID | State and action | Expected result | Evidence |
| --- | --- | --- | --- |
| END-01 | Talk to Giovanni after the Series 3 win | A clear `EXPOSE` / `CHAMPION` / `LEAVE` menu appears | Image + values |
| END-02 | Select either ending | Its distinct loss/gain consequences appear before a second YES/NO confirmation | Image |
| END-03 | Confirm EXPOSE on Red and CHAMPION on Blue | The selected ending and stage save exactly once, with readable ending copy | Image + values |
| END-04 | Say NO at the consequence confirmation, then confirm | Cancellation is non-mutating and the full choice menu remains available | Values |
| END-05 | Attempt to select the other ending after confirmation and reload | Giovanni gives ending-specific repeat copy; the first choice cannot change | Image + values |
| END-06 | Confirm EXPOSE with old debt, repay it, and request another loan | Existing debt remains payable, luxury access returns when clear, and new Rocket loans stay closed | Values |
| END-07 | Confirm CHAMPION below and near the Coin Case cap | Exactly 25,000 coins are granted once; only available room is credited and the remainder stays banked until room exists | Image + values |
| END-08 | Across paired Red/Blue runs, open High Roller and revisit Pallet, Celadon, Cinnabar, B1, B2, and an occupied family home | The title and selected NPC dialogue consistently reflect EXPOSE or CHAMPION | Image + values |
| END-09 | Save/reload after either ending and recheck the Arena, luxury-credit gate, and occupied house | Ending, reward ledger, Arena access, cleared-credit authorization, and house state persist | Values |

## Final signoff

- [x] The strengthened maintenance driver passes on Pokemon Red.
- [x] The strengthened maintenance driver passes on Pokemon Blue.
- [x] All new dialogue fits native text boxes with no clipped choice.
- [x] Schema-four migration and future-schema preservation pass.
- [ ] Supervised Cinnabar Lab and Mansion route traversal is still required
  before the next release; object registration and dialogue alone are not
  accepted as navigation evidence.
- [x] Complete automated suite, fixture/imported validation, ROM-content lint,
  release package inspection, and local checksum verification pass.

## 2026-08-11 final-stage release gate

The focused `final_story_foundation.lua` driver passed on imported Pokemon Red
and Blue. It physically read the B1 painting, persisted the complete lead
through a real disk save/restore, opened the completed-lead greeter dialogue,
met the Cinnabar Lab handler, and recovered the Mansion B1 specimen log. The
native interactions passed `STORY-03`, `STORY-09`, `STORY-10`, `CIN-03`, and
`CIN-05` in both ROMs. It also opened the Series 3 card, selected the committed
winner, watched the battle settle, and met the summoned Giovanni, passing
`EXH-04` and `EXH-05` in both ROMs. Evidence is under:

- Red complete path: `/tmp/blackjack-corner-v060/release-red`
- Blue complete path: `/tmp/blackjack-corner-v060/release-blue`

The release driver reported all 34 identifiers across the two branches. A
post-release audit found that several broad navigation/availability labels were
backed only by API checks or teleports; the rows above now state only what that
evidence actually proved. The driver first
cancelled Giovanni's consequence confirmation, then selected EXPOSE on Red and
CHAMPION on Blue. Red carried and repaid an old Rocket debt after exposure;
Blue entered at 990,000 coins, credited 10,000, banked 15,000, later delivered
the remainder, and proved the reward could not repeat. Both endings survived a
real disk restore, refused the opposite choice, kept Arena/luxury access, and
opened reactive dialogue in Pallet, Celadon, Cinnabar, B1, B2, and the occupied
family home.

The published v0.6.0 automated suite passed 1,671 assertions; the current
maintenance suite passes 1,687. The 49-case credit/home
and 37-case Arena regression drivers also passed independently on Red and Blue.
Fixture/imported validation, ROM-content lint, and the 64-file release-shaped
package passed without development-file leakage. The current maintenance driver
now performs a real mid-animation restore plus native loss/retry and ledger
checks; its maintenance rerun passed on both ROMs with evidence under
`/tmp/gen1-final-review.cFtOPH/red2` and
`/tmp/gen1-final-review.cFtOPH/blue`. The unsigned Cinnabar navigation row must
still be completed before the next release is signed.
