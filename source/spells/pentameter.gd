extends TileModifierSpell


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.set_face("5")

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.BOX_SHUFFLE)
  tile.add_poofcloud(Globals.COLORS.INK_BLACK)


func is_tile_selectable(tile: Tile):
 return not tile.is_space() and not tile.only_face_is("5")
