extends Status


func will_fall_on_turn_end():
 if not tile_exists() or not tile.can_fall():
  return false

 var coord = tile.get_coord()
 if coord == null:
  return false

 if coord.y == 0:
  return true

 var tiles_below = Game.tile_board.get_tiles({
  columns = [coord.x], 
  rows = Game.tile_board.get_row_coords(true, true, coord.y, false), 
  sorted = true, 
  custom_tile_check = func(check_tile, _params): return check_tile.will_exist_on_turn_end(), 
 })

 var blocking_tiles_below: Array[Tile] = []
 for below_tile: Tile in tiles_below:
  if not below_tile.can_fall() and not below_tile.will_be_melted_on_turn_end():
   return false

  if not below_tile.has_status(TileStatus.ACID):
   blocking_tiles_below.append(below_tile)

 return blocking_tiles_below.size() < 2
