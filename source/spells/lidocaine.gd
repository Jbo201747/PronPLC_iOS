extends Spell


func set_status_tooltips():
 status_tooltips = [TileStatus.FROZEN]


func _use():
 if not has_valid_word():
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.SPRAY_SHORT)

 var apply_to = get_target_tiles()
 for tile in apply_to:
  if is_tile_selectable(tile):
   tile.add_status(TileStatus.FROZEN)
   tile.add_poofcloud(tile.get_color())
  else:
   tile.animation.play("shake")

 _post_use()


func has_valid_word() -> bool:
 var words: WordList = word_builder.get_words()
 return word_builder.can_submit_tiles() and word_builder.can_submit_words(words) and words.sub_lists.size() == 1 and word_builder.tiles.size() > 1


func get_target_tiles():
 return [word_builder.tiles[0], word_builder.tiles[-1]]


func is_usable():
 return super.is_usable() and has_valid_word() and any_tile_selectable(get_target_tiles())


func is_tile_selectable(tile: Tile):
 return not tile.has_status(TileStatus.FROZEN) and tile.has_face()
