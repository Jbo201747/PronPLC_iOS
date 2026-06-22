extends Spell


func set_status_tooltips():
 status_tooltips = [TileStatus.DEFAULT]


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 _post_use()


func is_tile_selectable(tile: Tile):
 return true
