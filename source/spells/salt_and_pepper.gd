extends "res://source/spells/salt.gd"


func _spell_init():
 apply_number = true


func set_status_tooltips():
 status_tooltips = [{status = TileStatus.BOMB, bomb_turns = 1}, "number"]
