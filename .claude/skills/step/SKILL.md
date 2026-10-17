---
description: Implement exactly one numbered step of docs/TRI10NWARE.md, following the project's session protocol
argument-hint: <milestone.step, e.g. M0.4 or M1.2>
disable-model-invocation: true
---

You are a fresh session implementing step **$ARGUMENTS** of the TRI10NWARE spec. You have no memory of earlier sessions; the repository is your memory.

## 1. Orient

- Read `CLAUDE.md` and follow its "Start of every session" reading order.
- Find step $ARGUMENTS in `docs/TRI10NWARE.md`. "M0.4" means "M0 step 4"; "M1.2" means step 2 of the "M1 build order". Read that step in full, and every section it names. Do not read the whole spec.
- Check `git status`. If there are uncommitted changes you did not expect, stop and ask the owner before doing anything.
- If the Status block in `docs/build_journal.md` says this step is blocked or waiting on the owner, stop and say so.

## 2. Plan

Present a short plan before changing anything:

- the files you will create or extend, each with the spec line that lists it (a code file the spec does not list means **stop and ask**);
- what the step must make true, and the tests or scenarios that prove it;
- any ambiguity, contradiction or decision outside your authority tier, as a question for the owner.

Wait for the owner's approval of the plan.

## 3. Implement

- Do only this step. Do not start the next one, and do not "improve" earlier steps unless this step requires it.
- Follow the ground rules, the determinism contract and the same-tick contract exactly.
- Never edit a `.tscn` the owner has open in the Godot editor; ask first.

## 4. Verify

- Run the import step and the unit tests (see `CLAUDE.md`). Once M1 step 8 exists, run the scenarios too.
- Check the diagnostics tool for GDScript errors in the files you touched.
- Fix failures. After two failed attempts at the same failure, stop and explain it to the owner instead of guessing.

## 5. Explain

Append an entry to `docs/build_journal.md` using its entry template:

- **What was built:** every file created or changed.
- **How it works:** plain language, a few short paragraphs, written for the owner, who wants to understand the code, not just use it.
- **Why:** the spec sections and acceptance criteria it serves.
- **How to see it:** what to run or look at in Godot, if anything.
- **Decisions and questions:** every "decide and log" choice, and every open question.

Then update the Status block: last completed step, next step, waiting on owner, open questions.

## 6. Log

Record each "decide and log" choice in `docs/decision_log.md`. Before M0 step 11 creates it, the journal entry is the record.

## 7. Commit

Stage only the files this step touched (never `git add -A`) and commit as `M<n> step <k>: <title>`. Do not push.

## 8. Finish

End with a short message: what was built, what to look at in Godot, the next step's name, and anything the owner must do before it (paint tiles, supply art, answer a question).
