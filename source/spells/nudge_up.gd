extends Spell


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 var tile_coords = tile.get_coord()
 if tile_coords.y == 0:
  tile.animation.play("shake")
  _end_use()
  return

 var above_tile = tile_board.get_tile_at(tile_coords + Vector2i(0, 1))

 if above_tile == null:
  tile.animation.play("shake")
  _end_use()
  return

 tile_board.swap_tiles(tile, above_tile)

 _post_use()
