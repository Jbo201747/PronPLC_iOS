extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileEffect.SHIMMERING, TileStatus.CRIT]


func apply_to_tile(tile: Tile, real_tile: Tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.CRIT)

 if is_preview:
  tile.set_face([real_tile.face, "?"])
 else:
  tile.apply_shimmering(true, null, rng.spell)
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile):
 return not tile.has_harmful_status() and tile.is_single_letter(false)
