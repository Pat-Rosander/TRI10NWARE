# Support matrix

What the game has actually been tested on (AC D-02). Anything not listed as tested is **unverified**. Native builds count only when tested on their real target OS. The browser build must be tested on both macOS and Windows.

## Build

| Item | Value |
| --- | --- |
| Engine | Godot 4.5.1 stable, standard build (GDScript, no add-ons) |
| Renderer | Compatibility (OpenGL 3.3 on desktop, WebGL 2 on the web), on every target |
| Simulation | 60 ticks per second, fixed |
| Build Mac | MacBook Air (Mac14,2), Apple M2, 16 GB, macOS 15.5 (24F74) |
| Last build checked | `0.2.0-4357afe` (M3 step 6, the shipped Level 1 build) |

## Targets

| Target | Binary | OS / browser | CPU | Hardware | What was tested | Status |
| --- | --- | --- | --- | --- | --- | --- |
| macOS | Universal (x86_64 + arm64), ad-hoc signed | macOS 15.5 | Apple M2 (arm64) | Build Mac | Headless launch and quit, exit 0; universal; signature verified after the itch.io zip round trip (M0 step 10; again for `0.2.0-4357afe`, M3 step 6). Windowed play not yet checked | Partly tested |
| macOS | Universal | Any | Intel (x86_64) | — | Nothing | Unverified |
| macOS | Universal | Versions other than 15.5 | — | — | Nothing | Unverified |
| Windows | x86_64, single `.exe` | Windows 10 / 11 | x86_64 | Owner's Windows PC (details to record) | Nothing yet | Unverified |
| Web | WebAssembly, no threads | Safari on macOS | — | — | Nothing yet | Unverified |
| Web | | Chrome on macOS | — | — | Nothing yet | Unverified |
| Web | | Firefox on macOS | — | — | Nothing yet | Unverified |
| Web | | Chrome on Windows | — | — | Nothing yet | Unverified |
| Web | | Edge on Windows | — | — | Nothing yet | Unverified |
| Web | | Firefox on Windows | — | — | Nothing yet | Unverified |
| Web | | itch.io embed | — | — | Nothing yet | Unverified |

Not supported: Linux (no build is made), mobile browsers, 32-bit Windows, Windows on ARM (not tested; the x86_64 build may run under emulation).

When you test a row, fill in the exact OS or browser version, the hardware, what you ran and the build ID, and add the result to [`evidence/ledger.csv`](evidence/ledger.csv).
