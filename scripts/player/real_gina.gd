extends RigidBody2D

@onready var line = $"../Line2D"
@onready var hook = $"../hook"

var gina_labubu = load("res://character scenes/gina_labubu.tscn")
var force = 10
var speed = 5
var launch_force = 3
var duped = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if global_position.x >= hook.global_position.x:
		apply_central_impulse(Vector2(-force, 0))
	else:
		apply_central_impulse(Vector2(force, 0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	line.clear_points()
	line.add_point($"../hook/PinJoint2D".global_position)
	line.add_point(global_position)
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("left"):
		apply_impulse(Vector2(-force, 0))
	if Input.is_action_pressed("right"):
		apply_impulse(Vector2(force, 0))
		
	var v_axis = Input.get_axis("down", "up")
	if v_axis:
		apply_impulse(Vector2(0, force * -v_axis))
		
	if Input.is_action_pressed("jump"):
		var instance = gina_labubu.instantiate()
		instance.global_position = global_position
		var thug_launch = Vector2(global_position.distance_to(hook.global_position) + 60, 0).rotated(global_position.angle_to_point(hook.global_position)) * launch_force
		instance.velocity = thug_launch
		instance.max_speed = global_position.distance_to(hook.global_position) * launch_force
		instance.just_launched = true
		instance.jumps_left = instance.double_jumps
		get_tree().current_scene.add_child(instance)
		$"..".queue_free()
		duped = true
		
	if not Input.is_action_pressed("grapple") and not duped:
		var instance = gina_labubu.instantiate()
		instance.global_position = global_position
		instance.velocity = linear_velocity
		instance.just_launched = true
		instance.jumps_left = instance.double_jumps
		get_tree().current_scene.add_child(instance)
		$"..".queue_free()
