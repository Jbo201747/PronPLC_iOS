extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY, {status = TileStatus.BOMB, bomb_turns = 2}, TileStatus.MONEY, TileStatus.ENHANCED]


func get_tile_status(tile):
 var column_coords = tile_board.get_column_coords()
 var row_coords = tile_board.get_row_coords()
 var coord = tile.get_coord()
 if coord.x == column_coords[0] and coord.y == row_coords[-1]:
  return TileStatus.CANDY
 elif coord.x == column_coords[-1] and coord.y == row_coords[-1]:
  return TileStatus.BOMB
 elif coord.x == column_coords[-1] and coord.y == row_coords[0]:
  return TileStatus.MONEY
 elif coord.x == column_coords[0] and coord.y == row_coords[0]:
  return TileStatus.ENHANCED


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 var status = get_tile_status(real_tile)

 if status == TileStatus.BOMB:
  tile.add_status(status, 2)
 else:
  tile.add_status(status)

 if status == TileStatus.MONEY:
  tile.set_face("*")

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.DIAL)
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile):
 var status = get_tile_status(tile)
 if not status:
  return false

 return not tile.has_status(status) and not tile.is_indestructible()
