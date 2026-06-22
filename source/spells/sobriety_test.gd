extends TileModifierSpell


func _spell_init():
 selectable_regions = [Selection.LEFT_RIGHT, Selection.CENTER]


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 tile.set_face(get_inverse_faces(real_tile.faces, get_selected_offset()))

 if not is_preview:
  tile.add_poofcloud(Globals.COLORS.INK_BLACK)


func get_inverse_faces(faces: Array[String], offset: int) -> Array[String]:
 var reverse_alphabet = Letters.ALPHABET.duplicate()
 reverse_alphabet.reverse()

 return Letters.shift_faces(
  faces, 
  [Letters.ALPHABET], 
  offset, 
  true, 
  [reverse_alphabet]
 )


func get_selected_offset():
 if selected_tile_region == TileRegion.LEFT:
  return -1
 elif selected_tile_region == TileRegion.RIGHT:
  return 1
 elif selected_tile_region == TileRegion.CENTER:
  return 0

 return 0


func is_tile_selectable(tile):
 if tile.has_status(TileStatus.MYSTERY) or not tile.is_single_letter(false):
  return false

 if selected_tile_region == TileRegion.NONE:
  return true

 return get_inverse_faces(tile.faces, get_selected_offset()) != tile.faces
