extends Spell


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY]


func _use():
 if not has_valid_word():
  _end_use()
  return

 var middle_tile = get_target_tile()
 middle_tile.add_status(TileStatus.CANDY)
 middle_tile.add_poofcloud(middle_tile.get_color())

 _post_use()


func has_valid_word() -> bool:
 var words: WordList = word_builder.get_words()
 var num_tiles = word_builder.tiles.size()
 return word_builder.can_submit_tiles() and word_builder.can_submit_words(words) and words.sub_lists.size() == 1 and num_tiles > 1 and num_tiles % 2 != 0


func get_target_tile():
 var num_tiles = word_builder.tiles.size()
 return word_builder.tiles[ceili(num_tiles / 2.0) - 1]


func is_usable():
 return super.is_usable() and has_valid_word() and is_tile_selectable(get_target_tile())


func is_tile_selectable(tile: Tile):
 return not tile.has_status(TileStatus.CANDY) and tile.has_face()
