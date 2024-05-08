extends CharacterBody2D

var speed: int = 300

@onready var animation_tree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")

func _ready():
	animation_state.travel('Walk')

func get_input():
	if not is_multiplayer_authority(): return
	var input_direction = Input.get_vector("left", "right", "up", "down")
	animation_tree.set("parameters/Walk/blend_position", input_direction)
	velocity = input_direction * speed
	

func _physics_process(_delta):
	if not is_multiplayer_authority(): return	
	get_input()
	move_and_slide()
