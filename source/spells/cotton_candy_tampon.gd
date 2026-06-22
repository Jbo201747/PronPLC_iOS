extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY, TileStatus.PERIOD]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.CANDY)
 tile.add_status(TileStatus.PERIOD)

 if not is_preview:
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile):
 return tile.has_face() and not tile.has_harmful_status() and not tile.has_status(TileStatus.CANDY)
