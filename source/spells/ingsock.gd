extends TileModifierSpell


func apply_to_tile(tile: Tile, _real_tile, is_preview, _is_preview_update):
 tile.set_face("ing")

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.BOX_SHUFFLE)
  tile.add_poofcloud(Globals.COLORS.SMOKE)


func is_tile_selectable(tile: Tile):
 return not tile.only_face_is("ing")
