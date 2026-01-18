extends CharacterBody2D

@onready var animator = $sprite
@onready var hurtbox_animator = $AnimationPlayer
@onready var input_buffer = $"/root/InputProcessor"

enum state {idle, attacking, stunned}
var current_state
var facing_right = true

var jump_force = 300
var gravity = 400
var gravity_acceleration = 20
var jump_time = 0.2
var jumping = false
var jump_timer = 0

#Physic variables
var friction = 10
var ground_speed = 80
var ground_speed_multiplier = 1
var ground_acceleration = 20

#Frame data
#var jump_squat = 0.5 (now changed through animation)

func _ready() -> void:
	input_buffer.connect("acted", Act)
	current_state = state.idle
	
func _physics_process(_delta: float) -> void:
	var h_direction = Input.get_axis("left", "right")
	var raw_h_direction = sign(h_direction)
	
	velocity.x = move_toward(velocity.x, 0, friction)
	velocity.x = move_toward(velocity.x, ground_speed * ground_speed_multiplier * raw_h_direction, ground_acceleration)
	
	if is_on_floor():
		if h_direction == 0 and current_state == state.idle and animator.animation != "idle":
			animator.play("idle")
		if h_direction != 0 and current_state == state.idle:
			animator.play("crawl")

	if jumping:
		jump_timer += _delta
		#if jump_timer < jump_time:
			#velocity.y = -jump_force
			
		if Input.is_action_just_released("jump") or jump_timer >= jump_time:
			jumping = false
			jump_timer = 0
			
	if not jumping:
		velocity.y = move_toward(velocity.y, gravity, gravity_acceleration)
	
	if not is_on_floor():
		if velocity.y >= 0 and current_state == state.idle:
			pass
			#animator.play("fall")
		
	if current_state == state.idle:
		if facing_right and h_direction < 0:
			flip()
		if !facing_right and h_direction > 0:
			flip()
			
	move_and_slide()

func Act(move: String, direction: Vector2):
	if move == "jump" and current_state == state.idle:
		if is_on_floor():
			if Input.is_action_pressed("jump"):
				velocity.y = -jump_force
				jumping = true
			
	if move != "jump":
		if facing_right and direction.x < 0:
			flip()
		elif not facing_right and direction.x > 0:
			flip()
			
	if move == "attack":
		current_state = state.attacking
		input_buffer.actionable = false
		animator.play("bite")

func _on_animated_sprite_2d_frame_changed() -> void:
	if animator == null: return
	var current_frame = animator.frame
	match animator.animation: #active frames
		"bite":
			if current_frame == 3:
				pass
		
func flip():
	scale.x *= -1
	facing_right = !facing_right

func _on_animated_sprite_2d_animation_finished() -> void:
	if current_state == state.attacking:
		current_state = state.idle
		input_buffer.actionable = true
		
func Hit():
	Attack_Cancel()
	
func Attack_Cancel():
	input_buffer.actionable = true
	current_state = state.idle
