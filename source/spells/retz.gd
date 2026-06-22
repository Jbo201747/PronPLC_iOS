extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.CRIT, TileStatus.MYSTERY]


func apply_to_tile(tile: Tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.CRIT)
 tile.add_status(TileStatus.MYSTERY)

 if not is_preview:
  AudioManager.play_sound(Sounds.SPELLS.PILLS)
  tile.randomize_face([], rng.spell, false)
  tile.add_poofcloud(tile.get_color())
 else:
  tile.set_face("*")


func is_tile_selectable(tile):
 return not (tile.has_harmful_status()
   or (tile.has_status(TileStatus.CRIT) and tile.has_status(TileStatus.MYSTERY)))
