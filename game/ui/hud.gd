# The HUD: volt pips, state icon, dash pip and the zero-volt countdown, read from the player every
# frame; the volt pips flash on switch_refused. A read-only view that never changes state.
# Serves AC V-03, V-04.
extends CanvasLayer

const VOLT_SHEET: Texture2D = preload("res://art/ui/volt_pip.png")
const DASH_SHEET: Texture2D = preload("res://art/ui/dash_pip.png")
const STATE_SHEET: Texture2D = preload("res://art/ui/state_icons.png")
## Frames per sheet, left to right: volt [full, empty], dash [available, spent],
## state [default, flow, warning at 0 volts in flow].
const VOLT_FRAMES: int = 2
const DASH_FRAMES: int = 2
const STATE_FRAMES: int = 3
const STATE_DEFAULT: int = 0
const STATE_FLOW: int = 1
const STATE_WARNING: int = 2
## The refusal flash: this many blinks over this many seconds of rendered time.
const FLASH_S: float = 0.4
const FLASH_BLINKS: int = 3
const FLASH_COLOR: Color = Color(1.0, 0.25, 0.25)

## The player whose state is shown.
@export var player: Player

var _volt_frames: Array[AtlasTexture] = []
var _dash_frames: Array[AtlasTexture] = []
var _state_frames: Array[AtlasTexture] = []
var _pips: Array[TextureRect] = []
var _flash_left_s: float = 0.0

@onready var _volt_pips: HBoxContainer = %VoltPips
@onready var _state_icon: TextureRect = %StateIcon
@onready var _dash_pip: TextureRect = %DashPip
@onready var _countdown: Control = %Countdown
@onready var _ring: TextureProgressBar = %Ring
@onready var _numerals: Label = %Numerals


func _ready() -> void:
	_volt_frames = _cut(VOLT_SHEET, VOLT_FRAMES)
	_dash_frames = _cut(DASH_SHEET, DASH_FRAMES)
	_state_frames = _cut(STATE_SHEET, STATE_FRAMES)
	for i: int in Tuning.data.max_volts:
		var pip: TextureRect = TextureRect.new()
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip.texture = _volt_frames[0]
		_volt_pips.add_child(pip)
		_pips.append(pip)
	_ring.max_value = Tuning.countdown_ticks
	Trace.event_logged.connect(_on_event_logged)


func _process(delta: float) -> void:
	if player == null or player.flow.ledger == null:
		return
	var ledger: FlowLedger = player.flow.ledger
	for i: int in _pips.size():
		_pips[i].texture = _volt_frames[0 if i < ledger.volts else 1]
	var in_flow: bool = ledger.state == FlowLedger.State.FLOW
	var frame: int = STATE_DEFAULT
	if in_flow:
		frame = STATE_WARNING if ledger.volts == 0 else STATE_FLOW
	_state_icon.texture = _state_frames[frame]
	_dash_pip.texture = _dash_frames[0 if player.dash.charges > 0 else 1]
	_show_countdown(ledger.countdown_ticks_left)
	_show_flash(delta)


## Cuts [param sheet] into [param count] equal frames, left to right.
static func _cut(sheet: Texture2D, count: int) -> Array[AtlasTexture]:
	var frames: Array[AtlasTexture] = []
	@warning_ignore("integer_division")
	var width: int = sheet.get_width() / count
	for i: int in count:
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(i * width, 0, width, sheet.get_height())
		frames.append(frame)
	return frames


## Whole seconds left, rounded up: 180 ticks shows 3, 1 tick shows 1.
static func countdown_seconds(ticks_left: int, ticks_per_second: int) -> int:
	@warning_ignore("integer_division")
	return (ticks_left + ticks_per_second - 1) / ticks_per_second


func _show_countdown(ticks_left: int) -> void:
	_countdown.visible = ticks_left > 0
	if ticks_left <= 0:
		return
	_ring.value = ticks_left
	_numerals.text = str(countdown_seconds(ticks_left, Engine.physics_ticks_per_second))


func _show_flash(delta: float) -> void:
	var color: Color = Color.WHITE
	if _flash_left_s > 0.0:
		var elapsed: float = FLASH_S - _flash_left_s
		var phase: int = int(elapsed / (FLASH_S / (FLASH_BLINKS * 2)))
		if phase % 2 == 0:
			color = FLASH_COLOR
		_flash_left_s = maxf(_flash_left_s - delta, 0.0)
	_volt_pips.modulate = color


func _on_event_logged(entry: Dictionary) -> void:
	if entry["event"] == "switch_refused":
		_flash_left_s = FLASH_S
