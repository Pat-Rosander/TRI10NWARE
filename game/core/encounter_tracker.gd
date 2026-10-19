# One charged object's encounter state: outside, armed or spent, moved by two overlap tests in
# step 7 and spent by a charged jump in step 4. Gives one charged jump per visit.
# Serves AC C-03, C-04.
class_name EncounterTracker
extends RefCounted

enum State { OUTSIDE, ARMED, SPENT }

const STATE_NAMES: Array[String] = ["outside", "armed", "spent"]

var state: State = State.OUTSIDE


## Step 7. [param entry]: the region overlaps the body. [param still_inside]: the same test with
## the radius grown by charged_exit_margin_px. Outside becomes armed on entry; armed or spent
## becomes outside when no longer inside; otherwise nothing changes. Returns true if the state
## changed (the caller logs encounter).
func update(entry: bool, still_inside: bool) -> bool:
	var before: State = state
	if state == State.OUTSIDE:
		if entry:
			state = State.ARMED
	elif not still_inside:
		state = State.OUTSIDE
	return state != before


## Step 4, on a charged jump: armed becomes spent. Returns true if it was armed.
func spend() -> bool:
	if state != State.ARMED:
		return false
	state = State.SPENT
	return true


## True if this object can give a charged jump now (if it is also powered).
func is_armed() -> bool:
	return state == State.ARMED


## Back to outside, for a respawn or a rebuilt room.
func reset() -> void:
	state = State.OUTSIDE


## The trace name of [param s]: outside, armed or spent.
static func state_name(s: State) -> String:
	return STATE_NAMES[s]
