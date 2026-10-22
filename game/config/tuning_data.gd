# Every tunable number in the game, as typed fields; the one instance is config/tuning.tres.
# Values live only in the .tres (ground rules 4 and 9); this script holds names and types.
# Serves AC M-05, M-06, S-03 (fixed values) and every movement and flow criterion that reads tuning.
class_name TuningData
extends Resource

## What the zero-volt countdown does after the player leaves flow (open decision OD-1).
enum CountdownMode { CONTINUE, PAUSE, STOP }

@export_group("Body and run")
@export var body_size_px: Vector2i
@export var run_max_speed_px_s: float
@export var run_accel_px_s2: float
@export var run_reduce_px_s2: float

@export_group("Air and jump")
@export var air_control_mult: float
@export var gravity_px_s2: float
@export var max_fall_speed_px_s: float
@export var apex_gravity_mult: float
@export var apex_threshold_px_s: float
@export var jump_speed_px_s: float
@export var jump_h_boost_px_s: float
@export var jump_sustain_s: float
@export var coyote_s: float
@export var jump_buffer_s: float

@export_group("Wall")
@export var wall_check_px: int
@export var wall_jump_h_speed_px_s: float
@export var wall_jump_lock_s: float

@export_group("Assists")
@export var corner_correction_px: int
@export var dash_corner_correction_px: int
@export var oneway_assist_px: int
@export var post_dash_snap_px: int

@export_group("Dash")
@export var dash_speed_px_s: float
@export var dash_end_speed_px_s: float
@export var dash_end_up_mult: float
@export var dash_s: float
@export var dash_cooldown_s: float
@export var dash_buffer_s: float

@export_group("Charged objects")
@export var charged_refill_clears_cooldown: bool
@export var charged_launch_speed_px_s: float
@export var charged_region_radius_px: int
@export var charged_exit_margin_px: int
@export var root_contact_margin_px: int
@export var overlap_snap_px: int
@export var spike_depth_px: int
@export var spike_inset_px: int

@export_group("Flow and volts")
@export var max_volts: int
@export var countdown_s: float
@export var countdown_in_default: CountdownMode = CountdownMode.CONTINUE
@export var allow_flow_entry_at_zero: bool

@export_group("Death and rooms")
@export var death_freeze_s: float
@export var respawn_s: float
@export var room_transition_s: float
@export var fall_margin_px: int

@export_group("Visuals")
@export var flow_backdrop_color: Color
@export var flow_fade_s: float
@export var inactive_platform_alpha: float
@export var glow_hint_alpha: float
@export var coin_counter_s: float

@export_group("Input")
@export var stick_deadzone: float

@export_group("Audio")
@export var music_volume: float

@export_group("Trace")
@export var trace_memory_limit: int
