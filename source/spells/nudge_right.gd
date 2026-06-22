extends Spell


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 var tile_coords = tile.get_coord()
 if tile_coords.x == 3:
  tile.animation.play("shake")
  _end_use()
  return

 var right_tile = tile_board.get_tile_at(tile_coords + Vector2i(1, 0))

 tile_board.swap_tiles(tile, right_tile)

 if right_tile == null:
  tile.animation.play("shake")
  _end_use()
  return

 _post_use()
