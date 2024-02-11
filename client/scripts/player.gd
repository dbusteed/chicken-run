extends CharacterBody2D

@export var speed = 300

func _enter_tree():
	set_multiplayer_authority(str(name).to_int(), true)


@rpc("call_local", "any_peer")
func init(pos, it):
	global_position = pos
	if it:
		$Chicken.show()
		$Dog.hide()
	
	await get_tree().create_timer(1.0).timeout
	$MultiplayerSynchronizer.public_visibility = true

func get_input():
	if not is_multiplayer_authority(): return
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed


func _physics_process(_delta):
	if not is_multiplayer_authority(): return
	get_input()
	move_and_slide()
