extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.ASH, "wildcard"]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.ASH)
 tile.set_face("*")

 if not is_preview:
  tile.add_poofcloud(Globals.COLORS.ASH)


func is_tile_selectable(tile):
 return not (tile.has_harmful_status()
   or (tile.has_status(TileStatus.ASH) and tile.only_face_is("*")))
