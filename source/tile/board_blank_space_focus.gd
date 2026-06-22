class_name BoardBlankSpaceFocus extends Control


var coord: Vector2i

@onready var tile_board: TileBoard = Game.tile_board


func _ready() -> void :
 focus_mode = Control.FOCUS_ALL
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 size = Vector2.ZERO


func try_grab_tile_focus() -> void :
 var tile: = tile_board.get_tile_at(coord)
 if tile != null and not tile.in_word():
  tile.tile_collision.update_focus_enabled()
  if tile.tile_collision.can_grab_focus():
   tile.tile_collision.grab_focus()


func update_position():
 global_position = tile_board.get_coord_position(coord)
