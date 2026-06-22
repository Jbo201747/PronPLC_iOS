extends Spell


func _use():
 if not has_valid_word():
  _end_use()
  return

 var target_tiles = word_builder.tiles.duplicate()
 target_tiles.shuffle()
 for tile in target_tiles:
  if tile.is_type(TileType.DAMAGE):
   tile.set_type(TileType.DEFENSE)

  elif tile.is_type(TileType.DEFENSE):
   tile.set_type(TileType.DAMAGE)

  tile.add_poofcloud(tile.get_color())
  await Game.timeout(randf_range(0.01, 0.04))

 _post_use()


func has_valid_word() -> bool:
 var words: WordList = word_builder.get_words()
 return word_builder.can_submit_tiles() and word_builder.can_submit_words(words) and words.sub_lists.size() == 1


func is_usable():
 return super.is_usable() and has_valid_word()
