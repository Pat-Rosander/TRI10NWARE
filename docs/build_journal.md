# TRI10NWARE build journal

Every step of the build adds an entry here, newest at the bottom. The Status block below is updated at the end of every step; it is the first thing each new session reads.

## Status

- **Last completed:** M0 step 7, Main and World skeleton, 2026-10-17.
- **Next step:** M0 step 8, debug overlay (`/step M0.8`). Step 8 also adds the `DebugOverlay` instance to `world/main.tscn` (left out of step 7 because its scene did not exist yet), shown only when `Main.debug_tools` is true.
- **Waiting on the owner:**
    - Reopen Godot from `game/project.godot`. The missing-main-scene error is gone. Running the project (F5) shows a blank window, sized to the largest whole multiple of 640 × 360 that fits your screen. Please check three things: the window size; that Alt+Enter (Option+Enter) toggles fullscreen; and that a run with `-- --debug-tools` writes a file to `user://traces/` when you close the window, while a run without the flag writes none. These could not be checked automatically (see the M0 step 7 entry). If Godot asks to re-save `main.tscn`, accept: it adds the scripts' UIDs.
    - Push the tag: `git push origin prototype-v0`.
    - Fill in the license column for the three `game/art/legacy/` rows in `CREDITS.md`.
    - M0 step 0 prerequisites, still needed: the 4.5.1 export templates, the macOS bundle identifier, the itch.io project page, and access to a Windows PC. Godot 4.5.1 itself is confirmed at `/Applications/Godot 4.5.1 .app`.
    - Before M1 step 2: accept or replace the three proposed answers under "Decide before step 2" in the M1 build order.
- **Open questions:** none.
- **Note for M0 step 9 (spec updated 2026-10-17, owner decision):** step 9 now also adds `test_input_source.gd` and `test_trace.gd`, and `test_tuning.gd` checks every `tuning.tres` field against its start value. Rebuild the input-source and trace tests from the verification lists in the M0 step 5 and step 6 entries below; those scripts were not kept.
- **Note for M1 step 4:** `World` calls `expire()` on each press buffer before adding a new press (spec, M1 "Step 1, input").
- **Note for M1 step 4:** World must switch to the Player's `InputSource` and delete the temporary LiveInputSource creation in `world.gd` (marked `M0 only, replaced in M1 step 4`, in `_ready()` and `set_input_source()`), so two input sources never run at once. `set_input_source()` itself stays: it is World's permanent way to swap sources, and the M1 scenario runner uses it.
- **Note for M0 step 10:** `export_all.sh` must write `config/build_info.cfg` with section `[build]` and keys `version`, `commit`, `date`, the format `Trace` reads (see the M0 step 5 entry).

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
- No open questions.
