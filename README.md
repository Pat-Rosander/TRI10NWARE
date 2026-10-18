# TRI10NWARE

A precision platformer inspired by Celeste, made for the Tritonware game jam. You switch between a **default** state and a **flow** state that spends volts, and you use charged objects to extend your movement. It is built in **Godot 4.5.1** with GDScript and ships for macOS, Windows and the web (itch.io).

- Design and build plan: [`docs/TRI10NWARE.md`](docs/TRI10NWARE.md)
- Asset credits and licenses: [`CREDITS.md`](CREDITS.md)
- Tested platforms: [`docs/support_matrix.md`](docs/support_matrix.md)
- Known issues: [`docs/known_issues.md`](docs/known_issues.md)
- Decisions and tuning values: [`docs/decision_log.md`](docs/decision_log.md)

## Playing a build

You don't need Godot to play. Download the file for your system from the itch.io page, or take it from `builds/itch/` after an export.

### macOS (`TRI10NWARE_macos.zip`)

1. Unzip it and move `TRI10NWARE.app` wherever you like.
2. Double-click it. The app is not notarized, so on first launch macOS says it can't verify the developer. Click **Done** (not "Move to Trash").
3. Open **System Settings → Privacy & Security**, scroll to the message about TRI10NWARE, and click **Open Anyway**. Confirm with your password or Touch ID.
4. Launch the app again and click **Open**. From now on it opens normally.

Since macOS 15, Control-clicking the app no longer skips this check, so step 3 is required. The app is universal and runs natively on both Apple Silicon and Intel Macs.

### Windows (`TRI10NWARE_windows.zip`)

1. Unzip it. The game is a single file, `TRI10NWARE.exe`.
2. Double-click it. The executable isn't signed, so Windows SmartScreen may show "Windows protected your PC". Click **More info**, then **Run anyway**.

### Web

