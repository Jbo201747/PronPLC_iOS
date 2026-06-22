extends TileModifierSpell


var poof_color = Globals.COLORS.INK_BLACK


func _spell_init():
 selectable_regions = [Selection.LEFT_RIGHT]


func _gain() -> void :
 if rng.reroll.randi_range(1, 10) == 1 and secret_id == "":
  transform_spell(SPELLS.TYPE_O, false, true, true, true, true)


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 var new_faces: = Letters.shift_faces(
  real_tile.faces, 
  Letters.QWERTY, 
  get_selected_offset(), 
  false
 )
 tile.set_face(new_faces)

 if not is_preview:
  tile.add_poofcloud(poof_color)


func get_selected_offset():
 if selected_tile_region == TileRegion.LEFT:
  return -1

 return 1


func is_tile_selectable(tile):
 return tile.is_single_letter(false, true) and not tile.has_status(TileStatus.MYSTERY)
