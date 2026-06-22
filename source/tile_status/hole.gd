extends Status

var hole_position: Vector2


func apply(position):
 if position == null:
  position = Vector2(randi_range(-2, 2), randi_range(-2, 2))
 hole_position = position
 tile.tile_sprite.set_hole(true, hole_position)


func clear():
 tile.tile_sprite.set_hole(false)


func is_always_playable() -> bool:
 return true


func get_save_data():
 return hole_position


func load_save_data(position):
 hole_position = position
 tile.tile_sprite.set_hole(true, hole_position)
