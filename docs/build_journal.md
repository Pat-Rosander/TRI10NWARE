# TRI10NWARE build journal

Every step of the build adds an entry here, newest at the bottom. The Status block below is updated at the end of every step; it is the first thing each new session reads.

## Status

- **Last completed:** M0 step 5, Trace, the recorder, 2026-10-17.
- **Next step:** M0 step 6, input stage (`/step M0.6`).
- **Waiting on the owner:**
    - Reopen Godot from `game/project.godot` (closed for steps 3–5). Check Project → Project Settings → Input Map: 13 actions, keys marked "(Physical)". Check the Globals → Autoload tab: `Tuning` first, `Trace` second. Until M0 step 7 creates `world/main.tscn`, the editor and the import step report that the main scene is missing; that is expected.
    - Push the tag: `git push origin prototype-v0`.
    - Fill in the license column for the three `game/art/legacy/` rows in `CREDITS.md`.
    - M0 step 0 prerequisites, still needed: the 4.5.1 export templates, the macOS bundle identifier, the itch.io project page, and access to a Windows PC. Godot 4.5.1 itself is confirmed at `/Applications/Godot 4.5.1 .app`.
    - Before M1 step 2: accept or replace the three proposed answers under "Decide before step 2" in the M1 build order.
- **Open questions:** none.
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
