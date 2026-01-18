extends CharacterBody2D

var device_id = 0 #make it so that device id is set in the game manager. have game manager change our device id

@onready var animator = $AnimatedSprite2D
@onready var hurtbox_animator = $Hurtbox/AnimationPlayer
@onready var input_buffer = $InputBuffer

class BufferedMove:
	var move: String
	var direction: Vector2
	var time: int
var move_to_buffer

enum state {idle, attacking, stunned, jumping, jabbing}
var current_state
var facing_right = true
var jumps_left
var sprinting = false
var keep_jabbing

#Physic variables
var dj_decay = 0.8
var fast_fall_speed = 180
var friction = 10
var jump_force = 500
var short_hop_force = 350
var double_jumps = 2
var jump_multiplier = 1
var ground_speed = 80
var sprint_speed = 250
var air_speed = 160
var ground_speed_multiplier = 1
var air_speed_multiplier = 1
var initial_dash_speed = 200
var gravity = 170
var ground_acceleration = 20
var air_acceleration = 20

var aerial_attacking = false

#Frame data
#var jump_squat = 0.5 (now changed through animation)

func _ready() -> void:
	$InputBuffer.connect("acted", Act)
	current_state = state.idle
	device_id = $InputBuffer.device_id
	jumps_left = double_jumps
	
func _physics_process(_delta: float) -> void:
	var h_direction = Input.get_axis("left_%s" % [device_id], "right_%s" % [device_id])
	var raw_h_direction = sign(h_direction)
	
	if sprinting and h_direction == 0:
		sprinting = false
	
	velocity.x = move_toward(velocity.x, 0, friction)
	
	if is_on_floor():
		if aerial_attacking:
			Attack_Cancel()
		
		jumps_left = double_jumps
		if h_direction == 0 and current_state == state.idle and animator.animation != "idle":
			animator.play("idle")
		if h_direction != 0 and current_state == state.idle:
			if not Input.is_action_pressed("sprint_%s" % [device_id]):
				animator.play("walk")
				velocity.x = move_toward(velocity.x, ground_speed * ground_speed_multiplier * raw_h_direction, ground_acceleration)
			if Input.is_action_pressed("sprint_%s" % [device_id]):
				if not sprinting:
					velocity.x += initial_dash_speed * raw_h_direction
					sprinting = true
				animator.play("run")
				velocity.x = move_toward(velocity.x, sprint_speed * ground_speed_multiplier * raw_h_direction, ground_acceleration)
	
	if not is_on_floor():
		if current_state == state.jumping:
			current_state = state.idle
			if move_to_buffer != null:
				Act(move_to_buffer.move, move_to_buffer.direction)
				move_to_buffer = null
		velocity.y = move_toward(velocity.y, gravity, 30)
		
		if velocity.y >= 0 and current_state == state.idle:
			animator.play("fall")
			
		if h_direction != 0:
			velocity.x = move_toward(velocity.x, air_speed * air_speed_multiplier * h_direction, air_acceleration)
		
	if Input.is_action_just_pressed("down_%s" % [device_id]):
		gravity += fast_fall_speed
	if Input.is_action_just_released("down_%s" % [device_id]):
		gravity -= fast_fall_speed
		
	if Input.is_action_just_released("light_%s" % [device_id]) and current_state == state.jabbing:
		keep_jabbing = true
		
	if current_state == state.idle:
		if facing_right and h_direction < 0:
			flip()
		if !facing_right and h_direction > 0:
			flip()
	
	if current_state == state.jumping:
		if is_on_floor():
			animator.play("jump")
			
	move_and_slide()

func Act(move: String, direction: Vector2):
	sprinting = false
	if current_state == state.jumping and move != "jump":
		move_to_buffer = BufferedMove.new()
		move_to_buffer.direction = direction
		move_to_buffer.move = move
		
	if move == "jump" and current_state == state.idle:
		if is_on_floor():
			current_state = state.jumping
			#input_buffer.actionable = false
		elif not is_on_floor() and jumps_left != 0:
			velocity.y = -jump_force * jump_multiplier * pow(dj_decay, double_jumps - jumps_left)
			jumps_left -= 1
			
	if move != "jump":
		if facing_right and direction.x < 0:
			flip()
		elif not facing_right and direction.x > 0:
			flip()
			
	if (move == "light" or move == "special") and not is_on_floor() and current_state == state.idle:
		aerial_attacking = true
			
	if move == "light" and current_state == state.idle:
		current_state = state.attacking
		input_buffer.actionable = false
		
		if (abs(direction.x) > abs(direction.y)) :
			if is_on_floor():
				animator.play("side_light")
			else:
				animator.play("side_air")
		
		if (abs(direction.x) <= direction.y) and direction.y != 0:
			if not is_on_floor():
				animator.play("up_air")
			else:
				animator.play("up_light")
				
		if (abs(direction.x) <= abs(direction.y)) and direction.y < 0:
			if not is_on_floor():
				animator.play("down_air")
			else:
				animator.play("down_light")
				
		if direction == Vector2.ZERO:
			if not is_on_floor():
				animator.play("neutral_air")
			else:
				animator.play("jab")
				current_state = state.jabbing

func _on_animated_sprite_2d_frame_changed() -> void:
	if animator == null: return
	var current_frame = animator.frame
	match animator.animation: #active frames
		"jump":
			if current_frame == 1:
				#input_buffer.actionable = true
				if Input.is_action_pressed("jump_%s" % [device_id]):
					velocity.y = -jump_force * jump_multiplier
				else:
					velocity.y = -short_hop_force * jump_multiplier
					
		"side_light":
			if current_frame == 1:
				pass
				
		"up_air":
			if current_frame == 0:
				pass
		"jab":
			if current_frame == 1:
				if keep_jabbing and Input.is_action_pressed("light_%s" % [device_id]):
					keep_jabbing = false
				else:
					Attack_Cancel()
		
func flip():
	scale.x *= -1
	facing_right = !facing_right

func _on_animated_sprite_2d_animation_finished() -> void:
	if current_state == state.attacking or current_state == state.jabbing:
		current_state = state.idle
		keep_jabbing = false
		input_buffer.actionable = true
		
func Hit():
	move_to_buffer = null
	
func Attack_Cancel():
	keep_jabbing = false
	input_buffer.actionable = true
	aerial_attacking = false
	current_state = state.idle
