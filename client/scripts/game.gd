extends Node2D

var countdown: int
var game_seconds: int
var playing := true


func _ready():
	countdown = 3
	game_seconds = get_tree().root.get_node('/root/Menu/Settings').game_time
	
	$CanvasLayer.show()
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
		if multiplayer.get_unique_id() == 1:
			for p in get_node("Players").get_children():
				if p.name.begins_with('BOT'):
					p.playing = true
			
	else:
		$CountdownTimer.start(1)
		$CanvasLayer/Countdown.text = str(countdown)
		

func _on_game_timer_timeout():
	game_seconds -= 1
	if game_seconds < 0:
		$CanvasLayer/Gray.show()
		$CanvasLayer/Message.text = "Chicken Wins!"
		$CanvasLayer/Message.show()
		for player in get_node("Players").get_children():
			player.playing = false
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
	for player in get_node("Players").get_children():
		player.playing = false
	$EndGameTimer.start(4)


func _on_end_game_timer_timeout():
	get_tree().get_root().get_node("Menu").show()
	queue_free()
