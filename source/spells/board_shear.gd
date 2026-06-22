extends Spell


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 var selected_column = tile_board.get_column(tile.get_coord().x).duplicate(true)

 AudioManager.play_sound(Sounds.SPELLS.STAMP_BIG)

 await tile_board.remove_tiles(selected_column, {
  interval = 0.08, 
  poof_blend = Globals.COLORS.BLEND_SMOKE, 
  tile_color = true, 
  restock = false, 
 })
 await Game.timeout(0.1)

 var columns = tile_board.get_column_coords()
 var non_final_columns = columns.duplicate()
 non_final_columns.pop_back()
 for column_index in non_final_columns:
  if not tile_board.get_column(column_index).is_empty():
   continue

  var next_column_index = column_index + 1
  var next_column = tile_board.get_column(next_column_index)
  while next_column.is_empty():
   next_column_index += 1
   if next_column_index not in columns:
    break

   next_column = tile_board.get_column(next_column_index)

  if next_column_index not in columns:
   break

  for column_tile in next_column:
   tile_board.set_tile_coords(column_tile, Vector2i(column_index, column_tile.get_coord().y))

  tile_board.settle_board()

  await Game.timeout(0.08)

 await tile_board.fill_board()
 _post_use()
