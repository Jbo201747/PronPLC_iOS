extends Spell


func set_status_tooltips():
 status_tooltips = ["wildcard"]


func _use():
 if tile_board.restock_depth == 0:
  await _use_restock_disabled()
 else:
  await _use_normal()


func _use_normal():
 var queued_non_wildcard_tiles = tile_board.get_preview_tiles().filter(
   func(preview_tile): return "*" not in preview_tile.faces)

 if queued_non_wildcard_tiles.is_empty():
  _end_use()
  return

 var queued_tile = rng.spell.pick_random(queued_non_wildcard_tiles)
 queued_tile.faces = ["*"]
 tile_board.update_previews()

 _post_use()


func _use_restock_disabled():
 var possible_columns: Array[int] = []
 for column in tile_board.num_columns:
  var needed_tiles: int = tile_board.get_column_needed_tiles(column, true)
  if needed_tiles > 0:
   possible_columns.append(column)

 if possible_columns.is_empty():
  _end_use()
  return

 await Game.word_builder.remove_tiles()
 await tile_board.wait_for_idle_tiles()

 var add_to_column: int = rng.spell.pick_random(possible_columns)
 tile_board.queue.queue_tile({faces = ["*"], type = tile_board.pop_from_bag()}, false, false, Vector2i(add_to_column, 0))
 tile_board._add_tile_at(add_to_column)
 await tile_board.wait_for_idle_tiles()

 _post_use()
