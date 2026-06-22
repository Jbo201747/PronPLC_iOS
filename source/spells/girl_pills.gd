extends TileModifierSpell


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.set_type(TileType.DEFENSE)
 tile.set_face("e")

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.PILLS)
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile):
 return not (tile.only_face_is("e")
   and tile.type == TileType.DEFENSE)
