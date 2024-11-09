extends Node

var turn := 0

func new_turn():
	turn += 1
	$"../CanvasLayer/TurnCounter".text = "Turn: " + str(turn)



# Called when the node enters the scene tree for the first time.
func _ready():
	$"../Map".call("clear_grid")
	$"../Map".call("generate")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_turn_button_pressed():
	await new_turn()
