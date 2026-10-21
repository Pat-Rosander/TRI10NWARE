# Credits and asset register

One row per art, audio or font file in the game. `status` is `placeholder`, `owner draft` or `final`. The owner adds a row whenever they add a file; the developer adds rows for placeholders.

| path | purpose | status | author | license | source link | date added |
| --- | --- | --- | --- | --- | --- | --- |
| `game/art/legacy/player_v0.png` | Prototype player sprite; kept until the owner decides its use | owner draft | Pat Rosander | owner to confirm | — | 2026-10-17 |
| `game/art/legacy/world_tileset.png` | Prototype tile set; may become a tile slot (owner decides) | owner draft | Pat Rosander | owner to confirm | — | 2026-10-17 |
| `game/art/legacy/health.png` | Prototype health graphic; kept until the owner decides its use | owner draft | Pat Rosander | owner to confirm | — | 2026-10-17 |
| `game/art/tiles/level_1_tiles.png` | Level 1 tile atlas: stone blocks (solid) and telephone-pole pieces (decoration); source of `game/tiles/level_tiles.tres` | owner draft | Pat Rosander | owner to confirm | — | 2026-10-18 |
| `game/icon.svg` | Project and app icon (Godot's default icon, from project creation); replace when the owner supplies one | placeholder | Godot Engine contributors | MIT | https://github.com/godotengine/godot | 2026-10-18 |
| `game/art/player/player_frames.png` | Player frames: default state (left) and flow state (right), one 20 × 20 frame each; source of `game/player/player_frames.tres` (spec slot name: `player_sheet.png`) | owner draft | Pat Rosander | owner to confirm | — | 2026-10-18 |
| `game/art/objects/charged_object.png` | Charged object sprite (slot); centered on the region center | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/objects/charged_glow.png` | Charged object glow, drawn with additive blending (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/fonts/pixel_font.ttf` | HUD pixel font (Pixel Operator HB 8), native size 8 px (slot) | owner draft | Jayvee Enaguas (Pixel Operator); added by Pat Rosander | owner to confirm (believed CC0) | owner to confirm | 2026-10-19 |
| `game/art/player/switch_burst.png` | Switch burst effect, 4 frames of 32 × 32, left to right (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/ui/volt_pip.png` | Volt pip: full, empty; 2 frames of 8 × 8 (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/ui/dash_pip.png` | Dash pip: available (green), spent; 2 frames of 8 × 8 (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/ui/state_icons.png` | State icons: default, flow, flow-at-0-volts warning; 3 frames of 12 × 12, colored squares (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/ui/countdown_ring.png` | Countdown ring for the HUD's radial TextureProgressBar, 48 × 48 (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/backdrop/level_1_backdrop.png` | Level 1 backdrop (slot), 640 × 368, flat blue-grey; dimmed in flow | placeholder | developer (generated) | none (flat color) | — | 2026-10-20 |
