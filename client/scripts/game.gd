extends Node2D

var countdown: int
var game_seconds: int = 10
var playing := true


func _ready():
	countdown = 3
	$CountdownTimer.start(1)
	$CanvasLayer/Countdown.text = str(countdown)
	$CanvasLayer/Clock.text = "%d:%02d" % [(game_seconds / 60), (game_seconds % 60)]


@rpc("call_local")
func setup_camera(it: bool):
	var camera = $Camera2D
	camera.get_parent().remove_child(camera)
	get_node("Players/" + str(multiplayer.get_unique_id())).add_child(camera)
	if it:
		get_node("Players/" + str(multiplayer.get_unique_id())).chicken_caught.connect(on_chicken_caught)


func _on_timer_timeout():
	countdown -= 1
	if countdown == 0:
		$CanvasLayer/Gray.hide()
		$CanvasLayer/Countdown.hide()
		$GameTimer.start(1)
		get_node("Players/" + str(multiplayer.get_unique_id())).playing = true
			
	else:
		$CountdownTimer.start(1)
		$CanvasLayer/Countdown.text = str(countdown)
		

func _on_game_timer_timeout():
	game_seconds -= 1
	if game_seconds < 0:
		$CanvasLayer/Gray.show()
		$CanvasLayer/Message.text = "Chicken Wins!"
		$CanvasLayer/Message.show()
		get_node("Players/" + str(multiplayer.get_unique_id())).playing = false
		$EndGameTimer.start(3)
	
	elif playing:
		$GameTimer.start(1)
		$CanvasLayer/Clock.text = "%d:%02d" % [(game_seconds / 60), (game_seconds % 60)]


func on_chicken_caught():
	on_chicken_caught_rpc.rpc()
	
	
@rpc("call_local", "any_peer")
func on_chicken_caught_rpc():
	playing = false
	$CanvasLayer/Gray.show()
	$CanvasLayer/Message.text = "Dogs Win!"
	$CanvasLayer/Message.show()
	get_node("Players/" + str(multiplayer.get_unique_id())).playing = false
	$EndGameTimer.start(3)


func _on_end_game_timer_timeout():
	get_tree().get_root().get_node("Menu").show()
	queue_free()
