extends TileModifierSpell


func _spell_init():
 selectable_regions = [Selection.LEFT_RIGHT]


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 var new_faces: = Letters.shift_faces(
  real_tile.faces, 
  [Letters.ALPHABET, Letters.NUMPAD_CHARACTERS.keys()], 
  get_selected_offset()
 )
 tile.set_face(new_faces)

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.DIAL)
  tile.add_poofcloud(Globals.COLORS.INK_BLACK)


func get_selected_offset():
 if selected_tile_region == TileRegion.LEFT:
  return -1

 return 1


func is_tile_selectable(tile):
 return tile.is_single_letter(false, true) and not tile.has_status(TileStatus.MYSTERY)
