extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.CANDY)
 tile.set_face("3")

 if not is_preview:
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile):
 return not tile.has_harmful_status() and not (tile.has_status(TileStatus.CANDY) and tile.only_face_is("3"))
