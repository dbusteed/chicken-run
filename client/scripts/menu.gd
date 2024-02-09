extends Control

@onready var game_code = $Login/VBoxContainer/MarginContainer/VBoxContainer/GameCode
@onready var player_name = $Login/VBoxContainer/MarginContainer/VBoxContainer/Name
@onready var ws_url = $Login/VBoxContainer/MarginContainer/VBoxContainer/WebsocketURL

var players = {}

func _ready():
	randomize()
	var random_names = [
		"Alice",
		"Bob",
		"Chuck",
		"Doris",
		"Eddy",
		"Frank",
		"Gary",
		"Helen"
	]
	
	player_name.text = random_names.pick_random()
	
	Network.lobby_joined.connect(lobby_joined)
	#Network.say_hi.connect(say_hi)


func _on_create_pressed():
	Network.start(ws_url.text, game_code.text, true)


func _on_join_pressed():
	Network.start(ws_url.text, game_code.text, true)


func lobby_joined(lobby):
	$Login.visible = false
	$Lobby.visible = true
	$Lobby/VBoxContainer/LobbyCode.text = "GAME: " + lobby
	
	if multiplayer.get_unique_id() == 1:
		$Lobby/VBoxContainer/StartGame.disabled = false
		players[1] = {'name': player_name.text, 'it': true}
		update_lobby(players)

	else:
		while 1 not in multiplayer.get_peers():
			await get_tree().create_timer(0.1).timeout
		tell_server_hi.rpc_id(1, player_name.text)
	
	#players.append(player_name.text)
	#$Lobby/VBoxContainer/ItemList.clear()
	#for n in players:
		#$Lobby/VBoxContainer/ItemList.add_item(n, null, false)	
	#update_lobby_list.rpc(players)

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
	$Lobby/VBoxContainer/ItemList.clear()
	for p in players.values():
		if p['it']:
			$Lobby/VBoxContainer/ItemList.add_item(p['name'], load('res://textures/chicken.png'), false)
		else:
			$Lobby/VBoxContainer/ItemList.add_item(p['name'], load('res://textures/dog.png'), false)
	

#
# only the Host is able to click this button,
# which kicks off the next function for everyone
#
func _on_start_game_pressed():
	setup_game.rpc()


#
# 
#
@rpc("call_local")
func setup_game():
	#
	# everyone needs to create the game
	#
	var game_scene = load("res://scenes/game.tscn")
	var game = game_scene.instantiate()
	get_tree().root.add_child(game)
	hide()
	
	# temp probably
	for pid in players:
		if players[pid]['it']:
			if pid == multiplayer.get_unique_id():
				game.get_node("Camera2D").zoom = Vector2(0.4, 0.4)
	
	#
	# then let the host create the players (which will
	# be replicated via Spawner)
	#
	if multiplayer.get_unique_id() == 1:
		print(players)
		var player_scene = load("res://scenes/player.tscn")
		for pid in players:
			
			# TODO notitspawns need to pop or something to avoid dups
			
			var player = player_scene.instantiate()
			player.name = str(pid)
			player.it = players[pid]['it']
			var spawn = 'ItSpawns' if player.it else 'NotItSpawns'
			get_tree().get_root().get_node("/root/Game/Players").add_child(player, true)
			player.init.rpc(game.get_node(spawn).get_children().pick_random().global_position)
			game.setup_camera.rpc_id(pid)


func _on_item_list_item_clicked(index, _at_position, _mouse_button_index):
	if multiplayer.get_unique_id() != 1: return
	for p in players.values():
		p['it'] = false
	players[players.keys()[index]]['it'] = true
	update_lobby.rpc(players)
	


		#var player = player_scene.instantiate()
		#player.name = str(1)
		#player.it = true
		#player.global_position = game.get_node('ItSpawns').get_children().pick_random().global_position
		#get_tree().get_root().get_node("/root/Game/Players").add_child(player, true)
		#game.setup_camera.rpc_id(1)
#
		#for peer_id in multiplayer.get_peers():
			#player = player_scene.instantiate()
			#player.name = str(peer_id)
			#get_tree().get_root().get_node("/root/Game/Players").add_child(player, true)
			#player.init.rpc(game.get_node('NotItSpawns').get_children().pick_random().global_position)
			#game.setup_camera.rpc_id(peer_id)
