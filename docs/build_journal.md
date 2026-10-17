# TRI10NWARE build journal

Every step of the build adds an entry here, newest at the bottom. The Status block below is updated at the end of every step; it is the first thing each new session reads.

## Status

- **Last completed:** M0 prep (workflow files, spec and references in the repository), 2026-10-17.
- **Next step:** M0 step 1, migrate the existing repository (`/step M0.1`).
- **Waiting on the owner:**
    - Commit or discard the prototype's uncommitted edits (`levels/level_1.tscn`, `player/player.gd`, `project.godot`) before M0 step 1. That step tags `prototype-v0` and then deletes those files.
    - M0 step 0 prerequisites:
        - Godot 4.5.1 is installed at `/Applications/Godot 4.5.1 .app` (confirmed).
        - Still needed: the 4.5.1 export templates, the macOS bundle identifier, the itch.io project page, and access to a Windows PC.
    - Before M1 step 2: accept or replace the three proposed answers under "Decide before step 2" in the M1 build order.
- **Open questions:** none.

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
