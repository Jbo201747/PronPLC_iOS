class_name TileControl extends Control


var tile: Tile


func set_tile(value: Tile) -> void :
 tile = value
 tile.make_local()
 tile.reparent( %TileMarker, false)
