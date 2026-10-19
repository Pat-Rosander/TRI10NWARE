# TRI10NWARE decision and tuning log

This is the "decision and tuning log" required by AC page 9: every tuning value and every developer-owned choice, with its reason and the test or check that shows it. No fixed rule changes without being disclosed here.

- **What goes here:** every change to `game/config/tuning.tres`; every "decide and log" choice (spec, "Authority tiers"); every owner decision that changes behavior; every added test scenario (which bug or criterion it covers); every engine quirk worked around; every disclosed deviation from an AC value; questions raised for the owner.
- **How:** add a row in the same commit as the change. Newest at the bottom of each table. Never delete a row: when a choice changes, add a new row that names the one it replaces.
- **History:** until M0 step 11 (2026-10-18), decisions were recorded only in the build journal's entries. They are copied into section 2 below; the journal entries keep the full discussion.

## 1. Tuning values

Current values in `game/config/tuning.tres`. Source: **AC** values are fixed by the acceptance criteria (changing one is a disclosed deviation, section 3); **Celeste** values are Celeste's movement constants with distances and speeds doubled for 16 px tiles; **Ours** and **Owner** are starting values from the spec. Each value's reason is its row in the spec's M0 step 4 table. All start values are checked field by field, with their types, by `game/tests/unit/test_tuning.gd` (`test_every_field_has_its_start_value`, `test_no_unlisted_fields`); the 12 durations' tick conversions are checked by `test_derived_ticks`.

| Field | Value | Ticks | Source | Changed |
| --- | --- | --- | --- | --- |
| `body_size_px` | 12 × 15 | | Owner (from the sprite) | Start value |
| `run_max_speed_px_s` | 180 | | Celeste | Start value |
| `run_accel_px_s2` | 2000 | | Celeste | Start value |
| `run_reduce_px_s2` | 800 | | Celeste | Start value |
| `air_control_mult` | 0.65 | | Celeste | Start value |
| `gravity_px_s2` | 1800 | | Celeste | Start value |
| `max_fall_speed_px_s` | 320 | | Celeste | Start value |
| `apex_gravity_mult` | 0.5 | | Celeste | Start value |
| `apex_threshold_px_s` | 80 | | Celeste | Start value |
| `jump_speed_px_s` | 210 | | Celeste | Start value |
| `jump_h_boost_px_s` | 80 | | Celeste | Start value |
| `jump_sustain_s` | 0.2 | 12 | Celeste | Start value |
| `coyote_s` | 0.1 | 6 | AC M-05 | Start value |
| `jump_buffer_s` | 0.1 | 6 | AC M-06 | Start value |
| `wall_check_px` | 6 | | Celeste | Start value |
| `wall_jump_h_speed_px_s` | 260 | | Celeste | Start value |
| `wall_jump_lock_s` | 0.16 | 10 | Celeste | Start value. 9.6 ticks rounds to 10, so the real lock is 0.167 s |
| `corner_correction_px` | 8 | | Celeste | Start value |
| `dash_corner_correction_px` | 8 | | Celeste | Start value |
| `oneway_assist_px` | 8 | | Ours | Start value |
| `post_dash_snap_px` | 6 | | Ours | Start value |
| `dash_speed_px_s` | 480 | | Celeste | Start value |
| `dash_end_speed_px_s` | 320 | | Celeste | Start value |
| `dash_end_up_mult` | 0.75 | | Celeste | Start value |
| `dash_s` | 0.15 | 9 | Celeste | Start value |
| `dash_cooldown_s` | 0.2 | 12 | Celeste | Start value |
| `dash_buffer_s` | 0.1 | 6 | Ours | Start value |
| `charged_refill_clears_cooldown` | true | | Ours | Start value |
| `charged_launch_speed_px_s` | 440 | | Ours | Start value |
| `charged_region_radius_px` | 64 | | Ours | Start value |
| `charged_exit_margin_px` | 1 | | Ours | Start value |
| `root_contact_margin_px` | 4 | | Ours | Start value |
| `overlap_snap_px` | 6 | | Ours | Start value |
| `max_volts` | 3 | | AC | Start value |
| `countdown_s` | 3.0 | 180 | AC S-03 | Start value |
| `countdown_in_default` | `CONTINUE` (0) | | AC S-03; OD-1 | Start value |
| `allow_flow_entry_at_zero` | false | | AC S-03; OD-1 | Start value |
| `death_freeze_s` | 0.35 | 21 | Ours | Start value |
| `respawn_s` | 0.25 | 15 | Ours | Start value |
| `room_transition_s` | 0.3 | 18 | Ours | Start value |
| `fall_margin_px` | 32 | | Ours | Start value |
| `flow_backdrop_color` | `Color(0.55, 0.5, 0.7)` | | Owner (art), placeholder | Start value |
| `flow_fade_s` | 0.15 | 9 | Ours | Start value |
| `inactive_platform_alpha` | 0.35 | | Ours | Start value |
| `stick_deadzone` | 0.2 | | Ours | Start value |
| `trace_memory_limit` | 100000 | | Ours | Start value |

