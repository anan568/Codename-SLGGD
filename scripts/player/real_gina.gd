extends RigidBody2D

@onready var line = $"../Line2D"
@onready var hook = $"../hook"

var gina_labubu = load("res://character scenes/gina_labubu.tscn")
var force = 10
var speed = 5

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
		global_position = global_position.move_toward(hook.global_position, speed * v_axis)
		
	if not Input.is_action_pressed("grapple"):
		var instance = gina_labubu.instantiate()
		instance.global_position = global_position
		instance.velocity = linear_velocity
		instance.max_speed = max(linear_velocity.x, linear_velocity.y)
		instance.just_launched = true
		instance.jumps_left = instance.double_jumps
		get_tree().current_scene.add_child(instance)
		$"..".queue_free()
