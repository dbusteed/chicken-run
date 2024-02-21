extends Control

@onready var game_code = $Login/ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/GameCode
@onready var player_name = $Login/ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/Name
@onready var ws_url = $Login/ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/WebsocketURL
@onready var player_list = $Lobby/ColorRect/MarginContainer/VBoxContainer/ItemList

var players = {}


func _ready():	
	randomize()
	$Login.show()
	$Lobby.hide()
	$Settings.hide()
	$Login/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Create.disabled = true
	
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
		update_player_list(players)

	else:
		$Lobby/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/StartGame.hide()
		$Lobby/ColorRect/MarginContainer/VBoxContainer/NonHostMessage.show()
		$Settings/C/M/V/H1.hide()
		$Settings/C/M/V/H2.hide()
		$Settings/C/M/V/H3.hide()
		while 1 not in multiplayer.get_peers():
			await get_tree().create_timer(0.1).timeout
		tell_server_hi.rpc_id(1, player_name.text)
	

@rpc("any_peer")
func tell_server_hi(name_):
	players[multiplayer.get_remote_sender_id()] = {'name': name_, 'it': false}
	update_player_list.rpc(players)


@rpc("call_local")
func update_player_list(pp):
	players = pp
	player_list.clear()
	for p in players.values():
		var icon = load('res://textures/chicken.png') if p['it'] else load('res://textures/dog.png')
		$Lobby/ColorRect/MarginContainer/VBoxContainer/ItemList.add_item(p['name'], icon, false)		
	
	
# only the host is able to click this button,
# so once pressed they will kick off "start_game"
# for all peers (including themselves)
func _on_start_game_pressed():
	setup_game.rpc()


@rpc("call_local")
func setup_game():
	var game_scene = load("res://scenes/game.tscn")
	var game = game_scene.instantiate()
	get_tree().root.add_child(game)
	hide()
	
	# why is this here?
	for pid in players:
		if players[pid]['it']:
			if pid == multiplayer.get_unique_id():
				game.get_node("Camera2D").zoom = Vector2(0.3, 0.3)
	
	if multiplayer.get_unique_id() == 1:

		var spawns = []
		for spawn in game.get_node("NotItSpawns").get_children():
			spawns.append(spawn.global_position)
		spawns.shuffle()
		
		var player
		var spawn
		
		var speed_adj = get_tree().root.get_node("/root/Menu/Settings").speed_adj
				
		var player_scene = load("res://scenes/player.tscn")
		for pid in players:
			player = player_scene.instantiate()
			player.name = str(pid)
			var it = players[pid]['it']
			if it:
				spawn = game.get_node("ItSpawns").get_children().pick_random().global_position
			else:
				spawn = spawns.pop_front()
			get_tree().get_root().get_node("/root/Game/Players").add_child(player, true)
			player.init.rpc_id(pid, spawn, it, false, speed_adj)
			game.setup_camera.rpc_id(pid, it)

		var bot_setting_drp = get_tree().get_root().get_node("/root/Menu/Settings/C/M/V/H1/Bots")
		var bot_setting = bot_setting_drp.get_item_text(bot_setting_drp.selected)
		var n_bots
		match bot_setting:
			'Auto': n_bots = 5 - len(players)
			'None': n_bots = 0
			'1': n_bots = min(1, 5 - len(players))
			'2': n_bots = min(2, 5 - len(players))
			'3': n_bots = min(3, 5 - len(players))
			'4': n_bots = min(4, 5 - len(players))
	
		var n = 1
		for _bot in n_bots:
			player = player_scene.instantiate()
			player.name = str('BOT') + str(n)
			spawn = spawns.pop_front()
			get_tree().get_root().get_node("/root/Game/Players").add_child(player, true)
			player.init.rpc_id(1, spawn, false, true, 0.0)
			n += 1


func _on_item_list_item_clicked(index, _at_position, _mouse_button_index):
	if multiplayer.get_unique_id() != 1: return
	for p in players.values():
		p['it'] = false
	players[players.keys()[index]]['it'] = true
	update_player_list.rpc(players)
	

func _on_leave_lobby_pressed():
	$Login/ColorRect/MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/GameCode.text = ''
	$Login/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Create.disabled = true
	$Login.show()
	$Lobby.hide()
	Network.stop()


func _on_settings_btn_pressed():
	$Settings.show()
	$Lobby.hide()


func _on_back_pressed():
	$Lobby.show()
	$Settings.hide()
