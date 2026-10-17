# TRI10NWARE — guide for AI sessions

TRI10NWARE is a Celeste-inspired precision platformer for the Tritonware game jam, built in Godot 4.5.1 with GDScript and shipped on itch.io (web, macOS, Windows).

## Source of truth

`docs/TRI10NWARE.md` is the single source of truth. It is long (about 2,000 lines), so **never read or import it whole**. Read the sections listed below, by heading, using search or line ranges.

Its authorities are `docs/reference/TRI10NWARE_design.pdf` (the design) and `docs/reference/TRI10NWARE_acceptance_criteria.pdf` (the acceptance criteria, cited by IDs like M-05 or C-07). Open them only when the spec points you there.

## Start of every session: read in this order

1. The **Status** block at the top of `docs/build_journal.md`: where work stands and what is next.
2. In the spec, **"How an AI developer works from this document"**: the session rules and the **authority tiers** (what you may decide alone, what you decide and log, what needs the owner).
3. **"Ground rules for the code"** and **"Determinism contract"**.
4. The step you were asked to do (for example "M0 step 4" or "M1 build order", step 3), plus every section that step names.
5. When relevant: **"Same-tick contract"** (in M1), **"Open decisions"**, **"Parked ideas and rejected decisions"**, **"Repository layout"**.

The usual way to start is the `/step` skill, for example `/step M0.4`.

## Commands

`$GODOT` is set in `.claude/settings.json`. Always quote it.

- Import (needed on a fresh clone and after moving assets): `"$GODOT" --headless --path game --import`
- Unit tests: `"$GODOT" --headless --path game res://tests/test_runner.tscn`
- Scenarios: `"$GODOT" --headless --path game --fixed-fps 60 -- --run-scenarios --quit-when-done`
- Once M0 step 10 exists: `tools/run_tests.sh` runs everything; `tools/export_all.sh` builds all targets.

Until M0 step 1 finishes, the old prototype project sits at the repository root instead of `game/`.

## Godot editor running alongside

- The owner keeps the Godot editor open. Its GDScript errors reach VS Code's Problems panel; check them with the diagnostics tool after editing scripts.
- Never edit a `.tscn` file that is open in the editor. Ask the owner to close that scene tab first, or ask them to reload it afterward.
- Godot creates `.uid` files beside new scripts and `.import` files beside assets. Commit them; never commit `.godot/`.
- The owner paints tiles (gym stations, levels) in the editor. Build the scene's nodes and entrances, then hand off and wait.

## Never

- Edit `docs/TRI10NWARE.md`, anything in `docs/reference/`, or owner art without approval. Propose the change and wait.
- Create a code file the spec does not list, change a rule, tuning default or AC value, or add a feature (authority tiers).
- Overwrite an asset whose `CREDITS.md` status is `owner draft` or `final`.
- Push to GitHub. The owner pushes.
- Leave a decision only in chat. Chat is gone next session; decisions go in the spec (with approval), `docs/decision_log.md`, or the build journal.

## Every step ends with

1. Tests passing (and diagnostics clean).
2. A decision-log entry for every "decide and log" choice (before M0 step 11 creates `docs/decision_log.md`, record them in the build journal).
3. A build journal entry, plus an updated Status block.
4. A commit named `M<n> step <k>: <title>`.
