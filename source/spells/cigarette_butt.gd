extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.COAL]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.COAL)

 if not is_preview:
  tile.add_poofcloud(Globals.COLORS.COAL)


func is_tile_selectable(_tile):
 return true
