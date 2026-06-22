extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.DEFAULT]


func apply_to_tile(tile: Tile, _real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 tile.add_status(TileStatus.DEFAULT)

 if not is_preview:
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile: Tile):
 return true
