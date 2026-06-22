extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.CRIT, TileStatus.CAPITAL]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 if tile.only_face_is("8"):
  tile.set_face("*")

 tile.add_status(TileStatus.CRIT)
 tile.add_status(TileStatus.CAPITAL)

 if not is_preview:
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile):
 return not tile.has_harmful_status() and tile.has_face() and tile_board.get_row(tile.get_coord().y)[0] == tile
