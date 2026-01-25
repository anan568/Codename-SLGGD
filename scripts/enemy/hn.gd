extends StaticBody2D

@onready var path_follow = $".."
@onready var path = $"../.."
@export var speed = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_rotation = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	path_follow.progress += speed
