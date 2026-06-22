extends Status

var played_this_turn: = false


func get_save_data():
 return played_this_turn


func load_save_data(_played_this_turn):
 played_this_turn = _played_this_turn != null and _played_this_turn
