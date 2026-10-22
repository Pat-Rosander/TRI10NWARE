# Tuning autoload: loads config/tuning.tres and converts every time value to whole ticks, once.
# Gameplay code counts ticks, never seconds (ground rule 4). Serves AC M-05, M-06, S-03, D-05.
extends Node

const TICKS_PER_SECOND: int = 60
const DATA_PATH: String = "res://config/tuning.tres"

## The loaded tuning values, in their designer units (pixels, seconds).
var data: TuningData

var jump_sustain_ticks: int
var coyote_ticks: int
var jump_buffer_ticks: int
var wall_jump_lock_ticks: int
var dash_ticks: int
var dash_cooldown_ticks: int
var dash_buffer_ticks: int
var countdown_ticks: int
var death_freeze_ticks: int
var respawn_ticks: int
var room_transition_ticks: int
var flow_fade_ticks: int
var hint_ticks: int
var hint_fade_ticks: int
var level_banner_ticks: int


# Runs in _init, not _ready, so the values exist before any other autoload's _ready.
func _init() -> void:
	if Engine.physics_ticks_per_second != TICKS_PER_SECOND:
		push_error("Tuning: physics_ticks_per_second is %d, expected %d."
				% [Engine.physics_ticks_per_second, TICKS_PER_SECOND])
	data = load(DATA_PATH) as TuningData
	if data == null:
		push_error("Tuning: %s is missing or is not a TuningData." % DATA_PATH)
		return
	jump_sustain_ticks = seconds_to_ticks(data.jump_sustain_s)
	coyote_ticks = seconds_to_ticks(data.coyote_s)
	jump_buffer_ticks = seconds_to_ticks(data.jump_buffer_s)
	wall_jump_lock_ticks = seconds_to_ticks(data.wall_jump_lock_s)
	dash_ticks = seconds_to_ticks(data.dash_s)
	dash_cooldown_ticks = seconds_to_ticks(data.dash_cooldown_s)
	dash_buffer_ticks = seconds_to_ticks(data.dash_buffer_s)
	countdown_ticks = seconds_to_ticks(data.countdown_s)
	death_freeze_ticks = seconds_to_ticks(data.death_freeze_s)
	respawn_ticks = seconds_to_ticks(data.respawn_s)
	room_transition_ticks = seconds_to_ticks(data.room_transition_s)
	flow_fade_ticks = seconds_to_ticks(data.flow_fade_s)
	hint_ticks = seconds_to_ticks(data.hint_s)
	hint_fade_ticks = seconds_to_ticks(data.hint_fade_s)
	level_banner_ticks = seconds_to_ticks(data.level_banner_s)


## Converts a duration in seconds to the nearest whole number of 60 Hz ticks.
static func seconds_to_ticks(seconds: float) -> int:
	return roundi(seconds * TICKS_PER_SECOND)
