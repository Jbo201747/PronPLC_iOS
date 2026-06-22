extends "res://source/spells/letter_opener.gd"


func is_tile_selectable(tile):
 return not tile.is_indestructible()