Play it in the browser on the itch.io page. To run the web build yourself, serve it over HTTP (see [Serving the web build locally](#serving-the-web-build-locally)). Opening `index.html` directly as a `file://` page does not work.

## Controls

Every key is bound by its **physical position**, so the layout works the same on AZERTY and QWERTZ keyboards (the table gives the QWERTY names). Use whichever keyboard set suits your hands.

| Action | Arrow keys set | WASD set | Gamepad |
| --- | --- | --- | --- |
| Move / aim the dash | Arrow keys | W A S D | D-pad or left stick |
| Jump (including the charged jump) | C or Space | J or Space | Bottom face button (A / Cross) |
| Dash | X | K | Left face button (X / Square) |
| Switch default ⇄ flow | Z | L | Right shoulder (RB / R1) |
| Pause | Escape or P | Escape or P | Start |
| Fullscreen (desktop) | Alt+Enter (Option+Return on a Mac) | same | — |

The stick uses a round deadzone and snaps to 8 directions, so diagonals are never faster than straight moves. In a browser, Escape first leaves fullscreen (the browser does this), and the itch.io page's fullscreen button replaces Alt+Enter.

## Working on the project

### Prerequisites

- **Godot 4.5.1 stable, standard build** (not the .NET build): [download](https://godotengine.org/download/archive/4.5.1-stable/). No add-ons or plugins are needed.
- **The Godot 4.5.1 export templates**, installed through Godot's **Editor → Manage Export Templates** (only needed for exporting).
- **Git**, and a Mac with **Python 3** for the scripts in `tools/` (they are shell scripts for macOS).
- The `GODOT` environment variable set to the Godot executable. On the build Mac:

  ```bash
  export GODOT="/Applications/Godot 4.5.1 .app/Contents/MacOS/Godot"
  ```

  The path contains spaces, so always quote it, as in `"$GODOT"`.

### Getting the project

```bash
git clone https://github.com/Pat-Rosander/TRI10NWARE.git
cd TRI10NWARE
```

Or, on the GitHub page, click **Code → Download ZIP** and extract it.

The Godot project is the **`game/`** folder. The repository root holds documents and tools, which Godot never sees.

### Opening and running

1. Start Godot 4.5.1. In the Project Manager, click **Import**, choose `game/project.godot`, then **Import & Edit**. Let the first import finish. From a terminal, `"$GODOT" --headless --path game --import` does the same import.
2. Press **F5** (Run Project).
3. To test the window size and fullscreen from the editor, turn off **Embed Game on Next Play** in the Game tab first: a game embedded in the editor can't resize itself or go fullscreen.

From a terminal: `"$GODOT" --path game`.

### Debug tools

Debug tools are off for players. Turn them on with a command-line flag after `--`:

```bash
"$GODOT" --path game -- --debug-tools                              # from the project
builds/macos/TRI10NWARE.app/Contents/MacOS/TRI10NWARE -- --debug-tools   # exported macOS app
TRI10NWARE.exe -- --debug-tools                                    # exported Windows build, from a terminal
```

In the editor, set **Project → Project Settings → Run → Main Run Args** to `-- --debug-tools`. Don't commit that setting.

On the web build, add `?debug=1` to the address. This works only when the page is served from `localhost` or `127.0.0.1` (for example `http://localhost:8000/?debug=1`). It has no effect on itch.io.

With debug tools on:

| Key | Does |
| --- | --- |
| Backtick (`` ` ``) | Show or hide the debug overlay: tick, FPS, physics rate, build ID, speed |
| 1 (overlay open) | Freeze or unfreeze the simulation |
| 2 (overlay open, frozen) | Advance exactly one tick |
| 3 (overlay open) | Cycle slow motion: 1×, ½×, ¼× |

On desktop, closing the game saves the event trace to Godot's `user://traces/` folder. That is `~/Library/Application Support/Godot/app_userdata/TRI10NWARE/traces/` on macOS and `%APPDATA%\Godot\app_userdata\TRI10NWARE\traces\` on Windows. Other flags: `--render-fps=<n>` caps the frame rate (for 30/60/120 FPS checks), and `--run-scenarios[=prefix]` with `--quit-when-done` runs the scripted scenarios (from milestone M1).

### Tests

```bash
tools/run_tests.sh
```

This runs the import step, the unit tests and the scenarios headless at a fixed 60 FPS. It exits with 0 only when everything passes. The scenarios are skipped until the scenario runner exists (M1). The unit tests alone: `"$GODOT" --headless --path game res://tests/test_runner.tscn`.

### Exporting

```bash
tools/export_all.sh
```

The working tree must be clean: every build is stamped with the commit it came from, so uncommitted changes are refused. The script writes the build ID (`<version>-<commit>`, for example `0.1.0-4fa9196`) into the builds, exports all three targets and packages them:

| Output | What |
| --- | --- |
| `builds/macos/TRI10NWARE.zip` | macOS app (universal, ad-hoc signed, not notarized) |
| `builds/windows/TRI10NWARE.exe` | Windows build (x86_64, a single file) |
| `builds/web/` | Web build (`index.html` and its files) |
| `builds/itch/TRI10NWARE_web.zip`, `TRI10NWARE_macos.zip`, `TRI10NWARE_windows.zip` | The itch.io upload files |

If the script stops after exporting with "the working tree is not clean", the export rewrote `.import` or `.uid` files. Commit them and run it again. Editor runs show the build ID `0.1.0-dev`.

### Serving the web build locally

```bash
tools/serve_web.sh          # port 8000
tools/serve_web.sh 8080     # another port
```

Then open `http://localhost:8000/`. The script serves `builds/web/` with Python 3's built-in server, sends `.wasm` files with the type browsers require, and turns off caching so you always get the newest export. Press Ctrl+C to stop it.

### Uploading to itch.io

1. Run `tools/export_all.sh` from a clean commit.
2. On the itch.io project page, choose **Edit game**. Set **Kind of project** to **HTML**.
3. Under **Uploads**, upload `builds/itch/TRI10NWARE_web.zip` and tick **This file will be played in the browser**.
4. Upload `TRI10NWARE_macos.zip` and mark it **macOS**. Upload `TRI10NWARE_windows.zip` and mark it **Windows**.
5. Under **Embed options**, set the size to **1280 × 720**, turn **Fullscreen button** on, and leave **SharedArrayBuffer support** off (the web build doesn't use threads).
6. Save, then check the page in draft before publishing it.

## Repository layout

```text
README.md, CREDITS.md   this file; the asset register with licenses
docs/                   the spec, build journal, decision log, known issues, support matrix, evidence
docs/reference/         the authoritative design and acceptance-criteria PDFs, Level 1 mockups
tools/                  export_all.sh, run_tests.sh, serve_web.sh
game/                   the Godot project (res://)
builds/                 export output (not in git)
```

The full layout, with the reason for every file, is in [`docs/TRI10NWARE.md`](docs/TRI10NWARE.md) under "Repository layout".
