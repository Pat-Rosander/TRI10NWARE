# Sound feedback: plays the sound for each Trace event that has one, through a small pool of
# AudioStreamPlayers on the SFX bus, and the countdown tick each time the HUD's shown second
# changes; room_complete sounds only for a completed game, never for a level's goal. It only
# listens and reads, so no rule depends on it. Serves AC V-04.
extends Node

## Emitted each time a sound starts, with its slot name. Tests listen to it.
signal sound_played(slot: StringName)

const HudScript := preload("res://ui/hud.gd")

## How many sounds can play at once; the oldest is cut off when all are busy (decision log, M3.5).
const POOL_SIZE: int = 8
const BUS: StringName = &"SFX"
## One stream per sound slot (spec, M3 and M6 files).
const STREAMS: Dictionary = {
	&"jump": preload("res://audio/sfx/jump.wav"),
	&"charged_jump": preload("res://audio/sfx/charged_jump.wav"),
	&"dash": preload("res://audio/sfx/dash.wav"),
	&"charged_dash": preload("res://audio/sfx/charged_dash.wav"),
	&"switch_to_flow": preload("res://audio/sfx/switch_to_flow.wav"),
	&"switch_to_default": preload("res://audio/sfx/switch_to_default.wav"),
	&"switch_refused": preload("res://audio/sfx/switch_refused.wav"),
	&"countdown_tick": preload("res://audio/sfx/countdown_tick.wav"),
	&"death": preload("res://audio/sfx/death.wav"),
	&"respawn": preload("res://audio/sfx/respawn.wav"),
	&"room_complete": preload("res://audio/sfx/room_complete.wav"),
	&"collectible_touch": preload("res://audio/sfx/collectible_touch.wav"),
	&"collectible_commit": preload("res://audio/sfx/collectible_commit.wav"),
}

@export var player: Player

var _pool: Array[AudioStreamPlayer] = []
# The pool index used next: always the player that started longest ago.
var _next: int = 0
# True when the latest dash_refill since the last dash, respawn or room_enter had cause `charged`.
var _charged_refill: bool = false
# The countdown second last heard; 0 while no countdown shows.
var _shown_second: int = 0


func _ready() -> void:
	for i: int in POOL_SIZE:
		var sound: AudioStreamPlayer = AudioStreamPlayer.new()
		sound.bus = BUS
		add_child(sound)
		_pool.append(sound)
	Trace.event_logged.connect(_on_event_logged)


## Plays the sound in [param slot] on the next pool player.
func play(slot: StringName) -> void:
	var sound: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	sound.stream = STREAMS[slot]
	sound.play()
	sound_played.emit(slot)


# Reads the countdown the HUD shows and ticks once for each new whole second (3, 2, 1).
func _process(_delta: float) -> void:
	if player == null or player.flow == null or player.flow.ledger == null:
		return
	var shown: int = HudScript.countdown_seconds(player.flow.ledger.countdown_ticks_left,
			Engine.physics_ticks_per_second)
	if shown != _shown_second and shown > 0:
		play(&"countdown_tick")
	_shown_second = shown


func _on_event_logged(entry: Dictionary) -> void:
	var data: Dictionary = entry["data"]
	match entry["event"]:
		"jump":
			play(&"charged_jump" if data["kind"] == "charged" else &"jump")
		"dash_refill":
			_charged_refill = data["cause"] == "charged"
		"dash_start":
			play(&"charged_dash" if _charged_refill else &"dash")
			_charged_refill = false
		"switch":
			var to_flow: bool = data["to"] == FlowLedger.state_name(FlowLedger.State.FLOW)
			play(&"switch_to_flow" if to_flow else &"switch_to_default")
		"switch_refused", "death":
			play(StringName(entry["event"]))
		"room_complete":
			# Only the final goal sounds; a level's goal (M7 step 1) shows just the goal effect.
			if GameState.completed:
				play(&"room_complete")
		"respawn":
			# A respawn's fresh dash charge was not a charged refill.
			_charged_refill = false
			play(&"respawn")
		"room_enter":
			_charged_refill = false
		"collectible":
			# A lost collectible has no sound of its own: the death sound already plays.
			if data["change"] == "touched":
				play(&"collectible_touch")
			elif data["change"] == "committed":
				play(&"collectible_commit")
