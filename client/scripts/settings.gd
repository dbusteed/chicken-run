extends MarginContainer

@onready var speed_drp = $C/M/V/H2/Speed
@onready var time_drp = $C/M/V/H3/GameTime

# defaults
var speed_adj = 1.0
var game_time = 60


func _on_bots_item_selected(_index):
	pass


func _on_speed_item_selected(index):
	match speed_drp.get_item_text(index):
		'Auto':
			# TODO
			speed_adj = 1.0
		
		'Very Slow':
			speed_adj = 0.8
		
		'Slow': 
			speed_adj = 0.9
			
		'Normal':
			speed_adj = 1.0
		
		'Fast':
			speed_adj = 1.1
		
		'Very Fast':
			speed_adj = 1.2


func _on_game_time_item_selected(index):
	match time_drp.get_item_text(index):
		'0:30':
			game_time = 30
		
		'1:00':
			game_time = 60
			
		'2:00':
			game_time = 120

	sync_game_time.rpc(game_time)
	

@rpc
func sync_game_time(t):
	game_time = t
