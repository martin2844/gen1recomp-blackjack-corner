# Manual v0.5 QA

The v0.5 campaign systems need human review as well as Lua assertions. These
drivers prepare a deterministic save, move the player to the feature under
test, capture a baseline screenshot, and then stop automating. The game keeps
running so a tester can take the keyboard and judge the complete E2E flow.

Run from the `gen1recomp` host repository with the development copy of this mod
at `mods/blackjack_corner`:

```sh
mkdir -p /tmp/blackjack-corner-v05/fresh
POKEPORT_DRIVER=/absolute/path/to/gen1recomp-blackjack-corner/tests/manual/drivers/high_roller_fresh.lua \
POKEPORT_IDENTITY=blackjack-corner-v05-fresh \
SHOT_DIR=/tmp/blackjack-corner-v05/fresh \
POKEPORT_IMPORT_ROM=./red.gb POKEPORT_FORCE_IMPORT=1 \
./love-11.5-x86_64.AppImage .
```

The import variables are only required the first time a new test identity is
used. For Blue, also set `POKEPORT_VERSION=blue` and import `blue.gb`.

Wait for `MANUAL CONTROL READY` in the terminal. From that point onward the
driver only yields and all controls belong to the tester. Keep a separate
identity and screenshot directory for every matrix row so save state and
evidence cannot leak between scenarios.

Before signing off a release:

1. Record the host SHA and mod SHA in the release checklist.
2. Run every required row in `MATRIX.md` on Red and Blue.
3. Save screenshots under an external evidence directory; generated evidence
   is intentionally not committed or included in release archives.
4. Note any visual, input, persistence, or balance issue before marking a row
   complete.
