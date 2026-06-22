extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.ENHANCED]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.set_face("th")
 tile.add_status(TileStatus.ENHANCED)

 if not is_preview:
  tile.add_poofcloud(Globals.COLORS.SMOKE)


func is_tile_selectable(tile):
 return ( not tile.has_harmful_status()
   and not (tile.has_status(TileStatus.ENHANCED)
   and tile.only_face_is("th")))
