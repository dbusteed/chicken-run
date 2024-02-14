extends Control

@onready var game_code = $Login/ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/GameCode
@onready var player_name = $Login/ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/Name
@onready var ws_url = $Login/ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/WebsocketURL

var players = {}


func _ready():	
	randomize()
	$Login.show()
	$Lobby.hide()
	$Login/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Create.disabled = true
	
	var random_names = [
		"Alice",
		"Bob",
		"Chuck",
		"Doris",
		"Eddy",
		"Frank",
		"Gary",
		"Helen",
		"Iggy",
		"Jerry",
		"Karen",
		"Lisa",
		"Marvin"
	]
	
	player_name.text = random_names.pick_random()
	Network.lobby_joined.connect(lobby_joined)


func _input(_event):
	var inputs = [
		player_name.text == '',
		game_code.text == '',
		ws_url.text == '',
	]
	
	# if any of the three inputs are blank, disable the button
	$Login/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Create.disabled = inputs.max()


func _on_create_pressed():
	Network.start(ws_url.text, game_code.text, true)


func lobby_joined(lobby):
	$Login.visible = false
	$Lobby.visible = true
	$Lobby/ColorRect/MarginContainer/VBoxContainer/LobbyCode.text = "GAME: " + lobby
	
	if multiplayer.get_unique_id() == 1:
		players[1] = {'name': player_name.text, 'it': true}
		update_lobby(players)

	else:
		$Lobby/ColorRect/MarginContainer/VBoxContainer/StartGame.hide()
		$Lobby/ColorRect/MarginContainer/VBoxContainer/NonHostMessage.show()
		while 1 not in multiplayer.get_peers():
			await get_tree().create_timer(0.1).timeout
		tell_server_hi.rpc_id(1, player_name.text)
	

@rpc("any_peer")
func tell_server_hi(nom):
	players[multiplayer.get_remote_sender_id()] = {
		'name': nom,
		'it': false
	}
	update_lobby.rpc(players)


@rpc("call_local")
func update_lobby(pp):
	players = pp
	$Lobby/ColorRect/MarginContainer/VBoxContainer/ItemList.clear()
	for p in players.values():
		if p['it']:
			$Lobby/ColorRect/MarginContainer/VBoxContainer/ItemList.add_item(p['name'], load('res://textures/chicken.png'), false)
		else:
			$Lobby/ColorRect/MarginContainer/VBoxContainer/ItemList.add_item(p['name'], load('res://textures/dog.png'), false)
	

func _on_start_game_pressed():
	setup_game.rpc()


@rpc("call_local")
func setup_game():
	var game_scene = load("res://scenes/game.tscn")
	var game = game_scene.instantiate()
	get_tree().root.add_child(game)
	hide()
	
	# temp probably
	for pid in players:
		if players[pid]['it']:
			if pid == multiplayer.get_unique_id():
				game.get_node("Camera2D").zoom = Vector2(0.4, 0.4)
	
	if multiplayer.get_unique_id() == 1:
		#print(players)
		
		var spawns = []
		for spawn in game.get_node("NotItSpawns").get_children():
			spawns.append(spawn.global_position)
		spawns.shuffle()
		
		var player_scene = load("res://scenes/player.tscn")
		for pid in players:
			var player = player_scene.instantiate()
			player.name = str(pid)
			var it = players[pid]['it']
			var spawn
			if it:
				spawn = game.get_node("ItSpawns").get_children().pick_random().global_position
			else:
				spawn = spawns.pop_front()
			get_tree().get_root().get_node("/root/Game/Players").add_child(player, true)
			player.init.rpc_id(pid, spawn, it)
			game.setup_camera.rpc_id(pid, it)


func _on_item_list_item_clicked(index, _at_position, _mouse_button_index):
	if multiplayer.get_unique_id() != 1: return
	for p in players.values():
		p['it'] = false
	players[players.keys()[index]]['it'] = true
	update_lobby.rpc(players)
	

func _on_leave_lobby_pressed():
	$Login/ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/GameCode.text = ''
	$Login/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Create.disabled = true
	$Login.show()
	$Lobby.hide()
	Network.stop()
