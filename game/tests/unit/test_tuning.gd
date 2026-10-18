# Tests the Tuning autoload: seconds-to-ticks conversion, every derived tick value, and every
# field of tuning.tres against its start value in the spec's M0 step 4 table. Serves AC M-05, M-06, S-03, D-05.
extends TestCase

## Every TuningData field with its start value and type from the M0 step 4 table. A field
## missing from tuning.tres loads as 0 and fails here by name.
const EXPECTED: Dictionary[String, Variant] = {
	"body_size_px": Vector2i(12, 15),
	"run_max_speed_px_s": 180.0,
	"run_accel_px_s2": 2000.0,
	"run_reduce_px_s2": 800.0,
	"air_control_mult": 0.65,
	"gravity_px_s2": 1800.0,
	"max_fall_speed_px_s": 320.0,
	"apex_gravity_mult": 0.5,
	"apex_threshold_px_s": 80.0,
	"jump_speed_px_s": 210.0,
	"jump_h_boost_px_s": 80.0,
	"jump_sustain_s": 0.2,
	"coyote_s": 0.1,
	"jump_buffer_s": 0.1,
	"wall_check_px": 6,
	"wall_jump_h_speed_px_s": 260.0,
	"wall_jump_lock_s": 0.16,
	"corner_correction_px": 8,
	"dash_corner_correction_px": 8,
	"oneway_assist_px": 8,
	"post_dash_snap_px": 6,
	"dash_speed_px_s": 480.0,
	"dash_end_speed_px_s": 320.0,
	"dash_end_up_mult": 0.75,
	"dash_s": 0.15,
	"dash_cooldown_s": 0.2,
	"dash_buffer_s": 0.1,
	"charged_refill_clears_cooldown": true,
	"charged_launch_speed_px_s": 440.0,
	"charged_region_radius_px": 64,
	"charged_exit_margin_px": 1,
	"root_contact_margin_px": 4,
	"overlap_snap_px": 6,
	"max_volts": 3,
	"countdown_s": 3.0,
	"countdown_in_default": TuningData.CountdownMode.CONTINUE,
	"allow_flow_entry_at_zero": false,
	"death_freeze_s": 0.35,
	"respawn_s": 0.25,
	"room_transition_s": 0.3,
	"fall_margin_px": 32,
	"flow_backdrop_color": Color(0.55, 0.5, 0.7, 1.0),
	"flow_fade_s": 0.15,
	"inactive_platform_alpha": 0.35,
	"stick_deadzone": 0.2,
	"trace_memory_limit": 100000,
}

## Each derived tick value: roundi(seconds × 60) of its field.
const EXPECTED_TICKS: Dictionary[String, int] = {
	"jump_sustain_ticks": 12,
	"coyote_ticks": 6,
	"jump_buffer_ticks": 6,
	"wall_jump_lock_ticks": 10,
	"dash_ticks": 9,
	"dash_cooldown_ticks": 12,
	"dash_buffer_ticks": 6,
	"countdown_ticks": 180,
	"death_freeze_ticks": 21,
	"respawn_ticks": 15,
	"room_transition_ticks": 18,
	"flow_fade_ticks": 9,
}


func test_tuning_is_first_autoload() -> void:
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	assert_eq(String(root.get_child(0).name), "Tuning")


func test_data_is_loaded() -> void:
	assert_true(Tuning.data is TuningData, "Tuning.data is a TuningData")


func test_seconds_to_ticks() -> void:
	assert_eq(Tuning.seconds_to_ticks(0.1), 6, "0.1 s")
	assert_eq(Tuning.seconds_to_ticks(3.0), 180, "3.0 s")
	assert_eq(Tuning.seconds_to_ticks(0.15), 9, "0.15 s")


func test_derived_ticks() -> void:
	for property: String in EXPECTED_TICKS:
		assert_eq(Tuning.get(property), EXPECTED_TICKS[property], property)


func test_every_field_has_its_start_value() -> void:
	for field: String in EXPECTED:
		assert_eq(Tuning.data.get(field), EXPECTED[field], field)


func test_no_unlisted_fields() -> void:
	var stored: int = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE
	var fields: Array[String] = []
	for property: Dictionary in Tuning.data.get_property_list():
		var usage: int = property["usage"]
		if usage & stored == stored:
			fields.append(property["name"])
	for field: String in fields:
		assert_true(EXPECTED.has(field), "field %s is in the step 4 table" % field)
	assert_eq(fields.size(), EXPECTED.size(), "field count")
