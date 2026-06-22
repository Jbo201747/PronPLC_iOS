extends Spell


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 var tile_coords = tile.get_coord()
 var index = tile_coords.x
 var last_index = 0

 var selected_row = tile_board.get_row(tile_coords.y)
 var tiles = selected_row.slice(last_index, index + 1)
 tiles.reverse()

 tile_board.remove_tiles(tiles, {
  interval = 0.08, 
  poof_blend = Globals.COLORS.BLEND_SMOKE, 
  tile_color = true, 
 })

 _post_use()
