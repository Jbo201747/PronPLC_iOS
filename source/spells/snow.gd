extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.FROZEN, TileStatus.CAPITAL]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.FROZEN)
 tile.add_status(TileStatus.CAPITAL)

 if not is_preview:
  tile.add_poofcloud(Globals.COLORS.ICE)


func is_tile_selectable(tile):
 return not tile.has_harmful_status() and tile.has_face() and not tile.has_status(TileStatus.FROZEN)
