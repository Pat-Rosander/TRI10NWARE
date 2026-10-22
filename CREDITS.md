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
| `game/art/objects/charged_object.png` | Charged object sprite (slot); centered on the region center; source of `game/objects/charged_object/looks/default_frames.tres`, the placeholder look | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/objects/power_root.png` | Power source sprite (slot), 16 × 16 flat green; centered on the root's origin, matching `art_rect_px` (−8, −8, 16, 16) | placeholder | developer (generated) | none (flat color) | — | 2026-10-21 |
| `game/art/objects/power_root_glow.png` | Power source glow, drawn with additive blending (slot), 32 × 32 flat green at 25 % alpha; its strength is set in M5 step 2 | placeholder | developer (generated) | none (flat color) | — | 2026-10-21 |
| `game/art/props/wire_strip.png` | Wire texture (slot), 4 × 1 white; `Line2D` needs a texture for the current shader's coordinates, and the wire's color comes from its `default_color` | placeholder | developer (generated) | none (flat color) | — | 2026-10-21 |
| `game/art/objects/charged_glow.png` | Charged object glow, drawn with additive blending (slot); fully transparent, so no glow shows (owner, 2026-10-21) | placeholder | developer (generated) | none (transparent) | — | 2026-10-19 |
| `game/art/fonts/pixel_font.ttf` | HUD pixel font (Pixel Operator HB 8), native size 8 px (slot) | owner draft | Jayvee Enaguas (Pixel Operator); added by Pat Rosander | owner to confirm (believed CC0) | owner to confirm | 2026-10-19 |
| `game/art/player/switch_burst.png` | Switch burst effect, 4 frames of 32 × 32, left to right (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/ui/volt_pip.png` | Volt pip: full, empty; 2 frames of 8 × 8 (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/ui/dash_pip.png` | Dash pip: available (green), spent; 2 frames of 8 × 8 (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/ui/state_icons.png` | State icons: default, flow, flow-at-0-volts warning; 3 frames of 12 × 12, colored squares (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/ui/countdown_ring.png` | Countdown ring for the HUD's radial TextureProgressBar, 48 × 48 (slot) | placeholder | developer (generated) | none (flat color) | — | 2026-10-19 |
| `game/art/backdrop/level_1_backdrop.png` | Level 1 backdrop (slot), 640 × 368, flat blue-grey; dimmed in flow | placeholder | developer (generated) | none (flat color) | — | 2026-10-20 |
| `game/audio/sfx/jump.wav` | Ordinary, coyote and wall jumps (slot); 16-bit mono 44.1 kHz WAV | owner draft | Pat Rosander | owner to confirm | — | 2026-10-20 |
| `game/audio/sfx/charged_jump.wav` | Charged jump (slot); 16-bit mono 44.1 kHz WAV | owner draft | Pat Rosander | owner to confirm | — | 2026-10-20 |
| `game/audio/sfx/dash.wav` | Dash start (any dash not charged by a charged jump) (slot); 16-bit mono 44.1 kHz WAV | owner draft | Pat Rosander | owner to confirm | — | 2026-10-20 |
| `game/audio/sfx/charged_dash.wav` | Dash start when the latest dash refill was from a charged jump (C-08) (slot); 16-bit mono 44.1 kHz WAV | owner draft | Pat Rosander | owner to confirm | — | 2026-10-20 |
| `game/audio/sfx/switch_to_flow.wav` | Entering flow (slot); 16-bit mono 44.1 kHz WAV | owner draft | Pat Rosander | owner to confirm | — | 2026-10-20 |
| `game/audio/sfx/switch_to_default.wav` | Leaving flow (slot); 16-bit mono 44.1 kHz WAV | owner draft | Pat Rosander | owner to confirm | — | 2026-10-20 |
| `game/audio/sfx/death.wav` | Death (slot); 16-bit mono 44.1 kHz WAV | owner draft | Pat Rosander | owner to confirm | — | 2026-10-20 |
| `game/audio/sfx/respawn.wav` | Respawn (slot); 16-bit mono 44.1 kHz WAV | owner draft | Pat Rosander | owner to confirm | — | 2026-10-20 |
| `game/audio/sfx/switch_refused.wav` | Flow refused at zero volts (slot); 0.1 s of silence, 16-bit mono 44.1 kHz WAV | placeholder | developer (generated) | none (silence) | — | 2026-10-20 |
| `game/audio/sfx/countdown_tick.wav` | Countdown tick, once per remaining second (slot); 0.1 s of silence, 16-bit mono 44.1 kHz WAV | placeholder | developer (generated) | none (silence) | — | 2026-10-20 |
| `game/audio/sfx/network_activated.wav` | Network activation, once per tick however many networks activate (slot); 0.1 s of silence, 16-bit mono 44.1 kHz WAV | placeholder | developer (generated) | none (silence) | — | 2026-10-21 |
| `game/audio/sfx/room_complete.wav` | Room completion (slot); 6.8 s, 16-bit stereo 44.1 kHz WAV, converted from the owner's `completion.mp3` | owner draft | Pat Rosander | owner to confirm | — | 2026-10-21 |
| `game/audio/music/electrun_theme_1.mp3` | Game music (slot, M3 step 7); 81 s, stereo MP3, looped | owner draft | Pat Rosander | owner to confirm | — | 2026-10-21 |
| `game/art/objects/collectible.png` | Collectible sprite (slot, M6 step 1); 16 × 16 lightning coin, centered on the node; a copy of the owner's `game/art/collectibles/lighning_coin_collectible.png` | owner draft | Pat Rosander | owner to confirm | — | 2026-10-21 |
| `game/art/collectibles/lighning_coin_collectible.png` | The owner's lightning coin, source of the `collectible.png` slot | owner draft | Pat Rosander | owner to confirm | — | 2026-10-21 |
| `game/audio/sfx/collectible_touch.wav` | Collectible touched (slot); 0.1 s of silence, 16-bit mono 44.1 kHz WAV | placeholder | developer (generated) | none (silence) | — | 2026-10-21 |
| `game/audio/sfx/collectible_commit.wav` | Collectible committed (slot); 0.1 s of silence, 16-bit mono 44.1 kHz WAV | placeholder | developer (generated) | none (silence) | — | 2026-10-21 |
| `game/art/effects/effects.png` | Effects art (slot), source of `game/world/effects_frames.tres`: 6 cells of 16 × 16 in a row, left to right `death`, `respawn`, `charged_jump`, `dash`, `land`, `goal`; each a 1-px colored outline | placeholder | developer (generated) | none (flat color) | — | 2026-10-20 |
