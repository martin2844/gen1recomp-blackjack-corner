# Gamble Mode manual test matrix

| Scenario | Gamble | Save | Required checks |
| --- | --- | --- | --- |
| Fresh campaign | On | Fresh | Coin Case granted, campaign state created, High Roller screen readable |
| Rank-up | On | Prepared | One rank-up presentation, reward granted once, menu reflects new rank |
| Badge ceiling | On | Prepared | Points bank, rank remains locked, next badge requirement is explicit |
| Migration | On | v0.4 save | Existing party, coins, pawn ledger, and Gym Case queue survive |
| Base mode | Off | Fresh | Casinos and games work; campaign menu, reputation, and rank dialogue stay absent |
| Rocket credit | On | Prepared | Rookie offer is clear; borrow once; statement shows principal, fee, due badge |
| Credit repayment | On | Prepared | Coins and money reduce one ledger; fees clear first; full repayment restores CLEAR |
| Credit default | On | Prepared | Due badge applies one late fee once; repeated visits cannot grow debt |
| Pawn and pay | On | Prepared debt | Appraisal pays debt, surplus stays in Coin Case, ticket remains redeemable, FIFO warning still appears |
| Default consequences | On | Defaulted | Pallet/Celadon collectors appear; Prize Case and prize counters freeze; games, clerk, travel, healing, story and pawn redemption remain available |
| Default recovery | On | Defaulted | Full repayment restores luxury prizes and collectors disappear on the next map entry |
| Pawn family home | On | Any balance with 10,000 Coin Case capacity | Warning is explicit; YES adds exactly 10,000 once; NO changes nothing; debt remains independent |
| Repossessed house | On | Rocket-owned | Mom moves upstairs and still heals; Rockets/furniture appear; doors, stairs, PC, routes and story stay usable |
| House buyback | On | Rocket-owned + 30,000 coins | Exact deed cost is charged once and challenger replaces the ordinary tenant |
| House battle | On | Buyback paid | Loss remains retryable after reload; win restores the house exactly once |
| House restoration | On | Restored | Original Mom/home return; Rocket objects disappear; debt/default remain independent |

Run each row against both supported ROMs. Exercise at least one win and one
loss in every casino game before release: Blackjack, Hold'em, Crash, Tube
Flyer, Prize Case, Horse Racing, and Plinko.

For every game verify:

- stake is charged once;
- settlement is recorded once, including retries or screen exits;
- a loss still advances campaign statistics;
- reopening the game cannot duplicate reputation;
- text and controls fit at native 160x144 resolution.

The authoritative v0.6 case-by-case procedure is
[`V0.6_IN_GAME_TESTING.md`](V0.6_IN_GAME_TESTING.md).
