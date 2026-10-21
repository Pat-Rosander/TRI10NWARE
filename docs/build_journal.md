# TRI10NWARE build journal

Every step of the build adds an entry here, newest at the bottom. The Status block below is updated at the end of every step; it is the first thing each new session reads.

## Status

- **Last completed:** M4 step 1, spike rules, 2026-10-21: spike cells and hitboxes in `SolidGrid`, contact at every pixel of the move, step 10's spike death, the two spike tuning fields, `test_spikes.gd`, and the `spikes` gym entrance (gym widened to 5760 px). The spec now has an **M4 build order** (owner, 2026-10-21; M4 is built ahead of Level 2). Earlier: M3 step 6 (ship, 0.2.0 builds from `4357afe`; owner approved movement and visuals, web check still open), M3 steps 1–5, M2 step 5 (HUD), with placeholder art; the six M2 gym stations and part of the M1 gym are still unpainted (details below).
- **Next step:** M4 step 2, overlap policy (`/step M4.2`): `overlap_policy.gd` and its test, pending tiles in `solid_grid.gd`, the policy on every switch in `flow_controller.gd`, the step 7 pending re-check in `player.gd`, and `test_platforms.gd` (spec, **M4 build order**). It does not need the owner's platform art: its tests build grids in code. If the owner has set the spike tiles' `solidity` by then, first update `test_level_tiles_resource` to the new tiles (see M4.1 "How to see it"). Still postponed: **M1 steps 7–9** and M3's gate evidence (spec, **Postponed work**). Do not build them, or anything that waits on them, unless the owner asks. No session does itch.io work.
- **Added 2026-10-21: M3 step 7, music and volume** (`/step M3.7`; spec, M3 build order). It can run any time, before or between M4 steps: the owner's music loops on the Music bus from the title's dismissal, and the pause menu gains a music volume slider. Afterwards, run M3 step 6 (ship) again for a new build. The completion sound is already in its slot (`room_complete.wav`).
- **Waiting on the owner:**
    - **M4.1:** set the spike tiles' `solidity` (4 up, 5 down, 6 left, 7 right) in the TileSet panel; open `game/core/solid_grid.gd` and `game/tests/unit/test_spikes.gd` once for diagnostics; paint the `spikes` station (painting guide in the M4 step 1 entry); playtest it, especially that a held jump grazes the ceiling spikes and lives. If `gym.tscn` or `room_catalog.tres` was open, let Godot reload them.
    - **M3.6 ship checks:** movement and visuals approved (owner, 2026-10-21; decision log M3.6). Still open: (1) the **web pause and focus check** in Chrome, Safari and Firefox (switch tabs, click outside the canvas, switch apps), which the owner runs last. It is untested and at risk: `main.gd` pauses only on the *application* focus notification, which the web runtime may not send; a failure goes to `known_issues.md` with a spec fix *proposed*. (2) Any builds not yet played (macOS from its itch.io zip, Windows on the PC, web). (3) Make the itch.io page and upload `builds/itch/*`. 13 placeholders still ship (list in the M3 step 6 entry).
    - **M3.5 check:** follow "How to see it" in the M3 step 5 entry (open `game/audio/sfx.gd`, `game/world/effects.gd` and `game/tests/unit/test_feedback.gd` for diagnostics, reload `main.tscn` if Godot asks, press F5 and listen). Confirm the license of your 8 WAVs in `CREDITS.md`. Replace `effects.png` (then its frames in `effects_frames.tres`) and the three silent WAVs whenever you like. Optionally approve fixing the spec layout's stale "13 unit-test files" (now 17).
    - **M3.4 check:** follow "How to see it" in the M3 step 4 entry (open the three scripts for diagnostics, reload `level_1.tscn`/`gym.tscn`, look at the Inspector's **Frames** and **Glow Texture**). Add your charged-object types whenever you like ("To add a type" in that entry).
    - **M3.2 check:** open `game/world/main.gd`, `game/ui/title_overlay.gd`, `game/ui/pause_menu.gd` and `game/ui/completion_overlay.gd` once so the editor analyzes them (diagnostics). Then press F5 and follow "How to see it" in the M3 step 2 entry. Accept if Godot asks to re-save `main.tscn` or the new overlay scenes.
    - **M3.3 check:** follow "How to see it" in the M3 step 3 entry (open the four scripts for diagnostics, reload the three scenes, press F5 and Z). Optionally approve the "off-screen" → "invisibly, on screen" wording for the spec's `title_overlay.gd` row. Replace `level_1_backdrop.png` with your backdrop whenever you like.
    - **Level 1 (M3 step 1):** painted (commit `4cf3a1b`). Playtest: (1) the charged crossing (jump, Z for flow, jump again inside the ring, dash); (2) **try to cross with jump and dash only**. If (2) succeeds, widen the gap; if (1) fails, narrow it or move the object. Nothing automatic checks either until the postponed bypass search runs. Also open `game/objects/goal/goal_zone.gd` and `game/tests/unit/test_goal_zone.gd` once so the editor analyzes them (diagnostics). If `room_catalog.tres` was open in the Inspector, let Godot reload it.
    - **M2.5 check (also M2 step 6's done-when HUD check; tick it in the spec's M2 done-when when it passes):** open `game/ui/hud.gd` once so the editor analyzes it (diagnostics), then press F5 and press Z a few times: pips empty, the icon turns cyan, then red at 0 volts, a 3-second countdown appears top center, and a refused switch flashes the pips. Confirm the font's license (believed CC0) and source link in `CREDITS.md`. Replace the five M2.5 placeholders whenever you like (layouts in the M2 step 5 entry).
    - **Only for the postponed M1 step 8:** paint the six M2 gym stations (columns 160–319), following the painting guide in the M2 step 4 entry. The gym is now 5120 px wide, and the orange bounds outline shows the new area. Open `charged_object.tscn` once and check the ring still shows at 64 px: its `region_radius_px` is back to −1 (tuning). If not done yet, also open `charged_object.gd` and `game/tests/unit/test_charged_jump.gd` once so the editor analyzes them.
    - `CREDITS.md` lists `game/art/player/player_frames.png`, but the owner's commit `a29f319` renamed it to `player_sheet_v1.png` (`player_frames.tres` points there): update that row (and the slot-name question below may now be answered).
    - **Finish the gym** before the postponed M1 step 8 (painting guide in the M1 step 5 entry; details in the M1 step 6 entry, "Gym check"). Move the `WallShaft` marker (x 976) and the `CornerCeiling` marker (x 1480) out of the solid tiles. Give `dash_chamber`, `coyote_ledge` and `buffer_drop` their floors (from column 100 on, row 26 is open to the pit), and finish `corner_ceiling` and the 12 × 8 dash chamber box. While `gym.tscn` is open in the editor, no session may edit it.
    - Answer the slot-name question below, and confirm the license of `game/art/player/player_frames.png` in `CREDITS.md`.
    - Review `docs/support_matrix.md`, and fill in each row you test (OS or browser version, hardware, build ID).
    - The M0 step 10 build check is now part of the M3.6 ship checks above (same builds, newer commit). Optionally, also run the macOS app with `-- --debug-tools`, or the web build at `http://localhost:8000/?debug=1`, and press backtick to see the debug overlay.
    - Check the debug overlay (M0 step 8 entry, "How to see it"): run with `-- --debug-tools`, press backtick, and try 1, 2 and 3. Accept if Godot asks to re-save `main.tscn` or `debug_overlay.tscn`.
    - Check the window size: with "Embed Game on Next Play" off, press F5. The window should be the largest whole multiple of 640 × 360 that fits the screen (on the MacBook Air, 1280 × 720, centered), with crisp, unblurred pixels. Already confirmed on 2026-10-17: Option+Return toggles fullscreen, and the trace is saved on window close with `--debug-tools`. Not yet checked: that a run *without* the flag writes no trace.
    - Fill in the license column for the three `game/art/legacy/` rows in `CREDITS.md`.
    - M0 step 0 prerequisites, still needed: the itch.io project page and access to a Windows PC. Confirmed: Godot 4.5.1 at `/Applications/Godot 4.5.1 .app`, its export templates (installed), and the macOS bundle identifier `com.patrickrosander.tri10nware` (owner, 2026-10-18).
    - Confirm the license of `game/art/tiles/level_1_tiles.png` in `CREDITS.md`.
- **Open questions:** the owner's player art is at `game/art/player/player_frames.png`, but the spec's slot is `player_sheet.png`: rename the file, or rename the slot in the spec? (decision log, section 5).
- **Note on reaching the gym (from M3 step 1):** `level_1` becomes the start room. To playtest the gym, set `start_room` in `game/rooms/room_catalog.tres` to `gym` in the Inspector, and back to `level_1` afterwards; don't commit the change. The debug menu's room list is postponed with M1 step 7.
- **Note for the postponed M1 step 8:** the chimney's 4-tile width is provisional (decision log, M1.5); if the chimney scenario shows alternating wall jumps cannot climb it, propose a new width to the owner.
- **Note on diagnostics (2026-10-18):** headless runs never print GDScript warnings, so "no warnings in the headless run" proves nothing; check the diagnostics tool after editing scripts. It works now: VS Code's Godot Tools was looking on port 6008 while Godot 4.5 listens on 6005, and the owner set `godotTools.lsp.serverPort` to 6005. M1 steps 1–3 had left 13 editor warnings; they were cleared on 2026-10-18 (decision log, M1.1–3 Engine row), and all 26 scripts are clean.
- **Note on keyboard device numbers (2026-10-17, owner check of M0 step 7):** an input-map binding matches a key press only when their device numbers agree, or when the binding uses "All Devices" (`-1`). Step 3 bound every keyboard key to device `0`. The step 3 and step 6 checks used synthetic events, which are device `0` by default, so they never proved that real Mac keyboards send device `0`. The owner changed only the `fullscreen` binding to `-1` (in the Input Map) to test two keyboards, and Option+Return now toggles fullscreen on both. That change is committed (owner decision): `fullscreen` is the one keyboard binding at `-1`. It shows that `-1` works but says nothing about device `0`. **Simple check, run only if a key ever seems ignored (most likely first in M1 step 4, when key presses first drive the player):** set `fullscreen` back to device `0` (Input Map, or `git checkout game/project.godot`, then Project → Reload Current Project), and press Option+Return in a non-embedded game window on each keyboard. If it works on both, device `0` is fine. If it fails on either, every keyboard binding must move to `-1`; propose that input-map change to the owner first (authority tiers: controls).

## Entry template

```markdown
## <M#> step <k>: <title> (<date>)

**What was built:** files created or changed.

**How it works:** plain-language explanation, a few short paragraphs.

**Why:** spec sections and acceptance criteria this serves.

**How to see it:** what to run or look at in Godot (or "nothing visible yet").

**Decisions and questions:** "decide and log" choices made; questions for the owner.
```

---

## M0 prep: workflow files (2026-10-17)

**What was built:**

- `docs/TRI10NWARE.md` (the spec), `docs/reference/` (the design and acceptance-criteria PDFs, plus the two Level 1 mockups cropped from design page 2).
- `CLAUDE.md`, `.claude/settings.json`, `.claude/skills/step/SKILL.md`, `.claude/agents/spec-reviewer.md`, and this journal.

**How it works:** each Claude session starts with no memory of the last one. `CLAUDE.md` loads automatically and tells the session where the spec is and which parts to read; the spec itself is too long to load every time. The `/step` skill walks a session through one numbered step: orient, plan, implement, test, explain here, commit. `.claude/settings.json` turns on in-chat explanations (the Explanatory output style), sets the path to Godot, and makes edits to the spec, the reference documents and owner art, and every `git push`, ask the owner first. The spec reviewer is a read-only helper for checking a finished milestone against the spec.

**Why:** "How an AI developer works from this document" and "M0 prep" in the spec.

**How to see it:** start a new Claude Code session in VS Code and type `/step M0.1`.

**Decisions and questions:** the M1 build order and the gym-painting hand-off were added to the spec with the owner's approval of the workflow plan.

## M0 step 1: migrate prototype repository (2026-10-17)

**What was built:**

- Tag `prototype-v0` on `d9a0053` (local only; the owner pushes it).
- Moved with `git mv` into `game/`: `project.godot`, `.editorconfig`, `.gitattributes`, `.gitignore`, `icon.svg`, `icon.svg.import`.
- Moved into `game/art/legacy/`: `player_v0.png`, `world_tileset.png`, `health.png`, each with its `.import` file (rewritten by the import step).
- Deleted: `player/player.gd`, `player/player.gd.uid`, `player/player.tscn`, `levels/level_1.tscn`.
- `game/.gitignore` trimmed to `.godot/` and `/android/`, plus `config/build_info.cfg`.
- New root `.gitignore`: `builds/`, `.DS_Store`, `.vscode/`, `CLAUDE.local.md`, `.claude/settings.local.json`.
- New `CREDITS.md`: the asset register, with the three legacy files as `owner draft`.
- `tools/` and `builds/` created on disk (not committed; see below).

**How it works:** the repository root now holds only documents and tools, and the Godot project lives in `game/`, so `res://` means `game/`. Godot never sees the docs, and the docs never get `.import` files.

Files were moved with `git mv`, so git records them as renames. `git log --follow game/art/legacy/player_v0.png` still shows the prototype history. The prototype as a whole stays recoverable through the `prototype-v0` tag.

The headless import step rebuilt Godot's cache in `game/.godot/` and rewrote each art file's `.import` so that `source_file` points at `res://art/legacy/...`. The stale cache at the old root `.godot/` was deleted; it was never tracked.

`game/project.godot` is unchanged in content. Its `main_scene` still points at the deleted prototype level, so the import prints `Unrecognized UID: "uid://bvi1x41hav28d"`. That is expected until M0 step 2 rewrites every setting.

**Why:** spec "M0 step 1: migrate the existing repository" and "Repository layout"; AC D-08 (the project opens from the repository alone; asset attribution).

**How to see it:** open Godot and import `game/project.godot` (not the old root). Running the project will complain about the missing main scene until step 2. The three prototype images are under `art/legacy/` in the FileSystem dock.

**Decisions and questions:**

- *Decide and log:* `tools/` and `builds/` exist on disk only. Git cannot track an empty folder, the spec lists no `.gitkeep` for `tools/`, and `builds/` is ignored. `tools/` enters git in M0 step 10 with its scripts.
- *Decide and log:* `CREDITS.md` was created now, not in M0 step 11, because step 1.4 adds rows to it. It uses step 11's columns exactly; step 11 extends it. (Approved with the step plan.)
- *Deviation from step 1.1:* the tag is local. CLAUDE.md forbids the AI from pushing. Owner: run `git push origin prototype-v0`.
- *Question:* the license column for the three legacy images says "owner to confirm". Please fill it in.
- *Owner decision (2026-10-17):* `.vscode/` (personal VS Code settings) is ignored in the root `.gitignore`, and the spec's M0 step 1 `.gitignore` row was updated to match, with the owner's approval.
- Tests: none yet. The unit-test runner arrives in M0 step 9; verification was the import run, the rename status and the `.import` paths.

## M0 step 2: project settings (2026-10-17)

**What was built:**

- `game/project.godot`: every setting in the step 2 table. Changed: version `0.1.0`; main scene `res://world/main.tscn` (replacing the prototype's stale scene UID); Compatibility renderer for desktop, mobile and web (and the matching `GL Compatibility` feature tag); 1280 × 720 window override; `viewport` stretch, `keep` aspect, `integer` scale mode; pixel snapping on; physics interpolation on; jitter fix `0.0`; untyped declarations are an **Error**. Removed: the prototype's fullscreen window mode. The prototype's `[input]` block is untouched; step 3 replaces it.

**How it works:** Godot reads `project.godot` at startup, before any script runs. The game now draws everything onto a 640 × 360 canvas (`viewport` stretch) and scales that canvas up by a whole number only (`integer`), adding black bars instead of stretching (`keep`). Pixels therefore stay square and crisp at 2× and 3×. The window opens at 1280 × 720. Step 7's `main.gd` will grow it to the largest whole multiple that fits the screen.

The simulation clock is 60 physics ticks per second, and up to 8 ticks may run in one rendered frame, so at 30 FPS the game still advances 2 ticks per frame and never slows down. Physics interpolation smooths movement between ticks on displays faster than 60 Hz. It only changes what is drawn, never the simulation. Those first two values are Godot's defaults. Godot writes only non-default values to `project.godot`, so you won't see them in the file, but they were checked by reading them back.

With `untyped_declaration` set to Error, a script with any untyped variable, parameter or return value fails to load. That enforces ground rule 2 automatically.

**Why:** spec "M0 step 2: project settings"; "Starting decisions this plan depends on" (renderer, 60 ticks, 640 × 360); ground rules 2 and 4; AC V-01 (integer scaling) and D-04/D-05 (one renderer everywhere, frame-rate-independent ticks).

**How to see it:** reopen Godot from `game/project.godot`, then open Project → Project Settings with Advanced Settings on. The values match the step 2 table, and the top-right renderer label reads "Compatibility". Running the project fails until step 7 adds the main scene. Verified headless with a throwaway script that read all 23 settings back through `ProjectSettings` (23 passes; not committed, since the unit-test runner arrives in step 9).

**Decisions and questions:**

- *Decide and log:* removed the prototype's `display/window/size/mode=3` (exclusive fullscreen at launch). The step 2 table specifies a 1280 × 720 window by default, which launching fullscreen would contradict; fullscreen stays one key away through the `fullscreen` action (step 3, D-07).
- Not changed here: the prototype input actions, which step 3 replaces in full.
- No open questions.

## M0 step 3: input map (2026-10-17)

**What was built:**

- `game/project.godot`, `[input]` section: the prototype's `left`, `right`, `jump`, `dash` and `switch` actions are replaced by the 13 actions of the step 3 table: `move_left`, `move_right`, `move_up`, `move_down`, `jump`, `dash`, `switch`, `pause`, `fullscreen`, `debug_toggle`, `debug_freeze`, `debug_step`, `debug_slow`.
- The same commit carries the editor's own re-save of `project.godot` from after step 2 (see "How it works").

**How it works:** an *action* is a name the code asks about ("is `jump` pressed?") instead of asking about a specific key, so a key can be remapped without touching code. Each action lists the events that trigger it.

Every keyboard binding is a **physical** key: Godot stores the key's position on the keyboard (`physical_keycode`) and leaves the logical keycode at 0. On a French AZERTY keyboard, the key where QWERTY has W still moves up, even though it is printed Z. There are two hand positions: arrows with Z/X/C, or WASD with J/K/L. Space also jumps. Gamepad bindings work on any connected pad (`device` −1): D-pad and left stick to move, bottom face button to jump, left face button to dash, right shoulder to switch, Start to pause. `fullscreen` is Enter with Alt held (Option on a Mac). The debug keys (backtick, 1, 2, 3) are only names for now. Step 8's overlay decides when they do anything.

The four movement actions have a **deadzone of 0**. Godot's action deadzone works per axis: each direction checks only its own axis, which makes a square deadzone, so diagonals register later than straight directions. With it at 0, step 6's input source gets the raw stick, applies one round deadzone (`stick_deadzone`, 0.2) and snaps to 8 directions with equal 45° slices (M-03). The other actions keep Godot's default of 0.2, which buttons never notice.

The file was written by a throwaway headless script that built real `InputEvent` objects and called `ProjectSettings.save()`, so Godot serialized them exactly as the Input Map dialog would. Godot writes only values that differ from its defaults. That is why the editor's re-save after step 2 removed `stretch/aspect="keep"` and `rendering_method.web="gl_compatibility"`: both are defaults, and both still read back as `keep` and `gl_compatibility`.

**Why:** spec "M0 step 3: input map" and "M0 step 1" (the input map row); ground rule 5 (only an input source reads gameplay actions, and these are their names); AC M-03 (diagonals no faster, via the radial deadzone in step 6) and D-07 (fullscreen toggle).

**How to see it:** reopen Godot, then Project → Project Settings → Input Map. Each key shows "(Physical)". Verified headless with a throwaway script (not committed; the test runner arrives in step 9) that read the map back through `InputMap`. It checked every action's deadzone and event count, and each event's type, physical keycode (logical 0), modifiers, joypad button, axis, direction and device. It also checked that no unlisted action remains and that the two step 2 defaults still resolve: 192 passes, 0 fails. The import step's only error is the expected missing `world/main.tscn`.

**Decisions and questions:**

- *Decide and log:* the movement actions' deadzone is 0.0, so the input map applies no per-axis deadzone (spec step 3: "the left stick has no per-axis deadzone in the input map"). Step 6 must apply `stick_deadzone` itself and must not rely on the action's pressed state for the stick.
- *Decide and log:* gamepad events bind to any device (−1).
- *Decide and log:* `fullscreen` binds the main Enter key with Alt only, not keypad Enter; the spec lists only Alt+Enter.
- No open questions.

## M0 step 4: Tuning, the settings service (2026-10-17)

**What was built:**

- `game/config/tuning_data.gd` (new): `class_name TuningData extends Resource`, with 46 typed `@export` fields (one per row of the step 4 table) in 11 Inspector groups, plus `enum CountdownMode { CONTINUE, PAUSE, STOP }`.
- `game/config/tuning.tres` (new): the one `TuningData` instance, holding every start value from the table.
- `game/autoload/tuning.gd` (new): the `Tuning` autoload.
- `game/project.godot`: a new `[autoload]` section, with `Tuning` as the first and only entry.
- `game/config/tuning_data.gd.uid` and `game/autoload/tuning.gd.uid`: generated by Godot.

**How it works:** `tuning_data.gd` is a *schema*: it says which values exist and what type each one is, but holds no numbers. `tuning.tres` holds the numbers. Open it in Godot and the Inspector shows every field, grouped (Body and run, Air and jump, Wall, …), ready to edit. The file is plain text, so every retune also shows up as a readable git diff.

`Tuning` is an autoload, a node Godot creates before the main scene and keeps for the whole run. Code anywhere can reach it as `Tuning`. When it starts, it loads `tuning.tres` into `Tuning.data` and converts each of the 12 durations from seconds to whole 60 Hz ticks with `roundi(seconds × 60)`. Gameplay code then reads `Tuning.coyote_ticks` (6) or `Tuning.countdown_ticks` (180) and never sees a second. That conversion lives in a public static function, `seconds_to_ticks`, so step 9's `test_tuning.gd` can test it on its own. Each tick value is named after its field with `_s` swapped for `_ticks`, which is exactly the name the M1 scenario files use ("coyote_ticks", "jump_buffer_ticks+1"). `Tuning.get("coyote_ticks")` therefore works with no lookup table.

The loading runs in `_init`, the moment the node is constructed, rather than in `_ready`. Later autoloads (Trace, GameState) will then always find the values filled in, whatever order things become ready in. If the file is missing, or the physics rate isn't 60, `Tuning` reports an error at startup instead of failing quietly later.

The `.tres` was written by a throwaway headless script. It set each value and saved with `ResourceSaver`, so Godot serialized the file and assigned its IDs itself. The same script registered the autoload through `ProjectSettings.save()`.

**Why:** spec "M0 step 4: Tuning, the settings service", "Names used in this plan", and ground rules 2, 4, 9 and 12. AC values held here: M-05 (`coyote_s` 0.1), M-06 (`jump_buffer_s` 0.1), S-03 (`countdown_s` 3.0, `countdown_in_default`, `allow_flow_entry_at_zero`), `max_volts` 3. Counting time in ticks also serves D-05 (the same results at 30, 60 and 120 FPS).

**How to see it:** reopen Godot. Double-click `config/tuning.tres` in the FileSystem dock to see every value in the Inspector. Project → Project Settings → Globals → Autoload lists `Tuning`. Verified headless with a throwaway script (not committed; the test runner arrives in step 9) that booted the project with the autoload. It checked that `Tuning` is the first autoload and `Tuning.data` is a `TuningData`. It checked that there are exactly 46 fields, none unlisted, and that each loads from the `.tres` with its spec value and type. It also checked all 12 tick values and step 9's three conversion cases (0.1 s → 6, 3.0 s → 180, 0.15 s → 9): 64 passes, 0 fails. The import step's only error is the expected missing `world/main.tscn`. VS Code's diagnostics come from the Godot editor, which was closed. The headless runs parsed both scripts under the untyped-declaration Error rule with no errors.

**Decisions and questions:**

- *Decide and log:* start values live only in `tuning.tres`; `tuning_data.gd` gives its fields no values. Ground rule 4 says seconds appear only in `tuning.tres`. Also, Godot does not save a value equal to the script default, so values written in the script would leave the `.tres` empty and hide the real numbers. The one exception is `countdown_in_default`, whose default is `CONTINUE` (the AC value); the `.tres` omits it for that reason.
- *Decide and log:* field types. `_px` fields are `int`, because positions are whole pixels. `body_size_px` is `Vector2i(12, 15)`. Speeds, accelerations, multipliers, seconds, alpha and deadzone are `float`. `max_volts` and `trace_memory_limit` are `int`.
- *Decide and log:* `countdown_in_default` is an enum (`TuningData.CountdownMode`: `CONTINUE`, `PAUSE`, `STOP`), not a string. The Inspector shows a dropdown, and a misspelled mode fails when the script loads, not when the countdown runs. The `.tres` stores it as a number (0 = continue).
- *Decide and log:* the tick values are computed in `_init`, so they exist before any other autoload's `_ready`.
- *Note:* `wall_jump_lock_s` 0.16 s rounds to 10 ticks (9.6 exactly), so the real lock is 0.167 s. It is the only starting duration that isn't a whole number of ticks. It was not changed (a tuning value); retune it in playtesting if it matters.
- *Correction:* the step plan said 47 fields; the spec table has 46. The code matches the table.
- No open questions.

## M0 step 5: Trace, the recorder (2026-10-17)

**What was built:**

- `game/autoload/trace.gd` (new): the `Trace` autoload.
- `game/autoload/trace.gd.uid`: generated by Godot.
- `game/project.godot`: `Trace` added to `[autoload]`, second after `Tuning`.

**How it works:** `Trace` is the game's flight recorder. Any rule that does something worth proving calls `Trace.record("jump", {...})`. `Trace` stamps the entry with the current tick and room, giving `{tick, room, event, data}`, keeps it in memory, and emits the signal `event_logged`. Sound, HUD flashes and effects will listen to that signal. Rules never read the trace back, so the log can never change the game. `World` will set `Trace.tick` every tick (step 7) and `Trace.room` whenever it builds a room (M1). Until then nothing calls `record()`.

Every log starts with a header, a `session_start` entry holding the build ID, the platform (`OS.get_name()`), the physics tick rate and all 46 tuning values. `Trace` makes one at launch, and the scenario runner will call `begin_session()` again for each run. The header is stored apart from the events, so trimming never removes it. In normal play `Trace` keeps the newest `trace_memory_limit` events (100,000) in a *ring buffer*: once full, each new event overwrites the oldest in place. That keeps recording cheap. Removing the first element of a 100,000-entry array would move every other element, 60 times a second. `begin_session(true)` turns the limit off for scenario runs.

`record()` checks each event against `CATALOG`, a copy of the spec's event table. An unknown event, or data with the wrong field names, prints an error at once, so a typo cannot slip into the evidence unnoticed. Ground rule 7 is now checked in code. A wrong entry is still recorded, so the log stays complete.

`save_to_disk()` writes the header and then every event to `user://traces/<YYYYMMDD-HHMMSS>_<build>.jsonl` as JSON Lines, one JSON object per line. The format is easy to diff, grep and load line by line. Vectors and colors are written as arrays (`[12, 15]`), since JSON has no vector type and Godot would otherwise write the string `"(12, 15)"`. `to_jsonl()` and `file_name()` are public, so the debug overlay can offer the same file as a browser download on the web build.

**Why:** spec "M0 step 5: Trace, the recorder", ground rules 7 and 12, and the "Determinism contract". The trace is the evidence for D-04 (same events across targets) and D-05 (identical traces at 30/60/120 FPS), and it is what every M1+ scenario checks.

**How to see it:** nothing visible yet. Reopen Godot. Project Settings → Globals → Autoload lists `Trace` second. A file appears in `user://traces/` only when something calls `save_to_disk()` (the debug menu, from M1). Verified headless with a throwaway script (not committed; the test runner arrives in step 9), 30 passes, 0 fails. It checked:

- the autoload order;
- the header's keys, build `0.1.0-dev`, target `macOS`, tick rate 60, and all 46 tuning values;
- that `record()` stamps the tick and room and emits the signal once;
- the catalog errors;
- that a ring of 3 keeps only the newest 3 while the header survives, and `keep_everything` keeps all 200;
- that two saves in one second get distinct names with no colon;
- that every line parses as JSON, line 1 is the header, keys run tick, room, event, data, and vectors are written as arrays.

The import step's only error is the expected missing `world/main.tscn`. VS Code's diagnostics come from the Godot editor, which was closed. The headless run parsed `trace.gd` under the untyped-declaration Error rule with no errors.

**Decisions and questions:**

- *Decide and log:* **build ID** = `<version>-<commit>`, read from `res://config/build_info.cfg`, section `[build]`, keys `version`, `commit`, `date`. Step 10's `export_all.sh` must write exactly these. With no file (editor runs), the build ID is `<application/config/version>-dev`, currently `0.1.0-dev`; displays may show it as "dev build". `Trace.build_id` is the one place the overlay and title read it from. It is always safe in a file name.
- *Decide and log:* **target** is `OS.get_name()` ("macOS", "Windows", "Web"). **tick_rate** is `Engine.physics_ticks_per_second`, the rate that actually ran.
- *Decide and log:* **tuning** in the header is every stored `TuningData` field in designer units (seconds), found automatically, so new fields appear with no change to `Trace`. Derived tick values are not added, since the catalog lists only four keys and the ticks follow from the fields. `countdown_in_default` appears as its enum number (0 = continue).
- *Decide and log:* **JSON format.** Keys keep insertion order (tick, room, event, data), and floats are written at full precision, so cross-target comparisons (D-04) see every bit. This makes some floats look long: `coyote_s` 0.1 appears as `0.100000000000000006`. That is the exact stored value, not an error.
- *Decide and log:* the **file name timestamp** uses the local clock. Wall-clock time is used only for the name, never in rules. If a file with that name exists, `-2`, `-3` and so on is added before `.jsonl`, so two saves in one second never overwrite each other.
- *Decide and log:* the **session_start header** is an ordinary catalog entry at tick 0. It is written as line 1 of the file, kept outside the ring, and also emitted on `event_logged`. `begin_session()` resets `tick` to 0 and `room` to empty.
- *Decide and log:* **catalog check.** An event's data must carry exactly the listed fields, no more and no fewer. A field that doesn't apply (for example `object` on a ground jump) is still passed, with an empty value.
- No open questions.

## M0 step 6: input stage (2026-10-17)

**What was built:**

- `game/core/input_frame.gd` (new): `class_name InputFrame`, one tick of input: `tick`, `jump_held` / `jump_pressed`, `dash_held` / `dash_pressed`, `switch_held` / `switch_pressed`, and `direction` (a `Vector2i`, each axis −1, 0 or 1, y down).
- `game/core/press_buffer.gd` (new): `class_name PressBuffer`, at most one press token for one action, with `press`, `can_spend`, `spend`, `expire`, `clear`, `has_token`, `created_tick`.
- `game/input/input_source.gd` (new): `class_name InputSource`, the shared interface (`read(tick)`, `mark_all_stale()`) and the rules both sources share.
- `game/input/live_input_source.gd` (new): `class_name LiveInputSource`, keyboard and gamepad.
- `game/input/scripted_input_source.gd` (new): `class_name ScriptedInputSource`, plays back scenario input lists.
- Their five `.uid` files, generated by Godot.

**How it works:** gameplay never asks Godot "is jump down?". Once per tick, `World` (from step 7) will call `read(tick)` on whichever input source is plugged in and get back an `InputFrame`. That frame is the only thing the rules see, so a test can swap the keyboard for a script and the player cannot tell the difference.

`InputSource` holds the logic both sources share. Each source feeds it an ordered list of "action pressed" / "action released" transitions. A press of `jump`, `dash` or `switch` sets that button's `_pressed` flag on the next frame only. Holding never repeats it, and a press and release that both land inside one rendered frame still count as one press. For movement, it remembers when each key went down. With Left and Right both held, the one pressed most recently wins, and releasing it falls back to the other, so rolling between arrow keys never stalls. `mark_all_stale()` flags every currently held button as *stale*: it reports neither held nor pressed until it is let go. That stops the jump held through a death, or the key that closed the pause menu, from doing something by accident. Directions are never marked stale.

`LiveInputSource` listens in `_input()`, which Godot calls once per rendered frame for every event. It ignores key-repeat echoes and queues only real changes; `read()` empties the queue. A press is therefore never lost, even when a frame runs several ticks or the game is frame-stepped. It tracks which physical keys hold each action, so pressing C while Space already holds `jump` is not a second jump, and releasing Space while C is still down doesn't release it. The stick is read only when no movement key or D-pad button is held. It gets one *round* deadzone (`stick_deadzone`, 0.2), then snaps to 8 equal 45° slices. The snap compares |y| against |x| × tan 22.5°, and tan 22.5° is exactly √2 − 1, so it needs no trigonometry. Only the direction is passed on, so diagonals are never faster (M-03).

`ScriptedInputSource.play(entries, start_tick)` takes the exact scenario-file format, `{"tick": n, "press": "jump"}` or `{"tick": n, "release": "jump"}`. Each `read(tick)` applies every entry that is due, in list order, with no frame delay. A malformed entry or an unknown action prints an error instead of being silently skipped.

`PressBuffer` is the "one press, one action" rule. A token made on tick *t* can be spent by a decision on ticks *t* through *t* + window (6 ticks for 100 ms), and exactly once. A new press replaces an unspent token. `press()` returns the replaced token's tick, and `expire()` returns a token's tick on the first tick it can no longer be spent. Like every `core/` class, it touches no autoloads, so it can't write to `Trace` itself. It hands those numbers back, and `World` will log `press`, `press_spent` and `press_expired` (M1).

**Why:** spec "M0 step 6: input stage", "How input reaches the player", "Decision ticks" (M1), and ground rules 5, 8, 12 and 15. AC M-03 (8-way, no faster diagonals), M-06 and C-07 (buffer windows), M-07 (one press, one action; holding never repeats), R-01 and R-04 (stale buttons after respawn and unpause), and D-04/D-05 through scripted input.

**How to see it:** nothing visible yet; `World` plugs a source in at step 7, and the player uses frames from M1 step 4. Verified headless with a throwaway scene (not committed; `test_press_buffer.gd` is a step 9 file), 70 passes, 0 fails:

- `PressBuffer`: spendable on *t* through *t* + 6, not on *t* + 7 or before *t*; `expire()` silent through *t* + 6 and reporting on *t* + 7; replacement reports the old tick; single spend; a token on tick 0 is valid.
- Scripted: press on its tick; no repeat while held; press and release on one tick give one press; an entry on a skipped tick is still applied; most recent wins on both axes, with fallback on release; stale through release, then a fresh press; directions not stale; `play()` resets; three malformed entries rejected.
- Live, fed synthetic physical-key events: echoes ignored; two keys on one action; two taps in one frame give one press; arrows and WASD mixed; `mark_all_stale()` discards an unread press; focus loss releases everything; unbound keys ignored; process mode Always.
- Snapping: 16 angles around the circle land in the right 8 sectors; round deadzone edges on the diagonal and the axis; deadzone read from `Tuning`.

The import's only error is the expected missing `world/main.tscn`. The editor was closed, so VS Code showed no diagnostics. The headless runs loaded all five scripts with no errors or warnings.

**Decisions and questions:**

- *Decide and log:* **digital beats the stick.** When any movement key or D-pad button is held, the direction comes from those alone; the stick is used only when none is.
- *Decide and log:* **several gamepads** are merged. The stick value is `Input.get_action_raw_strength` over the input map's any-device (−1) bindings.
- *Decide and log:* **`mark_all_stale()` discards presses not yet read.** They arrived before the screen change, so they belong to the old screen.
- *Decide and log:* **the live source runs with process mode Always**, so it keeps tracking held keys while the tree is paused. Anything queued during the pause is discarded by the unpause `mark_all_stale()`.
- *Decide and log:* **focus loss releases everything.** On `NOTIFICATION_APPLICATION_FOCUS_OUT` or `NOTIFICATION_WM_WINDOW_FOCUS_OUT`, the live source releases every held action, because the operating system may never deliver the key-up events.
- *Decide and log:* **`press_expired` timing.** `PressBuffer.expire(tick)` reports on tick *t* + window + 1, the first tick the token can no longer be spent. `World` logs it then (M1). A replaced token is reported by `press()` at the moment it's replaced.
- *Decide and log:* **scripted ticks are relative.** Scenario ticks count from the case start; `play()` takes the case's `start_tick`. Resolving tuning names such as `"jump_buffer_ticks+1"` stays in the M1 scenario runner.
- No open questions.

## M0 step 7: Main and World skeleton (2026-10-17)

**What was built:**

- `game/world/main.tscn` (new): `Main` (Node, `main.gd`, process mode Always) → `World` (Node2D, `world.gd`, process mode Pausable) → `RoomSlot` (Node2D) and `Camera` (Camera2D, `camera_rig.gd`, at (320, 180), physics process callback).
- `game/world/main.gd`, `game/world/world.gd`, `game/world/camera_rig.gd` (new), with their `.uid` files.
- `docs/TRI10NWARE.md` (owner-approved edit): the `main.gd` row of the M0 step 7 table now says who saves the trace on quit. The M0 done-when line now reads "Run with `--debug-tools`, a trace file is written on quit…".

**How it works:** `Main` is the game screen. It is loaded once and never replaced. `World` is the referee and holds the project's only `_physics_process`. Godot calls it 60 times a second. Each call first decides whether a tick runs at all. Not if the simulation isn't running. Not if the debug freeze is on, unless one step was requested. In slow motion, only on every 2nd or 4th physics step, using a counter that resets whenever the speed changes. When a tick does run, `World` adds one to `tick`, copies it to `Trace.tick`, and calls the 11 step methods in their fixed order. In M0 only the first does anything. `_step_input` asks the input source for this tick's `InputFrame` and keeps it in `World.frame`. The other ten are empty, and each has a comment naming the milestone that fills it.

Slow motion works by *skipping* ticks, never by shortening them. Every tick that runs is a full 1/60 s, so a jump at ¼× follows exactly the same arc, only more slowly. `Engine.time_scale` would shrink the delta every tick receives and change the results (ground rule 4).

There is no Player yet, so `World` makes its own `LiveInputSource` child in `_ready()`. Those lines are marked `M0 only, replaced in M1 step 4`. `set_input_source()` is permanent: the M1 scenario runner will use it to plug in a `ScriptedInputSource`. When it replaces the source `World` made itself, it frees that one, so two sources never run at once.

`Main` reads the arguments after `--` (`--debug-tools`, `--run-scenarios[=prefix]`, `--quit-when-done`, `--render-fps=<n>`) into public fields that step 8 and M1 will read. Any scenario flag also turns debug tools on. So does `?debug=1` on a web page served from this machine. `--render-fps` takes effect now: it caps `Engine.max_fps` and turns vsync off. On desktop, `Main` grows the window to the largest whole multiple of 640 × 360 that fits the screen's usable area, title bar included, and centers it. Alt+Enter toggles fullscreen. In debug runs only, and never on the web, closing the window saves the trace to `user://traces/`, as does any quit `Main` makes through `quit_game()`. With no title screen until M3, `Main` starts `World` at launch.

`Main` runs with process mode **Always**, so fullscreen will still work while the game is paused (from M3). Children inherit their parent's process mode, so `World` is set to **Pausable** explicitly. Otherwise pausing would never stop the tick, and the countdown would keep running during pause (R-04).

`camera_rig.gd` provides `set_bounds(rect)`, which sets the four camera limits, and `move_to(target)`, which centers the view on a whole-pixel point clamped inside those bounds. Both are called during the tick from M1, so the camera moves on the physics step and physics interpolation smooths it in step with the player. The `Camera2D` uses the physics process callback. Godot forces this anyway when physics interpolation is on, and prints a warning if the scene says otherwise.

**Why:** spec "M0 step 7: Main and World skeleton", "What happens on every tick", "Names used in this plan", ground rules 2–5, 12 and 16, and the "Determinism contract". AC D-04/D-05 (one tick order; slow motion and freeze never change tick length; `--render-fps` for frame-rate runs), R-04 (World pausable), D-07 (fullscreen, window size), V-01 (integer window multiple; the camera never shows past room bounds).

**How to see it:** reopen Godot and press F5. You get a blank window. Nothing draws yet; step 8's overlay will show the tick counter. Verified headless with a throwaway script (not committed; the test runner arrives in step 9), 35 passes, 0 fails:

- Tree shape, node types and process modes; the camera at (320, 180) with the physics callback.
- `World` makes its own `LiveInputSource`; `Main` starts `World`.
- With `--fixed-fps 60`: 60 physics steps give 60 ticks, and `Trace.tick` follows. Not running gives 0 ticks. Frozen gives 0 ticks over 10 steps, and `request_step()` exactly 1. Slow ½ gives 20 ticks over 40 steps, and ¼ gives 10. A slow divisor of 3 is rejected.
- After `set_input_source(scripted)`, `World`'s own source is freed. A scripted jump press arrives exactly once, on start + 5, and `frame.tick` always equals `World.tick`.
- Argument parsing: no arguments, each flag, `=prefix`, bad `--render-fps` values ignored with an error, and scenario flags enabling debug tools.
- Window multiples: 1366 × 768 with a taskbar and title bar → 1×, bare → 2×; 1080p → 2×; 1440p → 3×; 4K → 6×; tiny screen → 1×.
- Camera clamping at both corners and inside, and its limits.

`_physics_process` appears only in `world.gd`. The import step now runs with no errors (the missing-main-scene error is gone). A real headless run with `--debug-tools` for 120 frames and a real windowed run both printed no errors or warnings. **Not verified automatically:** the real window size, the fullscreen toggle and the trace save on window close. The windowed test needed macOS Accessibility permission to measure and close the window, which it did not have. These are listed under "Waiting on the owner". The editor was closed, so VS Code showed no diagnostics; the headless runs compiled all three scripts with no errors.

**Decisions and questions:**

- *Decide and log:* **`DebugOverlay` is added to `main.tscn` in step 8**, not step 7: its scene is created in step 8.
- *Decide and log:* **`Main` starts `World` in `_ready()`** in M0, because there is no title screen yet. M3's Title state replaces this call.
- *Owner decision:* **World makes its own `LiveInputSource` in M0.** It is marked `M0 only, replaced in M1 step 4`; `set_input_source()` is permanent (see the Status note for M1 step 4).
- *Decide and log:* **window sizing** counts the title bar and borders, never goes below 1×, centers the window, and is skipped in headless runs, on the web, when embedded in the editor and when not windowed. Consequence: on a 1366 × 768 screen with a taskbar, the window is 1× (640 × 360), because 2× plus the title bar is taller than the usable area. Fullscreen (Alt+Enter) still gives 2× there.
- *Decide and log:* **`?debug=1`** counts only when the page host is `localhost` or `127.0.0.1`.
- *Decide and log:* **process modes:** `Main` is Always and `World` is Pausable, set explicitly in the scene.
- *Decide and log:* **slow motion and freeze:** the slow-motion counter resets when the speed changes. A requested single step while frozen always runs exactly one tick, whatever the slow-motion setting. A slow divisor other than 1, 2 or 4 is rejected with an error.
- *Decide and log:* **`--quit-when-done` counts as a scenario flag** and also turns debug tools on. An unknown argument prints a warning. An invalid `--render-fps` prints an error and is ignored.
- *Decide and log:* **the `Camera2D` uses the physics process callback**, avoiding Godot's warning under physics interpolation.
- *Owner decision (2026-10-17):* **trace on quit** happens only with debug tools on, and never on the web, where the debug overlay's download covers it (step 8). The spec's `main.gd` row and the M0 done-when line were updated with approval.
- *Note:* `main.tscn` was written by Godot's `ResourceSaver` from a headless script, like `tuning.tres` in step 4. The scripts are referenced by path, with no `uid=`. The editor adds UIDs the next time it saves the scene.
- *Fix after owner check (2026-10-17):* the editor reported two `INTEGER_DIVISION` warnings for `main.gd`'s `window_scale()`; headless runs do not print them. The division is meant to drop the remainder (whole multiples only), so the line carries `@warning_ignore("integer_division")`. The owner confirmed the trace is saved on window close with `--debug-tools`. Window checks need the editor's "Embed Game on Next Play" turned off, because an embedded game cannot resize itself or go fullscreen.
- No open questions.

## M0 step 8: debug overlay (2026-10-17)

**What was built:**

- `game/debug/debug_overlay.tscn` (new): a `CanvasLayer` named `DebugOverlay` (process mode Always, layer 100, hidden at start) with one `Label`, `Readout`, in the top-left corner.
- `game/debug/debug_overlay.gd` (new, with its `.uid`): fills the readout and handles the debug keys.
- `game/world/main.tscn`: a `DebugOverlay` instance as a child of `Main`, beside `World`.
- `game/world/main.gd`: wires the overlay to `World` when debug tools are on and frees it otherwise.

**How it works:** the overlay is a screen layer that draws on top of everything. It is drawn in screen space, so the camera never moves it. Its process mode is Always, so it keeps working while the game is paused (M3). Every rendered frame, while it is shown, it writes five lines: the current tick, frames per second, the physics rate (60 Hz), the build ID from `Trace` (`0.1.0-dev` in editor runs), and the speed (1×, ½× or ¼×, plus `FROZEN`). It only reads these values. It never runs gameplay, so `World` keeps the project's only `_physics_process`.

The keys come from the input map made in step 3. Backtick shows or hides the overlay. While it is shown, 1 freezes or unfreezes the simulation, 2 runs exactly one tick while frozen, and 3 cycles the speed 1× → ½× → ¼× → 1×. The overlay changes only `World`'s public `debug_frozen`, `request_step()` and `slow_divisor`; the tick-skipping itself was already in `World` from step 7. While the overlay is hidden, 1 to 3 do nothing, so stray number presses during play are harmless.

`Main` decides whether the overlay exists. Godot runs a child's `_ready()` before its parent's, so the overlay cannot know about the command-line flags when it starts; `Main` reads them in its own `_ready()`. With debug tools on, `Main` gives the overlay its `World`. Without them, it deletes the overlay, so a normal player has no overlay and no debug keys at all.

**Why:** spec "M0 step 8: debug overlay", the step 7 `main.tscn` row ("plus `DebugOverlay`"), and ground rules 3 and 5; M0 done-when line 2. AC D-01 (the build ID on screen), D-05 (frame-stepping and slow motion for frame-rate checks), and AC page 9 (debug access, documented in the README in step 11).

**How to see it:** in Godot, turn off "Embed Game on Next Play", set Project → Project Settings → Run → Main Run Args to `-- --debug-tools` (or run from a terminal: `"$GODOT" --path game -- --debug-tools`), and press F5. Press backtick and the tick counts up at 60 per second. Press 1 to freeze, 2 to step one tick, 1 again to resume, and 3 to cycle slow motion. Without the flag, backtick does nothing. If Godot asks to re-save `main.tscn` or `debug_overlay.tscn`, accept: it adds the UIDs (the files reference scripts by path).

Verified headless with a throwaway script (not committed; the test runner arrives in step 9), 22 passes with `--debug-tools` and 1 without, 0 fails:

- Without the flag, `DebugOverlay` is gone. With it, the overlay exists, starts hidden and is wired to `World`.
- 1 and 3 are ignored while hidden. A real backtick event through `Input.parse_input_event` shows the overlay.
- The readout holds the tick, `Physics 60 Hz` and the `-dev` build ID; it shows `FROZEN` and `¼×` when they apply.
- 12 physics steps give 12 ticks at 1×, 6 at ½× and 3 at ¼×. Frozen, 10 steps give 0 ticks; 2 then gives exactly 1. A 2 pressed before freezing did not leak a tick.
- Backtick hides the overlay, after which 1 is ignored again. The overlay still toggles while the scene tree is paused.

A real headless run with `--debug-tools` for 120 frames exited 0 with nothing on stderr, and still wrote its trace on quit. The editor was closed, so VS Code showed no GDScript diagnostics. **Not verified automatically:** how the readout looks on screen (font size 8 in the 640 × 360 canvas) and the real keyboard path for 1 to 3.

**Decisions and questions:**

- *Decide and log:* **the overlay starts hidden** when debug tools are on; backtick shows it.
- *Decide and log:* **the readout also shows the speed and `FROZEN`**, so a tester can see why ticks stopped.
- *Decide and log:* **2 (step) is ignored unless frozen.** `World` keeps a step request until the next frozen physics step, so a press while running would have leaked one tick into the next freeze.
- *Decide and log:* **without debug tools, `Main` frees the overlay** rather than hiding it, so its keys cannot work.
- *Decide freely:* the readout is a single `Label` with the default font at size 8, offset 4 px from the top-left corner. It is a placeholder for testing, not an art decision.
- *Correction to the step 7 entry:* that entry says the overlay's trace download covers the web build "(step 8)". The spec puts "save or download the current trace" in the **M1 debug menu** (M1 build order step 7), so step 8 adds no download. Until M1, web runs keep no trace file.
- No open questions.

## M0 step 9: unit-test runner (2026-10-17)

**What was built:**

- `game/tests/test_case.gd` (new): `class_name TestCase extends RefCounted`, the base for every unit test: `assert_eq`, `assert_true`, `assert_false`, `assert_near`, plus `add_node()` and `take_errors()`.
- `game/tests/test_runner.gd` (new): finds and runs the tests, prints results, and exits with code 0 or 1. It includes `ErrorCapture`, an inner `Logger` class.
- `game/tests/test_runner.tscn` (new): one `Node`, `TestRunner`, running `test_runner.gd`.
- `game/tests/unit/test_tuning.gd` (new): 6 tests.
- `game/tests/unit/test_press_buffer.gd` (new): 7 tests.
- `game/tests/unit/test_input_source.gd` (new): 20 tests.
- `game/tests/unit/test_trace.gd` (new): 11 tests.
- The six scripts' `.uid` files, generated by Godot.
- `game/project.godot`: unchanged. A stray uncommitted `[editor] run/main_run_args="-- --debug-tools"` line was reverted at the start of the step, on the owner's instruction.

**How it works:** one command, `"$GODOT" --headless --path game res://tests/test_runner.tscn`, opens the project with no window. It runs the test scene instead of the game, so the `Tuning` and `Trace` autoloads exist but `Main` and `World` do not. The runner lists `res://tests/unit/`, keeps every `test_*.gd`, and sorts them. In each file it runs every method whose name starts with `test_`, in the order they are written. Each method gets a brand-new instance of its test class, so nothing one test sets up can leak into the next. The runner prints `PASS` or `FAIL` for each method, with the failure messages under it, and ends with a count. The exit code is 0 only when everything passed, which is what step 10's `run_tests.sh` checks. Finding no tests at all is also a failure, so a mistyped folder can't look like success.

A test is a script that `extends TestCase` and calls the asserts. Each assert records a message naming the test and saying what was expected and what came instead, for example `test_derived_ticks: coyote_ticks: expected 6, got 7`. `assert_eq` also requires the same *type*: `6` and `6.0` are different. That matters for `test_tuning`, where an `int` field typed as a `float` by mistake would otherwise pass. `add_node()` puts a node into the scene tree for the test, so its `_ready` runs, and frees it when the test ends.

GDScript has no exceptions. When a line inside a test crashes (calling a method on `null`, say), Godot prints an error and that function simply stops, and the runner carries on as if nothing happened. A crashed test with no failed asserts would look like a pass. To stop that, the runner installs a `Logger`, a Godot 4.5 feature that receives every error the engine prints. Any error raised while a test runs is recorded against that test, and an error the test didn't expect fails it. Some tests cause errors on purpose: Trace's catalog check and the scripted source's bad-entry check both work by printing errors. Those tests call `take_errors()` to collect and check them. The console still shows those `ERROR:` lines (the engine prints them before the logger sees them), so the summary ends with "The 8 ERROR messages above were caused on purpose and checked by the tests."

What the four test files check:

- **`test_tuning`:** `seconds_to_ticks` (0.1 s → 6, 3.0 s → 180, 0.15 s → 9); all 12 tick values against hard-coded numbers; and every one of the 46 `tuning.tres` fields against its value *and type* in the spec's step 4 table. It also checks that the resource has no fields outside the table, and that `Tuning` is the first autoload. A field dropped from the `.tres` silently loads as 0, and fails here by name.
- **`test_press_buffer`:** a token is spendable on *t* through *t* + 6 but not before or after; `expire()` reports exactly once, on *t* + 7; a new press replaces an old token and reports it; a token is spent once; tick 0 is valid; `clear()` is silent.
- **`test_input_source`:** the step 6 verification list, rebuilt. *Scripted:* a press on its tick, no repeat while held, press and release on one tick give one press, a skipped tick loses nothing, most recent wins on both axes with fallback, stale until release, directions never stale, `play()` resets, the `start_tick` offset, and five kinds of malformed entry rejected. *Live*, fed synthetic key events: echoes ignored, two keys on one action (Space and C), two taps in one frame give one press, arrows and WASD mixed, `mark_all_stale()` discards an unread press, focus loss releases everything, unbound keys ignored, process mode Always, the deadzone read from `Tuning`, and digital input beating the stick. *Snapping:* every sector on both sides of each 22.5° boundary (stick ratios 0.40 and 0.43 against tan 22.5° ≈ 0.414), and the round deadzone's edges on the axis and the diagonal.
- **`test_trace`:** each test makes its own private copy of the Trace script, so the real `Trace` autoload is never touched. It covers: the header (build `0.1.0-dev`, target, tick rate 60, all 46 tuning values); `begin_session()` resetting tick, room and events; `record()` stamping the tick and room and emitting once; three kinds of catalog error, each still recorded; the ring (limit 3 keeps ticks 2, 3, 4 and the header) and keep-everything mode (200 kept); file names with no colon and the `YYYYMMDD-HHMMSS_<build>.jsonl` shape; two saves in one second getting distinct names (the test deletes both files); and JSON Lines (every line parses, the header first, key order tick, room, event, data, vectors and colors written as arrays). It also checks that `Trace` is the second autoload.

**Why:** spec "M0 step 9: unit-test runner" (including the owner's 2026-10-17 additions of `test_input_source.gd`, `test_trace.gd` and the full-table `test_tuning.gd`), and ground rules 1 (no add-ons), 2, 8 (each `core/` rule has a unit test) and 12. It re-proves what the step 4–6 throwaway scripts checked. AC served: M-03, M-05, M-06, M-07, C-07, R-01, R-04, S-03 through the code under test; D-04 and D-05 through the trace tests; D-08 (the project tests itself from the repository alone).

**How to see it:** in a terminal, `"$GODOT" --headless --path game res://tests/test_runner.tscn`, then `echo $?`. Expect `44 passed, 0 failed.` and `0`. In the Godot editor you can also open `tests/test_runner.tscn` and press F6 (Run Current Scene); the results appear in the Output panel and the window closes by itself.

Verification: the import step runs clean. The full run gives 44 passed, 0 failed, exit code 0, with no warnings or script errors. To prove the runner can fail, a temporary file (deleted afterward, never committed) held four broken tests: a wrong value, `6` against `6.0`, a call on `null`, and a stray `push_error`. All four were reported as `FAIL` with readable messages, and the exit code was 1. VS Code's Problems panel showed nothing for the new files: the Godot language server only checks files open in the editor. The headless runs loaded all seven scripts under the untyped-declaration Error rule with no errors.

**Decisions and questions:**

- *Decide and log:* **any engine error during a test fails it**, unless the test collects it with `take_errors()`. The capture uses Godot 4.5's `Logger` (`OS.add_logger`); warnings are ignored.
- *Decide and log:* **each test method gets a fresh instance** of its test class, and test files and methods run in a fixed order (files sorted by name, methods in source order).
- *Decide and log:* **finding zero tests is a failure** (exit code 1).
- *Decide and log:* **`assert_eq` requires the same type** as well as an equal value.
- *Decide and log:* **the trace tests use private instances** of `autoload/trace.gd`, so the real autoload's log is never wiped or filled. The ring test sets `Tuning.data.trace_memory_limit` to 3 for one `begin_session()` call and restores it at once.
- *Decide freely:* `TestCase` gains `add_node()`, `take_errors()`, `claimed_errors` and two runner hooks (`capture_error()`, `free_nodes()`) beyond the four asserts the spec names. The snap test uses hand-picked stick ratios around tan 22.5° instead of computing angles.
- *Note:* the M0 step 8 entry's "How to see it" says to set Main Run Args to `-- --debug-tools`. Doing that in Project Settings writes exactly the `[editor]` line reverted here. If it comes back, that is where it comes from. Setting it is the owner's choice; it is just not committed.
- No open questions.

## M0 step 10: delivery path (2026-10-18)

**What was built:**

- `game/export_presets.cfg` (new): the three export presets, `macOS`, `Windows Desktop` and `Web`.
- `tools/export_all.sh` (new): builds all three targets from one clean commit and packages the itch.io files.
- `tools/run_tests.sh` (new): import, unit tests, scenarios; one exit code for all of it.
- `tools/serve_web.sh` (new): serves `builds/web/` over local HTTP.
- `game/project.godot` (changed): `rendering/textures/vram_compression/import_etc2_astc=true`.
- `game/config/build_info.cfg` is *generated* by `export_all.sh` and deleted again when it finishes; it is git-ignored and never committed.

**How it works:**

*Exporting.* `tools/export_all.sh` first runs the import step, then refuses to go on unless `git status` is empty. Every build must come from a real commit, and a change you haven't committed would ship in a build that claims to be that commit. It then writes `game/config/build_info.cfg`:

```ini
[build]

version="0.1.0"
commit="4fa9196"
date="2026-10-18T17:18:12Z"
```

The version is read from `application/config/version` in `project.godot`, the commit is the 7-character short hash, and the date is UTC. `Trace` (M0 step 5) already reads this file at launch and builds the build ID `0.1.0-4fa9196` from it. That ID appears in every trace header, every trace file name and the debug overlay. The script then runs Godot's three command-line exports (`--export-release`, one per preset) into `builds/macos/`, `builds/windows/` and `builds/web/`. It checks `git status` again: an export can rewrite `.import` or `.uid` files, and if it did, the build doesn't quite match the commit, so the script stops and asks for them to be committed first. Finally it writes the three upload files to `builds/itch/`. When the script exits, even after a failure, it deletes `build_info.cfg`, so running the game from the editor goes back to showing `0.1.0-dev`.

*Presets.* Each preset follows the spec table: macOS is universal (Intel and Apple Silicon in one app), ad-hoc signed with Godot's built-in signer, not notarized, bundle ID `com.patrickrosander.tri10nware`. Windows is x86_64, with the game data embedded in the `.exe`, so it is a single file. Web has no threads and focuses the canvas on start. All three use the spec's filters: `config/build_info.cfg` and `verification/scenarios/*.json` are added (Godot only packs files it recognizes as resources unless told otherwise), and `tests/*` and `rooms/world_map_preview.*` are left out. Only the options the spec names are written in the file; Godot fills every other option with its default. If you open Project → Export in the editor, it will rewrite the file with every option spelled out. That is harmless, and worth committing if it happens.

*The ETC2/ASTC setting.* The first macOS export failed: Godot refuses a universal or Apple Silicon export unless "Import ETC2 ASTC" is on, because Apple GPUs need that texture format for VRAM-compressed textures. Our pixel art isn't VRAM-compressed, so nothing looks different, and the reimport changed no `.import` file. Turning the setting on is an engine requirement, not a design choice.

*itch.io files.* `TRI10NWARE_web.zip` holds the web export with `index.html` at the top. `TRI10NWARE_windows.zip` holds the `.exe`, `README.md` and `CREDITS.md`. `TRI10NWARE_macos.zip` holds `TRI10NWARE.app` and the two documents. The macOS one is repacked with macOS's `ditto` tool, not `zip`, because an `.app` is a folder with symlinks and a code signature that a plain zip can break. The signature lives inside the app, so the extended-attribute clutter (`__MACOSX/._*` entries) can be dropped safely, and was.

*Testing.* `tools/run_tests.sh` runs the import step, the unit tests, then the scenarios at a fixed 60 FPS. It returns 0 only if every stage passed. The scenarios stage is skipped, with a message, until `game/verification/scenario_runner.gd` exists (M1 step 8). Today nothing would make `--run-scenarios --quit-when-done` quit, so the command would hang forever.

*Serving the web build.* Browsers won't run a Godot web export from `file://`, and they refuse WebAssembly sent with the wrong content type. `tools/serve_web.sh` starts Python 3's built-in web server on `127.0.0.1` (port 8000, or the first argument). It sends `.wasm` as `application/wasm` and tells the browser not to cache, so a fresh export is never hidden behind an old one. Main's `?debug=1` check (M0 step 7) accepts `localhost` and `127.0.0.1`, so debug tools work through this server and nowhere else.

**Why:** spec "M0 step 10: delivery path" (files, preset table, itch.io files, filters), "M0 step 0: prerequisites" (templates, bundle ID), "M0 done when" (the fourth item), and the step 5 and step 9 notes that were in the Status block. AC served: D-01 (every build and trace names its source revision), D-03 (the web build is tested over HTTP), D-08 (reproducible exports from the repository alone), and D-04 and D-05 through `run_tests.sh`.

**How to see it:**

1. `tools/run_tests.sh`, then `echo $?`. Expect `44 passed, 0 failed.`, `skipped (scenario runner arrives in M1 step 8)`, `run_tests: all passed.` and `0`.
2. With everything committed: `tools/export_all.sh`. It prints `Build 0.1.0-<commit>` and lists the three itch.io zips.
3. macOS: `builds/macos/TRI10NWARE.app/Contents/MacOS/TRI10NWARE -- --debug-tools` (unzip `builds/macos/TRI10NWARE.zip` first). Press backtick: the overlay shows `Build 0.1.0-<commit>`. Running from the editor still shows `0.1.0-dev`.
4. Web: `tools/serve_web.sh`, then open `http://localhost:8000/?debug=1` and press backtick. Without `?debug=1` there is no overlay, and that is correct.
5. itch.io: upload `builds/itch/TRI10NWARE_web.zip` to a draft page, set up as the spec says (kind HTML, 1280 × 720, fullscreen button on, SharedArrayBuffer off). It should load, though the build ID isn't visible there until the title overlay arrives in M3: the debug overlay is off on any host other than this machine.
6. Windows: copy `TRI10NWARE_windows.zip` to the PC, unzip, run `TRI10NWARE.exe -- --debug-tools` from a terminal, and press backtick.

Verification done in this session: `run_tests.sh` exits 0. `export_all.sh`, run from commit `4fa9196` and again after the zip fix, produced all six outputs with exit code 0, left the tree clean and removed `build_info.cfg`. The exported `.pck` files (web, macOS, and the one embedded in the Windows `.exe`) contain `config/build_info.cfg` and no `tests/` script or scene. The `tests/` *paths* still appear as text inside the pack, because Godot's global class list (`TestCase`) and UID cache list every script in the project, but the files themselves are not there. The macOS app is universal (`x86_64 arm64`), its ad-hoc signature verifies after the itch.io zip round trip, and it starts and quits headless with exit code 0 and no errors. `serve_web.sh` served `index.wasm` as `application/wasm` with `Cache-Control: no-store`. No GDScript files changed, so there is nothing for diagnostics to check.

**Decisions and questions:**

- *Owner decision (2026-10-18):* macOS bundle identifier `com.patrickrosander.tri10nware`.
- *Decide and log (engine requirement):* **`import_etc2_astc` turned on** in `project.godot`. Godot 4.5.1 refuses universal and arm64 macOS exports without it. No texture or `.import` file changed.
- *Decide and log:* **exports are release builds** (`--export-release`). Debug tools stay available through `--debug-tools` on desktop and `?debug=1` on localhost, as Main already allows.
- *Decide and log:* **`export_all.sh` deletes `build_info.cfg` on exit**, so editor runs keep the `-dev` build ID (spec: "When missing (editor runs), the game shows 'dev build'"). The overlay's existing `Build 0.1.0-dev` line is how the game shows "dev build".
- *Decide and log:* **build info formats:** `commit` is the 7-character short hash; `date` is UTC `YYYY-MM-DDTHH:MM:SSZ`.
- *Decide and log:* **`run_tests.sh` skips the scenarios** until `verification/scenario_runner.gd` exists. The M0 done-when item needs only the unit tests.
- *Decide and log:* **`serve_web.sh` uses port 8000 by default** (overridable), binds to `127.0.0.1`, and disables caching.
- *Decide freely:* the macOS itch.io zip is built with `ditto --norsrc --noextattr`; the export presets list only the options the spec names.
- *Note:* the Windows export gave no warning about `rcedit` (the tool Godot uses to set the `.exe` icon and version info from a Mac), so no change was needed. Whether the `.exe` shows the game icon or Godot's default is for the Windows check to show.
- No open questions.

## M0 step 11: project documents (2026-10-18)

**What was built:**

- `README.md` (rewritten): how to play each build, including first-launch steps for macOS and Windows; controls; prerequisites and the `GODOT` variable; opening, running, debug tools, tests, exporting, serving the web build, and the itch.io upload steps.
- `CREDITS.md` (extended): a `placeholder` row for `game/icon.svg`, Godot's default icon (MIT).
- `docs/decision_log.md` (new): all 46 tuning values with source and test; every decision from M0 steps 1–11; empty tables for tuning changes, disclosed deviations, added scenarios and owner questions.
- `docs/known_issues.md` (new): severity scale and table; none known.
- `docs/support_matrix.md` (new): engine, renderer, the build Mac (MacBook Air M2, macOS 15.5), and one row per target and browser, each marked tested, partly tested or unverified.
- `docs/evidence/ledger.csv` (new): the header row only.
- `docs/evidence/traces/.gitkeep`, `docs/evidence/media/.gitkeep` (new, empty).
- The reference PDFs and Level 1 mockups were already in place from M0 prep; checked, not changed.

**How it works:** these are the documents a reviewer gets with every submission (AC page 9). Each has one job.

- The **README** is for someone with no help: a player downloading from itch.io, or a developer cloning the repository. The old README described the prototype, with the project at the root and dash on S, so it was rewritten from the step 3 input map and the step 10 tools. It also documents the debug flags, which AC page 9 asks for ("verification-scene/debug access instructions").
- The **decision log** replaces the "Decisions and questions" part of journal entries as the official record. Section 1 lists every tuning value: AC page 9 asks for "selected values", not only choices. Section 2 copies every earlier decide-and-log item and owner decision, each with the test or check that shows it. The journal keeps the longer explanation. From now on, every step records its choices in this log, in the same commit.
- The **support matrix** answers D-02 honestly. It records only what was actually run: the macOS build was launched headless on the build Mac, and Windows and every browser are still **unverified**. A row moves to "tested" only when someone runs the build on that OS or browser and records the version.
- **Known issues** and the **ledger** start empty. The ledger's header matches the spec letter for letter, because M3 and M9 fill it row by row.

**Why:** spec "M0 step 11: project documents" and "Repository layout"; AC page 9 (evidence package, decision and tuning log, known issues, ledger); D-02 (support matrix), D-03 (first-launch and web-serving instructions), D-08 (export instructions, controls, attribution).

**How to see it:** read `README.md` and `docs/support_matrix.md`. When you test the Windows build or a browser, fill in its row in the support matrix. Verified: `tools/run_tests.sh` exits 0 (44 passed, no code changed). The ledger header matches the spec's exactly. The decision log has 46 tuning rows, matching `test_tuning.gd`. The README's controls match the `[input]` section of `project.godot` and the step 3 table.

**Decisions and questions:** recorded in `docs/decision_log.md` (M0.11 rows): the README was rewritten rather than patched; `icon.svg` is registered as a placeholder; earlier decisions were copied into the log, which is now the record. No open questions. M0's done-when checks that need the owner's hands (window size, fullscreen, the trace on quit, the Windows and web launches) are still listed under "Waiting on the owner". Ask for the spec reviewer if you'd like M0 checked against the spec before starting M1.

## M1 step 1: tile set and SolidGrid (2026-10-18)

**What was built:**

- `game/tiles/level_tiles.tres` (new): the single `TileSet`. Tiles are 16 × 16, there are no physics layers, and one integer custom data layer is named `solidity`. Its one atlas source is your `game/art/tiles/level_1_tiles.png`, with 19 tiles. The 15 stone blocks are `1`; the four telephone-pole and wire pieces are `0`.
- `game/core/solid_grid.gd` and its `.uid` (new): `class_name SolidGrid`, the collision view of one room.
- `game/tests/unit/test_solid_grid.gd` and its `.uid` (new): 14 tests.
- `CREDITS.md`: a row for `level_1_tiles.png` (owner draft; please confirm the license).
- `docs/decision_log.md`: M1.1 rows, and one open question (a spec update).

**How it works:** the game uses no physics engine. Each tile carries one number, `solidity`: 0 decoration, 1 ordinary ground or wall, 2 and 3 the default-only and flow-only platforms that arrive in M4. When a room is built, `SolidGrid` walks the used cells of each of the room's tile layers once and copies each cell's number into its own dictionary, keyed by world cell. After that, collision questions never touch the engine's tile maps. This is why a freshly loaded room is solid on its very first tick.

Each cell is stored as a set of flags (solid, default-top, flow-top) rather than a single number. If the same cell is painted on two layers, it keeps both meanings instead of the last layer overwriting the first. The grid answers two questions about a rectangle in world pixels. `blocks(rect)` asks whether the rectangle overlaps anything solid from every side; sideways moves, upward moves and wall checks use it, and platform tops never count. `platform_top_at(rect)` asks whether the rectangle's bottom sits exactly on the top edge of a platform that is solid in the current state; only the downward move will use it. `set_flow()` picks which platform family counts. The player is always in default until M2.

Outside the room there are no tiles, so rules decide. Cells at or below the bottom edge are open, and the bottom is a pit. Every other outside cell (left, right, above, and the top corners) is solid, so those edges behave like walls. Converting pixels to cells uses floor division built from `posmod`. Plain integer `/` rounds toward zero, which would put pixel −1 in cell 0, and the gym may sit at negative coordinates.

The tests build their own four-tile tile set in code, so they keep working whatever you do to the art. One extra test loads the real `level_tiles.tres` and checks its shape and the pole/block assignment.

**Why:** spec M1 build order step 1, "M1 files" (`solid_grid.gd`, `level_tiles.tres`, `test_solid_grid.gd`), "The tile set", the "Room edges" paragraph of step 10, "Determinism contract" and ground rules 8 and 15. Collision basis for AC M-01, M-02 and M-03.

**How to see it:** in Godot, open `tiles/level_tiles.tres`, go to the TileSet panel, choose Paint, and pick the `solidity` property: blocks show 1, pole pieces 0. Nothing in the running game changes yet. Verified: the unit tests run 58 passed, 0 failed (14 new), and the headless run reports no script warnings.

**Decisions and questions:** recorded in `docs/decision_log.md` (M1.1 rows):

- Owner decisions: start M1 now; use `level_1_tiles.png` with the pole as decoration; accept the corner-cell rule.
- Decide-and-log choices: `add_layer()` reads only the layer it is given; room edges count as walls; unknown `solidity` values raise an error; pending-tile tests come in M4.
- **Spec update (approved by the owner, 2026-10-18):** the owner moved the atlas to `game/art/tiles/level_1_tiles.png` in the Godot editor, which kept its UID and updated `level_tiles.tres`. The spec slot, the repository layout, M1 step 1 and the M3/M4 rows now name that file. **Still open:** marking the corner-cell proposal accepted in the spec.

## M1 step 2: PixelMover without assists (2026-10-18)

**What was built:**

- `game/core/pixel_mover.gd` and its `.uid` (new): `class_name PixelMover`, the whole-pixel mover.
- `game/tests/unit/test_pixel_mover.gd` and its `.uid` (new): 16 tests.
- `docs/decision_log.md`: four M1.2 decide-and-log rows.

**How it works:** the mover holds the player's feet position in whole pixels, plus, for each axis separately, a velocity and a sub-pixel remainder as 64-bit floats. Each tick, `move()` adds one tick's worth of velocity to the remainder, moves by the remainder rounded to the nearest pixel, and keeps what is left over, so the remainder always stays between −0.5 and 0.5. A speed of 100 px/s therefore moves 2, 1, 2, 2, 1, 2… pixels (5 px every 3 ticks), and after ten seconds the player is exactly 1,000 px further on: nothing drifts. Rounding to nearest, with halves rounded away from zero, makes left and right exact mirror images.

The movement itself goes one pixel at a time: horizontal first, then vertical. Before each pixel it asks `SolidGrid` whether the body would overlap something solid there. If it would, that axis stops flush against the surface, its velocity and remainder become 0, and the move notes the contact (`wall_hit`, `ceiling_hit` or `floor_hit`) for the player to read in step 7. Because no pixel is ever skipped, nothing can tunnel through a tile, even at dash speed (8 px per tick). Stopping one axis leaves the other alone, so a diagonal dash into the floor slides along it.

One-way platform tops block only a body moving down whose feet are exactly on the tile's top edge. A body rising through the tile, walking sideways through it, or whose feet are already inside the tile never meets that alignment, so it passes. Which platform family counts comes from `SolidGrid.set_flow()`. Two queries round it out. `is_grounded()` asks whether a one-pixel move down would be blocked. `wall_at(side)` makes one overlap test with the body shifted `wall_check_px` (6) to that side, so a wall counts within 0–5 px; only ordinary solid cells and room edges count, never platform tops.

The mover touches no nodes and no autoloads: the grid, body size, wall-check distance and tick rate are passed in. It is plain arithmetic you can test in isolation, which is how the tests drive it, against small grids built in code.

**Why:** spec M1 build order step 2; "M1 files" (`pixel_mover.gd`, `test_pixel_mover.gd`); "How movement works", step 6 (items 1–3) and step 7 ("grounded", "Walls"); "Decide before step 2" (sub-pixel rounding, storage, halves and wall-check distance); the "Room edges" paragraph; "Determinism contract"; ground rules 8 and 15. Collision basis for AC M-01, M-02 and M-03; repeatability for D-04 and D-05.

**How to see it:** nothing visible yet; the player starts using the mover in step 4. Verified: the unit tests run 74 passed, 0 failed (16 new), and the headless run reports no script warnings. The flush-stop test alone runs 5,760 approaches (4 directions × 3 start gaps × every speed from 1 to 480 px/s) and checks that the body never overlaps a solid cell on any tick.

**Decisions and questions:** recorded in `docs/decision_log.md` (M1.2 rows), all decide-and-log:

- Integration divides by the tick rate rather than multiplying by 1/60. It is the same rule, but exact: 30 px/s gives exactly 0.5 px per tick.
- Body geometry: the feet line is the rectangle's bottom edge.
- Wall reach is 0 to `wall_check_px` − 1 px, exactly as the spec words it. My approved plan wrongly said "a gap of exactly 6 px is true"; the spec text governs, and the test follows it.
- Contacts are fields reset on each move; the mover logs no trace events until step 6.

No questions for the owner.

## M1 step 3: rule objects (2026-10-18)

**What was built:**

- `game/core/jump_resolver.gd` and its `.uid` (new): `class_name JumpResolver`, jump precedence and the both-walls rule.
- `game/core/dash_state.gd` and its `.uid` (new): `class_name DashState`, the dash rules.
- `game/tests/unit/test_jump_resolver.gd` and its `.uid` (new): 6 tests.
- `game/tests/unit/test_dash_state.gd` and its `.uid` (new): 12 tests.
- `docs/TRI10NWARE.md`: four owner-approved edits about the charged kind (below).
- `docs/decision_log.md`: five M1.3 rows.

**How it works:** `JumpResolver` has no state. The player hands it yes-or-no facts for this tick (grounded? coyote ticks left? a charged jump possible? a wall in reach? a dash active?) and the press and dash-start ticks, and it answers which jump fires. Outside a dash it is the first true item in the fixed list ground, coyote, charged, wall. During a dash the answer is always "none" unless a charged jump is possible *and* the jump was pressed after the dash started; that is how "jump and dash pressed together gives a clean, full dash" holds. A second helper picks which wall a wall jump leaves: the only wall in reach, or in a one-tile shaft the wall opposite the held direction (with nothing held, the wall behind the player).

`DashState` holds one dash charge plus two countdowns. Starting a dash spends the charge, sets the active countdown to 9 ticks and the cooldown to 12, and remembers the direction: the held 8-way direction, or the facing if nothing is held. It also computes velocities: 480 px/s along the direction at the start and 320 px/s at the end, with diagonals using a stored 1/√2 so they are never faster, and an upward end slowed by × 0.75. `tick_timers()` runs once per tick in step 9 and reports the tick the dash runs out, so a dash started on tick *t* moves on ticks *t* to *t* + 8 and the next can start on *t* + 12.

Refills follow the spec's two causes. `refill_ground()` runs on every grounded tick and gives the charge back only when no dash is active, so a dash along the ground refills on the first grounded tick after it ends, never during it (M-04). `refill_charged()` is the charged jump's refill (M2), which also clears the cooldown so a waiting dash press fires on the next tick: the charged dash (C-08). Both return true only when the charge actually goes from 0 to 1, which is exactly when the trace catalog's `dash_refill` event should be logged. Neither class logs anything itself or reads an autoload; tuning values are passed in.

**Why:** spec M1 build order step 3; "M1 files" (`jump_resolver.gd`, `dash_state.gd` and their tests); "How movement works", steps 3, 4 (precedence, during a dash, wall jump), 7 (refill) and 9 (dash end); "Charged objects, step by step" (refill and cooldown clear); "Same-tick contract" rows on jump kinds, dash and jump presses, and walls on both sides; ground rules 8 and 15. AC M-01, M-02, M-03, M-04, M-05, M-06, C-07, C-08.

**How to see it:** nothing visible yet; the player uses these classes in step 4. Verified: unit tests 92 passed, 0 failed (18 new), with no script warnings in the headless run. The resolver tests cover all 16 eligibility combinations without a dash and, with a dash, presses before, on and after the dash's start tick.

**Decisions and questions:**

- Owner decision: the charged kind is in the resolver now (the M1 test list asked for it; the M2 table said otherwise). The spec was edited with the owner's wording: the precedence order in the `jump_resolver.gd` row, "Step 4, jump" item 3, the charged refill in the `test_dash_state.gd` row, and the M2 `jump_resolver.gd` row removed.
- Decide and log (decision log, M1.3): the both-walls rule and dash velocities live in the core classes; a charged jump clears the cooldown even with a full charge, but `dash_refill` is reported only on 0 → 1; `interrupt()` leaves the cooldown running; the dash test uses constants, because `test_tuning.gd` already pins the tuning values (my plan had proposed a separate guard, which would only duplicate it).

No questions for the owner.

## M1 step 4: the player (2026-10-18)

**What was built:**

- `game/player/player.gd` and its `.uid` (new): `class_name Player`, the rule objects and the step methods.
- `game/player/player.tscn` (new): `Player` → `InputSource` (live) and `Visuals` → `Sprite`.
- `game/player/player_visuals.gd` and its `.uid` (new): picks the animation and facing each frame.
- `game/player/player_frames.tres` (new): the eight animations, using the owner's `game/art/player/player_frames.png` (supplied during this step; committed with its `.import`).
- `game/world/world.gd`: steps 1 and 3–11 wired to the player; the M0 temporary input source removed; a temporary test floor (marked `M1 step 4 only`).
- `game/world/main.tscn`: a `Player` instance under `World`, between `RoomSlot` and `Camera`.
- `docs/TRI10NWARE.md`: two owner-approved edits (below). `docs/decision_log.md`: thirteen M1.4 rows and one question. `CREDITS.md`: the owner's player art registered.

**How it works:** `Player` is a thin adapter. Everything that changes during play lives in rule objects it owns: the `PixelMover` (feet, velocity, sub-pixel remainders), `DashState`, the jump and dash `PressBuffer`s, and a small `MoveState` record (sustain, soft apex, wall-jump lock, coyote, facing, and what step 7 last sensed). `respawn()` throws all of them away and makes new ones, so a reset can never forget a field (R-01). It then senses the ground and walls straight away, so a jump pressed on the very first tick is a ground jump.

Each tick, `World` walks its checklist and calls one player method per step. Step 1 turns fresh presses into tokens, reporting expired tokens first. Step 3 spends a dash token if `DashState` allows it, sets the dash velocity and cancels the jump arc. Step 4 asks `JumpResolver` which jump fires, applies it (ground and coyote: up at 210 px/s plus an 80 px/s nudge toward a held direction; wall: 260 px/s away from the wall with a 10-tick steering lock), then counts coyote down. Step 5 is Celeste's run and gravity: accelerate toward the held speed (scaled by 0.65 in the air), apply gravity (halved near the top of a held jump), hold the rise at jump speed while the 12-tick sustain runs and jump is held, and cap the fall. Step 6 moves in whole pixels, step 7 senses landing, walls and ceilings and refills the dash on the ground, and step 9 runs the timers and ends the dash. Step 10 resets the player when they fall below the failure line. Step 11 copies the feet to the node and points the camera at them.

Rooms arrive in step 5, so for now `World` paints a throwaway test floor out of real tiles at startup: a floor with a 4-tile pit, side walls, a small step, a tall pillar and a ledge. It reads that floor into a `SolidGrid` exactly as rooms will be read. Every line of it is marked `M1 step 4 only`, and step 5 deletes it.

`player_visuals.gd` only reads the state: dash active shows `dash`, airborne shows `jump`, moving shows `run`, otherwise `idle`, all with the `default_` prefix until flow exists in M2. The owner's figure is 12 × 15 px, exactly the body size, and the sprite offset (−10, −20) lays it exactly over the body rectangle.

**Why:** spec M1 build order step 4; "M1 files" (player rows); "The player scene"; "How movement works, step by step" (steps 1, 3–7, 9, 10); "Control locks" (wall-jump and dash rows); "Same-tick contract" (jump kinds, jump and dash on one tick, walls on both sides); ground rules 3, 4, 5, 7, 8 and 13. AC M-01 to M-07, R-01.

**How to see it:** press F5. The player stands on the test floor. Use the arrow keys or WASD to run, jump (hold for higher, tap for lower), wall jump off the pillar or a side wall (holding toward the wall during the lock does not pull you back for 10 ticks), dash in 8 directions, and walk off the step or the pit edge and jump late (coyote). Fall into the pit to respawn at the start. With `-- --debug-tools`, the trace saved on close lists every `press`, `jump`, `dash_start`, `land` and `death` event.

Verified:

- Unit tests: 92 passed, 0 failed. A 120-frame headless run of the game prints no errors.
- A throwaway headless check (scratchpad, not committed; owner decision) drove `World` tick by tick with a `ScriptedInputSource`. All 30 checks passed:
    - A jump on tick 1 is a ground jump at −210 px/s, and the respawn logs no `land`.
    - A held jump rises 54 px and a tapped one 18 px. A held direction adds 80 px/s.
    - A jump pressed 6 ticks before the landing tick fires on it. One pressed 7 ticks before does not, and is logged expired on the landing tick.
    - A coyote jump works on airborne decision tick 6, and nothing fires on tick 7.
    - Wall jumps work off each side, and the lock carries the player away for 10 ticks. After an up-dash and a wall jump, the first refill comes only on the landing tick (M-02).
    - The dash has 9 active ticks, runs 480 → 320 px/s, uses × 1/√2 on diagonals and × 0.75 on an upward end, works in all 8 directions, and refills on landing.
    - Jump and dash pressed together give a clean dash, and the jump token expires on tick 8.
    - A fall logs `death` cause `fell` and resets to the spawn point with fresh state.
    - The same script run twice gives identical traces, and there are no `volts` events.
- Diagnostics: the editor still showed "Could not find type Player" in `player_visuals.gd` before its class cache refreshed. Headless loading resolves the class (it is in `global_script_class_cache.cfg`); if the error remains after the editor rescans, tell the next session. The `pixel_mover.gd` integer-division warning is older than this step and its line already has `@warning_ignore`.

**Decisions and questions:**

- Owner decisions (plan review): the temporary test floor; the throwaway check script instead of a new test file; `respawn()` senses grounded, walls and coyote without logging `land`; the soft apex needs allowed + held + `abs(vy) < 80`; coyote uses `Tuning.coyote_ticks`; the camera's interpolation is reset after a fall reset; a Status note for step 5.
- Owner-approved spec edits: the wall-jump and dash locks moved from build-order step 6 to step 4; step 9's "Expire stale tokens." now says tokens are expired in step 1.
- Owner art: the owner supplied `player_frames.png` during the step. `player_frames.tres` uses it, and the developer's placeholder was removed before commit.
- Decide and log (decision log, M1.4): air control on both acceleration and reduction; the facing rules; gravity on grounded ticks; `jump.object` is `""`; `land.vy_before`; replaced tokens logged as expired; the M1 fall reset without a `respawn` event.
- Question: the art file is `player_frames.png`, but the spec slot is `player_sheet.png`. Rename the file, or rename the slot?

## M1 step 5: rooms, gym skeleton (2026-10-18)

**What was built:**

- New: `game/rooms/room.gd`, `room_entrance.gd`, `room_entry.gd`, `room_catalog.gd`, `room_catalog.tres`, and `game/verification/gym/gym.tscn` (the skeleton), plus Godot's `.uid` files for the new scripts.
- Changed: `game/world/world.gd` gains `load_room()`, and every `M1 step 4 only` line (the test floor) is gone. `docs/TRI10NWARE.md` (load_room step 4, owner-approved), `docs/decision_log.md`.

**How it works:**

The **catalog** (`room_catalog.tres`) is the world map. It holds one `RoomEntry` per room: the room's ID, its scene, and its `world_rect`, its place and size on the map in pixels. It also names the starting room and entrance, which in M1 are `gym` and `start`. Rooms never point at each other; only the catalog knows where each one sits.

A **room scene** has a `Room` root and the seven fixed children from the spec's room convention. Its content is built with its top-left corner at (0, 0); World moves the whole room to `world_rect.position` when it builds it. `Room` looks up its own bounds in the catalog, finds entrances by ID (or lists them sorted by node name), and builds its `SolidGrid` from its three tile layers. In the editor it draws an orange outline of its bounds so you can see where to paint. It reads the catalog with `load()` rather than `preload`, because the catalog contains the room's scene and the scene contains `room.gd`; a preload would be a loop. An **entrance** is a `Marker2D` whose position is where the player's feet appear. It also says which way the player faces.

`World.load_room(room, entrance, is_respawn)` does the spec's four steps. It frees the old room, builds a fresh one from its scene at its map position, builds the grid, and places the player there with fresh rule objects. It then clamps the camera to the new bounds, moves it without smoothing, and logs one event: `room_enter`, or `respawn` for a respawn. World remembers the current room and the checkpoint entrance. The game starts with `load_room(start_room, start_entrance)`. A fall logs `death` and then calls `load_room(room, checkpoint, true)`, which also marks held buttons stale. Because the room is rebuilt from its scene rather than repaired, every retry starts from the room exactly as designed (R-01). Each trace line is now stamped with the current room's ID.

**Why:** "M1 build order" step 5, "M1 files" (the room rows), "Room scene convention", "Gym stations in M1", and "How rooms connect". It serves R-01 (a fresh room and player on every respawn) and prepares M-01 to M-08, whose scenarios run in the gym in step 8.

**How to see it:** open `game/verification/gym/gym.tscn`. The orange rectangle is the gym's bounds (2560 × 512, which is 160 × 32 tiles), and the `Entrances` node holds ten markers. Press F5: until the gym is painted, the player drops into the pit at the bottom and respawns at `start` about every half second. That is expected. With `-- --debug-tools`, the saved trace shows one `room_enter` and then `death`/`respawn` pairs.

**Painting guide for the owner.** The columns and rows are tiles measured from the gym's top-left corner. Paint ordinary ground and walls on `WorldTiles`. Each station's floor top is row 26 (y = 416 px), with floor tiles from row 26 down, except the two drop stations, whose ledge tops are at row 20. Put divider walls between stations wherever they help. Each entrance marker already sits on its planned floor top. If you paint a station somewhere else, drag its marker so it stays on a tile top (y a multiple of 16).

| Entrance | Columns | Paint |
| --- | --- | --- |
| `start` | 0–11 | Open floor |
| `run_track` | 12–55 | 40 tiles of flat floor plus a margin each side |
| `wall_shaft` | 56–65 | Two tall walls 6 tiles apart (inside, columns 58–63) |
| `narrow_shaft` | 66–71 | Two tall walls with a 1-tile gap (column 68) |
| `single_wall` | 72–81 | One tall wall, open space beside it |
| `chimney` | 82–89 | Two walls 4 tiles apart (inside, columns 84–87), tall, open at the top. The width is **provisional** from current tuning; step 8's scenario confirms it |
| `corner_ceiling` | 90–105 | Low ceilings with corners at about 3.5 tiles up (jump height is about 55 px), and ledge lips at dash height (a dash covers about 72 px) |
| `dash_chamber` | 106–119 | A closed box, 12 × 8 tiles inside: floor top at row 26, ceiling at row 17, walls at columns 106 and 119 |
| `coyote_ledge` | 120–139 | A ledge with its top at row 20, then a long drop with no floor, to the pit at the bottom edge |
| `buffer_drop` | 140–153 | A ledge with its top at row 20, then a 6-tile drop to flat floor at row 26 |

Columns 154–159 are spare.

**Decisions and questions:**

- Owner decisions (plan review): no new test file this step (M6's `test_world_layout.gd` checks the catalog); a fall logs `death` then `respawn`, never `room_enter`, through `load_room()`'s `is_respawn` parameter. The spec's load_room step 4 now reads "log `room_enter`, or `respawn` when the call is a respawn" (owner-approved).
- Decide and log (decision log, M1.5): the gym's `world_rect`; the station layout and entrance positions; the provisional chimney width; deferring the catalog's point and neighbor lookups to M6; reading the catalog with `load()`, not `preload`.
- Check run: 92 unit tests pass; import and a 300-frame headless run printed no errors. A throwaway script (not committed) confirmed `room_enter gym start` at tick 0, then `death`/`respawn` pairs only, one room under `RoomSlot`, and the feet at the gym's world offset.
- The owner's art rename (`player_frames.png` → `player_sheet_v1.png`, with `player_frames.tres` re-saved) was left untouched by this step; the owner committed it separately (`a29f319`). The slot-name question stays open: the spec's slot is still `player_sheet.png`.

## M1 step 6: assists (2026-10-18)

**What was built:**

- `game/core/pixel_mover.gd`: the four movement assists. The constructor now also takes `corner_correction_px`, `dash_corner_correction_px`, `oneway_assist_px`, `post_dash_snap_px` and `apex_threshold_px_s`. `move()` takes the facing and the active dash's direction. New: `corner_shift` and `dash_corner_shift` (what the last move did), `oneway_help()` and `post_dash_snap()`.
- `game/player/player.gd`: passes the new tuning to the mover, calls each assist in its step, and logs `assist` events.
- `game/tests/unit/test_pixel_mover.gd`: 13 assist tests (105 unit tests in total).
- `docs/decision_log.md`: seven M1.6 rows.

**How it works:** the assists are small, forgiving nudges, all borrowed from Celeste. Each one moves the player only into empty space, never into a tile.

The two *corrections* happen inside the move itself (step 6). When a rising player's head clips the edge of a ceiling, the mover looks up to 8 px left and right for a spot where the head would clear it. It takes the nearest one, slides there and keeps rising, so a jump that just catches a corner isn't killed. The **dash corner correction** is the sideways version. When a horizontal or up-diagonal dash would hit a ledge lip in the bottom 8 px of the body, the mover lifts the body up to 8 px and the dash carries on over the lip. Each correction can happen at most once per move. Corner correction shifts the horizontal position during the vertical pass, and dash corner correction shifts the vertical position during the horizontal pass, so this gives exactly the spec's "one correction per axis per tick".

The two *snaps* happen outside the move. **One-way platform help** runs at the start of step 7. A player rising slowly (near the top of a jump) whose feet are within 8 px below a one-way platform's top is lifted onto it and stops rising. The normal sensing that follows sees the player standing there and logs `land`, so it counts as a real landing. One-way platforms arrive in M4, so for now only the unit tests use this. The **post-dash floor snap** runs in step 9, when a dash ends. If the dash was horizontal or downward and the floor is within 6 px below the feet, the player is moved down onto it, so a dash that ends just above the ground doesn't leave a floaty little fall.

The mover is a pure rule class and may not touch `Trace` (ground rule 8), so it only reports what it did. `Player` writes the `assist` event, with `kind` set to `corner`, `dash_corner`, `oneway` or `dash_snap`, and `dx`, `dy` set to the nudge in pixels.

**Why:** spec "How movement works, step by step" (the **Movement assists** table and **Assist precedence**), the "Several assists could apply" and "Corner correction fits both ways" rows of the **Same-tick contract**, and "M1 files" (`pixel_mover.gd`, `test_pixel_mover.gd`). Serves M-01 to M-03 (forgiving, consistent movement) and D-04/D-05 (all whole-pixel, deterministic).

**How to see it:**

- Run `tools/run_tests.sh`: the new tests are in the `test_pixel_mover.gd` block.
- In the gym, with `-- --debug-tools`: dash sideways into a ledge lip so the dash starts just below the lip's top. The player hops onto it instead of stopping, and the saved trace shows `assist` with `kind` `dash_corner`. A throwaway check against the painted gym (not committed) found lips at columns 91–115 where this fires, with lifts of 1–8 px.
- Corner correction can't be seen in the gym yet, because the `corner_ceiling` station isn't finished (Status block).

**Decisions and questions:**

- Decide and log (decision log, M1.6): what "fits" means for each correction; which dashes get the dash corner correction; once per move; the one-way help's conditions and its place in step 7; the post-dash snap's floor rule and its landing timing (sensed on the next tick's step 7, one tick later than Celeste); the meaning of `assist` dx/dy; and the tie-break and once-per-move cases that only a wider limit can reach.
- **Gym check (owner):** the gym committed in `54b8164` is only partly painted. Columns 0–89 are painted (`start` through `chimney`). The `wall_shaft` marker (x 976) and the `corner_ceiling` marker (x 1480) sit inside solid tiles, so a player sent there is stuck. `dash_chamber`, `coyote_ledge` and `buffer_drop` have no floor: from column 100 on, row 26 is open to the pit. The box at columns 91–115, rows 18–24, and the blocks at rows 10–14 look unfinished. None of this affects step 6 or 7, but M1 step 8's scenarios need every station.
- Note: `54b8164` also added `[editor] movie_writer/movie_file` with an absolute path under `/Users/patrickrosander/` to `project.godot`. It's harmless, but machine-specific. Left as is.

## M2 step 1: rule objects (2026-10-19)

**What was built:**

- `game/core/geometry.gd`: `Geometry`, static overlap tests: `rects_overlap`, `circle_overlaps_rect`, `inflate`.
- `game/core/flow_ledger.gd`: `FlowLedger`, the state, volts and zero-volt countdown.
- `game/core/encounter_tracker.gd`: `EncounterTracker`, one charged object's outside / armed / spent state.
- `game/tests/unit/test_geometry.gd`, `test_flow_ledger.gd`, `test_encounter_tracker.gd`: 40 new tests (145 unit tests in total).
- `docs/TRI10NWARE.md`: the new **M2 build order** (owner approval of the plan, 2026-10-19).
- `docs/decision_log.md`: the M2 build-order row and five M2.1 rows.

**How it works:** these are M2's three rule classes. Like `DashState` and `JumpResolver` in M1, they are plain objects with no nodes, so they can be tested alone. Nothing in the game uses them yet; step 2 wires the ledger into the player and step 3 wires the other two into the charged object.

**`FlowLedger`** is the only thing allowed to change the player's state (default or flow), volts, or the countdown (ground rule 6). Its `request_switch()` follows the **FlowLedger rules** table. Entering flow costs a volt, and spending the last one starts a 180-tick countdown. At 0 volts entry is refused. Leaving flow is free, and the countdown keeps running (the AC setting). `tick()` runs once per tick in step 9 and returns true exactly once, when the countdown runs out. `recharge()` (used by M5's power sources) refills the volts and cancels the countdown, and `reset()` is the respawn. A rule class may not call `Trace` itself, so every change *returns* the trace events it caused, for example `switch`, then `volts`, then `countdown_start`. Step 2's `FlowController` just writes them out. A test checks every one of them against `Trace`'s catalog, so a misspelled field fails a test instead of printing an error at runtime.

**`EncounterTracker`** is what makes "one charged jump per visit" work. Step 7 gives it two yes/no answers each tick: does the region touch the player, and does a 1 px larger region touch the player? Outside becomes armed on the first answer. Armed or spent becomes outside only when even the larger region no longer touches, so a player hovering exactly on the edge can't flicker back to armed and get a second jump. A charged jump calls `spend()`. The tracker never hears about state switches, so toggling flow inside a region can't re-arm it.

**`Geometry`** does those overlap tests in whole-pixel integers. The circle test finds the point of the player's rectangle nearest the circle's center and compares squared distances (`dx² + dy² < r²`), with no square roots or floats, so it gives the same answer on every computer and in the browser.

**Why:** spec **M2 files** (the three classes and their tests), **FlowLedger rules**, **Charged objects, step by step** (step 7 sensing), the **Same-tick contract** rows on regions and on recharge versus expiry, and ground rules 6, 8 and 15. Serves S-02, S-03, S-04, C-03, C-04 and M-08.

**How to see it:** run the unit tests (`"$GODOT" --headless --path game res://tests/test_runner.tscn`, or `tools/run_tests.sh`). The three new files' blocks are `test_encounter_tracker.gd`, `test_flow_ledger.gd` and `test_geometry.gd`. Nothing changes in the game yet.

**Decisions and questions:**

- Decide and log (decision log, M2.1): touching never counts as overlap; the trace values `switch`, `recharge`, `default` and `zero_volts`; how the non-AC `pause` and `stop` countdown modes behave; entering flow at 0 when the flag allows it (free, and it never restarts a running countdown); and returning events instead of logging them.
- Skipped because it waits for the postponed M1 steps: nothing in this step.
- The editor's diagnostics still show stale "Could not find type FlowLedger" errors, because the editor hasn't rescanned since these files were created outside it. The headless run compiles all six files and every test passes. `geometry.gd`, `encounter_tracker.gd` and the other two test files haven't been analyzed by the editor yet; check them after the rescan (Status block).

## M2 step 2: flow in the player (2026-10-19)

**What was built:**

- `game/player/flow_controller.gd` (new): `FlowController`, the `FlowLedger`'s adapter in the player scene.
- `game/player/player.tscn`: a `FlowController` node beside `InputSource`.
- `game/player/player.gd`: the step 2 method `step_switch()`, with the coyote re-check; `respawn()` gives the controller a fresh ledger; `step_timers()` counts the countdown.
- `game/world/world.gd`: step 2 calls the player's switch step; step 10 checks countdown expiry before falls.
- `game/tests/unit/test_flow_controller.gd` (new): 9 tests (154 unit tests in total).
- `docs/TRI10NWARE.md`: the `test_flow_controller.gd` row in the **M2 files** table (owner approval, 2026-10-19).
- `docs/decision_log.md`: four M2.2 rows.

**How it works:** M2.1's `FlowLedger` decides everything about state, volts and the countdown, but it may not touch nodes or `Trace`. `FlowController` is the small node that connects it to the game. On a fresh switch press, the player asks the controller to switch. The controller asks the ledger, and if the state changed it tells the room's `SolidGrid` which platform family is now solid (default-only tops in default, flow-only tops in flow). It then writes the events the ledger returned (`switch`, `volts`, `countdown_start` or `switch_refused`) to the trace. Only `switch_pressed` reaches it, never `switch_held`, so holding the button can't spend two volts.

After a successful switch, the player checks its floor again with the same 1 px downward probe step 7 uses. If the player was standing on a platform of the family that just stopped being solid, they become airborne at once, with the full 6-tick coyote window. Steps 3 and 4 run later in the same tick, so a jump pressed on the switch tick is already a coyote jump. That is exactly what happens on the first airborne tick after walking off a ledge. Nothing else about the player changes: position, velocity and an active dash are left alone (S-01).

The countdown is split across two steps. Step 9 counts it down and, on the tick it reaches 0, logs `countdown_expire` and raises a flag. Step 10 reads the flag before checking falls (the spec's outcome order), logs `death` with cause `countdown`, and resets the player at the entrance, the same quick M1-style reset a fall uses until M3 adds the death sequence. Splitting it this way leaves room for M5: a recharge in step 8 cancels the countdown before step 9 can expire it, so the player is saved on the last tick. On every respawn the controller gets a brand-new ledger (default, 3 volts, no countdown) rather than a reset one (R-01).

**Why:** spec **M2 build order** step 2, **FlowLedger rules** ("What the flow controller does after a successful switch"), **What happens on every tick** (steps 2, 9, 10), **How movement works, step by step** (step 10 order, decision ticks), **The player scene** ("Fresh state on every respawn"), ground rules 3, 5, 6 and 7. Serves S-01, S-02, S-03, S-04, M-08, R-01.

**How to see it:** run the unit tests; the new block is `test_flow_controller.gd`. In the game, press the switch key (Z) with `-- --debug-tools`, then save the trace on window close. It shows `switch` and `volts` events. On the third entry into flow it shows `countdown_start`, and 180 ticks later `countdown_expire`, `death` (cause `countdown`) and `respawn`. Nothing is visible on screen yet: the gym has no platform tiles (M4), and the HUD and switch visuals arrive in M2 step 5.

**Decisions and questions:**

- Owner decision: the new unit test file `test_flow_controller.gd`, added to the spec's M2 files table.
- Decide and log (decision log, M2.2): a vanished floor makes the switch tick the first airborne decision tick, and a platform appearing under an airborne player waits for step 7; switch presses are not logged as `press`; the controller logs the ledger's events before the player's support re-check (the trace order is the same).
- Skipped because it waits for the postponed M1 steps: scenarios `s01`–`s04` and the flow cases in `m02`, `m04`, `m05`, `m07`, `m08` (M1.8); `test_flow_controller.gd` checks the same rules with unit tests until then. A World-level check of the countdown death (step 10 calling `load_room`) belongs to `s04`, so it also waits.
- Left for later M2 steps: the charged jump (step 3), and `Visuals/SwitchFX` and the `electric_` animations (step 5).

## M2 step 3: charged object (2026-10-19)

**What was built:**

- `game/objects/charged_object/charged_object.gd` (new): `ChargedObject`, a `@tool` node with `region_radius_px` (−1 = tuning default), `always_powered`, `powered`, an `EncounterTracker`, step 7 sensing, spending, and the ring drawn with `draw_arc()`.
- `game/objects/charged_object/charged_object.tscn` (new): `ChargedObject` → `Sprite`, `Glow` (additive `CanvasItemMaterial`).
- `game/art/objects/charged_object.png`, `game/art/objects/charged_glow.png` (new placeholders), registered in `CREDITS.md`.
- `game/rooms/room.gd`: `charged_objects()`, every charged object under `Objects` at any depth, sorted by node name.
- `game/player/player.gd`: `respawn()` takes the room's objects; step 7 senses them; step 4 now supplies charged eligibility and performs the charged jump.
- `game/world/world.gd`: `load_room()` passes `room.charged_objects()` to the player.
- `game/tests/unit/test_charged_jump.gd` (new): 8 tests (162 unit tests in total).
- `docs/TRI10NWARE.md`: the `test_charged_jump.gd` row in the **M2 files** table (owner approval, 2026-10-19).
- `docs/decision_log.md`: seven M2.3 rows.

**How it works:** a charged object is a circle whose center is the node's origin. Each tick, in step 7, the player hands every object in the room its body rectangle, in node-name order. The object asks `Geometry` two questions: does the circle overlap the body (entry), and would it still overlap with the radius 1 px bigger (still inside)? Its `EncounterTracker` turns those answers into outside, armed or spent, and every change is logged as `encounter`. The extra pixel on the way out stops a player resting exactly on the boundary from flickering in and out, which would otherwise re-arm the region.

In step 4, a charged jump is possible when the player is in flow, airborne, and at least one powered object is armed. `JumpResolver` (built in M1) already ranks it after ground and coyote jumps, and lets it, alone, cut a dash whose start came before the press. When it fires, the player first notes which object it will be logged against (the one nearest the body's center), then cuts any active dash while keeping its horizontal speed, sets vertical speed to exactly −440 px/s, and turns off the sustain and the soft apex, so holding or releasing jump changes nothing. It spends every armed region the player is inside, so overlapping regions give one jump, not two, and refills the dash. Because the refill also clears the dash cooldown, a dash press that waited in its buffer on the same tick fires on the next tick: that is the charged dash (C-08).

Timing falls out of the tick order. A region entered during the move of tick *N* is armed in step 7 of *N*, after step 4 has already run, so the first charged jump is on *N* + 1. A press buffered up to 6 ticks earlier is still valid then. The objects are rebuilt with the room on every respawn, so their trackers start fresh (R-01).

**Why:** spec **M2 build order** step 3, **M2 files**, **Charged objects, step by step**, **Same-tick contract** (region entry and exit, overlapping regions, dash cutting), **How movement works, step by step** (decision ticks, step 4), **Room scene convention**, ground rules 3, 7, 8, 13 and 14. Serves C-01 to C-08 and V-03.

**How to see it:** run the unit tests; the new block is `test_charged_jump.gd`, tick-exact cases first, as the owner asked. In Godot, open `game/objects/charged_object/charged_object.tscn`: a grey placeholder square with a light-blue ring at the tuning radius (64 px). Change `region_radius_px` in the Inspector and the ring follows. There is no charged object in the gym yet; that is step 4.

**Decisions and questions:**

- Owner decision: the new unit test file `test_charged_jump.gd`, added to the spec's M2 files table, with the tick-exact cases prioritized.
- Decide and log (decision log, M2.3): the meaning of "nearest" for the `jump` log; every armed region is spent, powered or not; the trace order within a charged jump; the ring and glow until M3; the placeholders; reading the radius from `tuning.tres` in the editor.
- Note: the test drives the player with its own copy of World's steps 1–9 (`_tick()`), because nothing can run a whole World headless until the scenario runner exists. That copy does not log `press` or `press_expired`; the test checks the buffer directly.
- Skipped because it waits for the postponed M1 steps: scenarios `c01`–`c08`, the `m05` ledge-into-region case (M1.8), and the region drawing in `debug_world_draw.gd` (M1.7).
- Left for later steps: the gym's charged stations (M2.4), and the glow's faint-in-default, full-in-flow behavior and ring visibility by state, which belong to `flow_presentation.gd` (M3).

## M2 step 4: gym charged stations (2026-10-19)

**What was built:**

- `game/verification/gym/gym.tscn`: seven `ChargedObject` instances under `Objects` (`ChargedTest`, `ChargedPairA`, `ChargedPairB`, `ChargedOverlapA`, `ChargedOverlapB`, `ChargedCeiling`, and `UnpoweredObject` with `always_powered` off), and six entrances under `Entrances` (`charged_test`, `charged_pair`, `charged_overlap`, `charged_ceiling`, `unpowered_object`, `zero_volt_lane`).
- `game/rooms/room_catalog.tres`: the gym's `world_rect` is now 5120 × 512 (320 × 32 tiles), up from 2560 × 512.
- `game/objects/charged_object/charged_object.tscn`: keeps the UID stamps the editor added, and drops the `region_radius_px = 64` the editor re-save had left on it (owner decision).
- `docs/decision_log.md`: five M2.4 rows.

**How it works:** nothing new in the rules. This step only places things in the gym, so each M2 rule has a spot of its own to try it in. Each station has its own entrance, so the debug menu and (later) the scenarios can start right there. Each object is an instance of the step 3 scene. It keeps the default radius of −1, so all seven follow `charged_region_radius_px` in `tuning.tres`. If the radius is retuned, every ring and every region changes together.

The heights come from the current tuning. A held jump rises about 56 px, so from the floor (feet at y 416) the head peaks around y 345. Every object's center is at y 320, six tiles above the floor, so its region reaches down to y 384. A player standing on the floor (head at y 401) is outside every region, and a jump carries the head well inside. That lets a jump with a run-up meet the region's edge while rising, at the top, or on the way down, depending on where it starts. That is what `charged_test` (C-01, C-05, C-07) needs. In `charged_pair`, the two regions are 32 px apart, enough room for the 12 px body plus the 1 px exit margin on each side, so the player can truly be outside both between them. In `charged_overlap`, the two regions share 64 px, so one jump inside both must spend both. `charged_ceiling` needs a ceiling whose underside is two tiles above the object's center, so a charged launch hits it while still in the region (C-06: a ceiling hit must not re-arm). `zero_volt_lane` is just a long floor: 39 tiles, more than the about 540 px a 3-second countdown covers at full run.

The gym had only six spare columns, so it grew to the right. The new stations continue the same single row, with the same floor height as M1's.

**Why:** spec **M2 build order** step 4, **Gym stations added in M2**, **Gym stations in M1** (one entrance per station; the developer states tuning-dependent sizes before the owner paints), **Room scene convention**, **Same-tick contract** (unique node names, so the order is fixed). Prepares C-01 to C-08 and S-03, S-04.

**How to see it:** open `game/verification/gym/gym.tscn` and scroll right past column 160 (x 2560). You'll see seven grey squares with light-blue rings in the air above where the floor will go, and six entrance markers on the floor line. Until the stations are painted, a player sent there falls into the pit. With `-- --debug-tools`, the debug menu can't jump to them yet (that's the postponed M1.7).

**Painting guide for the owner.** Columns and rows are tiles from the gym's top-left corner. As before, every station's floor top is row 26 (y 416), with floor tiles from row 26 down, on `WorldTiles`. Each entrance marker already sits on its floor. Add divider walls between stations wherever they help, but keep each station's columns between the object and its entrance open, since that space is the run-up.

| Entrance | Columns | Object centers (px; row 20 = y 320) | Paint |
| --- | --- | --- | --- |
| `charged_test` | 160–183 | x 2752 (column 172) | Open floor under the object. Three **height marks** as decoration (solidity 0, or backdrop art), beside the region at the heights a jump enters it: row 23 (the region's bottom edge, y 384), row 21 (the top of a held jump, head at about y 345) and row 20 (the region's center). They're visual aids only; place them however reads best |
| `charged_pair` | 184–215 | x 3136 and 3296 | Open floor; nothing between the objects |
| `charged_overlap` | 216–239 | x 3632 and 3696 | Open floor |
| `charged_ceiling` | 240–259 | x 4000 | Open floor, and a **ceiling on row 17** (its underside at y 288) spanning at least columns 246–253, above the object. Leave rows 18–25 open beneath it |
| `unpowered_object` | 260–279 | x 4320 | Open floor |
| `zero_volt_lane` | 280–319 | none | Flat floor across the whole lane, with a wall at column 319 (the room's right edge) |

Columns 154–159 (left over from M1) can simply continue the floor.

**Decisions and questions:**

- Owner decisions (plan review): the `charged_test` markers are painted decoration, not entrances (a scenario file has one entrance); `charged_object.tscn` keeps its UIDs and loses the `region_radius_px = 64` override.
- Decide and log (decision log, M2.4): the wider gym `world_rect`; the station columns and entrance positions; the object heights and spacings, and the `charged_ceiling` ceiling row.
- Check run: import clean; 162 unit tests pass. A throwaway scene (not committed) loaded the gym. It found 16 entrances, and 7 charged objects in node-name order, all at radius 64 from tuning, only `UnpoweredObject` unpowered, none armed, with bounds 5120 × 512. No script changed, so there was nothing new for the diagnostics tool.
- No new unit-test file: this step wires no rules into the player (standing rule, **Postponed work**).
- Skipped because it waits for the postponed M1 steps: scenarios `c01`–`c08` and `s01`–`s04` (M1.8), which will run at these stations, and the region drawing in `debug_world_draw.gd` (M1.7).
- If `charged_region_radius_px`, the jump or the body size is retuned, recheck the object height (y 320) and the `charged_pair` gap.

## M2 step 5: HUD and switch visuals (2026-10-19)

**What was built:**

- `game/ui/hud.tscn` (new): `HUD` CanvasLayer (layer 10) → `Root` (full screen, `theme.tres`) → `TopLeft` row (`VoltPips`, `StateIcon`, `DashPip`) and `Countdown` (`Ring` TextureProgressBar, `Numerals` Label).
- `game/ui/hud.gd` (new): reads the player every frame; flashes the volt pips on `switch_refused`.
- `game/ui/theme.tres` (new): the pixel font at its native 8 px.
- `game/art/fonts/pixel_font.ttf` (+ `.import`): the owner's Pixel Operator HB 8, moved from `PixelOperatorHB8 copy.ttf` to the slot path (owner decision), imported with antialiasing, hinting and subpixel positioning off.
- Placeholders: `game/art/player/switch_burst.png`, `game/art/ui/volt_pip.png`, `dash_pip.png`, `state_icons.png`, `countdown_ring.png`, all registered in `CREDITS.md` (plus the font's row).
- `game/world/main.tscn`: adds `HUD`, its `player` pointed at `World/Player`.
- `game/player/player.tscn`: adds `Visuals/SwitchFX` with an embedded `burst` animation.
- `game/player/player_visuals.gd`: plays `SwitchFX` on each `switch` event.
- `docs/TRI10NWARE.md`: the `state_icons.png` row now lists three frames (owner decision).
- `docs/decision_log.md`: eight M2.5 rows.

**How it works:** the HUD only reads. Every rendered frame, `hud.gd` asks the player's `FlowLedger` for volts, state and countdown, and asks `DashState` whether a charge is held, then picks the matching picture for each element. Nothing in it can change the game. It builds one pip per `max_volts`, so a retune to 4 volts would show 4 pips.

Each art file is a strip of equal frames. `hud.gd` cuts a strip into frames by dividing its width by the frame count, so you can draw the final art at any size, as long as you keep the frame order: volt [full, empty], dash [available, spent], state [default, flow, warning]. The warning frame shows in flow at 0 volts, when switching back to default means certain death.

The countdown appears only while it runs. The numerals are whole seconds rounded up (3, 2, 1). The ring is a radial progress bar whose value is the ticks left out of 180, so it drains smoothly while the numbers step. The numerals are drawn at 16 px, exactly twice the font's native 8 px, so they stay crisp.

Two things are moments rather than states, so they listen to the trace signal (`Trace.event_logged`) instead of reading the player. A refused switch changes nothing, so the event is the only way to see it: the pips blink red three times in 0.4 s. A successful switch plays `SwitchFX`, a 4-frame burst drawn over the player sprite and hidden when it finishes. Both run on rendered time and never feed back into the simulation (**Visuals are a window, not a lever**).

**Why:** spec **M2 build order** step 5, **M2 files**, **Files extended in M2**, **HUD layout**, **Visuals are a window, not a lever**, ground rules 3, 12 and 13, and level design rule 1 (the warning). Serves V-03 and V-04.

**How to see it:** press F5. At the top left: three yellow pips, a grey square (default) and a green square (dash). Press Z: a pip empties, the square turns cyan, and a white burst flashes on the player. Press Z twice more, until you're in flow at 0 volts: the square turns red, and a ring with "3" appears at the top center and drains. Switch back and press Z again: the refusal flashes the pips red. Dash: the green pip goes dark until you land.

**Decisions and questions:**

- Owner decisions: the font, moved to the slot path and used at 8 px; three state-icon frames (spec row updated); colored-square placeholders for the state icons and a green dash pip.
- Decide and log (decision log, M2.5): the sheet layouts and placeholder sizes; the dash pip ignores the cooldown; the countdown's rounding, its size and the ring's fill; the refusal flash timing; the HUD layer and positions; SwitchFX placement and its embedded frames.
- Check run: import clean; 162 unit tests pass. A throwaway scene (not committed) loaded `main.tscn` and went through flow at 2, 1 and 0 volts, 61 countdown ticks, a return to default, a refusal and a spent dash. Every pip, icon and dash frame, the countdown's visibility, its numerals (3 → 2) and the ring (180 → 119 of 180) matched, and SwitchFX showed. Diagnostics: `player_visuals.gd` is clean; `hud.gd` hasn't been analyzed yet (the editor analyzes files once opened), so the owner should open it once.
- No new unit-test file: this step wires no rules (standing rule, **Postponed work**).
- Question: please confirm the font's license and source link in `CREDITS.md` (Pixel Operator by Jayvee Enaguas is believed to be CC0).

## M3 step 1: Level 1, playable (2026-10-20)

**What was built:**

- `game/objects/goal/goal_zone.gd` (new, plus its `.uid`): the `GoalZone` node.
- `game/rooms/level_1/level_1.tscn` (new): the Level 1 room, with nodes placed and tile layers empty for the owner to paint.
- `game/rooms/room_catalog.tres`: adds `level_1` at `world_rect` (0, 0, 640, 368) and makes it the start room.
- `game/world/world.gd`: step 10's completion check, and the `Outcome` decision as a static function.
- `game/rooms/room.gd`: `goal_zones()`, the lookup World uses.
- `game/tests/unit/test_goal_zone.gd` (new): the stand-in for `l1_04`'s completion cases; its row is added to the spec's **M3 files** table (owner-approved).
- `docs/decision_log.md`: four M3.1 rows.

**How it works:**

A `GoalZone` is a thin invisible strip lying on a platform's top surface. Its origin is the surface's left end. It reaches `width_px` to the right, and from 4 px above the surface down to the surface row itself. That row matters: the mover puts a standing player's feet exactly on the floor tile's top line, so a zone that stopped one pixel short would never contain a standing player. In the editor it draws a green outline so you can see where it is; in the game it draws nothing.

Step 10 now asks three questions in a fixed order: is the player grounded with feet inside a goal zone, has the countdown run out, or have they fallen? The first "yes" wins. That is the **Same-tick contract**'s order, so landing on the goal on the very tick the countdown expires still counts as a win. "Grounded" comes from step 7 of the same tick. That is what stops the two false wins L1-04 worries about: touching the destination's side (never grounded on top) and flying through the strip (airborne). The decision is a small static function, `World.outcome()`, so a unit test can ask it directly, without building the whole game screen.

When the room is complete, World logs `room_complete` and, until step 2 adds the completion overlay, rebuilds Level 1 and puts you back at `start`. It marks your held buttons stale, so a jump you are still holding doesn't fire on arrival. Because the room is rebuilt immediately, `room_complete` is logged once per arrival.

**Placing the layout.** Positions came from a throwaway placement aid run in the session scratchpad (not committed). It is *not* the bypass search. It ran the real player rules for one jump plus one dash in 8 directions, with automatic wall jumps, and checked a destination 2 tiles closer than the real one. Nothing landed there. The aid's charged-route attempts never produced a charged jump, a flaw in the throwaway script that wasn't fixed within the two-run time box. So **whether the charged route reaches the destination is unconfirmed**. Your playtest decides it. Details are in the decision log (M3.1).

**Painting guide (all in `WorldTiles`, any ordinary tile with solidity 1; tile coordinates are column, row; the room is 40 × 23 tiles):**

| Part | Tiles | Notes |
| --- | --- | --- |
| Start platform | columns 0–7, rows 16–22 | Top surface y 256; `Start` stands on it at x 48 |
| Gap | columns 8–25, open from row 8 down to the bottom | The pit; falling below the room kills |
| Overhead block | columns 13–16, rows 1–7 | The object hangs below it (y 200). Keep its underside at row 7 or higher, so it doesn't block the jump arc and its sides don't become wall-jump footholds near the route |
| Destination | columns 26–39, rows 15–22 | Top surface y 240, one tile above the start, as in the mockup. `GoalZone` sits on it at (416, 240) |

If you move the destination, move `GoalZone` with it: its position is the top surface's left end (x = first column × 16, y = top row × 16), and it should end at least one tile before the room's edge. If you move the object, keep its ring (radius 64) where the first jump from the ledge passes through it.

**Why:** spec **M3 build order** step 1; **What Level 1 must demonstrate**; **Death, retry and completion in World** (completion, step 10); **Same-tick contract** (goal, countdown, fall order); **Room scene convention**; standing rule **Unit tests stand in for waiting scenarios**. AC L1-01 (elements present), L1-02 (the object is always powered), L1-04 (completion only by standing on the destination).

**How to see it:** paint the tiles first (guide above). Then press F5: you start on the left platform. Run right, jump, press Z for flow, press jump again inside the ring for the charged jump, dash, and land on the right platform. The game puts you back at the start. In the editor, open `level_1.tscn` to see the orange room outline, the object's ring and the goal zone's green strip. Tests: `"$GODOT" --headless --path game res://tests/test_runner.tscn` (167 passed, 0 failed, including the 5 new `test_goal_zone.gd` cases).

**Decisions and questions:**

- Decision log, M3.1: tiles left to you (nodes + guide); the starting positions and exactly what the placement aid covered; the `GoalZone` shape; completion's temporary reset (`room_enter`, inputs stale).
- Decided freely: `room.gd` gains `goal_zones()`, although the spec's "Files extended in M3" table doesn't list `room.gd`. Its header says World talks to rooms only through it, so the lookup lives there. Say if you'd like that row added to the spec.
- **Unchecked risk:** nothing automatic proves that ordinary movement can't cross the gap, or that the charged route can. After painting, try crossing with jump and dash only.

## M3 step 2: Play loop (2026-10-20)

**What was built:**

- `game/world/world.gd`: the play states (Title, Playing, Dying, Respawning, Complete) replace the old `running` flag; new public calls `start()`, `replay()`, `restart_room()`, `mark_inputs_stale()`, `ticks_run()`.
- `game/world/main.gd`: no longer starts World at launch; wires the overlays; pauses on the `pause` key and on focus loss; `toggle_fullscreen()` is now public.
- `game/world/main.tscn`: adds `TitleOverlay`, `CompletionOverlay`, `PauseMenu`.
- New: `game/ui/title_overlay.tscn`/`.gd`, `game/ui/pause_menu.tscn`/`.gd`, `game/ui/completion_overlay.tscn`/`.gd`.
- New: `game/tests/unit/test_play_loop.gd` (9 cases), with its row added to the spec's M3 files table (standing rule).
- `docs/decision_log.md`: nine M3.2 rows.

**How it works:**

World now knows where play stands. On launch it is on the **title**: the room is built and visible behind the title screen, but `_physics_process` returns before counting a tick, so nothing moves and no timer runs. The first key or click hides the title and calls `World.start()`, which marks held buttons stale (so the key that started the game can't also be a jump) and switches to **Playing**.

In Playing, the 11 steps run as before. What changed is step 10. Reaching the goal now logs `room_complete` and switches to **Complete**, which stops the ticks like the title does. The completion overlay is listening to the trace, so it appears. Pressing jump calls `World.replay()`, which rebuilds the room at `start`, marks inputs stale and plays again. A death (countdown or fall) logs `death` once and switches to **Dying**, with a 21-tick counter (`death_freeze_s`).

Dying and Respawning still count ticks, because the death-to-control limit (R-02) is measured in ticks. But they run a short "locked" tick instead of the 11 steps: read input and throw it away, count down, publish. When the freeze ends, the room is rebuilt from its scene and the player placed at the checkpoint (this logs `respawn` and marks inputs stale), and **Respawning** counts 15 ticks (`respawn_s`). Then `control_return` is logged and play resumes. Death to control is 36 ticks, 0.6 s. Because input is read and discarded during the lock, a button mashed during the death animation never turns into a jump after respawn.

**Pause** pauses the whole scene tree. World is "pausable" and Main is "always", so World's ticks stop (the countdown freezes) while the menu keeps working. The input source keeps watching keys while paused, so it knows what's held, and resuming marks those buttons stale. **Restart room** unpauses, then calls `World.restart_room()`: a death with cause `restart`, so it runs exactly the same freeze and respawn as any other death.

**Why:** spec **M3 build order** step 2; **Death, retry and completion in World**; **Pause and focus**; **Control locks** (death freeze, respawn); M3 files rows for the three overlays. AC R-01 (complete reset; a held jump doesn't fire), R-02 (control within 1 s), R-04 (pause freezes the countdown), L1-04 (visible completion), D-07 (fullscreen and quit from the menu).

**How to see it:** press F5. The title shows "TRI10NWARE", "Press any key" and the build ID. Press a key to play. Fall into the gap: a short freeze, then you're back at the start and can move again. Press Esc or P: the pause menu; try every button (Fullscreen, Sound, Restart room, Quit, Resume). Click outside the game window while playing: it pauses. Reach the goal: "Level complete" appears, and jump plays again. Tests: `"$GODOT" --headless --path game res://tests/test_runner.tscn` gives 175 passed, 1 failed. The failure is `test_level_tiles_resource`, caused by the uncommitted owner edits to `level_tiles.tres` (tile 2:1 no longer solid; 3:2 and 4:2, the telephone-pole pieces, now solid). This step doesn't touch that file. If the new solidity is intended, the test's expectations need updating with your approval; otherwise revert those three tiles in the TileSet editor.

**Decisions and questions:**

- Decision log, M3.2: the exact ticks of the death sequence; input read and discarded during the lock; restart applies at once and only from Playing; pause only while ticks run; what starts the title; sound mute is session-only; completion prompt has no delay; overlay layers and placeholder look; `start()`/`replay()` mark inputs stale themselves.
- Not in this step: the title's shader prewarm (step 3), death and respawn effects and sounds (step 4), the web pause and focus check (step 5).
- Left for the postponed M1.8: the scenario runner must call `World.start()` itself (the title now gates play), and `r01`/`r02` scenarios.

## M3 step 3: Flow visuals (2026-10-20)

**What was built:**

- New: `game/world/flow_presentation.gd`, on a new `World/FlowPresentation` node in `game/world/main.tscn`.
- `game/objects/charged_object/charged_object.gd`: `ring_shown` and `glow_strength`, set by `FlowPresentation`. At runtime the ring is now drawn only in flow (the editor still always draws it).
- `game/ui/title_overlay.gd` / `.tscn`: the shader prewarm (a `Prewarm` control filled from `prewarm_materials()`).
- New tuning field `glow_hint_alpha` (0.3): `game/config/tuning_data.gd`, `tuning.tres`, the spec's tuning table, the decision log's tuning table; `test_tuning.gd` and `test_trace.gd` (header count 46 → 47).
- New placeholder `game/art/backdrop/level_1_backdrop.png` (registered in `CREDITS.md`), shown by `Backdrop/Image` in `game/rooms/level_1/level_1.tscn`. That sprite is the only change to the scene. `level_1_props.png` was skipped (nothing references it; owner).
- New: `game/tests/unit/test_flow_presentation.gd` (7 cases), with its row in the spec's M3 files table. `test_play_loop.gd` gains a camera case.
- `game/tests/unit/test_solid_grid.gd`: `test_level_tiles_resource` now matches your committed `level_1_tiles_v2.png` atlas.
- `docs/decision_log.md`: seven M3.3 rows and one tuning row.

**How it works:**

`FlowPresentation` is a listener. It subscribes to `Trace.event_logged`, the same stream of rule events the traces record. Each time the rules log `switch`, it reads the event's `to` field. In flow, every charged object's ring appears and its glow goes to full strength, and a short `Tween` fades the room's `Backdrop` toward `flow_backdrop_color`, so the background dims and the electrical things stand out. Switching back reverses all of this. The rings and glows change on the switch tick itself; only the backdrop fades, over `flow_fade_s` (0.15 s).

On `room_enter` and `respawn` it does not animate: the room is a brand-new instance, so it snaps to whatever state the player is in, which after a death is always default. That is why you never respawn under a half-dimmed sky. Nothing in the rules reads anything `FlowPresentation` sets. A test runs the same scripted inputs with and without the node and checks the two traces are identical, which is V-02's "no rule depends on them" in code.

**The prewarm.** Godot compiles a material's shader the first time it draws something with it, which can cause a visible hitch, worst on the web. The title overlay now draws each "flow-state material" once while the title is up. The spec says "off-screen", but Godot skips drawing anything outside the view, so an off-screen draw would compile nothing. Instead it draws a 1 × 1 **black** pixel in the corner with additive blending: adding black changes no pixel, yet the draw still happens. **Honest caveat:** in M3 this probably prevents no stall. The only flow material today is the glow's additive blend, and the glow is already drawn faintly in default behind the title. The list exists for M5's wire-current shader, which is the material that really needs it.

**Camera follow** was already built in M1: World moves the camera in step 11 of every tick, centered on the player's feet, clamped to the room, with no smoothing. This step only adds a test proving it (in Level 1 the camera sits at the left and bottom limits, since the room is one screen).

**Why:** spec **M3 build order** step 3; M3 files row `flow_presentation.gd` and `title_overlay.gd`; **Visuals are a window, not a lever**; tuning `flow_backdrop_color`, `flow_fade_s`. AC V-02 (flow dims the world and emphasizes electrical objects), V-03 (rings that match the rules' region exactly), V-01 (camera within bounds).

**How to see it:** open `game/world/flow_presentation.gd`, `game/objects/charged_object/charged_object.gd`, `game/ui/title_overlay.gd` and `game/tests/unit/test_flow_presentation.gd` once so the editor analyzes them (diagnostics). Reload `main.tscn`, `level_1.tscn` and `title_overlay.tscn` if they were open. Press F5, then press a key. In default, the backdrop is a flat blue-grey, the charged object shows a faint glow and no ring. Press Z: the backdrop dims to purple-grey over a moment, the ring appears and the glow brightens; your painted poles, wires and blocks stay bright. Press Z again to reverse. Enter flow and fall into the gap: you respawn in default with the backdrop undimmed at once.

**Decisions and questions:**

- Decision log, M3.3: rings in flow only (owner); `glow_hint_alpha` (owner); the new test file (owner); the tiles test updated to the v2 atlas (owner); only the backdrop fades, in real time; the prewarm engine quirk; the `ChargedObject` setters and the backdrop placeholder.
- The spec's `title_overlay.gd` row still says "off-screen". If you want the wording to match the build, approve changing it to "invisibly, on screen".
- Unit tests: 184 passed, 0 failed. Scenarios remain postponed (M1.8).

## M3 step 4: Charged object looks (2026-10-20)

**What was built:**

- New: `game/objects/charged_object/looks/default_frames.tres`, the placeholder look: a `SpriteFrames` with animations `default` and `electric`, each one frame of `charged_object.png`.
- `game/objects/charged_object/charged_object.tscn`: `Sprite` is now an `AnimatedSprite2D` showing `default_frames.tres`. `Glow` is unchanged (still its own `Sprite2D` with additive blending).
- `game/objects/charged_object/charged_object.gd`: two new Inspector exports, `frames` (the object's look) and `glow_texture` (an optional type-specific glow), and a runtime `electric_look` switch.
- `game/world/flow_presentation.gd`: sets each charged object's `electric_look` with its ring and glow.
- `game/tests/unit/test_flow_presentation.gd`: animation checks added to the existing cases, plus two new cases (placeholder look; assigned look and glow). The spec's row for it is updated (approved through the edit prompt), and so is the M2 scene tree line for `Sprite` and `Glow`.
- `docs/decision_log.md` (two M3.4 rows), `CREDITS.md` (the `charged_object.png` row names its new use).

**How it works:**

A charged object's look is now a `SpriteFrames` resource: a named list of animations, each a list of frames. Every look must have two animations, `default` and `electric`. Select a placed charged object, drag a `SpriteFrames` onto its **Frames** slot in the Inspector, and that object uses it. Leave the slot empty and it uses the placeholder. Because the script is a `@tool` script, the choice shows in the editor right away. The **Glow Texture** slot works the same way: empty keeps `charged_glow.png`. The glow stays a separate node because it is drawn with additive blending, which brightens whatever is behind it, and that should not apply to the object's own art.

Which animation plays is decided in the same place as the rings and glows: `FlowPresentation`. On every `switch`, `room_enter` and `respawn` event it sets each object's `electric_look` to "is the player in flow?", and the object plays `electric` or `default`. Nothing in the rules reads it. The region, the encounter tracker and the charged jump never look at the sprite, so two types with different art behave identically. That is also why you must size `region_radius_px` to match your art by hand. The existing test that runs the same inputs with and without `FlowPresentation` still produces identical traces.

If one of your looks is missing an animation (say you have only made `default` so far), the object keeps showing what it had and Godot prints a warning naming the object, instead of crashing.

**Why:** spec **M3 build order** step 4 (owner, 2026-10-20); M3 files rows `default_frames.tres` and `flow_presentation.gd`; M3 "Files extended" row `charged_object.tscn`, `charged_object.gd`. AC V-02 (flow emphasizes electrical objects), V-03 (the cue never disagrees with the rules: the ring still comes from the rules' radius).

**How to see it:** open `game/objects/charged_object/charged_object.gd`, `game/world/flow_presentation.gd` and `game/tests/unit/test_flow_presentation.gd` once so the editor analyzes them (diagnostics). Reload `level_1.tscn` and `gym.tscn` if they were open. Open `charged_object.tscn`: `Sprite` is now an `AnimatedSprite2D`, and the object looks exactly as before. Select the `ChargedObject` in `level_1.tscn`: the Inspector shows **Frames** and **Glow Texture**. Press F5 and Z: with the placeholder both animations are the same frame, so you see no change until your own looks arrive.

**To add a type (owner):** save the sheet at `game/art/objects/charged/<type>.png`; in the FileSystem dock, create a new `SpriteFrames` resource at `game/objects/charged_object/looks/<type>_frames.tres`; in the SpriteFrames panel, rename the first animation to `default`, add one named `electric`, and fill both from the sheet; drag it onto an object's **Frames**; then set that object's `region_radius_px` to fit the art. Register both files in `CREDITS.md`.

**Decisions and questions:**

- Decision log, M3.4: a look with a missing animation keeps its current one and warns; the placeholder's settings (one frame, 5 fps, looping), the empty-glow fallback and the `electric_look` switch.
- Unit tests: 186 passed, 0 failed. Scenarios remain postponed (M1.8); the scenario command has nothing to run and does not quit, so it was stopped.

## M3 step 5: Effects and sound (2026-10-20)

**What was built:**

- New: `game/audio/sfx.gd` (the `Sfx` node in Main), `game/world/effects.gd` (the `Effects` node in `World`), `game/world/effects_frames.tres` (animations `death`, `respawn`, `charged_jump`, `dash`, `land`, `goal`), `game/default_bus_layout.tres` (Master, SFX, Music).
- Placeholders: `game/art/effects/effects.png` and silent `game/audio/sfx/switch_refused.wav`, `countdown_tick.wav`, `room_complete.wav`.
- `game/world/main.tscn`: adds `Sfx` (its `player` points at `World/Player`, like the HUD) and `World/Effects` (after `Player`, so effects draw on top).
- New: `game/tests/unit/test_feedback.gd` (27 cases; owner approved), and its row in the spec's M3 files table.
- `CREDITS.md`: your 8 WAVs as `owner draft`; the 4 placeholders. `docs/decision_log.md`: six M3.5 rows.
- Godot generated `.uid` files for the three scripts and `.import` files for the new WAVs and PNG.

**How it works:**

Both new nodes work like `FlowPresentation`: they listen to `Trace.event_logged`, the signal that fires for every rule event, and react. They never change anything the rules read, so the game plays identically with or without them. A test runs the same scripted inputs with both nodes and with both removed, and the traces match exactly.

`Sfx` maps events to sounds: a `jump` plays `jump`, or `charged_jump` if its kind is `charged`; a `switch` plays `switch_to_flow` or `switch_to_default`; `switch_refused`, `death`, `respawn` and `room_complete` play their own slots. For dashes it remembers one thing, whether the latest dash refill came from a charged jump. A `dash_start` plays `charged_dash` if so, otherwise `dash`, and then forgets. A ground refill, a respawn or a new room also forget it. The countdown has no per-second event, so `Sfx` reads it every rendered frame with the HUD's own "whole seconds left" function. When the shown number changes to 3, 2 or 1 it plays `countdown_tick`, so it never disagrees with the numerals.

`Effects` plays a short animation centered on the player's body for `death`, `respawn`, a charged `jump`, `dash_start`, `land` and `room_complete` (`goal`). When the player falls out of the room, that point is off screen, so a `fell` death clamps it to the edge of the camera's view, where the player left. When an animation finishes, the sprite hides itself. That is only visual: nothing waits for it.

Both nodes make a fixed pool when they load, 8 sound players and 8 effect sprites, and never add more. Each new sound or effect takes the pool slot that started longest ago. So 20 deaths in a row cannot pile up nodes (R-03), and a test checks the counts after six deaths. The sounds play on the SFX bus. The pause menu's Sound on/off still mutes Master, which silences everything.

**Why:** spec **M3 build order** step 5; M3 files rows `sfx.gd`, `default_bus_layout.tres`, the 11 sound slots, `effects.gd`, `effects_frames.tres`, `effects.png`; the `charged_dash.wav` row (owner, 2026-10-20); M3 "Files extended" `main.tscn`; **Visuals are a window, not a lever**; ground rules 3 and 13. AC V-04 (feedback for every important action), R-03 (nothing accumulates across retries).

**How to see it:** open `game/audio/sfx.gd`, `game/world/effects.gd` and `game/tests/unit/test_feedback.gd` once so the editor analyzes them (diagnostics). Reload `main.tscn` if Godot asks. It now has `Sfx` under Main and `Effects` under World. Press F5, then a key:

- Jump: your jump sound. Dash (X): the dash sound and a light-blue outline square.
- Land: a yellow outline. Z: the switch sounds.
- Charged jump through the ring: the charged-jump sound and a cyan outline; dash right after it: the charged-dash sound.
- Fall into the gap: the death sound, a red outline at the bottom edge of the screen, then the respawn sound and a white outline at the start.
- Spend all volts (Z in and out three times) and watch the countdown: the tick placeholder is silent, so nothing is heard yet.
- Reach the goal: a green outline (the completion sound is silent too).

To use your own effects art, save it over `game/art/effects/effects.png`, then open `effects_frames.tres` in the SpriteFrames panel and set each animation's frames, speed and loop. Keep the six animation names.

**Decisions and questions:**

- Decision log, M3.5: the new test file (owner); pool sizes and round-robin reuse; the `charged_dash` memory and what clears it; the countdown tick on 3, 2, 1; effect positions, draw order and the fall clamp; the placeholders and bus layout.
- The spec's repository layout still says `13 unit-test files`; there are now 17. That count was out of date before this step; I left it for you to approve a fix.
- Your 8 WAVs are registered with license "owner to confirm".
- Unit tests: 213 passed, 0 failed (27 new). The headless run shows no script errors. The editor diagnostics had not analyzed the three new scripts yet (they were not open). Scenarios remain postponed (M1.8).

## M3 step 6: Ship (2026-10-20)

**What was built:**

- `game/project.godot` (changed): `application/config/version` 0.1.0 → **0.2.0** (owner decision), in its own commit, `4357afe` (`M3 step 6: version 0.2.0`), so the export could run from a clean tree.
- The three builds and the itch.io upload files, made by `tools/export_all.sh` from commit `4357afe`: build ID **`0.2.0-4357afe`**. They sit in `builds/` (git-ignored): `builds/itch/TRI10NWARE_web.zip` (9.1 MB), `TRI10NWARE_macos.zip` (61 MB), `TRI10NWARE_windows.zip` (33 MB).
- `README.md` (changed): the build-ID example and the editor's `0.2.0-dev` ID, which now says where the version lives. The first-launch steps (macOS Open Anyway, Windows SmartScreen), serving the web build, and the itch.io upload steps were already complete from M0 step 11. They were re-read against this build and needed no change.
- `docs/support_matrix.md` (changed): last build checked is `0.2.0-4357afe`; the macOS row records this session's checks.
- `docs/decision_log.md` (changed, in `4357afe`): the owner's version decision.

No code file was created or changed, so there was nothing for diagnostics to check.

**How it works:** shipping uses no new machinery. It runs the delivery path that M0 step 10 built, then checks what came out. `export_all.sh` refuses to run with uncommitted changes, because the build ID names a commit, and a build with changes that aren't in that commit would be lying about its source. That is why the version bump went into a commit of its own *before* the export, and why this journal entry is a second commit *after* it. The builds name `4357afe`, and this step's later commit changes only documents, so the shipped game is exactly `4357afe`. The export rewrote no `.import` or `.uid` file, so it needed only one run, and it deleted `build_info.cfg` on exit as designed. Editor runs now show `0.2.0-dev`.

Checks run in this session, all passed:

1. `tools/run_tests.sh`: 213 passed, 0 failed; scenarios skipped (they wait for the postponed M1 step 8); exit 0.
2. `tools/export_all.sh`: exit 0, `Build 0.2.0-4357afe`; tree clean afterward.
3. **Zip layouts:** the web zip has `index.html` and its eight sibling files at the top level; the Windows zip holds `TRI10NWARE.exe`, `README.md` and `CREDITS.md`; the macOS zip holds `TRI10NWARE.app`, `README.md` and `CREDITS.md`.
4. **macOS app**, taken from the itch.io zip: `codesign --verify --deep --strict` passes (ad-hoc signature intact after the zip round trip), `lipo` reports `x86_64 arm64`, and a headless launch and quit exits 0.
5. **Packs** (web `index.pck`, the macOS app's `.pck`, and the pack embedded in the `.exe`): each contains `build_info.cfg` with `version="0.2.0"` and `commit="4357afe"`, and no exported test scene. The web pack contains all 11 sound slots, `level_1.tscn`, `effects_frames.tres` and `default_bus_layout.tres`.
6. **Web over HTTP:** `tools/serve_web.sh` served `index.html` (`text/html`), `index.wasm` (`application/wasm`), `index.pck` and `index.js`, all 200 with `Cache-Control: no-store`; the server was stopped afterward.

**What only the owner can check (still open):**

- **Web pause and focus (spec, Pause and focus; R-04).** In a real browser, switching tabs and clicking outside the game must pause it. I have no browser here, so this is untested, and **there is a known risk.** `main.gd` opens the pause menu only on `NOTIFICATION_APPLICATION_FOCUS_OUT`. The exported web runtime (`index.js`) reports the canvas's `focus` and `blur` events to Godot as *window* focus events (Godot's `NOTIFICATION_WM_WINDOW_FOCUS_OUT`). It also has a separate page-blur hook, and it isn't clear from the JavaScript alone whether that reaches the *application* notification. So the web build may not pause on focus loss, even though the desktop builds do. The input stage still releases held keys on focus loss either way (decision log, M0.6), so no key gets stuck. If the check fails, the spec says to record it in `docs/known_issues.md` and **propose** the fix in the spec before building it, for example also pausing on `NOTIFICATION_WM_WINDOW_FOCUS_OUT`. A session does that once you report the result.
- **Playing every build and approving it** (gate step 8, without its evidence): movement feel and visuals on macOS (windowed, from the itch.io zip, following the README's first-launch steps), on Windows (the PC), and on the web (locally, and on itch.io once uploaded).
- **Placeholders that ship in this build** (from `CREDITS.md`): `icon.svg` (Godot's icon), `charged_object.png`, `charged_glow.png`, `switch_burst.png`, `volt_pip.png`, `dash_pip.png`, `state_icons.png`, `countdown_ring.png`, `level_1_backdrop.png`, `effects.png`, and the silent `switch_refused.wav`, `countdown_tick.wav` and `room_complete.wav`. Gate step 8 says your art for every Level 1 slot must have arrived for approval. You can approve the build as it is and replace these later (then re-export), or replace them first.
- **itch.io** (gate step 7): make the page and upload the three files. No session does this.

**Why:** spec, M3 build order step 6; **Level 1 gate** steps 2, 7 (owner) and 8; **Pause and focus** (R-04); M0 step 10 (delivery path, itch.io files) and M0 step 11 (README). AC: D-01 (every build names its commit), D-03 (the web build is served over HTTP and the README covers first launch), D-08 (reproducible from the repository), R-04 (pause on focus loss: desktop by `main.gd`, web pending the check). Gate steps 1, 3–6 and the M3 done-when items stay postponed (spec, **Postponed M3 gate evidence**).

**How to see it:**

1. **Web pause and focus check.** Run `tools/serve_web.sh` and open `http://localhost:8000/` in Chrome, Safari and Firefox. Click to start, then:
   - (a) switch to another tab, wait 5 s and come back;
   - (b) click on the page outside the game canvas (make the window wider than the game if needed);
   - (c) click into another app, then come back.

   For each, say whether the pause menu was showing when you came back. A good test: enter flow at 0 volts so the countdown runs, then switch away for longer than 3 s. If the game wasn't paused, you'll come back to a death. Then tell the next session the results; any failure goes to `known_issues.md` with a proposed fix.
2. **macOS:** unzip `builds/itch/TRI10NWARE_macos.zip` somewhere else (for example Downloads), follow the README's macOS first-launch steps, and play Level 1 windowed and fullscreen. The title shows build `0.2.0-4357afe`. Check that losing focus (Cmd+Tab) opens the pause menu.
3. **Windows:** copy `builds/itch/TRI10NWARE_windows.zip` to the PC, follow the README's Windows steps, play, and fill in that `support_matrix.md` row (Windows version, hardware). Also note whether the `.exe` shows the game icon or Godot's.
4. **Approval:** tell a session "approve the M3 builds" (or list the changes you want). It records gate step 8 in the decision log and ticks the matching M3 done-when item, the one about owner approval.
5. **itch.io:** follow the README's "Uploading to itch.io".

**Decisions and questions:**

- *Owner decision (2026-10-20):* version **0.2.0** for the shipped Level 1 build (decision log, M3.6).
- No decide-and-log choices were needed: the export ran unchanged and rewrote nothing.
- *Open:* the web pause and focus result (above). If it fails, the fix is a spec change for the owner to approve, not something a session builds unasked.
- *Open:* the owner's approval of every build, or the changes they request (gate step 8).

## M4 step 1: spike rules (2026-10-21)

**What was built:**

- `docs/TRI10NWARE.md` (owner-approved edit): the new **M4 build order** (five steps, spikes first, built ahead of Level 2); M4 files rows for `test_spikes.gd` and `test_platforms.gd` (standing rule); extended-file rows for `player.gd`, `test_trace.gd` and `room_catalog.tres`; `gym.tscn`'s row now covers the `spikes` station; "Where each file is created" M4 count 7 → 9.
- `game/core/solid_grid.gd`: spike `solidity` values 4–7, their cell flags, `touches_spike(rect)` and `spike_hitbox(cell, spike)`; the constructor takes `spike_depth_px` and `spike_inset_px`.
- `game/core/pixel_mover.gd`: `spike_hit`, set by `move()` at the start position and at every pixel it moves.
- `game/player/player.gd`: `touched_spike()` for step 10.
- `game/world/world.gd`: `Outcome.SPIKE` between the goal and the countdown; `death` with cause `spike`.
- `game/rooms/room.gd`: passes the two tuning values when it builds the grid.
- `game/config/tuning_data.gd`, `game/config/tuning.tres`: `spike_depth_px` 6, `spike_inset_px` 2.
- `game/rooms/room_catalog.tres`: gym `world_rect` 5120 × 512 → 5760 × 512.
- `game/verification/gym/gym.tscn`: the `Spikes` entrance (`spikes`) at (5160, 416).
- Tests: new `game/tests/unit/test_spikes.gd` (+ `.uid`); spike cases in `test_solid_grid.gd` and `test_pixel_mover.gd`; the two fields in `test_tuning.gd`; `test_trace.gd`'s header count 47 → 49; `test_charged_jump.gd`, `test_flow_controller.gd`, `test_goal_zone.gd`, `test_play_loop.gd` build grids through a new `_new_grid()` helper.
- `docs/decision_log.md`: the two tuning rows; Owner rows M3.6 (partial approval) and M4 (build now, build order); five M4.1 rows.

**How it works:** a spike is a tile like any other. When a room is built, `SolidGrid` reads each cell's `solidity`. Values 4–7 (spikes pointing up, down, left, right) get their own flag, separate from "solid". So the existing collision questions (`blocks()`, `platform_top_at()`) never see spikes, and the player walks straight into a spike cell. That is how "spikes never block" holds without a special case.

What kills is the **hitbox**, a strip along the spike's base: 6 px deep, stopping 2 px short of each end. For an up-pointing spike, the strip is the bottom 6 px of the cell, minus 2 px on each side. The pointy top 10 px is harmless, so grazing the tips is safe. `touches_spike(rect)` looks only at the cells the body overlaps, builds each spike's strip, and asks whether the body *overlaps* it. A body that only touches the strip's edge, such as one standing on its top line, does not die.

`PixelMover` already moves one pixel at a time so it can stop flush at walls. It now asks `touches_spike` at the start position and after every pixel step, and sets `spike_hit` if any of them overlaps. That is why a fast dash can't skip a spike between ticks (a test moves 25 px in one tick, right through a 6 px strip), and why standing still on one kills. In step 10, `World.outcome()` now checks goal, spike, countdown, fall, in that order. A spike death goes through the same `_die()` as every other death, so the freeze, the respawn and the reset are identical.

**Why:** spec **M4 build order** step 1, **How spikes work**, **The tile set**, **Step 10, outcomes**, **Same-tick contract** (goal, spike, countdown, fall); ground rules 8 (tuning passed in), 9 (no tunable numbers in code) and 15 (only integer rectangle tests); AC R-01 and R-02 (spike deaths reset like every death).

**How to see it:**

1. Run the unit tests: 228 pass. The new block is `test_spikes.gd`.
2. Open `game/core/solid_grid.gd` and `game/tests/unit/test_spikes.gd` once, so the editor analyzes them (diagnostics). The other changed scripts are already clean.
3. **Set the spike tiles' `solidity`** in the TileSet panel (`level_tiles.tres`): 4 on the tile whose points face up, 5 down, 6 left, 7 right. Then `test_level_tiles_resource` in `test_solid_grid.gd` will fail, because it pins the shipped tile set exactly. That's expected; the next session updates it to your spike tiles' atlas coordinates (tell it which they are, or it reads them from the file).
4. Paint the `spikes` station (guide below), set `start_room` to `gym` in `room_catalog.tres` (don't commit that), and press F5. The debug menu can't jump to the station yet (postponed M1.7), so start from the `start` entrance or temporarily set `start_entrance` to `spikes`.

**Painting guide for the `spikes` station.** Columns and rows are tiles from the gym's top-left corner. The station uses columns 320–359. Its floor top is row 26 (y 416), like every station, with floor tiles from row 26 down on `WorldTiles`. Spike tiles can go on `WorldTiles` too. The entrance marker sits at column 322.

| Part | Where | Notes |
| --- | --- | --- |
| Floor | Columns 320–359, row 26 down | Continuous, so every part has clear floor beside it |
| Floor spikes (up, 4) | Columns 326–329, row 25 | Walk into them, land on them from a jump, dash into them |
| Ceiling and ceiling spikes (down, 5) | Ordinary ceiling on row 20, columns 333–340; spikes on row 21, columns 334–339 | A held jump's head peaks at about y 345 (M2.4 entry), inside the tips (y 342–351) and 3 px below the hitbox (y 336–341): it should graze and live, and an upward dash should die. If a held jump dies, move both rows up one |
| Shaft walls | Ordinary walls on columns 346 and 351, rows 12–25 | 4 open columns between them |
| Wall spikes | Right-pointing (7) on column 347 and left-pointing (6) on column 350, rows 16–21 | Spikes on both inner faces. Rows 22–25 stay clear, so standing in the shaft is safe and a jump reaches them |

The right edge (column 359) is already a wall, because room edges count as walls. Divider walls are up to you.

**Decisions and questions:**

- Owner decisions (plan review): M4 is built now, ahead of Level 2, spikes first, and the new build order is in the spec. The step 1 gym skeleton is in step 1. `test_spikes.gd` is approved under the standing rule. You set the spike tiles' `solidity` yourself, so this session did not touch `level_tiles.tres`. M3.6 results: movement and visuals approved; the web pause and focus check comes last (decision log, M3.6).
- Decide and log (decision log, M4.1): the spike cell flags and the constructor parameters; edge contact is not contact; contact is noted only inside step 6's move, so a body that the step 7 or step 9 snaps place on a spike dies one tick later; the unknown-solidity test now uses 8; the gym's width and the station columns.
- The `test_platforms.gd` row was added to the spec now, with step 2's file, so the table matches the build order.
- Skipped because they wait for the postponed M1 steps: `h01_spikes.json` (M1.8; `test_spikes.gd` stands in for it).
- Check run: import clean; 228 unit tests pass. A throwaway headless script (not committed) loaded the gym and found 17 entrances, including `spikes`, with bounds 5760 × 512. Its jump-height measurement didn't run, because scripts started with `-s` load no autoloads. So the ceiling row above comes from the M2.4 figure, and your playtest confirms it.
