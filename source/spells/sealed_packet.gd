extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [{status = "wildcard", wildcard_letter = "$"}, TileStatus.MONEY]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.MONEY)
 tile.set_face("**")

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.BOX_SHUFFLE)
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile):
 return not tile.has_harmful_status() and not tile.only_face_is("**")
