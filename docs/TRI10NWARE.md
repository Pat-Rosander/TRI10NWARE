# TRI10NWARE

## Introduction

TRI10NWARE is a 2D pixel-art precision platformer made for the Tritonware game jam, whose theme is **Flow State**. It takes its movement and feel from *Celeste*: tight jumps, wall jumps and a dash you can aim in any direction. Each room is a short movement puzzle that you read, plan and then execute.

The player character is struck by lightning and gains the ability to switch into **flow**, an electrically charged state. In flow, the world dims and electrical objects light up. The player can then use those objects to jump farther than they could on their own, and touch dead power sources to bring whole networks back to life. Switching back to the ordinary **default** state matters too: some platforms only hold the player in default, and others only in flow.

Flow has a cost. The player carries three **volts**, and every switch into flow spends one. Switching back to default is free, and powering up a network refills all three. Spending the last volt starts a short countdown, and the player has that long to reach a power source or die. Deaths are quick and the retry is instant, so failing is part of learning a room.

The challenge comes from combining all of this in one motion: jump, switch, launch off a charged object, dash, and switch back to land, while budgeting volts along the way. The world is a set of connected rooms with backtracking, secrets and optional challenges for players who want to master the movement.

The game is being built in Godot 4.5.1 with GDScript, for macOS, Windows and desktop web browsers.

## How the game is put together

### The big idea: one clock decides everything

The game runs on a steady internal clock that ticks 60 times a second, no matter how fast the screen redraws. Everything that matters happens on those ticks: whether a jump goes off, whether a volt is spent, whether the player dies. Drawing the picture happens separately and only shows the result.

Keeping these apart means the game follows the same rules on a fast computer, a slow laptop or a web browser. On any one computer, a jump is exactly as high at 30 frames per second as at 120; across different kinds of computer, results agree to within a pixel and a tick (see **Determinism contract**). Timing rules can also be stated exactly: "a jump pressed up to 100 ms before landing still counts" becomes "up to 6 ticks before landing."

### The four parts

The game is made of four parts, each with one job.

```text
┌──────────────────────────────────────────────────────────────────┐
│  ALWAYS-ON SERVICES  (exist for the whole time the game runs)    │
│                                                                  │
│   ┌────────────┐      ┌────────────┐      ┌────────────────┐     │
│   │  Settings  │      │  Recorder  │      │  Save record   │     │
│   │ every      │      │ log of     │      │ permanent      │     │
│   │ number and │      │ every rule │      │ progress:      │     │
│   │ switch     │      │ event      │      │ collectibles,  │     │
│   └────────────┘      └─────▲──────┘      │ unlocks        │     │
│                             │             └────────────────┘     │
└─────────────────────────────┼────────────────────────────────────┘
                              │ reports what happened
┌─────────────────────────────┼────────────────────────────────────┐
│  THE GAME SCREEN  (loaded once, never replaced)                  │
│                             │                                    │
│   ┌─────────────────────────┴─────────────────────────────────┐  │
│   │  WORLD — the referee                                      │  │
│   │  runs every tick in a fixed order; swaps rooms in and out │  │
│   └───────────┬──────────────────────────────────┬────────────┘  │
│               │ moves                            │ builds fresh  │
│               ▼                                  ▼               │
│   ┌──────────────────────┐   touches   ┌──────────────────────┐  │
│   │  PLAYER              │────────────▶│  CURRENT ROOM        │  │
│   │  survives every      │             │  thrown away and     │  │
│   │  death and room      │◀────────────│  rebuilt on death    │  │
│   │  change              │  recharges  │                      │  │
│   └──────────────────────┘             └──────────────────────┘  │
│                                                                  │
│   ┌────────────────────────────────────────────────────────────┐ │
│   │  SCREEN OVERLAYS — volts, countdown, pause menu, debug view│ │
│   └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

**The always-on services** start when the game launches and last until it closes. None of them decides anything about gameplay.

- **Settings** holds every adjustable number in one place: jump height, dash speed, timing windows, countdown length. It also holds the on/off switches for rules we expect to revisit after playtesting. Nothing changes it while the game runs.
- **Recorder** keeps a time-stamped log of every rule event: each jump, volt spent, death and so on. It is how we prove the game does what this document says, and it never influences play.
- **Save record** remembers permanent progress for the current session, such as collected items and the game's completion. It survives death and room changes; temporary things like a powered network do not. Nothing is saved to disk.

**The world** is the referee. It is the only part that runs the clock, and on every tick it walks through the same checklist in the same order (see the next section). It also brings rooms in and out as the player crosses between them, and remembers where the player should reappear after dying.

**The player** is the character and everything that belongs to them: what they are pressing, how they move, which state they are in, their volts and countdown, and how they look. The player survives deaths and room changes. They are reset rather than recreated.

**The current room** is one area of the level, at least one screen in size. Like *Celeste*, the world is made of separate rooms that sit side by side on one shared **world map**, joined where their edges touch. A room holds its ground and walls, its two kinds of state-dependent platforms, its charged objects, its power networks and its collectibles. Only the room the player is in is active; while the player crosses into a neighbor, both are briefly present so the camera can slide between them (see "How rooms connect" below). A room is disposable. When the player dies, the world throws the room away and builds a fresh copy, so nothing left over from a failed attempt can carry into the next one.

**The screen overlays** sit on top of the game: volts, flow state, dash availability, the countdown, the pause menu, and a debug view for testing. Like all visuals, they only display what the game already decided.

### What happens on every tick

The world runs the same checklist 60 times a second. Because the order never changes, any two things that happen at the same moment always resolve the same way.

```text
  ┌───────────────┐
  │ 1. Read input │  What did the player just press?
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 2. Switch     │  Default ⇄ flow: pay the volt, change which platforms are solid
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 3. Dash       │  If a dash is available
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 4. Jump       │  At most one jump: ground, late-ledge, charged, or wall
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 5. Physics    │  Apply gravity and speed
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 6. Move       │  Move the player, stopping at anything solid
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 7. Look around│  Landed? Touching a wall? Inside a charged object's area?
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 8. Contacts   │  Touching a dead power source while in flow? Power it up, refill volts
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 9. Timers     │  Count down the zero-volt timer and other short timers
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 10. Outcomes  │  Reached the goal → done; else countdown ran out or fell → death
  └───────┬───────┘
          ▼
  ┌───────────────┐
  │ 11. Show      │  The screen, HUD and sound read the new state
  └───────────────┘
```

A few rules follow directly from this order:

- Switching comes first, so a player in the air who switches into flow and presses jump at the same instant can get a charged jump.
- Dashing comes before jumping, so pressing both at once gives a clean, full dash. The jump press waits briefly and is used only if a jump becomes possible in time.
- Power sources are checked after moving and switching, so walking into one, falling onto one, dashing into one, or switching to flow while already touching one all work the same way.
- Recharging comes before the countdown, so a player who reaches a power source on the very last tick is saved.

### How input reaches the player

The player never reads the keyboard directly. A small input stage turns each fresh button press into a one-time "token" that can be spent on exactly one action. A press can't trigger two things, and holding a button down doesn't repeat it. An unused press quietly expires after a short window.

```text
  Keyboard / gamepad ─┐
                      ├──▶  Input stage  ──▶  press tokens  ──▶  Player
  Test script ────────┘    (same output either way)
```

The same input stage can also be fed from a test script instead of a real keyboard. A test can then replay an exact sequence of presses, tick by tick, and check the recorder's log for exactly the expected result.

### What happens when the player dies

```text
  Death ──▶ freeze input, play death effect (~0.35 s)
        ──▶ world throws away the room, builds a fresh copy (1 tick)
        ──▶ player reset: last entrance, default state, 3 volts, 1 dash, standing still
        ──▶ respawn effect, control returns (~0.25 s)

  Total: well under 1 second
```

Because the room is rebuilt rather than repaired, every retry starts from exactly the state the room was designed in. Powered networks switch back off, charged objects are ready again, and no half-finished timers or effects survive. Permanent progress lives in the save record, outside the room, so it is unaffected.

### How rooms connect

Every room has a fixed place on one shared **world map**, the way rooms sit next to each other on a Celeste chapter map. Each room is still its own file, built and thrown away on its own; the map only says where it sits and which rooms are its neighbors.

```text
  World map: one shared coordinate space; every room has a fixed place
  ┌────────────────────┬─────────────────┐
  │                    │                 │
  │      Room A        │     Room B      │
  │  (two screens wide)│  (one screen)   │
  │                    ├─────────────────┤
  └──────────┬─────────┤                 │
             │ Room D  │     Room C      │
             │ (one    │ (taller than a  │
             │ screen) │     screen)     │
             └─────────┴─────────────────┘

  During play:        only the room the player is in is active
  During a crossing:  that room and the one being entered, side by side
```

**Edges decide what happens when the player reaches them:**

- **An edge shared with another room is an opening.** Crossing it moves the player into that room.
- **A side or top edge with nothing beyond it is a wall.** The player stops there.
- **A bottom edge with nothing beyond it is a pit.** Falling past it kills the player.

**Crossing into a neighbor:**

```text
  Player crosses Room A's right edge into Room B
    ──▶ the rules pause (the zero-volt countdown is frozen)
    ──▶ Room B is built at its place on the map, right beside Room A
    ──▶ the camera slides from Room A to Room B (~0.3 s); both are visible
    ──▶ Room A is thrown away; a collectible the player is carrying is kept for good
    ──▶ the nearest entrance in Room B becomes the new checkpoint
    ──▶ the rules resume; the player carries on with the same speed, state and volts
```

**Why it works this way:**

- **The slide shows the real neighbor**, so the player always sees which way they went. That matters for backtracking and exploration.
- **Only one room is active during play,** so a retry rebuilds just that room. Nothing else in the world needs resetting.
- **Leaving a room and coming back rebuilds it,** so its power networks are off again and can recharge the player once more. One visit to a room is the reset period for networks.
- **Checkpoints are always room entrances.** Dying returns the player to the entrance where they last entered the current room.

### Visuals are a window, not a lever

Animations, effects, sound, the camera and the overlays only ever *show* what the world decided. Nothing waits for an animation to finish, and no effect can delay or block the player's control. This keeps the controls feeling immediate. It also means the visuals can be redesigned freely without changing how the game plays.

## Parked ideas and rejected decisions

This section records ideas that were considered and deliberately left out. It exists so they are not quietly reintroduced, misremembered as decided, or argued over again without new information.

**Rules for this section:**

- **Parked** means "not now." A parked idea must not appear in code, levels, art or tuning until the owner explicitly moves it into scope and this document is updated to say so.
- **Rejected** means "decided against." A rejected option stays rejected unless the owner reopens it, and reopening it is recorded here with the reason.
- When something below conflicts with an older note, mockup, chat or memory, this section wins.
- No **parked** idea may be partially built as groundwork, a hidden flag or a placeholder. Settings that exist for an **Open decision** are different; see that section.

Sources are abbreviated: **Design** is the consolidated TRI10NWARE design document (9 pages, October 12, 2026; `docs/reference/TRI10NWARE_design.pdf`), **AC** is the acceptance criteria (9 pages, October 12, 2026; `docs/reference/TRI10NWARE_acceptance_criteria.pdf`), and **Owner** is a decision the owner made in conversation, with its date. An earlier 4-page original design exists but is not authoritative and is not used.

### Parked: future features to test after the core game works

None of these exist in the first version. Each will be tried only once the core is finished and solid: movement, default/flow switching, the two platform types, charged objects and networks. Each needs an explicit owner decision before work starts (AC page 1).

#### Viruses (enemies)

- **Idea:** a virus travels along a power network and is visible only in flow. A later variant: powering an infected network could release an enemy that chases the player. A possible progression runs from a flow-only virus to one that exists in both states. A link to the game's story theme was mentioned.
- **What is not decided:** whether a virus is visible, exists and collides in each state. These are three separate rules, and none is settled. There is no story content.
- **Questions to answer first:** Does switching state make the danger trivial to avoid? Could a virus make a required charged crossing unfair or impossible?
- **Source:** Design pages 9 and 7; AC page 1.

#### Water

- **Idea:** an environment that is safe in default but cannot be safely entered in flow.
- **What is not decided:** what happens when the player enters water in flow.
- **Ruled out even when built:** swimming or water physics. Water is a state hazard, not a movement mode.
- **Source:** Design page 9; AC page 1.

#### Propulsion objects

- **Idea:** grew out of an earlier "repelling surface" idea: a separate kind of charged object that launches the player a long distance, vertically or horizontally.
- **Must stay separate from:** the ordinary charged object, whose launch rules are fixed (see the rejected decisions below).
- **Source:** Design page 9; AC page 1.

#### Timed networks

- **Idea:** a network that stays powered only for a limited time.
- **Condition:** only after players have mastered ordinary activation.
- **Source:** Design pages 5 and 9; AC page 1.

#### Interfering networks

- **Idea:** linked networks where powering A switches B off.
- **Condition:** only if time permits, and only after timed networks.
- **Source:** Design pages 5 and 9; AC page 1.

#### Whole-wall phasing

- **Idea:** passing through ordinary walls in some state.
- **Status:** at most a future possibility. Today ordinary walls are solid in both states and never phase.
- **Source:** Design pages 1 and 9; AC page 1.

#### Levers, keys, buttons and doors

- **Idea:** ordinary interactive objects to give the player more ways to engage with the world.
- **Status:** not committed, and specifically not a "default-only" system.
- **Condition if revisited:** a state restriction on any interaction must serve traversal, not just add a toggle.
- **Source:** Design page 4.

#### Other parked items

| Idea | Status | Source |
| --- | --- | --- |
| Hazards specific to one state | Open question about whether they would feel logical; none exist | Design page 9 |
| Changing or rearranging level geometry | Not the jam design; no such system | Design pages 4 and 7; AC page 1 |
| Currency or spending system for collectibles | Not selected | Design page 7 |
| Completion tracking and replay incentives | Possible later uses, not requirements | Design page 7 |
| Movement bonuses that depend on state | Not established; flow does not change jump or dash values | Design page 3 |
| Wall slide (slower falling while holding toward a wall) | Not needed now; Celeste has it, the design does not | Owner, 2026-10-16 |
| Fast fall (holding down to fall faster) | Not needed now; Celeste has it, the design does not | Owner, 2026-10-16 |
| Additional progression systems | Deferred until the core is tested | Design page 7 |
| Story development or new ending content | None required | AC pages 1 and 7 |
| Saving progress after the app closes | Not a jam focus; progress lasts for the session only | Owner, 2026-10-13 |

### Rejected: options considered and decided against

Each row names what was rejected, what replaced it, and where the decision was made. These are the arguments not to have again.

#### Player and states

| Rejected | What we do instead | Source |
| --- | --- | --- |
| Leaving flow kills the player (the original rule) | Running out of volts starts a countdown; leaving flow is free | Design page 6 |
| Switching changes the player's own body, such as partial intangibility | Switching changes only which platforms are solid; the player's body never changes | Design page 1 |
| Default as a second movement system with its own verbs or puzzles | Default's value is footing on default-only platforms and passing through flow-only ones | Design page 4 |
| Calling the state "electric" in design language | "Flow" is the design term; "electric" survives only in asset file names | Design page 8 |

#### Movement and charged objects

| Rejected | What we do instead | Source |
| --- | --- | --- |
| Dash only on the ground | Dash works on the ground and in the air, aimed in any of 8 directions | Design pages 3 and 6 |
| Ending a dash at its exit speed before a charged jump | The charged jump keeps the dash's full horizontal speed | AC C-06 (owner, 2026-10-16) |
| One charged jump spending only the nearest of several overlapping regions | It spends every region the player is inside | Owner, 2026-10-16 |
| A separate "charged dash" action | The charged dash is the normal dash, refilled by a successful charged jump | Owner, 2026-10-12 |
| A charged object used up after one jump, or once per landing | Reusable: one charged jump per visit, re-armed by physically leaving its area | Design page 3; AC C-03 and C-04 |
| Repeated launches while staying inside the area | One launch per visit; pressing again or holding does nothing | AC C-03 |
| Re-arming an object by switching state while inside it | Only a real exit from the area re-arms it | AC C-04 |
| Refilling the dash just by touching or passing through an object | Only a successful charged jump refills the dash | Design page 3; AC M-04 and C-02 |
| A charged jump that adds to the player's current upward speed | It replaces vertical speed with a fixed launch speed | AC C-05 |
| Releasing jump early to shorten a charged jump | A charged jump always goes full height | AC C-06 |

#### Networks and volts

| Rejected | What we do instead | Source |
| --- | --- | --- |
| Activating a network with a dash impact, or by switching at a set distance | Plain contact with the power source while in flow | Design page 5; AC N-01 |
| Requiring an already-powered object across the gap to start a network | The canonical crossing powers its network from the near side. Chaining is still allowed: one network's objects may carry the player to another network's source | Design page 5 |
| Re-touching an active source to refill volts again | One recharge per activation; resets only with the room | Design page 5; AC N-03 |
| Treating network power as permanent progress | Power is temporary and resets with the room; permanent progress is separate | Design pages 5 and 6; AC G-02 |

#### Level design

| Rejected | What we do instead | Source |
| --- | --- | --- |
| "Challenge A": an ordinary route beside an equally hard flow route that costs a volt | "Challenge B": jumps, dashes, charged actions and switching combined in one sequence | Design page 7 |
| Every room must offer an alternative route | Required single sequences are fine; choices must change risk, position, switches or volts | Design page 7 |
| A blanket ban on clever alternate routes in Level 1 | Not approved; bypasses are reported, and the charged route must still work | AC page 2 |
| Enemies that exist only in flow, in the first version | No enemies in the first version (see Viruses) | Design page 9 |
| One continuous map (Metroidvania-style) | Separate rooms joined at their edges on one world map, Celeste-style | Owner, 2026-10-13 |

#### Technical approach

These were chosen while planning the implementation; each was weighed against the acceptance criteria.

| Rejected | What we do instead | Why |
| --- | --- | --- |
| Gameplay timed by screen frames or engine timers | Every rule runs on the fixed 60-tick clock, counted in ticks | Must behave identically at 30, 60 and 120 FPS (AC D-05) |
| Each object running its own per-tick logic | One referee (World) runs the tick in a fixed order | The order settles every same-moment tie |
| Game events triggered by animations finishing | Visuals only display; they never trigger or delay rules | No hidden input delay (AC page 3) |
| Resetting a room in place after death | Throw the room away and build a fresh copy | Nothing can leak from a failed attempt (AC R-01, R-03) |
| Saving and restoring each room's state | Same: rebuild from the room file | Avoids per-object save code |
| Replacing the whole game screen for each room | Only the room is swapped; player, camera and overlays persist | Keeps control return under 1 second (AC R-02) |
| The room manager as an always-on service | Part of World, on the game screen | It must hold the room and tick with the player |
| Loading the whole level as one scene | Each room is its own scene; only the current room is active | Retries rebuild one room; no per-object reset code (AC R-01, R-03, N-04) |
| Isolated rooms joined by a fade to black | Rooms placed on a shared world map; the camera slides between neighbors | Shows the real neighbor and keeps the player oriented (owner, 2026-10-13) |
| Exit zones that name a target room and entrance | Crossing a shared edge into the neighbor found on the world map | The map is the only record of connections, so links cannot disagree with it |
| Saving progress to disk | Progress lasts for the session only | Not a jam focus (owner, 2026-10-13) |
| Engine collision signals deciding when a charged area is entered or left | A direct shape check every tick | Signals can arrive late or fire falsely on a state switch (AC C-04) |
| Buffering the switch button like jump and dash | A switch fires on its own tick or is refused | A delayed switch could spend a volt the player no longer wanted |
| Relying on the engine's built-in glow for the flow look | Hand-made glow sprites and dimming | The web build's renderer may not match it |
| Godot's physics bodies for the player (`CharacterBody2D`, `move_and_slide()`) | A custom whole-pixel mover against the tile grid | Determinism across CPUs and the web, Celeste-style assists, per-tile overlap rules (owner, 2026-10-16) |
| A level-complete screen between levels | Each level's goal opens into the next level, with a banner | Keeps the world connected for backtracking (owner, 2026-10-16) |
| Debug tools available to every player | Enabled only by a launch argument or a local URL parameter | The debug menu would be a level select (owner, 2026-10-16) |

## Open decisions

These questions are deliberately left open until playtesting. Until the owner decides, the game uses the current value shown, which matches the AC wherever the AC sets one. Each has an ID used elsewhere in this document. Deciding one means updating this table and the decision log.

Where a setting offers values other than the AC's (for example `countdown_in_default` = `pause`), using one of them is a **disclosed deviation**: before any build ships with it, the owner's decision is recorded in `docs/decision_log.md` and listed in that build's known deviations. The AC value is always the default.

| ID | Question | Current value | Where it lives |
| --- | --- | --- | --- |
| OD-1 | **Zero-volt rules.** After the last volt is spent, does the countdown continue, pause or stop when the player returns to default? Can flow be entered at 0 volts? Design page 6 lists both as deferred | Countdown continues; flow entry at 0 is refused (AC S-03) | `countdown_in_default` and `allow_flow_entry_at_zero` in `tuning.tres`. Consequence of the current values: switching to default at 0 volts is certain death (level design rule 1) |
| OD-2 | **Dash cue.** Hair color shows default versus flow (design page 8), but Celeste players read hair as dash availability. What on-character cue shows that a dash is available? | The HUD dash pip only | `player_visuals.gd`, `hud.gd` |
| OD-3 | **Volts as health.** Design page 6 calls volts health, but only entering flow spends them. Should anything else cost volts, and should the HUD call them health? Decide together with the spikes package: do spikes kill or cost a volt? | Only entering flow spends volts | `FlowLedger`, `hud.gd` |
| OD-4 | **Dash freeze and delayed aim.** Celeste briefly freezes the game when a dash starts and reads its direction at the end of the freeze, which forgives sloppy diagonals. Add either? A freeze would be a documented control lock (AC page 3) | Neither: the dash starts and aims on its press tick | `DashState`, step 3 |

## Implementation plan

This section is the build manual. It is written for a developer, human or AI, who starts with nothing but this document. Read the whole document first, especially **Parked ideas and rejected decisions** and **Open decisions**, then build in the order **How work is delivered** sets. Do not start a milestone until the previous one's **Done when** checks all pass.

**Authority.** The design document and the acceptance criteria (`docs/reference/`) are the authoritative sources. This document turns them into one technical authority: it records how each requirement is met, plus every owner decision made since. Where this document and those sources disagree, the difference is either an owner decision recorded here with its date, or a mistake in this document to fix.

Files fall into three groups, with different rules:

| Group | Examples | Rule |
| --- | --- | --- |
| **Code and structure** | `.gd` scripts, `.gdshader` shaders, `.tscn` scenes, `.tres` resources that hold rules, settings or structure, project and export configuration, tools, project documents | **Strictly listed.** Every one is named in this plan with the reason it exists. Creating one that is not listed is not allowed until this section is updated with the file and its reason |
| **Owner assets** | Sprites, tile art, effects art, fonts, sound effects, music, and the `SpriteFrames` and `TileSet` contents built from them | **Added by the owner, in parallel with the code, at any time.** They do not need to be listed here first. Each is recorded in the asset register (`CREDITS.md`, described below) when it is added. The plan names only the **slots** the code depends on (below) |
| **Test scenarios added later** | Regression scenarios for bugs, extra cases for a criterion | **Allowed without a plan update,** if the file sits in `game/verification/scenarios/`, is named `<criterion id>_<short_name>.json` or `regression_<short_name>.json`, and gets a decision-log entry saying which bug or criterion it covers |

Files Godot generates itself are exempt: the `.godot/` cache folder, `.import` files beside imported assets, `.uid` files beside scripts and shaders, and `.editorconfig`. Commit the `.import`, `.uid` and `.editorconfig` files; never commit `.godot/`.

**Asset slots and placeholders.** A slot is an asset path the code or a scene refers to directly, such as `game/art/player/player_sheet.png`. Every slot is listed in the milestone that first needs it, with what it must show. When the code needs a slot before the owner's file exists, the developer adds a plain placeholder at that exact path and registers it as a placeholder. The owner replaces it by saving the real file over the same path and updating the register. A file the owner adds beyond the slots (extra layers, variants, music) is used once the owner asks for it; if using it needs new code, that code is planned first like any other code file.

### How an AI developer works from this document

The code is written by an AI developer working from this document. Each working session follows these rules:

1. **Read before writing.** Read the ground rules, **Parked ideas and rejected decisions**, **Open decisions**, and the whole milestone being worked on.
2. **One numbered step at a time.** After each step, run `tools/run_tests.sh` (and the scenarios that step affects), and commit with a message naming the milestone and step, such as `M1 step: pixel mover`.
3. **Never invent.** Decide only what the authority tiers below allow. Never create an unlisted code file, change a rule, change an AC value, or add a feature. If one seems needed, stop and propose the change to this document; the owner decides.
4. **Ask instead of guessing.** Where this document is ambiguous, contradicts itself or contradicts the engine, stop, describe the problem, and record the question in `docs/decision_log.md`.
5. **Leave owner assets alone.** Never edit or overwrite an asset whose register status is `owner draft` or `final`. Placeholders may be added or changed only at listed slot paths.
6. **Keep the logs current.** Every tuning change, developer-owned choice and added test scenario gets a decision-log entry in the same commit.
7. **Explain and hand off.** Every step ends with an entry in `docs/build_journal.md` (what was built, how it works in plain language, why, how to see it, decisions and questions) and an updated **Status** block at the top of that file, so the next session knows exactly where work stands. Each session starts fresh with `/step <milestone.step>` (the skill in `.claude/skills/step/`), which encodes these rules; `CLAUDE.md` is a short index into this document, which is never loaded whole.

**Authority tiers.** What the AI developer may decide on its own:

| Tier | Examples | Rule |
| --- | --- | --- |
| **Decide freely** | Private functions, variables and data structures inside a listed file; any algorithm that produces exactly the behavior this document specifies; comments; the node layout of a menu scene | No approval and no log entry needed |
| **Decide and log** | Anything a player or tester could notice that this document leaves open; engineering constants that are not gameplay tuning (sound pool size, test-room dimensions); a workaround for an engine quirk | Allowed; recorded in `docs/decision_log.md` in the same commit |
| **Owner approval first** | New code files; changes to rules, tuning defaults, AC values, the trace catalog or controls; new features; anything in Parked, Rejected or Open decisions; anything that would make a test or scenario pass by changing what it checks | Stop and propose a change to this document |

Godot documentation links point at the 4.5 manual, `https://docs.godotengine.org/en/4.5/`. Where a link and this document disagree about *what the game should do*, this document wins. Where they disagree about *how the engine behaves*, the engine wins: record the difference in `docs/decision_log.md` and update this document.

