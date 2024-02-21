extends CharacterBody2D

@onready var nav_agent := $NavigationAgent2D

var speed: int = 300
var tilemap: TileMap
var tiles: Array
var playing := false
var bot := false

signal chicken_caught

func _enter_tree():
	if name.begins_with('BOT'):
		set_multiplayer_authority(1, true)
	else:
		set_multiplayer_authority(str(name).to_int(), true)


@rpc("call_local", "any_peer")
func init(pos: Vector2, it: bool, bot_: bool, it_speed_adj: float):
	global_position = pos
	bot = bot_
	
	if it:
		$Chicken.show()
		$Dog.hide()
		$Area2D.area_entered.connect(_on_area_2d_area_entered)
		speed *= it_speed_adj
		
	if bot:
		speed *= 0.90
		nav_agent.set_target_position(Vector2(1184, 787))
		nav_agent.velocity_computed.connect(Callable(_on_velocity_computed))
		tilemap = get_tree().get_root().get_node("/root/Game/TileMap")
		tiles = tilemap.get_used_cells_by_id(0, 2)
		
	# quick pause before syncing position to avoid some issues
	await get_tree().create_timer(1.0).timeout
	$MultiplayerSynchronizer.public_visibility = true


func get_input():
	if not is_multiplayer_authority(): return
	if bot: return # TODO combine these checks
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed


func _physics_process(_delta):
	if not playing: return
	if not is_multiplayer_authority(): return
	if bot:
		nav_agent.set_target_position(get_tree().get_root().get_node("/root/Game/Players/1").global_position)
		
		var next_pos = nav_agent.get_next_path_position()
		var new_velocity = global_position.direction_to(next_pos) * speed
		if nav_agent.avoidance_enabled:
			nav_agent.set_velocity(new_velocity)
		else:
			_on_velocity_computed(new_velocity)
	else:
		get_input()
		move_and_slide()


func _on_area_2d_area_entered(_area):
	chicken_caught.emit()


@rpc("call_local", "any_peer")
func set_playing(is_playing: bool):
	playing = is_playing


func _on_velocity_computed(vel):
	velocity = vel
	move_and_slide()
