extends CharacterBody2D

@onready var animator = $sprite
@onready var hurtbox_animator = $AnimationPlayer
@onready var input_buffer = $"/root/InputProcessor"

var grapple = preload("res://projectile scenes/grapple.tscn")
var grapple_gina = preload("res://character scenes/grapple_gina.tscn")
var grappleable = true
var grappling = false
var editable_grapple

enum state {idle, attacking, stunned}
var current_state
var facing_right = true

var jump_force = 250
var gravity = 600
var gravity_acceleration = 30
var jump_time = 0.2
var jumping = false
var jump_timer = 0

var double_jumps = 1
var jumps_left = 1

var just_launched = false

#Physic variables
var friction = 20
var ground_speed = 120
var ground_speed_multiplier = 1
var ground_acceleration = 20
var max_speed

#Frame data
#var jump_squat = 0.5 (now changed through animation)

func _ready() -> void:
	input_buffer.connect("acted", Act)
	current_state = state.idle
	if max_speed != null and max_speed < ground_speed:
		max_speed = ground_speed
	
func _physics_process(_delta: float) -> void:
	var h_direction = Input.get_axis("left", "right")
	var raw_h_direction = sign(h_direction)
	
	if not just_launched and !h_direction:
		velocity.x = move_toward(velocity.x, 0, friction)
		
	if h_direction:
		velocity.x = move_toward(velocity.x, max_speed * ground_speed_multiplier * raw_h_direction, ground_acceleration)
	
	if is_on_floor():
		max_speed = ground_speed
		just_launched = false
		jumps_left = double_jumps
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
			animator.play("fall")
		if velocity.y < 0 and current_state == state.idle:
			if jumps_left == double_jumps:
				animator.play("jump")
			else:
				animator.play("double_jump")
		
	if current_state == state.idle:
		if facing_right and h_direction < 0:
			flip()
		if !facing_right and h_direction > 0:
			flip()
			
	if Input.is_action_pressed("grapple") and grappleable and not grappling:
		grappling = true
		grappleable = false
		await get_tree().process_frame
		var instance = grapple.instantiate()
		instance.player = self
		instance.rotation = global_position.angle_to_point(get_global_mouse_position())
		instance.global_position = global_position
		get_tree().current_scene.add_child(instance)
		editable_grapple = instance
		
	if Input.is_action_just_released("grapple") and grappling:
		editable_grapple.going_back = true
			
	move_and_slide()

func Act(move: String, direction: Vector2):
	if move == "jump" and current_state == state.idle:
		if is_on_floor() or jumps_left > 0:
			velocity.y = -jump_force
			jumping = true
			if not is_on_floor():
				jumps_left -= 1
			
	if move != "jump":
		if facing_right and direction.x < 0:
			flip()
		elif not facing_right and direction.x > 0:
			flip()
			
	if move == "attack":
		current_state = state.attacking
		input_buffer.actionable = false
		animator.play("bite")
		
func Grapple(grapple_to: Vector2, rotate_to: float):
	Attack_Cancel()
	var instance = grapple_gina.instantiate()
	var hook = instance.get_node("hook")
	var real_gina = instance.get_node("real_gina")
	hook.global_position = grapple_to
	hook.global_rotation = rotate_to
	real_gina.global_position = global_position
	real_gina.apply_central_impulse(velocity)
	get_tree().current_scene.call_deferred("add_child", instance)
	queue_free()

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
