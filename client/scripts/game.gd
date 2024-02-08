extends Node2D

func _ready():
	$CanvasLayer/Label.text = str(multiplayer.get_unique_id())


@rpc("call_local")
func setup_camera():
	var camera = $Camera2D
	camera.get_parent().remove_child(camera)
	get_node("Players/" + str(multiplayer.get_unique_id())).add_child(camera)
