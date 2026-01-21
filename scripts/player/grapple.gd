extends Node2D

@onready var line = $Line2D
var player

var speed = 12
var time = 0.3
var min_time = 0.2
var timer = 0
var going_back = false

func _physics_process(delta: float) -> void:
	line.clear_points()
	line.add_point($Marker2D.global_position)
	line.add_point(player.global_position)
	
	timer += delta
	if (timer < time and not going_back) or (going_back and timer < min_time):
		global_position += transform.x * speed
		
	if timer >= time:
		going_back = true
		
	if going_back and timer >= min_time:
		global_position = global_position.move_toward(player.global_position, speed)
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not going_back and not body.is_in_group("player"):
		player.Grapple(global_position, global_rotation)
		queue_free()
		
	elif body.is_in_group("player") and going_back:
		player.grappleable = true
		player.grappling = false
		queue_free()