### Ground rules for the code

These rules apply to every file. Most exist because the acceptance criteria require behavior that is exact, repeatable and identical on every platform.

1. **Godot 4.5.1 stable, GDScript only.** No C#, no GDExtensions, no editor plugins, no Asset Library downloads. *Why:* the project must open and export on a fresh machine from the repository alone (AC D-08), and the web export must stay simple.
2. **Static typing everywhere.** Every variable, parameter and return value has a type. The project setting `debug/gdscript/warnings/untyped_declaration` is set to **Error** to enforce this. *Why:* typed GDScript catches mistakes at load time and runs faster. Docs: [Static typing](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/static_typing.html).
3. **Only `World` has `_physics_process`.** No other node runs gameplay in `_physics_process`, `_process`, `Timer`, `SceneTreeTimer`, `await`, physics signals (`body_entered` and similar) or animation callbacks. Visual and audio nodes may use `_process` to *read* state and draw it. *Why:* the 11-step tick order is the tie-break policy; any rule running elsewhere escapes it. Docs: [Idle and physics processing](https://docs.godotengine.org/en/4.5/tutorials/scripting/idle_and_physics_processing.html).
4. **Gameplay time is counted in ticks.** Seconds appear only in `config/tuning.tres`. The `Tuning` service converts them to whole ticks once at startup. Velocity integration uses the fixed tick length (1/60 s). Never use `Engine.time_scale`: it changes the delta every physics step receives and would change results. Docs: [Engine.time_scale](https://docs.godotengine.org/en/4.5/classes/class_engine.html).
5. **Only an input source reads the gameplay actions** (move, jump, dash, switch) for the simulation, which receives them as an `InputFrame`. Menus, overlays and debug keys may read their own actions, but change the simulation only through `World`'s public calls (start, pause, rebuild). *Why:* scripted tests must be able to replace the keyboard exactly.
6. **Only `FlowLedger` changes state, volts or the countdown.** *Why:* "no movement costs volts" (AC M-08) then holds by construction.
7. **Every rule event is reported to `Trace`** with its tick. If an event is not in the trace catalog (M0), add it to the catalog in this document first.
8. **Rules live in `res://core/`** as small classes that extend `RefCounted` and touch no nodes, autoloads included: tuning values are passed in when a class is created. Each has a unit test, except pure data holders such as `InputFrame`, which are covered by the tests that use them. Nodes are thin adapters that feed those classes and apply their results.
9. **No tunable number is written in code.** If a designer might ever adjust it, it is a field in `tuning.tres`.
10. **Nothing from the Parked list and nothing from the Rejected list** may be built, even partially.
11. **Room scenes never contain the player, camera, HUD or menus.**
12. **Every script begins with a short header comment** stating its job in one to three lines and the acceptance criteria IDs it serves. Use `##` documentation comments for public methods. Docs: [Documentation comments](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_documentation_comments.html).
13. **Art and audio belong to the owner.** The owner makes and decides all art and audio (sprites, tiles, palette, animation, effects, fonts, sound, music, visual style) and adds them to the project in parallel with the code. This plan names only the slots the code expects and what each must show. Until the owner's file arrives, the developer uses a registered placeholder at that exact path and never makes an art decision.
14. **Guard `@tool` scripts.** Scripts marked `@tool` (rooms, charged objects, networks and others that draw in the editor) create their runtime helpers and run gameplay code only when `Engine.is_editor_hint()` is false. In the editor, Godot gives them placeholder copies of non-tool classes. Docs: [Running code in the editor](https://docs.godotengine.org/en/4.5/tutorials/plugins/running_code_in_the_editor.html).
15. **Determinism-safe math in rules.** Gameplay rules use only `+`, `−`, `×`, `÷`, comparisons and `sqrt` on numbers. No trigonometry, `pow`, `exp`, randomness, or reliance on wall-clock time. The diagonal factor 1/√2 is a precomputed constant. These are the operations that give identical results on every CPU and in the browser (**Determinism contract**).
16. **Follow the official style guide:** `snake_case` file and folder names, `PascalCase` for `class_name` and node names, `snake_case` for functions and variables, `CONSTANT_CASE` for constants. Docs: [GDScript style guide](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_styleguide.html).

### Determinism contract

The game is deterministic in the way that matters, but not unconditionally. Positions are whole pixels, while velocities and sub-pixel remainders are floating-point numbers. Basic arithmetic gives the same results on Apple Silicon, Intel and WebAssembly; some math-library functions and compiler choices can differ in the last bit, which could occasionally flip a rounding by one pixel. Ground rule 15 removes the main risks. The tests then expect:

| Comparison | Requirement |
| --- | --- |
| The same build on the same machine, scripted input, run twice | Exactly identical traces |
| The same target at 30, 60 and 120 FPS, scripted input | Exactly identical traces (D-05) |
| Different targets (macOS, Windows, web), scripted input | The same events in the same order; event ticks within ±1 tick; positions within ±1 px. A difference is investigated and explained, not assumed to be harmless (D-04) |
| Live input | Not deterministic by nature (input arrives once per rendered frame); checked by hand (M3 gate, step 4) |

### Names used in this plan

Earlier sections use plain names. The code uses these:

| Plain name in this document | Name in the project | Kind |
| --- | --- | --- |
| Settings | `Tuning` (`autoload/tuning.gd`) with data in `config/tuning.tres` | Autoload (always-on service) |
| Recorder | `Trace` (`autoload/trace.gd`) | Autoload |
| Save record | `GameState` (`autoload/game_state.gd`) | Autoload |
| The game screen | `Main` (`world/main.tscn`) | Main scene, loaded once |
| World, the referee | `World` node (`world/world.gd`) | Node inside Main |
| Player | `Player` (`player/player.tscn`) | Scene instanced under `World` |
| Current room | One room scene, the only child of `RoomSlot` | Scene instanced at runtime |
| Screen overlays | `HUD`, `TitleOverlay`, `PauseMenu`, `CompletionOverlay`, `DebugOverlay` | CanvasLayer scenes in Main |

Docs: [Singletons (Autoload)](https://docs.godotengine.org/en/4.5/tutorials/scripting/singletons_autoload.html), [Autoloads versus regular nodes](https://docs.godotengine.org/en/4.5/tutorials/best_practices/autoloads_versus_internal_nodes.html).

### Starting decisions this plan depends on

| Decision | Value | Why |
| --- | --- | --- |
| Engine | Godot 4.5.1 stable, standard build (not .NET) | Owner choice; GDScript only |
| Renderer | Compatibility on every target | The web export supports only Compatibility (WebGL 2); one renderer keeps targets identical (AC D-04) |
| Simulation rate | 60 ticks per second | Celeste parity; one tick is 16.7 ms |
| Base resolution | 640 × 360, integer-scaled | Owner decision (2026-10-13). Scales exactly to 1280 × 720 (2×) and 1920 × 1080 (3×) (AC V-01). With 16 px tiles a screen shows 40 × 22.5 tiles, so a screen is not a whole number of tiles: rooms are, and the minimum room is 640 × 368 (40 × 23 tiles), with the camera clamped inside it. Celeste does the same |
| Tile size | 16 × 16 px | Owner decision (2026-10-13) |
| Collision | A custom whole-pixel mover against the room's tile grid; Godot's physics engine is not used | Owner decision (2026-10-16). Every solid is a 16 px tile or a one-way tile top. Whole-pixel positions make results agree across CPUs and the browser (within the **Determinism contract**) and make Celeste-style assists simple (M1) |
| Player body | A collision rectangle sized from the owner's sprite (the sprite will be close to 16 × 16), slightly narrower than the art; origin at the bottom center (the feet). Until the sprite exists, use 12 × 15 (`body_size_px`). The final size goes in the decision log | Owner decision on the sprite (2026-10-13). A body a little narrower than the art makes edges forgiving; a feet origin makes ground checks and spawning simple |

### How mockups are used

Mockups show **concepts**, not specifications. This applies to the two original Level 1 mockups (design document page 2) and to every room mockup the owner supplies later.

- **A mockup decides** which elements a room contains and how they relate to each other. For example: "a gap between two platforms, with a powered object above it that makes the crossing possible."
- **A mockup does not decide** positions, distances, sizes, scale or artwork, **unless the mockup explicitly labels them**: for example a written dimension, a coordinate, a tile count or an annotation such as "exactly 6 tiles". A labeled value is a requirement for that room; everything unlabeled is free. Mockups are not drawn with movement values in mind, and their art is subject to change.
- **Geometry comes from movement values,** within any labeled values. After tuning, place the room's parts so the intended route works and any route the room is meant to forbid fails. Prove it with that room's scenarios. If a labeled value cannot work with the tuned movement, raise it with the owner rather than quietly changing either.
- **Art comes from the owner** (ground rule 13). A mockup's art is never copied as a requirement.

**Owner interpretation of the acceptance criteria (2026-10-13).** Three AC passages read more literally than this:

- AC page 1 says later room mockups "define their geometry and content."
- L1-01 asks for the Level 1 elements "as depicted" and a comparison "with both references."
- V-01 compares screenshots with the original mockups.

In this project, those comparisons check that the same elements are present in the same relationships, and that the presentation follows the same pixel-art direction and flow-state behavior: the background dims and electrical objects are emphasized. They do not check positions, scale, spacing or specific artwork, except values the mockup explicitly labels. Every difference from a mockup is still disclosed with the comparison, as AC page 2 requires.

### Level design rules

These follow from the rules of the game and apply to every room. A room that breaks one needs an owner decision recorded in the decision log.

1. **Never require a default-only landing during a countdown.** Under the AC's zero-volt rules (OD-1), switching to default at 0 volts is certain death: the countdown continues, flow cannot be re-entered, and power sources only work in flow. The HUD warns when a switch to default would happen at 0 volts.
2. **Budget from the volts a room can be entered with, at most 3.** Dying refills volts to 3 (R-01), so a room's volt budget describes one attempt, not a whole run.
3. **Every last-volt moment needs a power source within reach.** The 3 s countdown at run speed covers about 540 px, less than one screen.
4. **Place power sources beside doors deliberately.** Leaving and re-entering a room rebuilds it, so a source near a door can recharge the player repeatedly. That is accepted (owner decision 2026-10-16); it just must never happen by accident.
5. **Networks never span rooms.** Only one room is active at a time, so a network's source and objects live in the same room.
6. **Chaining networks is allowed.** One network's objects may carry the player to another network's source.
7. **Decorative wiring must not look like a power source.** Once networks appear, players learn that wires lead from sources to objects.
8. **Pits are the only hazard until a level adds spikes.** Spikes are a future feature package (**How work is delivered**).

### Repository layout

The repository root holds documentation and tools. The Godot project lives in `game/`, so `res://` means `game/`. Keeping docs and tools outside the project stops Godot from importing them.

```text
tri10nware/
├── README.md                      setup, run, test, export, controls, first-launch steps
├── CREDITS.md                     the asset register: every asset's path, purpose, status, author, license
├── CLAUDE.md                      short index for each AI session (M0 prep)
├── .gitignore                     repository-level ignores (builds/, .DS_Store, local Claude files)
├── .claude/
│   ├── settings.json              output style, GODOT path, permissions (M0 prep)
│   ├── skills/step/SKILL.md       the /step session protocol (M0 prep)
│   └── agents/spec-reviewer.md    read-only milestone reviewer (M0 prep)
├── docs/
│   ├── TRI10NWARE.md              this document: the source of truth
│   ├── build_journal.md           status block and one explanation entry per step (M0 prep)
│   ├── .gdignore                  keeps Godot from importing docs (M0 prep)
│   ├── reference/
│   │   ├── TRI10NWARE_design.pdf               authoritative design (9 pages)
│   │   ├── TRI10NWARE_acceptance_criteria.pdf  authoritative acceptance criteria
│   │   └── mockups/
│   │       ├── level_1_default.png  Level 1 concept, default state
│   │       └── level_1_flow.png     Level 1 concept, flow state
│   ├── decision_log.md            tuning values and developer choices, with reasons and tests
│   ├── known_issues.md            open defects in the submitted build
│   ├── support_matrix.md          tested OS, hardware, browsers, engine version
│   └── evidence/
│       ├── ledger.csv             one row per criterion × target (AC page 9)
│       ├── traces/                trace and scenario-result files from each target
│       │   └── .gitkeep
│       └── media/                 videos and screenshots for manual criteria
│           └── .gitkeep
├── tools/
│   ├── export_all.sh              writes build info, exports all three targets, packages them
│   ├── run_tests.sh               runs unit tests and scenarios headless
│   └── serve_web.sh               serves the web build over local HTTP
├── builds/                        export output (git-ignored)
└── game/                          the Godot project (res://)
    ├── .gitignore                 generated by Godot
    ├── .gitattributes             generated by Godot
    ├── .editorconfig              generated by Godot
    ├── project.godot
    ├── export_presets.cfg
    ├── icon.svg
    ├── default_bus_layout.tres
    ├── autoload/
    │   ├── tuning.gd
    │   ├── trace.gd
    │   └── game_state.gd
    ├── config/
    │   ├── tuning_data.gd
    │   ├── tuning.tres
    │   └── build_info.cfg         generated at export time
    ├── core/
    │   ├── input_frame.gd
    │   ├── press_buffer.gd
    │   ├── jump_resolver.gd
    │   ├── dash_state.gd
    │   ├── geometry.gd
    │   ├── pixel_mover.gd
    │   ├── solid_grid.gd
    │   ├── flow_ledger.gd
    │   ├── encounter_tracker.gd
    │   └── overlap_policy.gd
    ├── input/
    │   ├── input_source.gd
    │   ├── live_input_source.gd
    │   └── scripted_input_source.gd
    ├── world/
    │   ├── main.tscn
    │   ├── main.gd
    │   ├── world.gd
    │   ├── camera_rig.gd
    │   ├── flow_presentation.gd
    │   ├── effects.gd
    │   └── effects_frames.tres
    ├── player/
    │   ├── player.tscn
    │   ├── player.gd
    │   ├── flow_controller.gd
    │   ├── player_visuals.gd
    │   └── player_frames.tres
    ├── rooms/
    │   ├── room.gd
    │   ├── room_entrance.gd
    │   ├── room_entry.gd
    │   ├── room_info.gd
    │   ├── room_catalog.gd
    │   ├── room_catalog.tres
    │   ├── world_map_preview.tscn
    │   ├── world_map_preview.gd
    │   ├── level_1/
    │   │   └── level_1.tscn
    │   └── <room_id>/
    │       └── <room_id>.tscn     one folder per owner-supplied room (M7)
    ├── objects/
    │   ├── charged_object/
    │   │   ├── charged_object.tscn
    │   │   └── charged_object.gd
    │   ├── network/
    │   │   └── network.gd
    │   ├── power_root/
    │   │   ├── power_root.tscn
    │   │   └── power_root.gd
    │   ├── wire/
    │   │   ├── wire.gd
    │   │   └── wire_current.gdshader
    │   ├── collectible/
    │   │   ├── collectible.tscn
    │   │   └── collectible.gd
    │   └── goal/
    │       └── goal_zone.gd
    ├── tiles/
    │   └── level_tiles.tres
    ├── ui/
    │   ├── theme.tres
    │   ├── hud.tscn
    │   ├── hud.gd
    │   ├── title_overlay.tscn
    │   ├── title_overlay.gd
    │   ├── pause_menu.tscn
    │   ├── pause_menu.gd
    │   ├── completion_overlay.tscn
    │   └── completion_overlay.gd
    ├── audio/
    │   ├── sfx.gd
    │   └── sfx/                   13 sound files (10 in M3, 1 in M5, 2 in M6)
    ├── debug/
    │   ├── debug_overlay.tscn
    │   ├── debug_overlay.gd
    │   └── debug_world_draw.gd
    ├── verification/
    │   ├── scenario_runner.gd
    │   ├── bypass_search.gd
    │   ├── gym/
    │   │   ├── gym.tscn
    │   │   └── gym_annex.tscn
    │   └── scenarios/             36 fixed scenario files plus one route file per room
    ├── tests/
    │   ├── test_runner.tscn
    │   ├── test_runner.gd
    │   ├── test_case.gd
    │   └── unit/                  13 unit-test files
    └── art/                       17 slots across the folders below, each listed in its milestone; the owner adds more freely
        ├── player/                player_sheet.png, switch_burst.png
        ├── tiles/                 tiles.png
        ├── objects/               charged_object.png, charged_glow.png, power_root.png,
        │                          power_root_glow.png, collectible.png
        ├── backdrop/              level_1_backdrop.png
        ├── effects/               effects.png
        ├── props/                 level_1_props.png, wire_strip.png
        ├── ui/                    volt_pip.png, dash_pip.png, state_icons.png, countdown_ring.png
        ├── fonts/                 pixel_font.ttf
        └── legacy/                the prototype's art (player_v0.png, world_tileset.png, health.png)
```

Docs: [Project organization](https://docs.godotengine.org/en/4.5/tutorials/best_practices/project_organization.html), [Scene organization](https://docs.godotengine.org/en/4.5/tutorials/best_practices/scene_organization.html).

### How work is delivered: level gates

Work is delivered level by level, the way AC page 1 frames it: a Level 1 gate, then "later core rooms" whose systems' criteria apply "when each system enters scope."

1. **Foundation (M0–M2):** the clock, input, movement, flow, volts, charged objects, the verification room and the tests. It has no gate of its own; it is the start of Level 1's work.
2. **Level 1 gate (M3).**
3. **One gate per later level (M7).** When the owner supplies a level's mockup, it is registered in the Levels table below and given its own section. The level claims each feature package it needs, its features are discussed and written into this document, and its gate passes when those criteria and its rooms' routes pass on all three targets.
4. **Final gate (M8, M9):** once the owner declares the level list complete.

**Feature packages (M4–M6)** are fully specified now so their design is not lost, but each is built only when the first level that needs it is registered. Their order follows the levels, not their numbers. A package's criteria become applicable at that level's gate.

| Package | Builds | Criteria it brings into scope | Built for |
| --- | --- | --- | --- |
| M4 Platforms | Default-only and flow-only platforms, the overlap policy | P-01 to P-04 | The first level that uses state-dependent platforms |
| M5 Networks | Power sources, networks, recharging | N-01 to N-04, and S-04's recharge cases | The first level that uses a power network |
| M6 Rooms and progress | Crossings between rooms, collectibles, session progress | G-01, G-02 | The first level with more than one room, or with a collectible |
| Hazards (spikes) | Specified when the first level with spikes is registered. Whether spikes kill or cost a volt is decided together with OD-3 | Defined with the package | The first level with spikes |

**Levels** (one row per level, added when its mockup arrives):

| Level | Rooms | Mockup | What it introduces | Packages it claims | Gate | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `level_1` | Design page 2 (concept only) | Flow, volts and countdown, the charged jump | None | Level 1 gate (M3) | Planned |

### Where each file is created

Every file appears once, in the milestone or package that creates it. Later milestones may *extend* a file; the milestone says when. M4–M6 are built when a level claims them.

| Milestone | New files |
| --- | --- |
| M0 prep (workflow, already in the repository) | 6 |
| M0 Foundations | 47 |
| M1 Movement kit | 31 |
| M2 Flow and charge | 32 |
| M3 Level 1 room | 36 |
| M4 Platforms | 6 |
| M5 Networks | 10 |
| M6 Rooms and progress | 13 |
| M7 Adding a level | 2 per room, plus any art and mockup files the level needs |
| M8 Reset sweep | 0 (evidence only) |
| M9 Evidence package | 0 (evidence only) |

---

### M0 — Foundations

**Goal:** a project that opens, ticks, records, accepts input, runs tests and exports to all three targets, with nothing playable yet. Exporting this early proves the delivery path before any gameplay depends on it.

#### M0 prep: workflow files (already in the repository)

These were added on 2026-10-17, before M0 starts, so each fresh AI session can find this document and follow the session rules. They are listed here like every other file.

| File | What it is | Why it exists |
| --- | --- | --- |
| `CLAUDE.md` | A short index (under 100 lines): where the source of truth is, which sections to read in what order, commands, Godot editor caveats, what never to do | Loaded automatically by every Claude Code session; keeps each session oriented without loading this whole document |
| `.claude/settings.json` | Project settings: Explanatory output style, the `GODOT` path, and permissions (Godot and git commands allowed; edits to this document, the reference folder and owner art, and every push, always ask) | Makes the workflow and its guardrails the same in every session |
| `.claude/skills/step/SKILL.md` | The `/step <milestone.step>` skill: orient, plan, implement one step, verify, explain, log, commit | Encodes "How an AI developer works" so every session follows it the same way |
| `.claude/agents/spec-reviewer.md` | A read-only reviewer subagent, used at the end of each milestone | Catches unlisted files, rule violations and spec mismatches that a single session can miss |
| `docs/build_journal.md` | A Status block plus one explanation entry per step | Long-term memory between sessions, and the owner's record of what was built and why |
| `docs/.gdignore` | An empty file | Stops Godot from importing the documents and mockup images while the prototype project still sits at the repository root; harmless once M0 step 1 moves the project into `game/` |
| (already listed) `docs/TRI10NWARE.md` and `docs/reference/` | This document and its sources | Listed in M0 steps 1 and 11; placed early so sessions can read them |

The root `.gitignore` (M0 step 1) also ignores `CLAUDE.local.md` and `.claude/settings.local.json`, which hold personal, uncommitted settings.

#### M0 step 0: prerequisites

Before M0 can finish, these must exist. The last three come from the owner.

- **Godot 4.5.1** (standard build) at `/Applications/Godot 4.5.1 .app/` on the build Mac. The path contains spaces, so every script quotes it.
- **The Godot 4.5.1 export templates,** installed through the editor's Export Template Manager.
- **The macOS bundle identifier** for the export preset.
- **An itch.io project page** for the game (step 10).
- **Access to a real Windows PC** for Windows testing. The tools run on the Mac; Windows builds are copied over and tested there.

#### M0 step 1: migrate the existing repository

The game jam repository already exists: **https://github.com/Pat-Rosander/TRI10NWARE** (branch `main`). It holds a simple prototype platformer whose code will be replaced (owner decision 2026-10-17). As found on 2026-10-17:

| Existing path | What it is | What happens to it |
| --- | --- | --- |
| `project.godot` (repository root) | The prototype's settings: name misspelled `TRI10WARE`, Forward+ renderer, `canvas_items` stretch, fullscreen window, its own input map | Moves to `game/project.godot`; every setting is then set as step 2 says, including the name `TRI10NWARE`, the Compatibility renderer, the input map and the main scene |
| `.editorconfig`, `.gitattributes`, `.gitignore`, `icon.svg`, `icon.svg.import` | Godot-generated files | Move to `game/`. `game/.gitignore` keeps `.godot/` and `/android/` and adds `config/build_info.cfg` |
| `assets/player_v0.png`, `assets/world_tileset.png`, `assets/health.png` (each with its `.import`) | The owner's prototype art | Move to `game/art/legacy/` and are registered in `CREDITS.md` as `owner draft`. The owner decides whether any becomes a slot (for example the tile set) |
| `player/player.gd`, `player/player.gd.uid`, `player/player.tscn`, `levels/level_1.tscn` | The prototype's code and scenes | Deleted. The plan's own files replace them; none are reused |
| `README.md` | The prototype's setup instructions | Rewritten in step 11; its Godot 4.5.1 download link and import steps are kept and updated for the `game/` folder |

Steps:

1. Tag the current `main` as `prototype-v0` and push the tag, so the prototype stays recoverable.
2. Create the `tools/` and `builds/` folders at the repository root (`docs/` exists since M0 prep).
3. Move the Godot project into `game/`, as in the table above. Move files with `git mv` so their history is kept, then run the import step (step 9) so Godot rebuilds its cache and the `.import` files point at the new paths.
4. Delete the prototype code and scenes, and add `game/art/legacy/` to `CREDITS.md`.
5. Check that this document and `docs/reference/` are in place (done in M0 prep).
6. Commit as `M0 step 1: migrate prototype repository`.

| File | What it is | Why it exists |
| --- | --- | --- |
| `.gitignore` | Ignores `builds/`, `.DS_Store`, `.vscode/`, `CLAUDE.local.md` and `.claude/settings.local.json` | Export output is regenerated; macOS folder files would break the clean-tree check; personal editor and Claude settings stay local |
| `game/.gitignore` | The existing Godot `.gitignore`, moved; add `config/build_info.cfg` | Keeps the engine cache and the generated build file out of version control |
| `game/.gitattributes` | Generated by Godot | Consistent line endings across macOS and Windows |
| `game/.editorconfig` | Generated by Godot | Editor text settings |
| `game/project.godot` | All project settings (step 2) | The engine reads every setting below from here |
| `game/icon.svg` | The existing icon, moved | Required by the project; replaceable later |
| `game/art/legacy/` | The prototype's three art files, moved | Owner art kept until the owner decides how to use it |
| `docs/TRI10NWARE.md` | This document | The single source of truth |

#### M0 step 2: project settings

Set these in **Project → Project Settings** (enable **Advanced Settings** to see all of them). Each one is written to `project.godot`.

| Setting | Value | Why |
| --- | --- | --- |
| `application/config/name` | `TRI10NWARE` | Window title and export name |
| `application/config/version` | `0.1.0` | Shown with the commit in the build ID |
| `application/run/main_scene` | `res://world/main.tscn` | Main is the only scene ever run in play |
| `display/window/size/viewport_width` / `viewport_height` | `640` / `360` | The pixel canvas |
| `display/window/size/window_width_override` / `window_height_override` | `1280` / `720` | A 2× window by default. On desktop, `main.gd` then resizes it at launch to the largest whole multiple of 640 × 360 that fits the screen's usable area, so it fits a 1366 × 768 laptop |
| `display/window/stretch/mode` | `viewport` | Renders at 640 × 360, then scales up: crisp pixels |
| `display/window/stretch/aspect` | `keep` | Letterbox instead of stretching |
| `display/window/stretch/scale_mode` | `integer` | Whole-number scaling only, so pixels never distort (AC V-01) |
| `rendering/renderer/rendering_method` (and `.mobile`, `.web`) | `gl_compatibility` | One renderer everywhere; required for web |
| `rendering/textures/canvas_textures/default_texture_filter` | `Nearest` | No blurred sprites |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | `true` | Crisp pixel positions; verify against interpolation in M1 |
| `physics/common/physics_ticks_per_second` | `60` | The simulation clock |
| `physics/common/max_physics_steps_per_frame` | `8` | At 30 FPS the engine still runs 2 ticks per frame, so game time never slows |
| `physics/common/physics_interpolation` | `true` | Smooth motion on displays above 60 Hz. It interpolates every node moved during the physics tick, including the player and the camera; verify in M1 |
| `physics/common/physics_jitter_fix` | `0.0` | Recommended with physics interpolation; keeps tick timing plain |
| `input_devices/compatibility/legacy_just_pressed_behavior` | `false` (default) | A press and release within one frame is not lost |
| `debug/gdscript/warnings/untyped_declaration` | `Error` | Enforces ground rule 2 |

Do **not** enable `input_devices/buffering/agile_event_flushing`: the 4.5 docs state it is implemented only on Android, so it cannot help desktop or web.

Docs: [Multiple resolutions](https://docs.godotengine.org/en/4.5/tutorials/rendering/multiple_resolutions.html), [Physics interpolation](https://docs.godotengine.org/en/4.5/tutorials/physics/interpolation/index.html), [ProjectSettings](https://docs.godotengine.org/en/4.5/classes/class_projectsettings.html), [Jitter, stutter and input lag](https://docs.godotengine.org/en/4.5/tutorials/rendering/jitter_stutter.html).

#### M0 step 3: input map

Create these actions in **Project Settings → Input Map**. Bind every key as a **physical** key, so the same positions work on AZERTY and QWERTZ keyboards. There are two keyboard sets: arrows with Z/X/C for the left hand, or WASD with J/K/L for the right hand. Shift and the F-keys are avoided: five Shift presses open Sticky Keys on Windows, F-keys control the system on Macs, and browsers use F1 and F3.

| Action | Keyboard (physical) | Gamepad | Purpose |
| --- | --- | --- | --- |
| `move_left` | Left, A | D-pad left, left stick | Movement and dash aim |
| `move_right` | Right, D | D-pad right, left stick | Movement and dash aim |
| `move_up` | Up, W | D-pad up, left stick | Dash aim |
| `move_down` | Down, S | D-pad down, left stick | Dash aim |
| `jump` | Space, C, J | Bottom face button | Every jump, including charged |
| `dash` | X, K | Left face button | Dash |
| `switch` | Z, L | Right shoulder | Default ⇄ flow |
| `pause` | Escape, P | Start | Pause menu. In a browser, Escape first leaves fullscreen; that is browser behavior |
| `fullscreen` | Alt+Enter | None | Toggle fullscreen on desktop (D-07). On itch.io, the page's fullscreen button does this |
| `debug_toggle` | Backtick (`` ` ``) | None | Show or hide the debug overlay; only with debug tools on (step 7) |
| `debug_freeze` | 1, while the overlay is open | None | Freeze the simulation for frame-stepping |
| `debug_step` | 2, while the overlay is open | None | Advance one tick while frozen |
| `debug_slow` | 3, while the overlay is open | None | Cycle slow motion: 1×, ½×, ¼× |

The left stick has no per-axis deadzone in the input map. The input source applies a radial deadzone (`stick_deadzone`) and snaps the stick's angle to the nearest 45°, so all 8 directions get equal 45° sectors.

Docs: [Input examples](https://docs.godotengine.org/en/4.5/tutorials/inputs/input_examples.html), [Controllers, gamepads and joysticks](https://docs.godotengine.org/en/4.5/tutorials/inputs/controllers_gamepads_joysticks.html).

#### M0 step 4: Tuning, the settings service

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/config/tuning_data.gd` | `class_name TuningData extends Resource`, one `@export` field per value below, grouped with `@export_group` | Gives every tunable number a typed, named, editor-visible home (ground rule 9) |
| `game/config/tuning.tres` | The one `TuningData` instance, holding the starting values below | The file a designer edits; recorded in every trace |
| `game/autoload/tuning.gd` | Autoload named `Tuning`, first in the autoload list. Loads `tuning.tres`, exposes it as `data`, and precomputes every time value as whole ticks (`roundi(seconds × 60)`) | Converts seconds to ticks in one place (ground rule 4) |

Field names carry their unit as a suffix: `_px`, `_px_s` (pixels per second), `_px_s2` (pixels per second squared), `_s` (seconds). Values marked **AC** are fixed by the acceptance criteria; changing one is a disclosed deviation. Values marked **Celeste** are starting points from Celeste's movement code, **doubled**: Celeste uses 8 px tiles and this game uses 16 px tiles, so doubling every distance and speed keeps the same feel measured in tiles. Times are not doubled. Every value is tuned in playtesting and logged in `docs/decision_log.md`.

| Field | Start | Source | Used for |
| --- | --- | --- | --- |
| `body_size_px` | 12 × 15 | Owner (from the sprite) | The player's collision rectangle, feet at the origin |
| `run_max_speed_px_s` | 180 | Celeste | Top running speed |
| `run_accel_px_s2` | 2000 | Celeste | Speeding up and turning |
| `run_reduce_px_s2` | 800 | Celeste | Slowing down when above top speed |
| `air_control_mult` | 0.65 | Celeste | Horizontal control in the air |
| `gravity_px_s2` | 1800 | Celeste | Falling |
| `max_fall_speed_px_s` | 320 | Celeste | Terminal fall speed |
| `apex_gravity_mult` | 0.5 | Celeste | Softer apex while holding jump on an ordinary jump |
| `apex_threshold_px_s` | 80 | Celeste | Vertical speed below which the soft apex applies |
| `jump_speed_px_s` | 210 | Celeste | Ordinary jump launch |
| `jump_h_boost_px_s` | 80 | Celeste | Extra horizontal speed when jumping while moving |
| `jump_sustain_s` | 0.2 | Celeste | How long holding jump keeps the launch speed |
| `coyote_s` | 0.1 | AC M-05 | Late jump after leaving a ledge |
| `jump_buffer_s` | 0.1 | AC M-06 | Early jump before landing or region entry |
| `wall_check_px` | 6 | Celeste | How close a wall must be for a wall jump |
| `wall_jump_h_speed_px_s` | 260 | Celeste | Horizontal kick of a wall jump |
| `wall_jump_lock_s` | 0.16 | Celeste | Time steering back toward the wall is overridden (see **Control locks**) |
| `corner_correction_px` | 8 | Celeste | How far a rising jump that clips a ceiling corner is nudged sideways |
| `dash_corner_correction_px` | 8 | Celeste | How far a horizontal dash that clips a ledge lip is nudged up |
| `oneway_assist_px` | 8 | Ours | How far below a one-way platform's top a rising player near the apex is lifted onto it |
| `post_dash_snap_px` | 6 | Ours | How far down a dash that ends just above the floor is snapped onto it |
| `dash_speed_px_s` | 480 | Celeste | Dash speed in any direction |
| `dash_end_speed_px_s` | 320 | Celeste | Speed when a dash ends or is cut short |
| `dash_end_up_mult` | 0.75 | Celeste | Extra slowdown when a dash ends moving upward |
| `dash_s` | 0.15 | Celeste | Dash duration |
| `dash_cooldown_s` | 0.2 | Celeste | Minimum time between dash starts |
| `dash_buffer_s` | 0.1 | Ours | Early dash press |
| `charged_refill_clears_cooldown` | true | Ours | A charged jump's refill also clears the dash cooldown, so a waiting dash press fires on the next tick: the charged dash (C-08) |
| `charged_launch_speed_px_s` | 440 | Ours | Charged jump launch. It must out-rise an ordinary jump: 440 px/s rises about 54 px, matching a full ordinary jump at the starting values (design page 1: charged objects "extend their movement"). Then tuned so Level 1 needs it |
| `charged_region_radius_px` | 64 | Ours | Default region radius; each object may override. Match it to the owner's ring art |
| `charged_exit_margin_px` | 1 | Ours | Exit radius = entry radius + this |
| `root_contact_margin_px` | 4 | Ours | How far a power source's contact area extends past its art |
| `overlap_snap_px` | 6 | Ours | Overlap policy snap distance (P-04) |
| `max_volts` | 3 | AC | Volt capacity |
| `countdown_s` | 3.0 | AC S-03 | Zero-volt countdown |
| `countdown_in_default` | `continue` | AC S-03; open decision OD-1 | What the countdown does after leaving flow: `continue`, `pause` or `stop` |
| `allow_flow_entry_at_zero` | false | AC S-03; open decision OD-1 | Whether flow can be entered at 0 volts |
| `death_freeze_s` | 0.35 | Ours | Death effect before rebuild |
| `respawn_s` | 0.25 | Ours | Respawn effect before control returns (total under 1 s, AC R-02) |
| `room_transition_s` | 0.3 | Ours | Camera slide between rooms |
| `fall_margin_px` | 32 | Ours | Failure line distance below a room's bottom edge |
| `flow_backdrop_color` | `Color(0.55, 0.5, 0.7)` | Owner (art) | Multiplied onto the backdrop in flow. A placeholder; the owner sets it to suit the art |
| `flow_fade_s` | 0.15 | Ours | Backdrop fade time |
| `inactive_platform_alpha` | 0.35 | Ours | How faint the currently non-solid platform family is drawn |
| `stick_deadzone` | 0.2 | Ours | Radial stick deadzone before 8-way snapping |
| `trace_memory_limit` | 100000 | Ours | Events kept in memory during normal play |

Docs: [Resources](https://docs.godotengine.org/en/4.5/tutorials/scripting/resources.html), [GDScript exported properties](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_exports.html), [Singletons (Autoload)](https://docs.godotengine.org/en/4.5/tutorials/scripting/singletons_autoload.html).

#### M0 step 5: Trace, the recorder

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/autoload/trace.gd` | Autoload named `Trace`, second in the autoload list | One tick-stamped log of every rule event: the evidence the AC demands, and the feed for sound and visual feedback |

How it works:

- `World` sets `Trace.tick` at the start of every tick. `Trace.record(event, data)` (not `log`, which is a built-in GDScript function) appends `{tick, room, event, data}` to an in-memory list and emits the signal `event_logged`. Sound, HUD flashes and visual effects listen to that signal; **no rule ever reads the trace**.
- `begin_session()` stores a header: build ID, target platform, tick rate and every tuning value. The header is kept apart from the event list, so trimming never removes it.
- `save_to_disk()` writes the header and the list as JSON Lines to `user://traces/<YYYYMMDD-HHMMSS>_<build>.jsonl`. File names never contain colons, which Windows forbids. On the web build, the debug overlay offers the same file as a download through `JavaScriptBridge.download_buffer()`.
- Normal play keeps the newest `trace_memory_limit` events. Scenario runs keep everything.

The event catalog is fixed. New events are added here first.

| Event | Data fields | Logged when |
| --- | --- | --- |
| `session_start` | build, target, tick_rate, tuning | Game launch or scenario run start |
| `press` | action | A fresh press becomes a token |
| `press_spent` | action, created_tick, spent_on | A token is used |
| `press_expired` | action, created_tick | A token runs out unused or is replaced |
| `switch` | from, to, volts_before, volts_after | State changes |
| `switch_refused` | reason | Flow entry blocked at zero volts |
| `volts` | before, after, cause | The volt count changes (a recharge at 3 volts logs none) |
| `countdown_start` | ticks | Last volt spent |
| `countdown_cancel` | cause | Recharge stops it |
| `countdown_expire` | none | It reaches zero |
| `jump` | kind (ground, charged, coyote, wall), vx, vy, object | Any jump, with velocity after the jump |
| `dash_start` | dir_x, dir_y, vx, vy | A dash begins |
| `dash_end` | vx, vy, interrupted | A dash ends or is cut short |
| `dash_refill` | cause (ground, charged) | Dash goes from 0 to 1 |
| `land` | vx, vy_before | The player becomes grounded |
| `encounter` | object, from, to | A charged object's encounter state changes |
| `platform_pending` | family, tiles | Overlapped tiles of a family wait to turn solid (overlap policy) |
| `platform_solid` | family, tiles | Those tiles become solid for the player |
| `overlap_snap` | family, dy | The player is snapped onto a platform top |
| `network_activated` | network, members | A power source is activated |
| `assist` | kind (corner, dash_corner, oneway, dash_snap), dx, dy | A movement assist moves the player |
| `death` | cause (countdown, fell, restart) | Death latches |
| `respawn` | room, entrance | The room is rebuilt and the player placed |
| `control_return` | none | Input is accepted again after a respawn |
| `room_enter` | room, entrance | A room is built for play |
| `transition_start` | from_room, to_room, edge | The player crosses an opening |
| `transition_end` | room, checkpoint | The crossing finishes and the rules resume |
| `room_complete` | room | The goal is reached |
| `goal_banner` | level | A level's goal is reached and play continues (from Level 2 on) |
| `collectible` | id, change (touched, committed, lost) | Collectible state changes |
| `snapshot` | position, velocity, state, volts, dash, countdown, grounded | Scenario runner requests a state capture |

Docs: [FileAccess](https://docs.godotengine.org/en/4.5/classes/class_fileaccess.html), [JSON](https://docs.godotengine.org/en/4.5/classes/class_json.html), [JavaScriptBridge](https://docs.godotengine.org/en/4.5/classes/class_javascriptbridge.html), [File paths in Godot projects](https://docs.godotengine.org/en/4.5/tutorials/io/data_paths.html).

#### M0 step 6: input stage

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/core/input_frame.gd` | `class_name InputFrame extends RefCounted`: the tick number, which gameplay actions are held, which were freshly pressed this tick, and an 8-way direction as a `Vector2i` | The only form in which input reaches gameplay (ground rule 5) |
| `game/core/press_buffer.gd` | `class_name PressBuffer extends RefCounted`: holds at most one unspent token for one action | Implements "one press, one action" and the buffer windows (M-06, M-07, C-07) |
| `game/input/input_source.gd` | `class_name InputSource extends Node`: the shared interface, `read(tick) -> InputFrame` and `mark_all_stale()` | Lets live and scripted input be swapped without the player noticing |
| `game/input/live_input_source.gd` | Reads the keyboard and gamepad through `Input` | The real player's input |
| `game/input/scripted_input_source.gd` | Plays back a list of `{tick, action, press or release}` entries | Exact, repeatable input for scenarios |

Rules the input stage must follow:

- **Fresh presses.** The live source receives gameplay press and release events in `_input()` as they arrive, ignoring key-repeat echoes, and queues them. `read()` drains the queue on the next tick that runs, so a press is never lost, even during slow motion or frame-stepping. Godot delivers input once per rendered frame, so at 30 FPS a press is seen on the first tick of the next frame, up to 2 ticks late. Scripted input has no such delay.
- **Stale buttons.** `mark_all_stale()` records which of `jump`, `dash` and `switch` are currently held. A stale action reports neither held nor pressed until it is released. Movement directions are never marked stale, so a direction held through a respawn or unpause keeps moving the player. `World` calls this on respawn, on unpause and when the title screen is dismissed, so the key that dismissed a screen, or a jump held through a death, never triggers an action by accident (R-01, R-04).
- **Direction.** Each axis is −1, 0 or 1. When both opposing keys are held, the one pressed most recently wins, so rolling between arrow keys never stalls the player. The stick uses the radial deadzone and 45° snapping from step 3. Only the direction matters, so diagonals cannot be faster (M-03).
- **Token windows.** A token created on tick *t* can be spent by a decision on ticks *t* through *t + W*, where *W* is the window in ticks (6 for 100 ms). "Decision tick" is defined in M1. A new press of the same action replaces an unspent token; the old one is logged as `press_expired`.

Docs: [Input](https://docs.godotengine.org/en/4.5/classes/class_input.html), [Using InputEvent](https://docs.godotengine.org/en/4.5/tutorials/inputs/inputevent.html).

#### M0 step 7: Main and World skeleton

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/world/main.tscn` | The main scene. In M0 it holds `Main` → `World` → `RoomSlot` and `Camera`, plus `DebugOverlay` | The persistent game screen (never replaced) |
| `game/world/main.gd` | Script on `Main` (a `Node`). Reads command-line user arguments, enables debug tools, sizes the window at launch, toggles fullscreen, handles pause and focus notifications (from M3), and wires overlays. When debug tools are enabled, and not on the web, it saves the trace with `Trace.save_to_disk()` on window close and before any quit it triggers itself; normal player runs never write trace files | Keeps app-level concerns out of the simulation |
| `game/world/world.gd` | Script on `World` (a `Node2D`). The only `_physics_process` in the project | The referee: runs the tick and (from M1) loads rooms |
| `game/world/camera_rig.gd` | Script on `Camera` (a `Camera2D`). Its target is set during the tick (step 11) and it moves on the physics step, so physics interpolation smooths it together with the player. Clamped to the current room's bounds; from M6, slides between rooms | The camera must not follow the player past room edges, must show crossings, and must not jitter against the player |

`World._physics_process` in M0:

1. If the simulation is not running, or the debug freeze is on and no step was requested, return. **Ticks count only while the rules run:** in the Playing, Dying and Respawning states. The title screen, the completion screen, room crossings (Transition) and paused time do not advance the tick, so press windows and every other gameplay timer freeze with them.
2. If slow motion is set to ½× or ¼×, skip ticks so that only every 2nd or 4th physics step runs the simulation. Never use `Engine.time_scale` (ground rule 4).
3. Increase `tick` by one and set `Trace.tick`.
4. Call the 11 step methods in order: `_step_input`, `_step_switch`, `_step_dash`, `_step_jump`, `_step_integrate`, `_step_move`, `_step_sense`, `_step_contacts`, `_step_timers`, `_step_outcomes`, `_step_publish`. In M0 only `_step_input` does anything; the rest are filled in by later milestones.

`main.gd` reads `OS.get_cmdline_user_args()` (arguments after `--`) for these flags, used from M1:

| Flag | Effect |
| --- | --- |
| `--run-scenarios` or `--run-scenarios=<prefix>` | Start the scenario runner, optionally only files whose names start with the prefix |
| `--quit-when-done` | Quit when the scenarios finish; exit code 0 if all pass, 1 otherwise |
| `--render-fps=<n>` | Cap rendering at *n* FPS with vsync off, for frame-rate independence runs (D-05) |
| `--debug-tools` | Enable the debug overlay and menu. Scenario flags enable them too. On the web build, the URL parameter `?debug=1` does the same when the game is served locally; itch.io's player never passes it on |

Docs: [Idle and physics processing](https://docs.godotengine.org/en/4.5/tutorials/scripting/idle_and_physics_processing.html), [Camera2D](https://docs.godotengine.org/en/4.5/classes/class_camera2d.html), [OS](https://docs.godotengine.org/en/4.5/classes/class_os.html), [Command line tutorial](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html).

#### M0 step 8: debug overlay

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/debug/debug_overlay.tscn` | A `CanvasLayer` with a text readout and (from M1) a debug menu. Present only when debug tools are enabled (step 7), so players never see a level select | Exposes exact values for testing and evidence; the README explains how reviewers enable it (AC page 9 requires debug access instructions) |
| `game/debug/debug_overlay.gd` | Reads `World`, the player and `Tuning` each frame and fills the readout; handles the debug keys (backtick, then 1–3) | Shows tick, FPS, physics rate, build ID; later state, volts, countdown ticks, dash, coyote and buffer counters, velocity |

Its process mode is **Always** so it keeps working while the game is paused. Docs: [Canvas layers](https://docs.godotengine.org/en/4.5/tutorials/2d/canvas_layers.html), [Pausing games](https://docs.godotengine.org/en/4.5/tutorials/scripting/pausing_games.html).

#### M0 step 9: unit-test runner

The project uses a small built-in test runner instead of a test add-on. Ground rule 1 rules out add-ons, and the same in-project approach runs inside exported builds for the scenario runner.

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/tests/test_case.gd` | `class_name TestCase extends RefCounted` with `assert_eq`, `assert_true`, `assert_false` and `assert_near`, each recording failures with a message | The base every unit test extends |
| `game/tests/test_runner.tscn` | A scene with one `Node` running `test_runner.gd` | Lets the runner be launched by path from the command line |
| `game/tests/test_runner.gd` | Finds every `res://tests/unit/test_*.gd`, runs each method whose name starts with `test_`, prints results, and quits with exit code 0 or 1 | One command answers "do the rules still hold?" |
| `game/tests/unit/test_tuning.gd` | Seconds-to-ticks conversion (0.1 s → 6, 3.0 s → 180, 0.15 s → 9), every derived tick value, and **every field of `tuning.tres` against its start value in the M0 step 4 table**, so a field missing from the `.tres` (which silently loads as 0) fails the test | Every timer and every movement value depends on it |
| `game/tests/unit/test_press_buffer.gd` | Token lifetime, window edges, replacement, single spend | M-06, M-07 and C-07 depend on it |
| `game/tests/unit/test_input_source.gd` | The shared input rules, through `ScriptedInputSource` and synthetic events fed to `LiveInputSource`: one press per press, no repeat while held, stale buttons until release, directions never stale, most-recent-wins with fallback, digital input beating the stick, focus loss releasing everything, and stick snapping (radial deadzone, equal 45° sectors) | M-03, M-07, R-01 and R-04 depend on it (added by owner decision 2026-10-17, after steps 2–6 verified this with scripts that were not kept) |
| `game/tests/unit/test_trace.gd` | The session header and its fields, tick and room stamping, the catalog check, the ring buffer (oldest dropped, header kept, keep-everything mode), file names without colons and with unique suffixes, and the JSON Lines format (key order, vectors as arrays) | The trace is the evidence for D-04, D-05 and every scenario (added by owner decision 2026-10-17) |

Command: `"$GODOT" --headless --path game --import`, then `"$GODOT" --headless --path game res://tests/test_runner.tscn`. The import step is needed on a fresh clone, where the `.godot/` cache does not exist yet. Unit tests run in the editor build only; they are excluded from exports (step 10).

#### M0 step 10: delivery path

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/export_presets.cfg` | Three presets, settings below | Reproducible exports from the command line (D-01, D-08) |
| `game/config/build_info.cfg` | Generated by `export_all.sh`: version, commit hash, export date. Git-ignored. When missing (editor runs), the game shows "dev build" | Every build and trace names its exact source revision (D-01) |
| `tools/export_all.sh` | Runs the import step; checks the working tree is clean; writes `build_info.cfg`; runs the three exports; checks the tree is still clean (exports may rewrite `.import` and `.uid` files, which must then be committed first); and builds the itch.io upload files (below) | All three targets come from one commit, every time |
| `tools/run_tests.sh` | Runs the import step, the unit tests, then all scenarios headless with `--fixed-fps 60` | One command for the full deterministic check |
| `tools/serve_web.sh` | Serves `builds/web/` over local HTTP with Python 3's built-in server, mapping `.wasm` to `application/wasm` explicitly | The web build must be validated over HTTP, never `file://` (D-03), and browsers refuse WebAssembly served with the wrong type |

All scripts read the Godot executable path from the `GODOT` environment variable (on the build Mac, `/Applications/Godot 4.5.1 .app/Contents/MacOS/Godot`) and always quote it. The tools are shell scripts for the Mac; they are not run on Windows.

| Preset | Key options | Output |
| --- | --- | --- |
| `macOS` | `binary_format/architecture` universal; `codesign/codesign` Built-in (ad-hoc only); notarization disabled; bundle identifier supplied by the owner | `builds/macos/TRI10NWARE.zip` |
| `Windows Desktop` | `binary_format/architecture` x86_64; `binary_format/embed_pck` on | `builds/windows/TRI10NWARE.exe`, zipped by the script |
| `Web` | `variant/thread_support` off; `html/focus_canvas_on_start` on; default HTML shell | `builds/web/index.html` and its files |

**itch.io upload files.** The game is submitted through its itch.io page. `export_all.sh` writes three files to `builds/itch/`:

| File | Contents | On the itch.io page |
| --- | --- | --- |
| `TRI10NWARE_web.zip` | The web export, with `index.html` at the top level of the zip | Upload with "This file will be played in the browser" checked |
| `TRI10NWARE_macos.zip` | The macOS app, `README.md` and `CREDITS.md` | Downloadable file, marked macOS |
| `TRI10NWARE_windows.zip` | The Windows executable, `README.md` and `CREDITS.md` | Downloadable file, marked Windows |

On the itch.io project page (set by the owner): kind of project **HTML**; embed size **1280 × 720**; **fullscreen button** on; **SharedArrayBuffer support** off (the web export has no threads, so it is not needed). Uploads are done through the page's upload form; the README lists the exact steps.

For every preset, set **Resources → Filters to export non-resource files** to `config/build_info.cfg, verification/scenarios/*.json`, and **Filters to exclude** to `tests/*, rooms/world_map_preview.*`.

Docs: [Exporting projects](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_projects.html), [Exporting for the Web](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html), [Exporting for macOS](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_macos.html), [Running Godot apps on macOS](https://docs.godotengine.org/en/4.5/tutorials/export/running_on_macos.html), [Exporting for Windows](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html), [ConfigFile](https://docs.godotengine.org/en/4.5/classes/class_configfile.html).

#### M0 step 11: project documents

| File | What it is | Why it exists |
| --- | --- | --- |
| `README.md` | Godot version and prerequisites; how to open, run, test and export; controls; how to enable debug tools; first-launch steps (macOS: System Settings → Privacy & Security → Open Anyway, since macOS 15 removed the Control-click bypass; Windows: SmartScreen → More info → Run anyway); how to serve the web build locally; the itch.io upload steps | A recipient can run every build with no help (D-03, D-08) |
| `CREDITS.md` | The **asset register**: one row per art, audio or font file, with columns `path`, `purpose` (the slot it fills, or what it is for), `status` (`placeholder`, `owner draft` or `final`), `author`, `license`, `source link`, `date added`. The owner adds a row whenever they add a file; the developer adds rows for placeholders | Asset attribution (D-08), and one place to see which art is still a placeholder before a gate |
| `docs/decision_log.md` | Every tuning value and developer-owned choice, with reason and the scenario or test that shows it | The "decision and tuning log" (AC page 9) |
| `docs/known_issues.md` | Severity, steps, affected targets and criteria, workaround, whether the build contains it | Required in every submission (AC page 9) |
| `docs/support_matrix.md` | OS versions, CPU architectures, hardware, engine version, browsers actually tested; everything else marked unverified | D-02 |
| `docs/evidence/ledger.csv` | Header row, no spaces: `id,milestone,target,start_conditions,inputs,expected,actual,evidence,status,failure_class` | The results ledger (AC page 9). `failure_class` records timing, positioning or resources for failed attempts (AC page 3) |
| `docs/evidence/traces/.gitkeep` | Empty | Keeps the folder in version control |
| `docs/evidence/media/.gitkeep` | Empty | Keeps the folder in version control |
| `docs/reference/TRI10NWARE_design.pdf` | The consolidated design document, 9 pages, October 12, 2026 (the owner's file `TRI10NWARE (1).pdf`, renamed) | Authoritative design source; every "Design page N" refers to it |
| `docs/reference/TRI10NWARE_acceptance_criteria.pdf` | The acceptance criteria, 9 pages, October 12, 2026 | Authoritative acceptance source; every criterion ID refers to it |
| `docs/reference/mockups/level_1_default.png` | The Level 1 concept mockup in default, from design page 2 | Concept reference for L1-01 and V-01 |
| `docs/reference/mockups/level_1_flow.png` | The Level 1 concept mockup in flow, from design page 2 | Concept reference for L1-01 and V-01 |

#### M0 done when

- [ ] The project opens with no errors or warnings in Godot 4.5.1.
- [ ] Running the project with `--debug-tools` shows a blank screen with the debug overlay (backtick) counting ticks at 60 per second.
- [ ] `tools/run_tests.sh` passes all four M0 unit-test files.
- [ ] `tools/export_all.sh` produces all three builds and the three itch.io files from a clean commit; each build launches on its target and shows the build ID. The web build loads over `tools/serve_web.sh` and in a draft (unpublished) itch.io page.
- [ ] Run with `--debug-tools`, a trace file is written on quit and its header lists every tuning value.

---

### M1 — Movement kit

**Goal:** the full ordinary movement set (run, jump, coyote time, jump buffer, wall jump, 8-way dash) in a verification room, proven by scenarios. No flow yet.

#### M1 build order

M1 is built in these numbered steps, one session each (`/step M1.1` and so on). The sections below this list are the specification each step implements.

1. **Tile set and `SolidGrid`:** `level_tiles.tres` with the `solidity` custom data layer, using the owner's legacy tile set (`game/art/legacy/world_tileset.png`) as the placeholder atlas until the owner supplies `tiles.png`; `solid_grid.gd`; `test_solid_grid.gd`.
2. **`PixelMover` without assists:** `pixel_mover.gd`, `test_pixel_mover.gd`.
3. **Rule objects:** `jump_resolver.gd`, `dash_state.gd`, `test_jump_resolver.gd`, `test_dash_state.gd`.
4. **The player:** `player.tscn`, `player.gd` with steps 1–10 wired into `World`, `player_visuals.gd`, `player_frames.tres` (placeholder frames until the owner's sheet arrives).
5. **Rooms:** `room.gd`, `room_entrance.gd`, `room_entry.gd`, `room_catalog.gd`, `room_catalog.tres`, `World.load_room()`, and `gym.tscn` as a **skeleton**: the room node, its three empty tile layers, one entrance per station, and its `RoomEntry`. **Owner hand-off:** the owner paints each station's tiles in the Godot editor, following the gym station table. The step is complete when the painted gym is committed.
6. **Assists:** corner correction, dash corner correction, one-way platform help and post-dash floor snap in `PixelMover`, with their unit tests, plus the **Control locks** behavior.
7. **Debug tools:** `debug_world_draw.gd`, and the debug menu's room and station list.
8. **Scenarios:** `scenario_runner.gd` and `m01`–`m08`, run against the painted gym.
9. **Done-when:** the owner's feel playtest, the interpolation and jitter check, and the M1 summary in the build journal.

**Decide before step 2** (open items 7, 9 and 10 from the 2026-10-17 specification review). Each has a proposed answer; until the owner accepts or replaces it, a session reaching it stops and asks:

- **Sub-pixel rounding:** each tick, per axis, `remainder += velocity × tick length`; `move = roundi(remainder)` (round to nearest, halves away from zero); `remainder -= move`. The remainder resets to 0 when that axis is blocked and on respawn, and is kept through room crossings.
- **Cells outside a room's corners:** a cell outside the current room belongs to another room if it is inside that room's `world_rect`; otherwise it is open if it is at or below the current room's bottom edge (a pit), and solid if not.
- **Wall-check distance:** a single overlap test at the full `wall_check_px` is enough, because every solid cell is 16 px wide. `wall_check_px` must therefore stay below 16, checked by a unit test.

#### M1 files

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/player/player.tscn` | The player scene (tree below) | One reusable player, instanced once in Main |
| `game/player/player.gd` | `class_name Player extends Node2D`. Holds the player's rule objects (movement state, `PixelMover`, `DashState`, press buffers) and the step methods `World` calls. It has **no** `_physics_process` | The movement rules' adapter to the scene |
| `game/player/player_visuals.gd` | Script on the `Visuals` node. Each frame, picks the animation and facing from the player's state | Visuals read state and never drive it |
| `game/player/player_frames.tres` | `SpriteFrames` with eight animations: `default_idle`, `default_run`, `default_jump`, `default_dash`, and the same four with an `electric_` prefix | The design document's naming; "electric" survives only in asset names |
| `game/art/player/player_sheet.png` | Player sprite sheet for both states, made by the owner. Until it arrives, a plain placeholder at this path | Source frames for `player_frames.tres` |
| `game/core/jump_resolver.gd` | `class_name JumpResolver extends RefCounted`. Given what is currently possible, returns which jump fires: ground, charged, coyote, wall or none | Jump precedence in one testable place |
| `game/core/dash_state.gd` | `class_name DashState extends RefCounted`. Dash charges (0 or 1), active ticks, direction, start tick, cooldown ticks, refill rules | The dash rules (M-03, M-04, C-08) in one testable place |
| `game/core/pixel_mover.gd` | `class_name PixelMover extends RefCounted`. Whole-pixel position, sub-pixel remainder, the pixel-by-pixel move, and the movement assists (below) | All collision in one deterministic, testable place |
| `game/core/solid_grid.gd` | `class_name SolidGrid extends RefCounted`. Which 16 px cells are solid, one-way or open, built from a room's tile layers; answers "is this rectangle blocked for this state?" | The mover's view of the world, with no physics engine |
| `game/tiles/level_tiles.tres` | The single `TileSet`, 16 × 16 tiles, with one custom data layer, `solidity` (below) | Every room paints with it, so collision is identical everywhere |
| `game/art/tiles/tiles.png` | Tile atlas made by the owner: ordinary ground and walls first, platform tiles from M4. A plain placeholder until it arrives | Source for `level_tiles.tres` |
| `game/rooms/room.gd` | `class_name Room extends Node2D`, marked `@tool` so it can draw its bounds in the editor. Exports `room_id`; reads its bounds from the catalog; provides lookups for entrances, charged objects, networks and goal zones | Every room scene uses it; `World` talks to rooms only through it |
| `game/rooms/room_entrance.gd` | `class_name RoomEntrance extends Marker2D`. Exports `entrance_id` and `facing`. Its position is where the player's feet appear | Spawn points and checkpoints |
| `game/rooms/room_entry.gd` | `class_name RoomEntry extends Resource`: `room_id`, `scene` (a `PackedScene`) and `world_rect` (a `Rect2i` in pixels: the room's place and size on the world map) | One record per room: what to build and where it sits |
| `game/rooms/room_catalog.gd` | `class_name RoomCatalog extends Resource`. A list of `RoomEntry` records plus the starting room and entrance. Finds a room by ID, finds which room contains a world point, and finds a room's neighbor beyond an edge | The world map. Rooms never refer to each other directly, so no scene loads another in a cycle, and connections cannot disagree with positions |
| `game/rooms/room_catalog.tres` | The catalog. M1: `gym`. M3 adds `level_1` as the start. M6 adds `gym_annex`. M7 adds each owner room | One list of every room and its place on the map |
| `game/verification/gym/gym.tscn` | The verification room (stations below). A normal `Room` scene. The developer builds its nodes, entrances and `RoomEntry`; **the owner paints its tiles** in the Godot editor | Tests every movement rule in isolation; not a game room (L1-05) |
| `game/debug/debug_world_draw.gd` | A `Node2D` inside `World`, drawn above the room when the overlay is on. Draws the player's body, room bounds, failure line and entrances; later regions, contact areas and goal zones | Makes invisible rules visible (C-01, V-03) |
| `game/verification/scenario_runner.gd` | `class_name ScenarioRunner extends Node`. Runs scenario files against the real game and writes results (below) | Deterministic, repeatable evidence on every target |
| `game/tests/unit/test_jump_resolver.gd` | Every combination of ground, coyote, charged and wall eligibility, with and without an active dash, returns the documented winner | Precedence must never drift |
| `game/tests/unit/test_dash_state.gd` | Start, duration, cooldown, a refill on every grounded tick, no refill mid-dash | M-03, M-04 |
| `game/tests/unit/test_pixel_mover.gd` | Against a small hand-made grid: stopping at walls, floors and ceilings at every speed up to dash speed; one-way tops blocking only from above; each assist, including when it must *not* apply | Collision correctness |
| `game/tests/unit/test_solid_grid.gd` | Building from tile data, state-dependent solidity, edge walls and pits, pending tiles | Collision correctness |
| `game/verification/scenarios/m01_ordinary_jump.json` … `m08_no_volt_cost.json` | 8 scenario files, listed below | Evidence for M-01 to M-08 |

Main gains a `Player` instance as a child of `World`, beside `RoomSlot` and `Camera`. The debug overlay gains a debug menu: jump to any room and entrance in the catalog, run scenarios, and save or download the current trace.

#### The player scene

```text
Player            Node2D, player.gd   (position = the feet, in whole pixels)
├── InputSource   Node, live_input_source.gd (scenario runs swap in scripted_input_source.gd)
└── Visuals       Node2D, player_visuals.gd
    └── Sprite    AnimatedSprite2D, player_frames.tres, offset so the feet sit at the origin
```

The player's body is a rectangle of `body_size_px` with its bottom center at the player's position. It is not a physics shape: the debug overlay draws it. Rooms use square tiles only (no slopes).

**Fresh state on every respawn.** All of the player's changing state lives in its rule objects: the mover, `DashState`, the press buffers, and a small movement-state record (sustain, soft apex, wall-jump lock, coyote, facing, grounded). On respawn the player replaces them with new instances instead of resetting fields one by one, so nothing can be forgotten (R-01). `FlowLedger` is replaced the same way from M2. The node's own position is set explicitly.

Docs: [2D sprite animation](https://docs.godotengine.org/en/4.5/tutorials/2d/2d_sprite_animation.html), [SpriteFrames](https://docs.godotengine.org/en/4.5/classes/class_spriteframes.html).

#### How movement works, step by step

All velocities are in pixels per second; the tick length is a fixed 1/60 s. "Held" and "pressed" come from the `InputFrame`.

**Step 1, input.** `World` reads the frame. First it calls `expire()` on each press buffer and logs any expired token as `press_expired`; only then does a fresh `jump` press add a token to the jump buffer and a fresh `dash` press to the dash buffer, each logged as `press`. That order (owner decision 2026-10-17) means a token whose window already closed is always reported as expired, never as replaced by the new press.

**Decision ticks.** Steps 3 and 4 make decisions using what step 7 sensed on the previous tick. Every window is counted in decision ticks:

- The **landing tick** is the first tick whose decision steps see the player grounded: one tick after the move that touched down.
- The **first airborne tick** is the first tick whose decision steps see the player airborne after leaving the ground.
- An **entry tick** (charged regions, M2) is the first tick whose decision steps see a region armed.
- A press on tick *t* can be used by a decision on ticks *t* through *t* + 6. So a press up to 6 ticks before a landing or entry tick acts on it, and a coyote jump works on airborne ticks 1 through 6.

**Step 3, dash.** If the dash buffer holds a valid token and `DashState` allows a start (a charge is available, the cooldown is clear and no dash is active):

- The direction is the 8-way input, or the facing direction if no direction is held (M-03).
- Velocity becomes that direction, normalized, times `dash_speed_px_s`, so diagonals are no faster.
- Gravity is ignored while the dash is active. The charge goes to 0 and the cooldown starts.
- The jump sustain timer and the soft apex are cancelled. A dash replaces a jump's arc completely, so no upward pull can return when the dash ends.
- The dash records the tick it started.

**Step 4, jump.** If the jump buffer holds a valid token, `JumpResolver` picks the first eligible kind in this fixed order. "Ranks above" in this document means "comes earlier in this list":

1. **Ground:** the player is grounded.
2. **Coyote:** airborne with coyote ticks remaining.
3. **Charged:** from M2 (flow, airborne, an armed and powered region).
4. **Wall:** airborne with an ordinary wall within `wall_check_px` on either side.

Coyote ranks above charged so that a late-ledge jump behaves exactly like a jump from the ledge, where a ground jump already ranks above a charged jump. Walking off a ledge into a charged region therefore gives the ordinary jump on the first press and the charged jump on the next.

**During a dash,** only a charged jump is eligible, and only if its press came after the tick the dash started. Any other jump press waits in its buffer and expires if the dash outlasts it. So pressing jump and dash together always gives a clean, full dash.

If a kind is chosen, the token is spent and logged, and:

- **Every jump** sets coyote ticks to zero.
- **If a dash is active** (a charged jump), the dash ends immediately and is logged as interrupted. Its current horizontal velocity is kept as the launch's horizontal speed (C-06: incoming horizontal velocity is preserved).
- **Each jump sets the soft apex for itself:** allowed for ground, coyote and wall jumps; off for charged jumps.
- **Ground and coyote jumps:** vertical speed becomes −`jump_speed_px_s`. If a direction is held, `jump_h_boost_px_s` is added in that direction. The sustain timer starts.
- **Wall jump:** horizontal speed becomes `wall_jump_h_speed_px_s` away from the wall and vertical speed −`jump_speed_px_s`. The sustain timer starts. For `wall_jump_lock_s` the horizontal input is treated as "away from the wall" (a control lock; see **Control locks**). A wall jump never refills the dash (M-02). **If walls are within reach on both sides** (a one-tile shaft), the player jumps off the wall opposite the held direction; with no direction held, off the wall behind their facing.

**Wall-jump intent** (owner decision 2026-10-17, as in Celeste). The player cannot scale a single wall: repeated wall jumps on one wall lose height. But a narrow vertical chamber can be climbed by bouncing between its two walls. No extra rule enforces this; it follows from the wall-jump values: the lock carries the player away from the wall, and they lose height before they can steer back. Two scenarios guard both halves. If a retune breaks either, the owner chooses between restoring the values and adding an explicit rule.

**Coyote countdown.** At the end of step 4, if the player is airborne and coyote ticks remain, subtract one. Counting at the decision, rather than in step 9, keeps the window at exactly 6 airborne ticks.

**Step 5, integrate.**

- **While dashing,** velocity is left alone.
- **Horizontal otherwise:**
    - Let *x* be the held direction, or the forced direction during a wall-jump lock.
    - Control is multiplied by `air_control_mult` in the air.
    - If moving faster than `run_max_speed_px_s` in the held direction, slow toward it by `run_reduce_px_s2`. Otherwise move toward *x* × `run_max_speed_px_s` by `run_accel_px_s2`.
- **Vertical otherwise,** in this order (Celeste's order):
    1. Apply gravity, `gravity_px_s2`, multiplied by `apex_gravity_mult` when the soft apex is allowed, jump is held, and vertical speed is within `apex_threshold_px_s`.
    2. While the sustain timer runs and jump is held, vertical speed may not rise above −`jump_speed_px_s`. Because this cap comes after gravity, a held jump rises at exactly `jump_speed_px_s` for the whole sustain. Releasing jump ends the sustain early; this is the variable jump height.
    3. Cap fall speed at `max_fall_speed_px_s`.
- **Facing** follows the held horizontal direction.

**Step 6, move.** `PixelMover` moves the player by velocity × tick length, in whole pixels:

1. Add the movement to the sub-pixel remainder; move by its whole-pixel part and keep the fraction for later ticks.
2. **Horizontal first, one pixel at a time.** Before each pixel, check whether the body would overlap a cell that is solid for the player right now. One-way platform tops never block sideways movement. If blocked, apply the **dash corner correction** if it fits (below); otherwise stop, set horizontal velocity and remainder to 0, and note a wall contact.
3. **Then vertical, one pixel at a time.** Moving down, the body is blocked by solid cells and by one-way tops exactly at the feet (the feet were at or above the top before the step). Moving up, only solid cells block. If an upward move is blocked, apply the **corner correction** if it fits; otherwise stop, set vertical velocity and remainder to 0, and note a ceiling contact.

Every position is a whole pixel, so results agree across CPUs and the browser within the **Determinism contract**, and nothing can tunnel through a tile even at dash speed (8 px per tick).

**Movement assists** (Celeste's, scaled to 16 px tiles). Each logs an `assist` event and has a gym station:

| Assist | When | What happens |
| --- | --- | --- |
| Corner correction | Rising, and the head hits a ceiling corner with the overlap within `corner_correction_px` of the body's left or right edge | Shift sideways, a pixel at a time, up to that distance into free space, and keep rising |
| Dash corner correction | A horizontal dash hits a ledge lip within `dash_corner_correction_px` of the feet | Shift up into free space and keep dashing |
| One-way platform help | Step 7: rising slower than `apex_threshold_px_s`, with the feet within `oneway_assist_px` below the top of a one-way tile that is solid for the player, and room for the body above | Lift onto the top; vertical speed 0; counts as a landing |
| Post-dash floor snap | Step 9: a dash ends moving horizontally or downward with the floor within `post_dash_snap_px` below the feet | Move down onto the floor |

Every assist applies only where the body fits at the new position; none ever pushes the player into a solid cell.

**Assist precedence.**

- **At most one correction per axis per tick,** each in its own step: overlap snap (step 2, M4, only on a switch); ordinary landing, dash corner correction and corner correction (step 6); one-way platform help (step 7); post-dash floor snap (step 9).
- **A snap never applies to a player who is already grounded.**
- **Corner correction** tries shifts of 1, 2, … up to its limit and takes the smallest that fits. If the same shift fits both ways, it prefers the direction of horizontal velocity, then the facing direction.
- **Dash corner correction** applies only to dashes whose vertical component is zero or upward.

**Step 7, sense.**

- `grounded` = the body moved one pixel down would be blocked.
- **On the first grounded tick:** log `land`.
- **On every grounded tick:** if no dash is active and the charge is 0, refill the dash (logged with cause `ground`). This includes the ticks after a dash along the ground ends while the player is still grounded (M-04).
- **While grounded:** coyote ticks are set to the window (6) and the soft apex resets.
- **Walls:** the body moved `wall_check_px` left or right would overlap an ordinary solid cell. State-dependent platforms never count as walls.
- **Ceiling:** a ceiling contact in step 6 ends the sustain timer.
- **One-way platform help** (table above).

**Step 9, timers.** Count down the sustain timer, the wall-jump lock, dash active ticks and dash cooldown. (Coyote ticks are counted in step 4.) When dash active ticks reach zero:

- Velocity becomes the dash direction × `dash_end_speed_px_s`.
- If the dash was moving upward, the vertical part is multiplied by `dash_end_up_mult`.
- The post-dash floor snap applies (table above).
- `dash_end` is logged.

Expire stale tokens.

**Step 10, outcomes.** Checked in this fixed order; the first that applies wins and is the one logged:

1. **Goal reached** (from M3): the player is grounded with their feet inside a goal zone. The goal counts even if the countdown expired this same tick, the same player-favorable tie as recharging (S-04).
2. **Countdown expired** (from M2): death, cause `countdown`.
3. **Fell:** the feet are below the room's failure line (`bounds` bottom + `fall_margin_px`) with no room below. Death, cause `fell`.
4. **Crossing** (from M6): the body's center has left the room into a neighbor.

In M1, a fall simply resets the player at the current entrance; M3 adds the full death sequence.

**Room edges.** `SolidGrid` treats the cells just outside a side or top edge with no neighbor as solid, so those edges are walls the mover stops at. Cells below a bottom edge with no neighbor are open, so that edge is a pit. In M1 there are no neighbors yet; M6 adds crossings.

#### Control locks

AC page 3 forbids *undocumented* control lockouts. These are all of them:

| Lock | Duration | What is locked | Why |
| --- | --- | --- | --- |
| Wall-jump lock | `wall_jump_lock_s` (10 ticks) | Steering back toward the wall | Makes a wall jump carry the player away from the wall |
| Dash | `dash_s` (9 ticks) | Steering, and jumps other than a charged jump | The dash is a committed move |
| Death freeze | `death_freeze_s` (21 ticks) | All gameplay input | The death effect plays |
| Respawn | `respawn_s` (15 ticks) | All gameplay input | The respawn effect plays; control returns after |
| Room crossing | `room_transition_s` (0.3 s of real time; the tick does not advance) | All gameplay input; the rules and every gameplay timer are paused; presses during the slide are discarded | The camera slides to the next room |

Any new lock is added here first, with its tuning value.

#### Same-tick contract

**Ordering rule.** Within a step, objects of one kind (charged objects, networks, collectibles, entrances) are always processed in the same order: sorted by node name within their room. Room scenes give every object a unique name, so the order never changes between runs. Whenever one of several candidates must be chosen, the tie-breaks are, in order: the rule's own priority, then the shortest distance, then the lowest node name (or `entrance_id`).

Every known case where two things meet on the same tick, in one place. A new case is added here before it is built.

| Situation | Outcome | Defined in |
| --- | --- | --- |
| Switch, dash and jump pressed on one tick | Switch, then dash, then jump (steps 2, 3, 4) | The tick |
| Several jump kinds possible | Ground, then coyote, then charged, then wall | M1 step 4 |
| Jump pressed on, or before, the tick a dash starts | Cannot cut that dash; the press waits and expires if the dash outlasts it | M1 step 4 |
| Charged jump pressed after a dash started | Cuts the dash; horizontal speed is kept | M1 step 4, M2 |
| Jump pressed on the tick after a dash's last active tick | Normal precedence; there is no dash left to cut | M1 |
| Walls within reach on both sides | Jump off the wall opposite the held direction; with none held, the wall behind the facing | M1 step 4 |
| Several assists could apply | At most one per axis per tick, in step order; never a snap while grounded | M1, **Assist precedence** |
| Corner correction fits both ways at the same distance | Direction of horizontal velocity, then facing | M1, **Assist precedence** |
| Region entered on tick *N* | Armed in step 7 of *N*; the first charged jump is possible on *N* + 1 | M2 |
| Region left on tick *N* | Outside in step 7 of *N*; a press on *N* + 1 does nothing | M2 |
| Airborne, inside an armed region: switch to flow and jump on one tick | Charged jump (switch runs first) | M2 |
| Switch to default and jump on one tick | No charged jump | M2 |
| Several armed regions overlap the player | One charged jump spends them all, in node-name order; logged against the nearest | M2 |
| Recharge and countdown expiry on one tick | Recharge wins (step 8 runs before step 9) | M2, M5 |
| Two or more power sources touched on one tick | All activate, in node-name order; one recharge; one `volts` event if the count changed; one `countdown_cancel` if it was running | M5 |
| Goal, countdown expiry, fall and crossing on one tick | The first that applies, in that order (step 10) | M1 step 10 |
| A collectible touched or carried on a tick the player dies | It never commits; commits are checked in step 10, after the death checks | M6 |
| A room crossing begins | The tick stops advancing; presses during the slide are discarded; held buttons are read fresh when the rules resume | M6 |
| Choosing the checkpoint after a crossing | The new room's entrance nearest the player's feet, among those within 48 px of the edge actually crossed; ties go to the lowest `entrance_id` | M6 |
| A level's goal is reached | The banner (or, for Level 1 alone and for the final room, the completion overlay) triggers on the goal zone in step 10, never on a crossing; goal zones never sit on a room edge | M3, M7 |

#### The tile set

The tile set has no physics layers. Instead, one **custom data layer** named `solidity` (an integer) tells `SolidGrid` what each tile is:

| `solidity` | Meaning | Blocks the player |
| --- | --- | --- |
| 0 | Decoration | Never |
| 1 | Ordinary ground or wall | Always, from every side, in both states |
| 2 | Default-only platform (M4) | Only from above (its top edge), only in default |
| 3 | Flow-only platform (M4) | Only from above (its top edge), only in flow |

Every room has three `TileMapLayer` nodes, `WorldTiles`, `DefaultTiles` and `FlowTiles`, all using this tile set; the separate layers exist so each family can be drawn differently by state. When a room is built, `SolidGrid` reads every used cell of the three layers once (`get_cell_tile_data()`, then the `solidity` value) into its own lookup. It never waits on the engine's deferred tile updates, so a new room is solid on its first tick.

Docs: [Using TileSets (custom data layers)](https://docs.godotengine.org/en/4.5/tutorials/2d/using_tilesets.html), [Using TileMaps](https://docs.godotengine.org/en/4.5/tutorials/2d/using_tilemaps.html), [TileMapLayer](https://docs.godotengine.org/en/4.5/classes/class_tilemaplayer.html), [TileData](https://docs.godotengine.org/en/4.5/classes/class_tiledata.html), [Rect2i](https://docs.godotengine.org/en/4.5/classes/class_rect2.html).

#### Room scene convention

Every room scene, including the gym, uses exactly this structure. `room.gd` finds children by these names.

```text
<RoomName>        Node2D, room.gd       (room_id; info from M6)
├── Backdrop      Node2D                (background art and decoration; dimmed in flow)
├── WorldTiles    TileMapLayer
├── DefaultTiles  TileMapLayer
├── FlowTiles     TileMapLayer
├── Objects       Node2D                (charged objects, networks, goal zones)
├── Collectibles  Node2D
└── Entrances     Node2D                (RoomEntrance children)
```

**Room coordinates.** A room's content is built with the room's top-left corner at (0, 0). Its place on the world map comes only from `world_rect` in its `RoomEntry`; `World` sets the room node's position to `world_rect.position` when it builds the room. The room's `bounds` are `world_rect`. Rules for every `world_rect`:

- Position and size are whole multiples of 16 px (whole tiles), so tiles line up across shared edges.
- The size is at least 640 × 368 (40 × 23 tiles). That is the smallest whole-tile size covering the 640 × 360 screen, so the camera never shows outside a room; a one-screen room scrolls 8 px vertically.
- No two rooms overlap.
- Verification rooms (the gym and its annex) sit far from the game's rooms, so they are never neighbors of game rooms.

`World` gains `load_room(room_id, entrance_id)`, used at game start, for respawns, by the debug menu and by scenarios:

1. Remove and free every room under `RoomSlot`.
2. Instance the requested room from the catalog, position it at its `world_rect`, add it under `RoomSlot`, and build its `SolidGrid`.
3. Place the player at the entrance with fresh state, calling `reset_physics_interpolation()` on the player and the camera so the jump is not smoothed.
4. Set the camera limits from the room's bounds, and log `room_enter`.

Docs: [Nodes and scene instances](https://docs.godotengine.org/en/4.5/tutorials/scripting/nodes_and_scene_instances.html), [PackedScene](https://docs.godotengine.org/en/4.5/classes/class_packedscene.html), [Running code in the editor](https://docs.godotengine.org/en/4.5/tutorials/plugins/running_code_in_the_editor.html), [Node.reset_physics_interpolation](https://docs.godotengine.org/en/4.5/classes/class_node.html).

#### Gym stations in M1

Each station has its own entrance, so the debug menu and scenarios can start there directly. **In every milestone, the owner paints gym stations** in the Godot editor from these tables; the developer adds each station's entrance first and writes its scenarios after the painting is committed. Where a station's size depends on tuning (for example the chimney's width), the developer states the needed size in the build journal before the owner paints it.

| Entrance | Layout | Tests |
| --- | --- | --- |
| `start` | Open floor | General play |
| `run_track` | 40 tiles of flat floor | M-01 run, turn, stop |
| `wall_shaft` | Two tall ordinary walls 6 tiles apart | M-02, both sides |
| `narrow_shaft` | Two walls one tile apart | The both-walls rule |
| `single_wall` | One tall wall with open space beside it | Guard: repeated wall jumps on one wall never gain height |
| `chimney` | A tall, narrow vertical chamber; its width is chosen once the wall-jump values are tuned and recorded in the decision log | Guard: alternating wall jumps between its walls gain height and reach the top |
| `corner_ceiling` | Low ceilings with corners at jump height, and ledge lips at dash height | Corner correction and dash corner correction |
| `dash_chamber` | Closed box 12 × 8 tiles with floor, ceiling and walls | M-03, every direction and every collision |
| `coyote_ledge` | A ledge over a long drop | M-05 |
| `buffer_drop` | A 6-tile drop onto flat floor | M-06 |

#### Scenario files

A scenario is a JSON file in `game/verification/scenarios/`. Its name starts with the lowercase criterion ID. JSON was chosen over Godot resources so scenarios can be written and reviewed as plain text.

| Key | Meaning |
| --- | --- |
| `id` | Same as the file name without `.json` |
| `criteria` | Criterion IDs covered, such as `["M-05"]` |
| `room`, `entrance` | Where each case starts |
| `setup` | Optional starting overrides: `state`, `volts`, `facing` |
| Tuning names | Any number in `inputs`, `ticks`, `expect`, `forbid` or `final` may instead be a tuning value's name, optionally plus or minus a whole number, such as `"coyote_ticks"` or `"jump_buffer_ticks+1"`. Scenarios then survive retuning |
| `cases` | A list of cases, each run from a fresh room |
| `cases[].name` | Short name |
| `cases[].inputs` | List of `{"tick": n, "press": "jump"}` or `{"tick": n, "release": "jump"}`; ticks count from 0 at the case start |
| `cases[].ticks` | How long the case runs |
| `cases[].expect` | Events that must appear: `{"event": "jump", "fields": {"kind": "coyote"}, "tick": [a, b], "count": 1}`. `tick` and `count` are optional |
| `cases[].forbid` | Events that must not appear, in the same shape |
| `cases[].final` | Expected values in the closing `snapshot`, such as `{"volts": 2, "state": "flow"}` |
| `cases[].measure` | Values to record, such as `{"label": "launch_vy", "event": "jump", "field": "vy"}` |
| `compare` | Optional: labels whose measured values must match within a tolerance, such as `{"labels": ["launch_vy_rising", "launch_vy_falling"], "tolerance": 0}` |

How the runner works:

1. Before the run: save a copy of `GameState`, and turn off pausing on focus loss so clicking another window does not stall a windowed run. For each case: reset `GameState`, rebuild the room, place the player at the entrance with fresh state, and apply `setup`. `FlowLedger.set_for_test()` exists only for this and logs its change. After the run, restore `GameState`.
2. Swap in a scripted input source and run exactly `ticks` ticks.
3. Log a `snapshot` and check `expect`, `forbid`, `final` and `measure` against the trace.
4. Write one row per case to `user://evidence/scenario_results_<build>_<target>_<fps>.csv` with columns `scenario, case, criteria, target, build, render_fps, result, failures, measures`.

Commands:

- All scenarios, fast and headless: `godot --headless --path game --fixed-fps 60 -- --run-scenarios --quit-when-done`. `--fixed-fps` runs one tick per frame as fast as possible, with identical results.
- One family: `-- --run-scenarios=c05`.
- In exported builds, pass the same flags after `--`, or use the debug menu.

Docs: [Command line tutorial](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html), [JSON](https://docs.godotengine.org/en/4.5/classes/class_json.html).

| Scenario file | What its cases prove |
| --- | --- |
| `m01_ordinary_jump.json` | One grounded jump; a second press in open air does nothing; turning and stopping on the run track |
| `m02_wall_jump.json` | Wall jumps off left and right walls; the both-walls rule in the narrow shaft; repeated wall jumps on a single wall never gain height; alternating wall jumps climb the chimney; no `dash_refill` from wall contact; corner corrections apply where expected and nowhere else (flow cases added in M2) |
| `m03_dash_directions.json` | All 8 directions plus the no-direction fallback; diagonal speed magnitude equals straight; collisions with floor, ceiling and wall leave the player outside the wall |
| `m04_dash_refill.json` | No second dash before landing; landing refills; a dash along the ground refills on the next grounded tick after it ends; a wall touch does not (charged, switching and region cases added in M2) |
| `m05_coyote.json` | A jump on airborne tick 6 succeeds as `coyote`; on tick 7, nothing; a spent coyote jump cannot be reused (a region case is added in M2) |
| `m06_jump_buffer.json` | A press 6 ticks before the landing tick jumps on the landing tick; 7 ticks before, nothing; one press gives one jump |
| `m07_simultaneous_input.json` | Jump and dash pressed on one tick give a full dash and no jump: the jump press expires unused; a dash started right after a jump leaves no upward pull when it ends; holding never repeats; rapid direction changes (switch cases added in M2) |
| `m08_no_volt_cost.json` | Many jumps, wall jumps and dashes produce no `volts` events (volt snapshots added in M2) |

#### M1 done when

- [ ] All M0 and M1 unit tests pass.
- [ ] All eight M1 scenario files pass headless.
- [ ] Physics interpolation and pixel snapping together show no shimmer or camera jitter in the gym at 60 Hz and 144 Hz; otherwise the chosen fix is in the decision log.
- [ ] The owner has played the gym and recorded first feel notes and any tuning changes in `docs/decision_log.md`.

---

### M2 — Flow and charge

**Goal:** default and flow states, volts, the zero-volt countdown, and the always-powered charged object, proven in the gym.

#### M2 files

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/core/flow_ledger.gd` | `class_name FlowLedger extends RefCounted`. State, volts, countdown and every transition between them (rules below) | The sole owner of state, volts and countdown (ground rule 6) |
| `game/player/flow_controller.gd` | Script on a new `FlowController` node in the player scene. Holds the `FlowLedger`, applies its results (which platform family is solid for the player, trace events) | The ledger's adapter to the scene |
| `game/core/encounter_tracker.gd` | `class_name EncounterTracker extends RefCounted`. Outside, armed or spent, updated from two overlap tests | One charged jump per visit (C-03, C-04) |
| `game/core/geometry.gd` | `class_name Geometry extends RefCounted` with static functions: circle–rectangle overlap, rectangle–rectangle overlap, rectangle inflation | Exact, engine-independent overlap tests (no physics signals) |
| `game/objects/charged_object/charged_object.tscn` | The charged object (tree below) | Placed in rooms; used by Level 1 and every later room |
| `game/objects/charged_object/charged_object.gd` | `class_name ChargedObject extends Node2D`, `@tool`. Exports `region_radius_px` (−1 = use tuning default) and `always_powered`; holds `powered` and an `EncounterTracker`; draws its ring with `draw_arc()` from the same radius | Rule data plus a visible cue that can never disagree with it (V-03) |
| `game/art/objects/charged_object.png` | The charged object's sprite, made by the owner | Art |
| `game/art/objects/charged_glow.png` | Glow drawn with additive blending, made by the owner: faint in default as a hint, full in flow | The default-state hint (design page 8) and the flow emphasis (V-02), without engine glow |
| `game/art/player/switch_burst.png` | Frames for the switch effect | Plays over movement animation (V-04) |
| `game/ui/hud.tscn` | `CanvasLayer` with volt pips, state icon, dash pip, countdown numerals and a draining ring | Shows what planning needs (V-03) |
| `game/ui/hud.gd` | Reads the player each frame; flashes the volt pips on `switch_refused` | A read-only view |
| `game/ui/theme.tres` | `Theme` using the pixel font at its native size | Consistent, crisp UI text |
| `game/art/fonts/pixel_font.ttf` | The pixel font the owner chooses, imported with antialiasing off, hinting off and subpixel positioning disabled; license recorded in `CREDITS.md` | Readable text at 640 × 360 |
| `game/art/ui/volt_pip.png` | Full and empty volt pip | HUD |
| `game/art/ui/dash_pip.png` | Dash available and spent | HUD |
| `game/art/ui/state_icons.png` | Default and flow icons | HUD; a non-color state cue |
| `game/art/ui/countdown_ring.png` | Ring texture for a `TextureProgressBar` | HUD countdown |
| `game/tests/unit/test_flow_ledger.gd` | Every rule below, including flag variants | S-02, S-03, S-04 |
| `game/tests/unit/test_encounter_tracker.gd` | Arm, spend, exit hysteresis, state switch does nothing | C-03, C-04 |
| `game/tests/unit/test_geometry.gd` | Overlap edge cases, touching edges, zero sizes | Everything that uses overlap |
| `game/verification/scenarios/c01_activation_window.json` … `c08_refill_and_precedence.json` | 8 files, listed below | C-01 to C-08 |
| `game/verification/scenarios/s01_switch_preserves_motion.json` … `s04_recharge_and_expiry.json` | 4 files, listed below | S-01 to S-04 |

Files extended in M2:

| File | Change |
| --- | --- |
| `player.tscn` | Adds `FlowController` (Node) and `Visuals/SwitchFX` (AnimatedSprite2D) |
| `player.gd` | Calls the switch step; adds the charged jump |
| `player_frames.tres` | The owner's `electric_` animations |
| `jump_resolver.gd` | Adds the charged kind |
| `gym.tscn` | Adds charged stations |
| `debug_world_draw.gd` | Draws regions colored by encounter state, plus their exit rings |
| `main.tscn` | Adds `HUD` |
| `m02`, `m04`, `m05`, `m07`, `m08` scenario files | Add flow cases; `m05` adds walking off a ledge into an armed region: coyote jump on the first press, charged jump on the second |

```text
ChargedObject     Node2D, charged_object.gd   (origin = region center)
├── Sprite        Sprite2D, charged_object.png
└── Glow          Sprite2D, charged_glow.png, CanvasItemMaterial blend mode Add; faint in default while powered (a hint), full in flow
```

The ring is drawn by the script itself, not by a child node. Docs: [Custom drawing in 2D](https://docs.godotengine.org/en/4.5/tutorials/2d/custom_drawing_in_2d.html), [CanvasItemMaterial](https://docs.godotengine.org/en/4.5/classes/class_canvasitemmaterial.html), [Using fonts](https://docs.godotengine.org/en/4.5/tutorials/ui/gui_using_fonts.html), [TextureProgressBar](https://docs.godotengine.org/en/4.5/classes/class_textureprogressbar.html).

#### FlowLedger rules

| Request or event | Rule |
| --- | --- |
| Switch while in default, volts ≥ 1 | Enter flow, volts − 1. If volts are now 0, start the countdown at `countdown_s` in ticks (180) |
| Switch while in default, volts = 0 | Refused unless `allow_flow_entry_at_zero` is on (AC: off). State and countdown unchanged; log `switch_refused` |
| Switch while in flow | Enter default at no cost. The countdown follows `countdown_in_default` (AC: continue) |
| Recharge (network activation, M5) | Volts to `max_volts`; countdown off; log `countdown_cancel` if it was running |
| Each tick (step 9) | If the countdown is running, count down by one; report expiry exactly once, when it reaches 0. The countdown starts at 180 in step 2 and is counted in step 9 of the same tick, so it expires on the 180th tick counting the tick it started |
| Reset (respawn) | Default, `max_volts`, countdown off |

Volts can never go below 0 or above `max_volts`. Only fresh presses reach the ledger, so holding the switch cannot charge twice.

`countdown_in_default` is a three-way setting rather than a yes/no because open decision OD-1 asks whether the countdown should continue, pause or stop after returning to default. The AC value is `continue`.

**What the flow controller does after a successful switch,** in order within step 2:

1. Change which platform family `SolidGrid` treats as solid for the player: default-only tiles in default, flow-only tiles in flow. From M4, this goes through the overlap policy.
2. Re-check support with a one-pixel downward probe. If the floor vanished, start coyote time exactly as if the player had walked off a ledge.
3. Log `switch`.

Position, velocity and an active dash are untouched (S-01).

#### Charged objects, step by step

**Step 7, sense.** For each charged object in the room:

- *entry* = the region circle overlaps the player's body rectangle.
- *still inside* = the same test with the radius increased by `charged_exit_margin_px`.

The tracker moves:

- **Outside → armed** on entry.
- **Armed or spent → outside** when no longer inside.
- **Spent** otherwise stays spent.

State switches never touch the tracker.

**Step 4, jump.** A charged jump is eligible when the player is in flow and not grounded, and at least one object is powered and armed. It ranks below ground and coyote jumps (M1), and it is the only jump that can cut short an active dash. On a charged jump:

- **An active dash ends** immediately, if the jump press came after the dash started; its horizontal velocity is kept (next bullets).
- **Coyote ticks** go to zero, as for every jump.
- **Vertical speed** becomes −`charged_launch_speed_px_s`, replacing whatever it was (C-05).
- **Horizontal speed** is kept exactly as it was, including the full dash speed when launching out of a dash (C-06). Air control then slows it toward run speed as usual.
- **No variable height:** the sustain timer is zeroed and the soft apex is off for this jump, so neither releasing nor holding jump changes the arc (C-06).
- **Every armed region the player is inside** becomes spent, not just one, processed in node-name order (**Same-tick contract**), so overlapping regions never give extra charged jumps. The jump is logged against the nearest object; ties go to the lowest node name.
- **The dash refills** (cause `charged`). If `charged_refill_clears_cooldown` is on, the cooldown clears too. A dash press made on the same tick waited in its buffer (step 3 ran first, with no charge), so it fires on the next tick's step 3: that is the charged dash (C-08).
- **Logged** as a `jump` with kind `charged` and the object's name.

An unpowered object, or the default state, never offers a charged jump, and passing through a region without a fresh press does nothing (C-02).

#### HUD layout

All HUD elements sit inside the 640 × 360 canvas with at least 8 px of margin:

- **Top left:** three volt pips, then the state icon, then the dash pip.
- **Top center:** the countdown, only while it runs: large numerals over a ring draining from full to empty.
- **On refusal:** the volt pips flash.
- **At 0 volts in flow:** the state icon shows a warning, because switching to default now is certain death (level design rule 1).

Everything is readable with sound muted (V-04).

#### Gym stations added in M2

| Entrance | Layout | Tests |
| --- | --- | --- |
| `charged_test` | An always-powered object hanging over open floor, with markers at three heights so a jump enters its region rising, at the apex and falling | C-01, C-05, C-07 |
| `charged_pair` | Two always-powered objects side by side, regions not overlapping | C-04, objects tracked independently |
| `charged_overlap` | Two always-powered objects whose regions overlap | One charged jump spends both |
| `charged_ceiling` | An always-powered object 2 tiles under a ceiling | C-06 ceiling case |
| `unpowered_object` | An object with `always_powered` off and no network | C-02 |
| `zero_volt_lane` | A long flat floor | S-03, S-04 |

#### M2 scenario files

| Scenario file | What its cases prove |
| --- | --- |
| `c01_activation_window.json` | A charged jump fires when pressed rising, at the apex and falling inside the region; landing on the object is never needed |
| `c02_gates.json` | Default state: no charged jump. Unpowered object: none in either state. Passing through without a press: no launch, no refill |
| `c03_one_per_encounter.json` | A second fresh press inside: nothing. Holding: nothing |
| `c04_reentry.json` | Leave and re-enter: another charged jump, repeatedly. Toggling state inside: no re-arm. Two objects tracked separately. Two overlapping regions: one charged jump spends both. Resting on the boundary: no false re-arm. Tick-exact edges: entering on tick *N* allows a jump on *N* + 1 but not *N*; leaving on *N* means a press on *N* + 1 does nothing; switching to flow and jumping on one tick inside an armed region gives a charged jump; switching to default and jumping on one tick does not |
| `c05_launch_speed.json` | Rising, near-zero and fast-falling entries all measure vertical speed exactly −`charged_launch_speed_px_s` right after launch (`compare`, tolerance 0) |
| `c06_horizontal_and_ceiling.json` | Horizontal speed kept at launch, including the full dash speed out of a dash; held and released runs give identical snapshots; a ceiling hit does not re-arm |
| `c07_buffered_charged.json` | A press 6 ticks before the entry tick fires on the entry tick; 7 ticks before, nothing; the token is spent once |
| `c08_refill_and_precedence.json` | Dash 0 → charged jump → `dash_refill` with cause `charged`; jump and dash pressed on one tick inside a region with no dash left: charged jump, then the dash on the next tick; a charged jump pressed during a dash cuts it short; a press on the dash's start tick never cuts it (it expires); a press on the tick after the dash's last active tick follows normal precedence; a press on the tick a region first becomes eligible mid-dash cuts the dash; a press buffered before the dash started never cuts it; never two actions from one press |
| `s01_switch_preserves_motion.json` | Switching while grounded, airborne and mid-dash leaves position and velocity unchanged and grants no jump or dash |
| `s02_entry_cost.json` | Default → flow costs exactly 1; flow → default costs 0; volts stay within 0–3; holding switch does not repeat |
| `s03_last_volt.json` | Entering flow at 1 volt: 0 volts and a 180-tick countdown; a charged jump still works; returning to default does not stop the countdown; entering flow at 0 is refused without touching the timer |
| `s04_recharge_and_expiry.json` | Expiry gives exactly one death, on the 180th tick counting the tick the countdown started, and no second timer (recharge and same-tick cases are added in M5) |

#### M2 done when

- [ ] All unit tests and all M1 and M2 scenarios pass headless.
- [ ] The HUD shows volts, state, dash and countdown correctly in the gym, including with sound muted.
- [ ] The debug overlay shows each region's exact boundary and encounter state.

---

### M3 — Level 1 room

**Goal:** the Level 1 crossing, playable from a title screen, with death and retry, completion, pause, sound, final art, and all three builds. This milestone ends at the **Level 1 gate**.

#### M3 files

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/rooms/level_1/level_1.tscn` | The Level 1 room (layout below) | The first required room (L1-01) |
| `game/objects/goal/goal_zone.gd` | `class_name GoalZone extends Node2D`, `@tool`. Exports a thin rectangle that sits on a platform's top surface | Completion means standing on the destination, not touching its side or flying past (L1-04) |
| `game/objects/wire/wire.gd` | `class_name Wire extends Line2D`, `@tool`. Exports `decorative_powered`; holds `powered` and `flow_mode`; switches between the default look and the flow current | Level 1's visible electrical connections (L1-01), and (M5) the visible link between a power source and its objects |
| `game/objects/wire/wire_current.gdshader` | Canvas-item shader: dashes scrolling along the line in flow; a `pulse_progress` uniform used from M5 | The animated current, using only features the Compatibility renderer supports |
| `game/world/flow_presentation.gd` | Script on a new `FlowPresentation` node in `World`. Listens for `switch`, `room_enter` and `respawn`; fades the room's `Backdrop`, shows glows and region rings, sets wire modes | All flow visuals in one place; no rule depends on them (V-02) |
| `game/ui/title_overlay.tscn` | `CanvasLayer`: title, build ID, "press any key". On the web build it asks for a click or key press specifically | Starts play on a user gesture, which browsers need before audio (D-04). Gamepad buttons do not count as a gesture in browsers |
| `game/ui/title_overlay.gd` | While shown, draws each flow-state material once off-screen so its shader compiles before play. On the first key or click: hides, starts `World`, marks inputs stale | No stall on the first switch into flow (worst on the web); the start key never becomes a jump |
| `game/ui/pause_menu.tscn` | `CanvasLayer`, process mode **Always**: Resume, Restart room, Fullscreen, Sound on/off, Quit (Quit hidden on web) | R-04, D-07 and normal play |
| `game/ui/pause_menu.gd` | Pauses and unpauses the scene tree; marks inputs stale on resume. Restart room is a death with cause `restart`, so it resets exactly like any other death | Pausing freezes ticks, so the countdown cannot expire in the background |
| `game/ui/completion_overlay.tscn` | `CanvasLayer`: "Level complete", then "press jump to play again" | Visible completion (L1-04, V-04) |
| `game/ui/completion_overlay.gd` | Shows on `room_complete`; on replay, marks inputs stale and rebuilds the room | Clean replay; the jump that dismissed it never becomes a jump |
| `game/audio/sfx.gd` | Script on a new `Sfx` node in Main. Plays sounds in response to `Trace` events through a small pool of `AudioStreamPlayer`s on the SFX bus; plays the countdown tick each time the displayed second changes | Audio feedback with no link to the rules (V-04) |
| `game/default_bus_layout.tres` | Audio buses: Master, SFX, Music (Music is reserved; no track is required) | Separate volume control |
| `game/audio/sfx/jump.wav` | Ordinary, coyote and wall jumps | Feedback |
| `game/audio/sfx/charged_jump.wav` | Charged jump | Feedback |
| `game/audio/sfx/dash.wav` | Dash start | Feedback |
| `game/audio/sfx/switch_to_flow.wav` | Entering flow | Feedback |
| `game/audio/sfx/switch_to_default.wav` | Leaving flow | Feedback |
| `game/audio/sfx/switch_refused.wav` | Flow refused at zero volts | Feedback |
| `game/audio/sfx/countdown_tick.wav` | Once per remaining second | Urgency |
| `game/audio/sfx/death.wav` | Death | Feedback |
| `game/audio/sfx/respawn.wav` | Respawn | Feedback |
| `game/audio/sfx/room_complete.wav` | Completion | Feedback |
| `game/art/backdrop/level_1_backdrop.png` | Level 1's background, made by the owner. If the owner splits it into layers, each layer file is added to this table before it is created | The part of the screen that dims in flow (V-02) |
| `game/art/props/level_1_props.png` | Level 1's decorative props as one atlas, made by the owner | Decoration only; props never collide |
| `game/art/props/wire_strip.png` | A 4 × 1 white texture | `Line2D` only generates the coordinates the current shader needs when it has a texture |
| `game/world/effects.gd` | Script on a new `Effects` node in `World`. Plays one-shot visual effects at the right position in response to `Trace` events, through a small pool of `AnimatedSprite2D`s | Visible feedback for every important action (V-04), with no link to the rules |
| `game/world/effects_frames.tres` | `SpriteFrames` with one animation per effect: `death`, `respawn`, `charged_jump`, `dash`, `land`, `goal` | One place that maps effect names to art |
| `game/art/effects/effects.png` | The effects art, made by the owner (slot) | Source frames for `effects_frames.tres` |
| `game/verification/bypass_search.gd` | `class_name BypassSearch extends RefCounted`, used by the scenario runner. From a room's start, tries every combination of jump tick, dash tick and dash direction within set bounds, without flow, and reports any that reach the goal | Proves "ordinary movement falls short" instead of hoping hand-written attempts found every route (6.2) |
| `game/verification/scenarios/l1_02_powered_on_retry.json` … `r03_repeated_retries.json` | 6 files, listed below | L1-02 to L1-04, R-01 to R-03 |

Files extended in M3:

| File | Change |
| --- | --- |
| `world.gd` | Death sequence, completion, title gating (below) |
| `main.gd` | Pause on the `pause` action and on `NOTIFICATION_APPLICATION_FOCUS_OUT`, except while the scenario runner is active |
| `main.tscn` | Adds `TitleOverlay`, `PauseMenu`, `CompletionOverlay`, `Sfx`, `World/FlowPresentation`, `World/Effects` |
| `camera_rig.gd` | Follows the player, clamped to the room's bounds, no smoothing; moved on the physics step |
| `player_sheet.png`, `tiles.png` | The owner's art, when it arrives, at the same paths |
| `room_catalog.tres` | Adds `level_1` and makes it the start room |
| `debug_world_draw.gd` | Draws goal zones |
| `README.md`, `docs/*` | Level 1 gate evidence |

Docs: [Pausing games](https://docs.godotengine.org/en/4.5/tutorials/scripting/pausing_games.html), [Godot notifications](https://docs.godotengine.org/en/4.5/tutorials/best_practices/godot_notifications.html), [Audio buses](https://docs.godotengine.org/en/4.5/tutorials/audio/audio_buses.html), [AudioStreamPlayer](https://docs.godotengine.org/en/4.5/classes/class_audiostreamplayer.html), [Line2D](https://docs.godotengine.org/en/4.5/classes/class_line2d.html), [CanvasItem shaders](https://docs.godotengine.org/en/4.5/tutorials/shaders/shader_reference/canvas_item_shader.html), [Tween](https://docs.godotengine.org/en/4.5/classes/class_tween.html), [Feature tags](https://docs.godotengine.org/en/4.5/tutorials/export/feature_tags.html).

#### What Level 1 must demonstrate

Level 1 proves one idea, which the AC states on page 2: **analyze the gap, enter flow, jump toward the powered object, trigger an aerial charged jump, and land on the destination.** Network activation is not part of Level 1, and its object is powered from the start (L1-02).

The two original mockups (design document page 2) visualize this idea. Follow **How mockups are used**: take the elements and their relationships from the mockups, and nothing else.

| Element (L1-01) | What must hold |
| --- | --- |
| Starting platform | Safe footing where the player begins; entrance `start` on it |
| Destination | Across a gap from the start; a `GoalZone` covers its top surface |
| The gap | Cannot be crossed with ordinary movement alone |
| Powered object | One `ChargedObject` with `always_powered` on, above the gap, placed so a jump from the start can reach its region and a charged jump from there can reach the destination |
| Overhead geometry | Ordinary solid geometry above the gap, from which the object visibly hangs. Its shape and size are free, but it must not block the intended route |
| Visible electrical connections | Decorative `Wire` nodes with `decorative_powered` on, showing the object belongs to an electrical system. Where they run and how they look is the owner's call |
| Bounds | One screen; its `RoomEntry` has `world_rect` (0, 0, 640, 368), the minimum room size (40 × 23 tiles) |

**Geometry follows the tuned movement, not the picture.** Once jump, dash and charged-jump values are tuned (M1, M2), place the start, the object and the destination so that:

- jump, enter flow, then charged jump (plus the refilled dash if wanted) reaches the destination; and
- ordinary jump plus dash falls short.

Prove the first with `l1_03_intended_crossing.json` and the second with the bypass search (`bypass_search.gd`), which fails Level 1 if any ordinary-only route reaches the goal. A bypass the owner accepts on purpose is listed in the decision log. Any bypass is reported, not hidden: the AC does not ban advanced routes, but the charged route must work (AC page 2). Record the final positions and the reasons in the decision log. If movement values change later, re-check Level 1 and adjust its geometry.

**Evidence for L1-01 and V-01:** side-by-side screenshots of the room and both mockups, in default and in flow, with one line per element saying where it is and what differs. This is the comparison the owner interpretation above describes.

#### Death, retry and completion in World

`World` now runs a small sequence of play states. Ticks count in Playing, Dying and Respawning, but not in Title, Complete, Transition or while paused (M0 step 7).

| State | What happens | Leaves when |
| --- | --- | --- |
| Title | Simulation off; title overlay shown | Any key or click |
| Playing | The 11 steps run | Death, completion or pause |
| Dying | Death logged once; player frozen; death effect plays (for a fall, at the point where the player left the screen, clamped to the view); input ignored | After `death_freeze_s` |
| Respawning | Room rebuilt from its scene; player placed at the checkpoint entrance with fresh state; inputs marked stale; `respawn` logged; respawn effect plays | After `respawn_s`; then `control_return` is logged |
| Complete | Completion overlay shown; simulation off | Jump pressed: rebuild and play |
| Transition (added in M6) | Rules and tick paused while the neighbor is built and the camera slides to it | The slide ends |

Death to control takes 0.6 s, under the 1 s limit (R-02). **The player reset is complete** (R-01), because the player's rule objects are replaced with fresh instances (M1, **The player scene**). The result:

- position at the checkpoint entrance, facing its `facing`
- default state, so default-only platforms are solid; `max_volts` volts; no countdown
- no pending platform tiles
- dash charge 1, no dash active, no cooldown, velocity 0
- no sustain, soft apex reset, no wall-jump lock, coyote ticks 0, not grounded until sensed
- all tokens cleared; held jump, dash and switch stale
- `reset_physics_interpolation()` called on the player and the camera

The room is a fresh instance, so encounters, effects and timers start clean.

**Completion (step 10):** the player is grounded and their feet are inside a `GoalZone`. Log `room_complete` once. Until Level 2 exists, Level 1's goal shows the completion overlay. When Level 2 is registered, Level 1's goal becomes an opening into Level 2's first room (owner decision 2026-10-16): reaching it shows a brief level-complete banner and sound without stopping play (`goal_banner`, satisfying L1-04's "visibly completes"), and only the final room's goal ends the game (M7). The banner triggers on the goal zone in step 10, never on the crossing that follows; a goal zone never sits on a room edge.

**Pause and focus (R-04):** the `pause` action, or `NOTIFICATION_APPLICATION_FOCUS_OUT`, pauses the scene tree. That stops `World`'s ticks, freezing the countdown. Resuming marks inputs stale. On the web build, check that switching tabs and clicking outside the game pause it. If they do not, record it in `docs/known_issues.md` and propose the fix in this document before building it.

#### M3 scenario files

Scenario files gain one optional key in M3: `"report_only": true` on a case records its result without counting it as pass or fail. It is used for exploratory cases whose outcome is information, not a requirement.

| Scenario file | What its cases prove |
| --- | --- |
| `l1_02_powered_on_retry.json` | The object is usable on a fresh start and after a death; a charged jump succeeds right after respawn |
| `l1_03_intended_crossing.json` | The full intended route reaches `room_complete` with no death; the bypass search finds no ordinary-only route |
| `l1_04_completion_and_failure.json` | Landing on top completes exactly once; side contact and flying past do not; falling below the failure line kills (cause `fell`) and respawns cleanly |
| `r01_reset_state.json` | After a death, the `snapshot` shows every reset value above; a jump held through death does not fire after respawn |
| `r02_control_return.json` | Ticks from `death` to `control_return` are at most 60 |
| `r03_repeated_retries.json` | 20 deaths, mixing falls, countdown expiries and restarts, then the crossing: launch speed and the engine-wide counts match the first attempt; nothing accumulates |

To support R-03, the `snapshot` event also records engine-wide counts: total nodes and objects (from Godot's performance monitors), active sound players, running tweens and active effects. Leaks can hide outside the room, so the whole engine is counted.

#### Level 1 gate: evidence and delivery

1. `tools/run_tests.sh` passes.
2. `tools/export_all.sh` produces all three builds from one clean commit.
3. On each target, run the scenarios inside the exported build (desktop: `-- --run-scenarios --quit-when-done`; web, served locally with `?debug=1`: debug menu) and copy the results file to `docs/evidence/traces/`. Results on different targets are compared within one-tick tolerance, never for exact equality.
4. **Frame-rate independence (D-05):** on each desktop target, run the scenarios windowed with `--render-fps=30`, `60` and `120`; measured values must match tick for tick on the same target. Browsers set their own frame rate, so the web build runs at the browser's rate, which is recorded. Then hand-test the coyote and buffer edges with live input at 30 and 120 FPS on desktop: live input arrives once per rendered frame, so record where its edges differ by a tick as a sampling limit. Record any rate the hardware could not reach as a limitation, not a pass.
5. **Video and screenshot evidence:** the L1-01 and V-01 comparison screenshots described under **What Level 1 must demonstrate**, and videos for L1-03, V-02 to V-04, R-04 and D-07. Godot's Movie Maker mode (`--write-movie`) records any scripted scenario at an exact frame rate. Docs: [Creating movies](https://docs.godotengine.org/en/4.5/tutorials/animation/creating_movies.html).
6. **Documents:** fill `docs/evidence/ledger.csv` for every L1, M, C, S, R, V and D criterion on every target, with `failure_class` for every failed attempt in the feel playtest (AC page 3). Update `support_matrix.md`, `known_issues.md` and `decision_log.md`. Complete the README's first-launch and itch.io steps.
7. **itch.io:** upload the three files from `builds/itch/` to the game's itch.io page (M0 step 10) and play the web build in the itch.io page on macOS and Windows browsers.
8. The owner plays every build and records approval, or requested changes, for movement feel and visuals. The owner's art for every Level 1 slot must have arrived for this approval; `CREDITS.md` shows any placeholder still in use.

#### M3 done when

- [ ] All unit tests pass in the editor, and all M1–M3 scenarios pass in all three exported builds.
- [ ] The frame-rate runs match, or their limits are recorded.
- [ ] The ledger has a row with evidence for every applicable criterion on every target; nothing is marked pass without evidence.
- [ ] The owner has approved movement feel and visuals, or the requested changes are logged and done.

---

### M4 — Platforms (feature package)

**Built when** the first level that uses state-dependent platforms is registered (see **How work is delivered**).

**Goal:** default-only and flow-only platforms with one-way support and the overlap policy, proven in the gym.

#### M4 files

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/core/overlap_policy.gd` | `class_name OverlapPolicy extends RefCounted`. Given the tiles of the newly solid family that the body overlaps, where the feet are relative to their tops, the vertical speed and whether the body fits above, returns `solid`, `snap` or `pending` | The P-04 decision in one testable place |
| `game/tests/unit/test_overlap_policy.gd` | Every branch, including the exact snap boundary | P-04 |
| `game/verification/scenarios/p01_state_matrix.json` … `p04_overlap_policy.json` | 4 files, listed below | P-01 to P-04 |

Files extended in M4:

| File | Change |
| --- | --- |
| `tiles.png` | Platform tile art, visually distinct by family in shape as well as color |
| `level_tiles.tres` | Platform tiles with `solidity` 2 (default-only) or 3 (flow-only) |
| `flow_controller.gd` | Applies the overlap policy on every switch |
| `player.gd` | Re-checks pending tiles every tick in step 7 |
| `solid_grid.gd` | Pending tiles: a set of cells that stay passable for the player until the body clears them |
| `flow_presentation.gd` | Draws the currently non-solid family at `inactive_platform_alpha` |
| `gym.tscn` | Platform stations |
| `debug_world_draw.gd` | Marks pending tiles |

#### How the overlap policy works

When a switch makes a platform family solid for the player:

1. **Find the overlapped tiles.** Ask `SolidGrid` which tiles of that family the player's body overlaps. If none, the family is solid now; log `platform_solid`.
2. **Snap when it's a landing.** Take every overlapped tile under the feet, across the body's full width. If the feet are no more than `overlap_snap_px` below the highest of their tops, vertical speed is zero or downward, **and the body fits** at the snapped position (no solid cell above), move the player up onto that top and log `overlap_snap` and `platform_solid`. This counts as a landing.
3. **Otherwise, those tiles wait.** Only the overlapped tiles become pending: they stay passable for the player while every other tile of the family is solid at once, so the player can never fall through a different platform. Log `platform_pending` with the tiles. Each tick in step 7, any pending tile the body no longer overlaps becomes solid (`platform_solid`).
4. **A switch back cancels** all pending tiles.

Nothing ever pushes the player sideways or down, so the policy cannot embed, teleport, crush or catapult (P-04).

Docs: [TileMapLayer](https://docs.godotengine.org/en/4.5/classes/class_tilemaplayer.html), [TileData](https://docs.godotengine.org/en/4.5/classes/class_tiledata.html).

#### Gym stations added in M4

| Entrance | Layout | Tests |
| --- | --- | --- |
| `platform_matrix` | Rows of default-only and flow-only platforms over a floor | P-01 |
| `platform_oneway` | Platforms to jump up through and walk off sideways, at heights that exercise the one-way platform help | P-02 and the one-way help |
| `platform_support` | A default-only platform over a pit, and a flow-only one over another | P-03 |
| `platform_overlap` | Platforms placed across jump arcs and dash lines, for switching while inside them | P-04 |

#### M4 scenario files

| Scenario file | What its cases prove |
| --- | --- |
| `p01_state_matrix.json` | Each cell: ordinary ground solid in both states; default-only holds in default, passes in flow; flow-only holds in flow, passes in default |
| `p02_one_way.json` | Rising through from below and crossing sideways never collide; no wall jump off a platform's side; ordinary walls never change |
| `p03_support_change.json` | Switching on a default-only platform: the player falls, with coyote time. Switch and jump on the same tick there: a coyote jump. Jump, then switch: the jump continues. The opposite family. Landings in midair after a switch |
| `p04_overlap_policy.json` | Rising, falling, edge and mid-dash switches: no position change larger than the snap distance; no snap under a low ceiling; a pending tile never lets the player through a different platform; pending tiles become solid once clear; never embedded |

#### M4 done when

- [ ] All unit tests and all M1–M4 scenarios pass.
- [ ] The two platform families are distinguishable by shape, not only color, in both states (owner review).

---

### M5 — Networks (feature package)

**Built when** the first level that uses a power network is registered.

**Goal:** power sources, networks of charged objects, recharging, and the same-tick tie rule, proven in the gym.

#### M5 files

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/objects/network/network.gd` | `class_name Network extends Node2D`, `@tool`. Its children are one `PowerRoot`, its member `ChargedObject`s and its `Wire`s. Holds `powered` (starts off) and `try_activate()`. Shows an editor warning unless it has exactly one root | One network = one node; membership is visible in the scene tree |
| `game/objects/power_root/power_root.tscn` | The power source (tree below) | Placed inside each network |
| `game/objects/power_root/power_root.gd` | `class_name PowerRoot extends Node2D`, `@tool`. Exports the art rectangle; its contact area is that rectangle grown by `root_contact_margin_px`; draws the area in the editor | Contact activation (N-01) |
| `game/art/objects/power_root.png` | The source's sprite (an A.C. unit fits the design notes) | Art |
| `game/art/objects/power_root_glow.png` | A faint hint in default; strong while unpowered in flow | "Hint which objects can become interactable" (design page 8) |
| `game/audio/sfx/network_activated.wav` | Activation | Feedback |
| `game/verification/scenarios/n01_contact_activation.json` … `n04_death_reset.json` | 4 files, listed below | N-01 to N-04 |

```text
Network           Node2D, network.gd
├── Root          PowerRoot (power_root.tscn)
│   ├── Sprite    Sprite2D, power_root.png
│   └── Glow      Sprite2D, power_root_glow.png, additive
├── <objects>     ChargedObject instances, always_powered off
└── <wires>       Wire nodes from the root to each object
```

The power source is not solid; if a room needs footing there, it paints ordinary tiles under it.

Files extended in M5:

| File | Change |
| --- | --- |
| `world.gd` | Step 8 calls `try_activate()` on every network |
| `wire.gd`, `wire_current.gdshader` | The activation pulse |
| `room.gd` | Networks lookup |
| `flow_presentation.gd` | Power-source hint glow |
| `sfx.gd` | Activation sound |
| `debug_world_draw.gd` | Contact areas and network membership |
| `gym.tscn` | Network stations |
| `s04_recharge_and_expiry.json` | Recharge and tie cases |
| scenario runner | Accepts `setup.countdown`, the remaining countdown ticks, so a recharge can be timed onto the expiry tick |

#### How activation works (step 8)

For each network in the room, in node-name order (**Same-tick contract**): if the player is in flow, the network is unpowered, and the player's body overlaps the root's contact area, then the network activates. If several activate on the same tick, each powers its own members and logs its own `network_activated`, but the player is recharged only once (one `volts` event if the count changed, one `countdown_cancel` if it was running). For each activation:

- **Power:** the network and every member become powered.
- **Recharge:** `FlowController` recharges: volts to `max_volts`, countdown cancelled (once per tick, however many networks activated).
- **Pulse:** the wires play a pulse from the root outward.
- **Log:** `network_activated`, plus a `volts` event if the count changed.

Because this checks a condition every tick rather than waiting for an "entered" event, walking, jumping, falling, dashing and switching into flow while touching all activate it the same way (N-01). A powered network never activates again, so touching it again never recharges (N-03). Network power lives in the room instance and resets when the room is rebuilt (N-04). Level 1's always-powered object belongs to no network and is never affected.

Step 8 runs before step 9, so a recharge on the same tick as an expiry always wins (S-04).

#### Gym stations added in M5

| Entrance | Layout | Tests |
| --- | --- | --- |
| `network_pit` | A root on the near side of a wide pit; three member objects across it | The design's canonical pit crossing |
| `network_pair` | Two separate networks side by side | N-02: activating one leaves the other unchanged |
| `network_approaches` | A root reachable by walking, by falling onto it, by jumping up to it, and along a dash lane | N-01 |
| `zero_volt_recovery` | Start at 1 volt; a crossing that spends it; a root beyond | S-04 recharge and the tie case |

#### M5 scenario files

| Scenario file | What its cases prove |
| --- | --- |
| `n01_contact_activation.json` | Default contact: no activation. Flow contact by walking, jumping, falling and dashing: activation. Switching to flow while overlapping: activation on that tick |
| `n02_activation_effects.json` | Members powered; volts 3; countdown cancelled; the other network unchanged |
| `n03_no_recharge_farming.json` | Touching a powered root again gives no volts (a room re-entry case is added in M6) |
| `n04_death_reset.json` | After a death, the network is unpowered again; Level 1's object stays powered across deaths |

`s04_recharge_and_expiry.json` gains cases where a recharge cancels the countdown, and where recharge and expiry fall on the same tick and the player lives.

#### M5 done when

- [ ] All unit tests and all M1–M5 scenarios pass.
- [ ] From the HUD and visuals alone, a playtester can say which objects a power source controls and what activating it changed (owner review).

---

### M6 — Rooms and progress (feature package)

**Built when** the first level with more than one room, or with a collectible, is registered.

**Goal:** crossings between neighboring rooms with a camera slide, checkpoints, collectibles and session progress, proven with a second verification room.

#### M6 files

| File | What it is | Why it exists |
| --- | --- | --- |
| `game/autoload/game_state.gd` | Autoload named `GameState`, third in the autoload list. Committed collectible IDs, permanent unlock flags and the completion flag, kept in memory for the session. Nothing is written to disk (saving is parked) | Permanent progress, kept apart from temporary electricity (G-02) |
| `game/rooms/room_info.gd` | `class_name RoomInfo extends Resource`: entry state and assumed volts per entrance, volt budget, recharge points, completion route, notes. Saved inside each room scene | The G-03 record, shown in the debug overlay and copied into the ledger |
| `game/objects/collectible/collectible.tscn` | A `Node2D` with a sprite | Placed in rooms |
| `game/objects/collectible/collectible.gd` | `class_name Collectible extends Node2D`. ID is room ID plus node name; idle or following; hides itself if already committed | The commitment rule (below) |
| `game/art/objects/collectible.png` | Collectible sprite | Art |
| `game/audio/sfx/collectible_touch.wav` | Touched | Feedback |
| `game/audio/sfx/collectible_commit.wav` | Committed | Feedback |
| `game/verification/gym/gym_annex.tscn` | A second verification room placed on the map directly right of the gym, with entrances beside the shared edge, a network near that edge and a collectible station | Crossings, re-entry and progress can be tested without owner rooms |
| `game/rooms/world_map_preview.tscn` | An editor-only scene with one `Node2D` running `world_map_preview.gd`. Excluded from exports | Lets the owner see the whole world map at once, the way Celeste's map view does |
| `game/rooms/world_map_preview.gd` | `@tool`. In the editor, builds every catalog room at its `world_rect` (never saved into the scene) and draws each room's outline, its ID and every shared opening | Laying out and checking the map without playing |
| `game/tests/unit/test_world_layout.gd` | Checks the catalog: unique IDs; each scene's `room_id` matches its record; positions and sizes are multiples of 16; sizes are at least 640 × 368; no overlaps; the start room and entrance exist; every shared edge has an entrance within 48 px (3 tiles) on both sides; every entrance keeps the whole body inside its room's bounds, so a respawn can never trigger a crossing | Layout mistakes are caught before anyone plays |
| `game/verification/scenarios/g01_transitions.json` | Listed below | G-01 |
| `game/verification/scenarios/g02_permanent_progress.json` | Listed below | G-02 |

Files extended in M6:

| File | Change |
| --- | --- |
| `project.godot` | Adds the `GameState` autoload |
| `world.gd` | Crossings and checkpoints (below) |
| `camera_rig.gd` | The slide between rooms |
| `room.gd` | Exposes its `RoomInfo` |
| `room_catalog.tres` | Adds `gym_annex` beside `gym` |
| `gym.tscn` | An opening in its right wall where it meets the annex, with an entrance beside it |
| `debug_world_draw.gd`, `debug_overlay.gd` | Shared openings and room info |
| `sfx.gd` | Collectible sounds |
| `n03_no_recharge_farming.json` | Re-entry case |

#### How crossings work

This implements "How rooms connect" from earlier in this document.

**Detecting a crossing (step 7).** When the center of the player's body leaves the current room's bounds, ask the catalog which room contains that point:

- **Another room:** a crossing begins at step 10.
- **No room, side or top edge:** the edge is a wall (the M1 rule).
- **No room, bottom edge:** the failure line applies.

Step 10's fixed order applies: deaths are checked before a crossing, so if the countdown expires on the tick the player crosses, the player dies. Until a crossing begins, cells beyond an opening are open to the mover; once the neighbor is built, `SolidGrid` holds both rooms' cells for the length of the crossing.

**The crossing (`World`'s Transition state):**

1. Log `transition_start`. Stop running the rules and stop the tick: the player, every gameplay timer, press windows and the countdown are frozen. Gameplay presses made during the slide are discarded; held buttons are read fresh when the rules resume, with no stale marking, so a jump held through the crossing keeps its sustain.
2. Commit any collectible the player is carrying (they are leaving its room).
3. Build the neighbor at its `world_rect` under `RoomSlot`, beside the current room.
4. Slide the camera over `room_transition_s`: clear the camera limits, tween from the old room's clamped view to the new room's clamped view, then set the new room's limits. The tween is visual only.
5. Free the old room.
6. Choose the new checkpoint: among the new room's entrances within 48 px of the edge actually crossed (the layout test guarantees at least one), the one nearest the player's feet; ties go to the lowest `entrance_id`. Log `room_enter` and `transition_end` (on the same tick as `transition_start`), then resume the rules.

**What carries across:** all player state carries over unchanged: position, velocity, sub-pixel remainders, state, volts, any countdown, press tokens and their remaining windows, coyote ticks, sustain, soft apex, wall-jump lock, dash state and cooldown, and a carried collectible. Movement continues as if the crossing took no time. Physics interpolation is not reset, because the player has not teleported.

**Checkpoints and deaths:** a death rebuilds only the current room, at its place on the map, and respawns the player at the checkpoint entrance (R-01).

**Re-entry:** leaving a room frees it, so coming back builds it fresh: its networks are off and can recharge the player once more. This is the documented reset scope for N-03.

**Performance:** every room scene is loaded with the catalog at startup, so a crossing only instances a scene that is already in memory. Measure crossings in the performance check (D-06).

#### Collectibles

1. **Touching** a collectible (body overlap, step 7) sets it following the player and logs `touched`.
2. **Committing:** checked in step 10, after the death checks. It commits on a tick the player is grounded and did not die, including the tick it was touched, or at the start of a crossing out of its room. `GameState` records it and `committed` is logged. A death while carrying it means it is lost, even if the player was grounded on that tick.
3. **Losing:** dying before that logs `lost`. The rebuilt room shows the collectible again.
4. **Already committed:** a committed collectible hides itself whenever its room is built.

Progress lasts for the session only; closing the app starts a new game. This answers G-02's separate choice and is recorded in the decision log.

#### M6 scenario files

| Scenario file | What its cases prove |
| --- | --- |
| `g01_transitions.json` | Gym → annex → gym across the shared edge in both directions; exactly one `transition_start` and `transition_end` each way; a death after crossing respawns at the annex entrance nearest the crossing; position, velocity, state, volts and countdown carry across; side and top edges with no neighbor stop the player; the annex network recharges again after re-entry; a countdown expiring on the crossing tick kills before crossing |
| `g02_permanent_progress.json` | Touch then die: lost, and it reappears. Touch then land: committed, and gone after a death and after re-entry. Touch then leave the room: committed |

#### M6 done when

- [ ] All unit tests and all M1–M6 scenarios pass.
- [ ] Every gym–annex passage works in both directions, after a death, and at 0 and 1 volts.
- [ ] The camera slide shows both rooms, with no gap, seam or flicker, on all three targets.
- [ ] `test_world_layout.gd` passes and the world map preview shows the layout correctly.

---

### M7 — Adding a level

**Goal:** add each level the owner supplies, one at a time, each with its own gate. This plan does not invent levels, rooms, room counts or the ending. Each mockup is used as **How mockups are used** describes: it decides the elements and their relationships, while geometry follows the tuned movement and art comes from the owner.

**When the owner supplies a level:**

1. **Register it.** Add a row to the Levels table (**How work is delivered**). Save its mockups as `docs/reference/mockups/<level>_<name>.png`.
2. **Discuss its features with the owner** and write the outcome into this document before building:
    - which feature packages (M4–M6) it claims;
    - any new feature it needs. A new feature is written up as a new feature package first, or goes to the Parked list if it is not in scope.
3. **Add a level section** below, `#### Level N — <name>`, holding:
    - its rooms (rows in the Rooms table);
    - the packages it claims and any new files, listed with their reasons;
    - the criteria that become applicable at its gate;
    - its gate checklist: those criteria and every route scenario for its rooms pass, with evidence, on all three targets, and the owner approves.
4. **Build** the claimed packages that do not exist yet, then the level's rooms.

**For each room in the level:**

1. **Register it.** Add a row to the Rooms table below. Any new art file the room needs is listed here before it is created.
2. **Place it on the world map.** Agree its position with the owner and add its `RoomEntry` to `room_catalog.tres`. Check it in the world map preview; `test_world_layout.gd` must still pass.
3. **Build the scene** `game/rooms/<room_id>/<room_id>.tscn` following the room scene convention, with its `RoomInfo` filled in and an entrance beside every shared opening.
4. **Write the route.** Create `game/verification/scenarios/route_<room_id>.json`. Its cases play from each entrance to each opening or goal under the room's intended entry state and volts.
5. **Record evidence:** the G-03 row in the ledger and a short video of the route.

| File per room | Why it exists |
| --- | --- |
| `game/rooms/<room_id>/<room_id>.tscn` | The room |
| `game/verification/scenarios/route_<room_id>.json` | Proves the room can be completed as designed (G-03, G-04) |

**Level goals and the final room** (owner decision 2026-10-16). When a level after Level 1 is registered, the previous level's goal becomes an opening into the new level's first room on the world map, with the level-complete banner from M3. `goal_zone.gd` gains two exports in this milestone: `banner_level` (shows the banner and logs `goal_banner` without stopping play) and `completes_game` (only on the final room's goal; calls `GameState.mark_completed()` and shows the completion overlay with the game's ending message). The banner's duration becomes the tuning value `level_banner_s` (1.5 s) at that point.

**Rooms table** (filled as mockups arrive):

| Room ID | Mockup | Systems it introduces | Place on the map (`world_rect`) | Neighbors | Entrances | Goal |
| --- | --- | --- | --- | --- | --- | --- |
| `level_1` | Design document page 2 (concept only) | Charged jump | (0, 0, 640, 368) | None yet | `start` | Yes |

---

### M8 — Reset and backtracking sweep (final gate)

**Runs** once the owner declares the level list complete. Each level gate already checks its own passages; this sweep checks the whole world together.

**Goal:** prove no player can be trapped (G-01). No new files.

For every passage between rooms, in both directions, add cases to the relevant `route_<room_id>.json`:

- entering with 1, 2 and 3 volts in each state, plus 0 volts in flow (0 volts in default is certain death by design, level design rule 1)
- entering after a death
- reaching each room's power sources from the side used when backtracking

Every case must end in a valid route, a recovery, or a clean retry. Any trap is a blocker and is fixed before M9.

---

### M9 — Evidence package (final gate)

**Goal:** one complete submission that meets the AC's final gate. No new files.

1. **Freeze the content:** the owner-approved room list and completion condition are recorded in this document.
2. **Build:** run `tools/run_tests.sh`, then `tools/export_all.sh` from a clean commit.
3. **Test every build:**
    1. Run every scenario inside each exported build: the forced 30/60/120 FPS runs on desktop, and the browser's own rate on the web. Compare targets within one-tick tolerance.
    2. Play a fresh-start completion on each target, with deaths along the way.
    3. Record performance: hardware, resolution, frame rate, frame times, any stalls (D-06).
    4. Check window resize, fullscreen, focus, pause, audio and controls on each target (D-07).
4. **Complete the documents:**
    - `docs/evidence/ledger.csv`: a row with evidence for every criterion on every target.
    - `docs/decision_log.md`: every developer-owned choice from AC page 9, with values, reasons and tests.
    - `docs/known_issues.md`, `docs/support_matrix.md`, `README.md`, `CREDITS.md`.
5. **Upload to itch.io** (M0 step 10) and play the uploaded web build on the itch.io page.
6. **Submit once,** with nothing unexplained. Missing evidence counts as a fail, and a known blocker is still a blocker.

#### Whole-game done when (the AC final gate)

- [ ] An owner-approved room list and completion condition exist.
- [ ] Every required room and every applicable criterion passes, with evidence, on macOS, Windows and the web.
- [ ] Fresh-start completion, resets and backtracking pass on every target.
- [ ] No blockers remain.
- [ ] The owner has explicitly approved movement feel and visual quality.
