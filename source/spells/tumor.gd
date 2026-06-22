extends TileModifierSpell


func set_status_tooltips():
 status_tooltips = [TileStatus.ENHANCED]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 tile.add_status(TileStatus.ENHANCED)
 tile.set_face("2")

 if not is_preview:
  tile.add_poofcloud(tile.get_color())

  var target_tile = get_tiles({
   amount = 1, 
   effect_priority = NONPOSITIVE_EFFECT_PRIORITY, 
  })

  for target in target_tile:
   await Game.timeout(0.18)
   target.add_status(TileStatus.ENHANCED)
   target.set_face("2")
   target.add_poofcloud(target.get_color())




func is_tile_selectable(tile):
 return not (tile.has_status(TileStatus.ENHANCED) and tile.only_face_is("2"))
