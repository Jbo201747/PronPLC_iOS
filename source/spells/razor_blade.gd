extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.CRIT]


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 var new_face = real_tile.face + real_tile.face

 tile.set_face(new_face)
 tile.add_status(TileStatus.CRIT)

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.STAMP_BIG)
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile: Tile) -> bool:
 return tile.is_single_letter(false, true) and not tile.has_harmful_status() and not tile.has_status(TileStatus.MYSTERY)