**Tuning changes** (one row per retune, with the playtest or scenario behind it):

| Date | Field | Old → new | Reason | Test or scenario |
| --- | --- | --- | --- | --- |
| | | | None yet | |

## 2. Developer choices and owner decisions

Kind: **D&L** = decide and log; **Owner** = owner decision; **Engine** = workaround for engine behavior.

| Step | Date | Kind | Choice | Reason | Test or check |
| --- | --- | --- | --- | --- | --- |
| M0.1 | 2026-10-17 | D&L | `tools/` and `builds/` existed on disk only until step 10 | Git cannot track an empty folder; `builds/` is ignored | `tools/` committed in M0 step 10 |
| M0.1 | 2026-10-17 | D&L | `CREDITS.md` created in step 1, not step 11, with step 11's columns | Step 1 registers the legacy art | `CREDITS.md` |
| M0.1 | 2026-10-17 | Owner | `.vscode/` is ignored in the root `.gitignore`; spec updated | Personal editor settings stay out of the repository | `.gitignore` |
| M0.1 | 2026-10-17 | D&L | Tag `prototype-v0` is local; the owner pushes it | The AI never pushes | Owner to run `git push origin prototype-v0` |
| M0.2 | 2026-10-17 | D&L | Removed the prototype's launch-in-fullscreen setting (`display/window/size/mode=3`) | The spec sets a 1280 × 720 window; fullscreen stays one key away (D-07) | Settings read back headless (journal, M0 step 2) |
| M0.3 | 2026-10-17 | D&L | Movement actions have deadzone 0; the input source applies the round `stick_deadzone` | Godot's per-axis deadzone is square and delays diagonals (M-03) | `test_input_source.gd` (snapping and deadzone tests) |
| M0.3 | 2026-10-17 | D&L | Gamepad events bind to any device (−1) | Any connected pad works | Input map read back (journal, M0 step 3) |
| M0.3 | 2026-10-17 | D&L | `fullscreen` is the main Enter key with Alt; keypad Enter is not bound | The spec lists only Alt+Enter | Input map read back |
| M0.3 | 2026-10-17 | Owner | `fullscreen` keyboard binding uses device −1 (All Devices); every other key stays device 0 | Owner tested two keyboards; see the build journal Status note on device numbers | Owner check, M0 step 7 |
| M0.4 | 2026-10-17 | D&L | Start values live only in `tuning.tres`; `tuning_data.gd` fields have no values, except `countdown_in_default` | Ground rule 4; Godot omits values equal to the script default | `test_tuning.gd` |
| M0.4 | 2026-10-17 | D&L | Field types: `_px` are `int`, `body_size_px` is `Vector2i`, `max_volts` and `trace_memory_limit` are `int`, the rest `float` (or `bool`, `Color`) | Positions are whole pixels | `test_tuning.gd` checks types |
| M0.4 | 2026-10-17 | D&L | `countdown_in_default` is the enum `TuningData.CountdownMode` (stored as a number, 0 = continue) | Inspector dropdown; a misspelling fails at load | `test_tuning.gd` |
| M0.4 | 2026-10-17 | D&L | Tick values are computed in `Tuning._init` | They exist before any other autoload's `_ready` | `test_tuning.gd` (`test_derived_ticks`) |
| M0.5 | 2026-10-17 | D&L | Build ID = `<version>-<commit>` from `config/build_info.cfg` `[build]`; `<version>-dev` without it | One build ID everywhere (D-01) | `test_trace.gd`; step 10 export check |
| M0.5 | 2026-10-17 | D&L | Trace header `target` is `OS.get_name()`; `tick_rate` is `Engine.physics_ticks_per_second` | The values that actually ran | `test_trace.gd` |
| M0.5 | 2026-10-17 | D&L | Header `tuning` holds every stored field in designer units, found automatically; no derived ticks | Ticks follow from the fields; new fields need no Trace change | `test_trace.gd` |
| M0.5 | 2026-10-17 | D&L | JSON keeps key order (tick, room, event, data) and full float precision; vectors and colors as arrays | Cross-target comparison sees every bit (D-04) | `test_trace.gd` |
| M0.5 | 2026-10-17 | D&L | Trace file names use the local clock, with `-2`, `-3` added on a clash | Wall-clock time only in names, never in rules | `test_trace.gd` |
| M0.5 | 2026-10-17 | D&L | `session_start` is a catalog entry at tick 0, written first and kept outside the ring; `begin_session()` resets tick and room | The header always survives trimming | `test_trace.gd` |
| M0.5 | 2026-10-17 | D&L | Catalog check: event data must carry exactly the listed fields (empty values for fields that don't apply) | Typos can't slip into evidence | `test_trace.gd` |
| M0.6 | 2026-10-17 | D&L | Digital input beats the stick: the stick is read only when no movement key or D-pad button is held | One clear precedence rule | `test_input_source.gd` |
| M0.6 | 2026-10-17 | D&L | Several gamepads are merged (any-device bindings) | No pad selection screen | Step 6 check |
| M0.6 | 2026-10-17 | D&L | `mark_all_stale()` discards presses not yet read | They belong to the screen that just closed (R-01, R-04) | `test_input_source.gd` |
| M0.6 | 2026-10-17 | D&L | The live input source runs with process mode Always | Keeps tracking held keys during pause | `test_input_source.gd` |
| M0.6 | 2026-10-17 | D&L | Losing window or app focus releases every held action | The OS may never send the key-ups | `test_input_source.gd` |
| M0.6 | 2026-10-17 | D&L | `PressBuffer.expire()` reports on tick *t* + window + 1; a replaced token is reported by `press()` | The first tick the token can't be spent | `test_press_buffer.gd` |
| M0.6 | 2026-10-17 | D&L | Scripted input ticks are relative to the case's `start_tick` | Scenario files stay position-independent | `test_input_source.gd` |
| M0.7 | 2026-10-17 | D&L | `DebugOverlay` joins `main.tscn` in step 8 | Its scene is created in step 8 | `main.tscn` |
| M0.7 | 2026-10-17 | D&L | `Main` starts `World` in `_ready()` until M3's title screen | No title screen in M0 | Step 7 check |
| M0.7 | 2026-10-17 | Owner | `World` makes its own `LiveInputSource` in M0 (marked `M0 only, replaced in M1 step 4`); `set_input_source()` is permanent | Input works before the Player exists | Step 7 check |
| M0.7 | 2026-10-17 | D&L | Window sizing counts the title bar, never goes below 1×, centers the window; skipped headless, on web, embedded and when not windowed | Whole multiples only (V-01). On 1366 × 768 with a taskbar the window is 1× | Step 7 check; owner check pending |
| M0.7 | 2026-10-17 | D&L | `?debug=1` counts only on `localhost` or `127.0.0.1` | Debug tools never reach players on itch.io | Step 7 check |
| M0.7 | 2026-10-17 | D&L | `Main` process mode Always; `World` Pausable, set explicitly | Fullscreen works while paused; pause stops ticks (R-04) | Step 7 check |
| M0.7 | 2026-10-17 | D&L | Slow-motion counter resets on speed change; a requested step while frozen runs exactly one tick; divisors other than 1, 2, 4 are rejected | Predictable frame-stepping (D-05) | Step 7 and 8 checks |
| M0.7 | 2026-10-17 | D&L | `--quit-when-done` counts as a scenario flag and turns debug tools on; unknown arguments warn; a bad `--render-fps` errors and is ignored | Consistent flag handling | Step 7 check |
| M0.7 | 2026-10-17 | Engine | `Camera2D` uses the physics process callback | Godot forces it under physics interpolation and warns otherwise | Step 7 check |
| M0.7 | 2026-10-17 | Owner | Trace saved on quit only with debug tools on, and never on the web; spec updated | Players get no trace files | Owner check, M0 step 7 |
| M0.7 | 2026-10-17 | Engine | `main.gd` `window_scale()` carries `@warning_ignore("integer_division")` | The remainder is meant to be dropped | Editor warning gone |
| M0.8 | 2026-10-17 | D&L | The debug overlay starts hidden; backtick shows it | Debug runs start looking like the game | Step 8 check |
| M0.8 | 2026-10-17 | D&L | The overlay readout also shows the speed and `FROZEN` | A tester sees why ticks stopped | Step 8 check |
| M0.8 | 2026-10-17 | D&L | Key 2 (step) is ignored unless frozen | Otherwise a press while running leaks a tick into the next freeze | Step 8 check |
| M0.8 | 2026-10-17 | D&L | Without debug tools, `Main` frees the overlay | Its keys can't work for players | Step 8 check |
| M0.9 | 2026-10-17 | D&L | Any engine error during a unit test fails it, unless the test collects it with `take_errors()` (Godot 4.5 `Logger`); warnings ignored | GDScript has no exceptions; a crash would look like a pass | Runner self-check with broken tests (journal, M0 step 9) |
| M0.9 | 2026-10-17 | D&L | Each test method gets a fresh instance; files sorted by name, methods in source order | No leaks between tests; repeatable order | `test_runner.gd` |
| M0.9 | 2026-10-17 | D&L | Finding zero tests is a failure | A mistyped folder can't look like success | `test_runner.gd` |
| M0.9 | 2026-10-17 | D&L | `assert_eq` requires the same type | `6` and `6.0` differ; catches mistyped tuning fields | `test_tuning.gd` |
| M0.9 | 2026-10-17 | D&L | Trace tests use private instances of `trace.gd`; the ring test sets `trace_memory_limit` to 3 briefly | The real autoload is never touched | `test_trace.gd` |
| M0.10 | 2026-10-18 | Owner | macOS bundle identifier `com.patrickrosander.tri10nware` | Required by the export preset | `export_presets.cfg` |
| M0.10 | 2026-10-18 | Engine | `rendering/textures/vram_compression/import_etc2_astc=true` | Godot 4.5.1 refuses universal and arm64 macOS exports without it; no texture changed | `export_all.sh` succeeds |
| M0.10 | 2026-10-18 | D&L | Exports are release builds (`--export-release`); debug tools stay reachable by flag | Players get release builds | Step 10 export check |
| M0.10 | 2026-10-18 | D&L | `export_all.sh` deletes `build_info.cfg` on exit | Editor runs keep the `-dev` build ID | Step 10 export check |
| M0.10 | 2026-10-18 | D&L | Build info: `commit` is the 7-character short hash; `date` is UTC `YYYY-MM-DDTHH:MM:SSZ` | Short, unambiguous IDs | Step 10 export check |
| M0.10 | 2026-10-18 | D&L | `run_tests.sh` skips scenarios until `verification/scenario_runner.gd` exists | The command would otherwise hang | `tools/run_tests.sh` |
| M0.10 | 2026-10-18 | D&L | `serve_web.sh` uses port 8000 by default, binds to `127.0.0.1`, and disables caching | Matches `?debug=1`; never serves a stale export | Step 10 check |
| M0.11 | 2026-10-18 | D&L | `README.md` rewritten rather than patched | The old one described the prototype layout and controls | README cross-checked against the input map |
| M0.11 | 2026-10-18 | D&L | `game/icon.svg` (Godot's default icon) registered in `CREDITS.md` as a placeholder | Every art file is registered (D-08) | `CREDITS.md` |
| M0.11 | 2026-10-18 | D&L | Decisions from M0 steps 1–10 copied here from the build journal; this log is the record from now on | One place for AC page 9's log | This file |
| M1.1 | 2026-10-18 | Owner | M1 starts while some M0 owner checks are still open | Step 1 does not depend on them; they stay listed in Status | — |
| M1.1 | 2026-10-18 | Owner | `level_tiles.tres` uses the owner's `game/art/tiles/level_1_tiles.png` (6 × 4 tiles), not the legacy tile set. Solidity 1: atlas (0–5, 0), (0–5, 1), (0, 2), (1, 2), (2, 2). Solidity 0: the telephone pole and wire pieces (3, 2), (4, 2), (5, 2), (0, 3), because the pole becomes the charged object | Owner art arrived before the step | `test_level_tiles_resource` |
| M1.1 | 2026-10-18 | Owner | Cells outside a room's corners: at or below the bottom edge they are open (a pit), otherwise solid. This accepts the "Decide before step 2" proposal for rooms without neighbors; the neighbor part waits for M6 | Walking off a bottom corner falls into the pit, not onto an invisible wall | `test_corner_cells` |
| M1.1 | 2026-10-18 | D&L | `SolidGrid.add_layer()` reads only the `TileMapLayer` it is given: no scene tree, no autoloads | Reconciles ground rule 8 (core touches no nodes) with "SolidGrid reads every used cell of the three layers" | `test_add_layer_reads_solidity` |
| M1.1 | 2026-10-18 | D&L | Room-edge cells count as ordinary solid, so they also count as walls for wall jumps | The spec calls them walls the mover stops at | `test_edges_are_walls_and_the_bottom_is_a_pit` |
| M1.1 | 2026-10-18 | D&L | A tile with an unknown `solidity` value raises an error and is ignored; tiles painted outside the room are ignored | Painting mistakes surface; the edge rules alone decide outside cells | `test_unknown_solidity_is_an_error`, `test_cells_painted_outside_the_room_are_ignored` |
| M1.1 | 2026-10-18 | D&L | The pending-tile tests in `test_solid_grid.gd` come with M4 | The spec adds pending tiles to `solid_grid.gd` in M4 | — |
| M1.2 | 2026-10-18 | Owner | Sub-pixel rounding: round to nearest (`roundi`, halves away from zero) with a per-axis remainder, reset on a block and on respawn, kept through room crossings. Velocity and remainder are separate 64-bit `float` values per axis, never a `Vector2`. Spec "Decide before step 2" proposal accepted with that addition | Celeste's method; symmetric left and right; repeatable jump heights. A `Vector2` would store 32-bit floats. Alternatives rejected in the spec's Technical approach table | `test_pixel_mover.gd` (rounding tests) |
| M1.2 | 2026-10-18 | Owner | Wall check: one overlap test at the full `wall_check_px`, as a `PixelMover` query; a guard test keeps `wall_check_px` below 16 | Celeste's method; exact while every solid is a 16 px tile. Alternatives rejected in the spec's Technical approach table | `test_pixel_mover.gd` (wall query and guard) |
| M1.2 | 2026-10-18 | D&L | Sub-pixel integration divides by the tick rate (`remainder += velocity / ticks_per_second`, with 60 passed in) instead of multiplying by a 1/60 constant | The same "velocity × tick length". One correctly rounded operation, so speeds such as 30 px/s give exactly 0.5 px per tick; 1/60 has no exact float form. Core code may not read the `Tuning` autoload (ground rule 8). Steps 4 and 5 should integrate acceleration the same way | `test_exact_half_rounds_away_from_zero` |
| M1.2 | 2026-10-18 | D&L | The body is `Rect2i(x − w/2, y − h, w, h)` for feet at `(x, y)`: the feet line is the rectangle's bottom boundary, so a standing player's `position.y` equals the floor tile's top. For an odd width, the extra pixel goes to the right | Spec "bottom center at the player's position"; matches `SolidGrid.platform_top_at()`, which tests `rect.end.y` | `test_body_rect_has_its_feet_at_the_bottom_center` |
| M1.2 | 2026-10-18 | D&L | `wall_at()` is true when a wall is 0 to `wall_check_px` − 1 px away (6 px out, the shifted body only touches the wall). This is the spec's literal "moved `wall_check_px` … would overlap", as in Celeste | Spec M1 step 7, "Walls" | `test_wall_query_reaches_the_full_wall_check_distance` |
| M1.2 | 2026-10-18 | D&L | Contacts from a move are fields (`wall_hit`, `ceiling_hit`, `floor_hit`) reset at the start of each `move()`; the mover logs no trace events until the assists add `assist` in step 6 | Step 7 reads the contacts (ceiling ends the sustain); ground rule 8 keeps core free of autoloads | `test_stops_flush_at_every_speed_up_to_dash_speed` |
| M1.3 | 2026-10-18 | Owner | `JumpResolver` includes the charged kind from M1, as an eligibility input the player passes as false until M2. Spec edited: kinds listed in precedence order in the `jump_resolver.gd` row; "Step 4, jump" item 3 says charged is built in M1 step 3 and first eligible in M2; the `test_dash_state.gd` row adds the charged refill (C-08); the M2 "Files extended" row for `jump_resolver.gd` is removed | The M1 test list required charged combinations while the M2 table said the kind arrived in M2 | `test_jump_resolver.gd` |
| M1.3 | 2026-10-18 | D&L | The both-walls rule lives in `JumpResolver.wall_jump_side()`, and the dash start and end velocities (diagonal × 1/√2, upward end × `dash_end_up_mult`) in `DashState`, so `player.gd` (step 4) only applies them | Rules live in tested core classes (ground rule 8) | `test_both_walls_*`, `test_every_direction_has_the_same_speed`, `test_end_velocity_slows_an_upward_dash` |
| M1.3 | 2026-10-18 | D&L | A charged jump clears the cooldown (when `charged_refill_clears_cooldown` is on) even if the dash charge was already full; `dash_refill` is reported only when the charge goes from 0 to 1 | Spec: "the dash refills … the cooldown clears too", with no condition on the charge; the trace catalog defines `dash_refill` as 0 → 1 | `test_charged_refill_clears_the_cooldown_when_on` |
| M1.3 | 2026-10-18 | D&L | `interrupt()` ends a dash without touching the cooldown, which keeps running from the dash start | The cooldown is the minimum time between dash starts; only the charged refill clears it | `test_interrupt_ends_the_dash_and_keeps_the_cooldown` |
| M1.3 | 2026-10-18 | D&L | `test_dash_state.gd` uses the tuning start values as constants and has no separate tuning guard | `test_tuning.gd` already pins every dash field and the derived ticks (9 and 12) | — |
| M1.1–3 | 2026-10-18 | Engine | `@warning_ignore("integer_division")` on the 9 intended integer divisions in `solid_grid.gd`, `pixel_mover.gd`, `test_pixel_mover.gd` and `test_solid_grid.gd`; `test_tuning.gd` calls the static `seconds_to_ticks()` through a preloaded script constant instead of the autoload instance | The editor showed 13 warnings that headless runs never print. The divisions mean to drop the remainder, as in `main.gd`; the static call had a real fix | Godot language server: all 26 scripts clean |
| M1.4 | 2026-10-18 | Owner | Until `load_room()` (step 5), `World` paints a temporary test floor in code (a `TileMapLayer` under `RoomSlot`, 640 × 368, atlas tile (0, 0)): floor with a 4-tile pit at cells 22–25, side walls, a 2-tile step (cells 7–11), a tall pillar (cells 16–17, rows 6–20) and a 2-tile ledge (cells 30–35). Spawn: feet at (72, 336), facing right. Every line is marked `M1 step 4 only` | The player needs a grid before rooms exist; the owner can play it at once | Step 4 check script |
| M1.4 | 2026-10-18 | Owner | Step 4 is proven by a throwaway headless check script (scratchpad, not committed); step 8's scenarios are the permanent proof | No player unit-test file is listed | Results in the build journal |
| M1.4 | 2026-10-18 | Owner | Spec edits: the wall-jump and dash rows of **Control locks** move from build-order step 6 to step 4 (built now); step 9's "Expire stale tokens." becomes "(Stale tokens are expired in step 1, before new presses.)" | Step 1's `expire()` already removes every token past its window, so an expiry in step 9 could never fire | Check script: jump press expires on tick 8 after a 9-tick dash |
| M1.4 | 2026-10-18 | D&L | `respawn()` senses grounded and walls at once, and sets coyote to `Tuning.coyote_ticks` when grounded, without logging `land` (owner addition at plan review) | Tick 1's decisions must see the real state: a jump pressed on tick 1 is a ground jump | Check: "jump on tick 1 is a ground jump", "respawn logs no land" |
| M1.4 | 2026-10-18 | D&L | Soft apex: applies only when allowed **and** jump is held **and** `abs(vy) < apex_threshold_px_s` (strict, Celeste's `<`); it resets to allowed on every grounded tick, so walking off a ledge also gets it | Spec "within `apex_threshold_px_s`" leaves the boundary open; the owner confirmed the three conditions | Check: held jump apex 54 px vs tapped 18 px |
| M1.4 | 2026-10-18 | D&L | Air control: `air_control_mult` scales both `run_accel_px_s2` and `run_reduce_px_s2`, using the grounded state sensed on the previous tick; acceleration integrates as `accel × mult / 60` through `move_toward` | Celeste's `mult` applies to both; decisions use the previous tick's sensing (spec "Decision ticks") | Check script |
| M1.4 | 2026-10-18 | D&L | Facing follows the effective horizontal input (the forced direction during a wall-jump lock); it is not updated while a dash is active; a dash with a horizontal component sets it | Steering is locked during a dash (**Control locks**), so held input must not turn the player mid-dash | Check: wall-jump lock carries the player away for 10 ticks |
| M1.4 | 2026-10-18 | D&L | Gravity applies on grounded ticks too (the spec's "otherwise"); the floor zeroes it each tick (30 px/s gives a 0.5 px remainder, rounded to 1, blocked) | Follows the spec literally; the player never drifts into the floor | Check: standing still logs nothing and stays at (72, 336) |
| M1.4 | 2026-10-18 | D&L | `jump.object` is `""` for every non-charged jump | The catalog field exists for charged jumps (M2) | Trace |
| M1.4 | 2026-10-18 | D&L | `land.vy_before` is the vertical velocity just before step 6's move | The mover zeroes vertical velocity on a blocked landing | Check: `vy_before` 320 after a long fall |
| M1.4 | 2026-10-18 | D&L | A fresh press that replaces an unspent token logs `press_expired` for the old token, then `press` | Catalog: `press_expired` is "runs out unused or is replaced" | Code review |
| M1.4 | 2026-10-18 | D&L | M1 fall: `death` (cause `fell`) is logged, the player respawns at the spawn point, held buttons are marked stale, and the camera's interpolation is reset after it moves (step 11). No `respawn` event until rooms exist | `respawn` names a room and an entrance, which arrive in step 5 | Check: "falling into the pit logs death", "player is reset at the spawn point" |
| M1.4 | 2026-10-18 | Owner | The M1.4 row on `respawn()` sensing at placement is approved as a spec change: M3's reset list (R-01) now says grounded, walls and coyote are sensed at placement with no `land`, replacing "coyote ticks 0, not grounded until sensed" | The old wording contradicted the built behavior, and `r01_reset_state.json` checks that list. Scenario starts and debug jumps use `load_room()` with no respawn lock | Check: "jump on tick 1 is a ground jump", "respawn logs no land" |
| M1.4 | 2026-10-18 | Owner | `player_frames.tres` uses the owner's `game/art/player/player_frames.png` (40 × 40: default frame at (0, 0, 20, 20), flow frame at (20, 0, 20, 20)); every `default_` animation shows the default frame and every `electric_` one the flow frame. The developer's placeholder at `player_sheet.png` was removed before commit. Sprite offset (−10, −20) puts the 12 × 15 figure exactly on the body rectangle | The owner supplied the art during the step and asked for it to be used | Visual check (F5) |
| M1.5 | 2026-10-18 | Owner | `load_room(room_id, entrance_id, is_respawn = false)` logs `room_enter`, or `respawn` when the call is a respawn; a fall logs `death` then `respawn`, never `room_enter`. Spec updated ("Room scene convention", load_room step 4) | Logging stays in one place, so no caller can forget or duplicate it; `room_enter` means entering a room for play | Scratch check: `room_enter` at tick 0, then `death`/`respawn` pairs only |
| M1.5 | 2026-10-18 | D&L | Gym `world_rect` = `Rect2i(32768, 0, 2560, 512)` (160 × 32 tiles) | Far from the game rooms near (0, 0) (verification rooms are never neighbors); room for M6's annex beside it; wide enough for every station in one row | M6 `test_world_layout.gd` |
| M1.5 | 2026-10-18 | D&L | Gym skeleton layout: the stations in one row, at the column ranges in the M1 step 5 journal entry; floor top at row 26 (y = 416), the `coyote_ledge` and `buffer_drop` ledges at row 20 (y = 320); entrance node names are PascalCase forms of their snake_case `entrance_id`s, so the two sort orders agree | Entrances must exist before the owner paints; style guide node names | Owner painting; M1 step 8 scenarios |
| M1.5 | 2026-10-18 | D&L | Provisional `chimney` width: 4 tiles between the walls, from current tuning (wall jump 260 px/s away with a 10-tick lock; a rise of about 0.32 s). Confirmed or changed when the step 8 chimney scenario runs | Gym station table: the width is chosen from the wall-jump values and logged | M1 step 8 chimney scenario |
| M1.5 | 2026-10-18 | D&L | `RoomCatalog` has only `find(room_id)` for now; "which room contains a world point" and "neighbor beyond an edge" are built in M6 with crossings, their first caller | Avoids fixing an API before anything uses it | M6 |
| M1.5 | 2026-10-18 | D&L | `Room` reads the catalog with a runtime `load()`, never `preload` | The catalog holds the room's scene, which holds `room.gd`: a preload would be a load cycle | Import and smoke run clean |
| M1.6 | 2026-10-18 | D&L | Corner correction "fits" only if every sideways pixel at the current height is free and the body is free 1 px higher at the shifted spot; the shift and that 1 px rise happen together, and rising continues | Spec: "shift sideways, a pixel at a time, … into free space"; never passes through a solid | `test_corner_correction_never_moves_into_a_solid_cell` |
| M1.6 | 2026-10-18 | D&L | Dash corner correction applies while a dash is active with `dir.x ≠ 0` and `dir.y ≤ 0` (horizontal and up-diagonal dashes); the body rises straight up, every pixel free, then takes its sideways pixel | Assist precedence: "only to dashes whose vertical component is zero or upward" | `test_dash_corner_correction_*` |
| M1.6 | 2026-10-18 | D&L | Each correction applies at most once per `move()` (one per axis per tick); a second block in the same move stops the body normally. When a correction applies, no wall or ceiling contact is noted and velocity is kept | Assist precedence, "at most one correction per axis per tick" | `test_*_applies_at_most_once_per_move` |
| M1.6 | 2026-10-18 | D&L | One-way help: rising with `-vy < apex_threshold_px_s` (strict), not grounded, the nearest tile top above the feet within `oneway_assist_px` (0 < distance ≤ limit), that top an active-family platform, and the body free at the top. Lift sets vertical velocity and remainder to 0; it runs at the start of step 7, so the same step's sensing logs `land` | Strict `<` matches the soft apex (M1.4); "counts as a landing" | `test_oneway_help_*` |
| M1.6 | 2026-10-18 | D&L | Post-dash floor snap: when a dash ends (step 9) with `dir.y ≥ 0` and the body not grounded (checked live), it descends up to `post_dash_snap_px` onto anything that stops a fall (ordinary tiles and active one-way tops). Only the position moves; the next move's floor block zeroes velocity, and the landing is sensed in the next tick's step 7 like any other, one tick later than Celeste | Keeps all sensing in step 7; landing uses one rule everywhere | `test_post_dash_snap_*` |
| M1.6 | 2026-10-18 | D&L | `assist` fields `dx`, `dy` are the displacement the assist added: corner (±k, 0), dash_corner (0, −k), oneway (0, −k), dash_snap (0, +k) | The catalog names the fields but not their meaning | Code review |
| M1.6 | 2026-10-18 | D&L | The corner-correction tie-break (velocity, then facing) is built but cannot occur at current tuning: with 16 px tiles and a 12 px body the two shifts add up to at least 28 px, so a tie needs 14 px, beyond the 8 px limit. Tested with a 14 px limit. Likewise the once-per-move tests use a 20 px limit, because 16 px tiles and a 15 px body never allow two corrections within 8 px in one move | Proves the rule survives a retune | `test_corner_correction_tie_prefers_velocity_then_facing` |

## 3. Disclosed deviations

AC values changed for a build. Each needs an owner decision before any build ships with it, and must be listed in that build's known deviations.

| Date | Field or rule | AC value → used value | Owner decision | Builds affected |
| --- | --- | --- | --- | --- |
| | | | None | |

## 4. Added test scenarios

Regression and extra scenarios added without a plan update (spec, "Implementation plan", file groups).

| Date | File | Bug or criterion covered |
| --- | --- | --- |
| | | None yet |

## 5. Questions for the owner

| Date | Question | Raised in | Answer |
| --- | --- | --- | --- |
| 2026-10-18 | Spec update awaiting approval: mark the "Cells outside a room's corners" proposal accepted for rooms without neighbors (accepted by the owner on 2026-10-18; the spec text still reads as a proposal) | M1 step 1 | Approved 2026-10-18: the spec marks it accepted, with the M1 step 2 rounding and wall-check items |
| 2026-10-18 | The player art is at `game/art/player/player_frames.png`, but the spec's slot is `game/art/player/player_sheet.png`. Rename the file to the slot path, or change the slot name in the spec? | M1 step 4 | |
