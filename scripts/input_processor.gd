extends Node2D

class BufferedMove:
	var move: String
	var direction: Vector2
	var time: int

var max_buffered_moves = 2
var buffer_time = 100

var moves: Array[BufferedMove]
var whitelisted_moves = ["grapple", "attack", "jump"]
var actionable = true #make sure its turned off when acting
var action_just_pressed
signal acted(move, direction)

func _input(event: InputEvent) -> void:
	var direction = Input.get_vector("left", "right", "down", "up")

	if Whitelisted_Pressed(event):
		Add_Buffer(action_just_pressed, direction)

func _physics_process(delta: float) -> void:
	if moves.is_empty(): return
	if Time.get_ticks_msec() - moves[0].time > buffer_time:
		Remove_Buffer()
	if actionable and !moves.is_empty(): Act()
	
func Add_Buffer(action: String, direction: Vector2):
	if moves.size() >= max_buffered_moves: Remove_Buffer()
	var new_input = BufferedMove.new()
	new_input.move = action
	new_input.direction = direction
	new_input.time = Time.get_ticks_msec()
	moves.append(new_input)
	
func Remove_Buffer():
	moves.remove_at(0)
	
func Act():
	acted.emit(moves[0].move, moves[0].direction)
	Remove_Buffer()
	
func Whitelisted_Pressed(event: InputEvent):
	for action in whitelisted_moves:
		if event.is_action_pressed(action + ""):
			action_just_pressed = action
			return true
	return false
