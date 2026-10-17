class_name Player
extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const DASH_VELOCITY = 200.0
const DASH_DURATION = 0.4
const MAX_JUMPS = 1

var curr_state = "default"
var direction

var is_dashing = false
var jumps_left = 0
var dash_timer = 0.0

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Update dash timer.
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Assign jumps_left with MAX_JUMPS.
	if is_on_floor():
		jumps_left = MAX_JUMPS
		
	# Handle state switch
	handle_state_switch()

	# Handle jump.
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		
	# Handle roll.
	if Input.is_action_just_pressed("dash") and is_on_floor() and not is_dashing:
		is_dashing = true
		dash_timer = DASH_DURATION
		var dash_direction = -1 if animated_sprite.flip_h else 1
		velocity.x = dash_direction * DASH_VELOCITY
		animated_sprite.play(curr_state + "_dash")
	
	# Skip regular movement if rolling.
	if is_dashing:
		move_and_slide()
		return

	# Get the input direction and handle the movement/deceleration.
	direction = Input.get_axis("left", "right")
	
	# Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true 
		
	if is_on_floor():
		if direction == 0:
			animated_sprite.play(curr_state + "_idle")
		else:
			animated_sprite.play(curr_state + "_run")
	else: 
		animated_sprite.play(curr_state + "_jump")
	
	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
func handle_state_switch() -> void:
	if Input.is_action_just_pressed("switch"):
		if curr_state == "default":
			# Activate a signal that triggers an activation animation
			# Connect to CanvasLayer --> toggle visibility to dim background?
			curr_state = "electric"
		
		elif curr_state == "electric":
			# reverse signal 
			curr_state = "default"
