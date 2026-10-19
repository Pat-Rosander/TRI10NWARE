# TRI10NWARE build journal

Every step of the build adds an entry here, newest at the bottom. The Status block below is updated at the end of every step; it is the first thing each new session reads.

## Status

- **Last completed:** M2 step 3, charged object, 2026-10-19. M1 step 5's gym is **partly painted** (owner commit `54b8164`); the rest is listed below.
- **Next step:** M2 step 4, gym charged stations (`/step M2.4`). It edits `gym.tscn`, so **close the gym's scene tab in the editor first**; after it, the owner paints the six stations' tiles. **M1 steps 7–9 are postponed** (owner, 2026-10-19; spec, **Postponed work**): do not build them, or anything that waits on them (scenario files, `debug_world_draw.gd` extensions), unless the owner asks.
- **Waiting on the owner:**
    - Focus the Godot editor once so it registers the new `ChargedObject` class, then open `game/objects/charged_object/charged_object.gd` and `game/tests/unit/test_charged_jump.gd` once so the editor analyzes them (the headless run compiles both and every test passes). Then open `charged_object.tscn` and check the ring is drawn at radius 64 around the placeholder square.
    - `CREDITS.md` lists `game/art/player/player_frames.png`, but the owner's commit `a29f319` renamed it to `player_sheet_v1.png` (`player_frames.tres` points there): update that row (and the slot-name question below may now be answered).
    - **Finish the gym** before the postponed M1 step 8 (painting guide in the M1 step 5 entry; details in the M1 step 6 entry, "Gym check"). Move the `WallShaft` marker (x 976) and the `CornerCeiling` marker (x 1480) out of the solid tiles. Give `dash_chamber`, `coyote_ledge` and `buffer_drop` their floors (from column 100 on, row 26 is open to the pit), and finish `corner_ceiling` and the 12 × 8 dash chamber box. While `gym.tscn` is open in the editor, no session may edit it.
    - Answer the slot-name question below, and confirm the license of `game/art/player/player_frames.png` in `CREDITS.md`.
    - Review `docs/support_matrix.md`, and fill in each row you test (OS or browser version, hardware, build ID).
    - Check the builds (M0 step 10 entry, "How to see it"): run `tools/export_all.sh`, launch the macOS app with `-- --debug-tools` and press backtick to see the build ID; open the web build through `tools/serve_web.sh` at `http://localhost:8000/?debug=1`; upload `TRI10NWARE_web.zip` to a draft itch.io page; on the Windows PC, run `TRI10NWARE.exe -- --debug-tools`.
    - Check the debug overlay (M0 step 8 entry, "How to see it"): run with `-- --debug-tools`, press backtick, and try 1, 2 and 3. Accept if Godot asks to re-save `main.tscn` or `debug_overlay.tscn`.
    - Check the window size: with "Embed Game on Next Play" off, press F5. The window should be the largest whole multiple of 640 × 360 that fits the screen (on the MacBook Air, 1280 × 720, centered), with crisp, unblurred pixels. Already confirmed on 2026-10-17: Option+Return toggles fullscreen, and the trace is saved on window close with `--debug-tools`. Not yet checked: that a run *without* the flag writes no trace.
    - Fill in the license column for the three `game/art/legacy/` rows in `CREDITS.md`.
    - M0 step 0 prerequisites, still needed: the itch.io project page and access to a Windows PC. Confirmed: Godot 4.5.1 at `/Applications/Godot 4.5.1 .app`, its export templates (installed), and the macOS bundle identifier `com.patrickrosander.tri10nware` (owner, 2026-10-18).
    - Confirm the license of `game/art/tiles/level_1_tiles.png` in `CREDITS.md`.
- **Open questions:** the owner's player art is at `game/art/player/player_frames.png`, but the spec's slot is `player_sheet.png`: rename the file, or rename the slot in the spec? (decision log, section 5).
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
