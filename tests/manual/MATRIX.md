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

Run each row against both supported ROMs. Exercise at least one win and one
loss in every casino game before release: Blackjack, Hold'em, Crash, Tube
Flyer, Prize Case, Horse Racing, and Plinko.

For every game verify:

- stake is charged once;
- settlement is recorded once, including retries or screen exits;
- a loss still advances campaign statistics;
- reopening the game cannot duplicate reputation;
- text and controls fit at native 160x144 resolution.
