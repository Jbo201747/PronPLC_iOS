extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.BLEED, TileEffect.SUIT]


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 tile.add_status(TileStatus.BLEED)
 tile.set_face("♥♥")

 if not is_preview:
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile: Tile):
 return not tile.has_harmful_status() and not tile.has_effect(TileEffect.SHIMMERING) and tile.face != "♥♥"
