extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY, "wildcard"]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.CANDY)
 tile.set_face("*")

 if not is_preview:
  tile.add_poofcloud(tile.get_color())


func is_tile_selectable(tile):
 return ( not tile.has_harmful_status() and not 
   (tile.is_single_letter("*") and tile.has_status(TileStatus.CANDY)))
