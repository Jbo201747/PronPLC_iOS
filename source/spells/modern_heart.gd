extends Spell


func set_status_tooltips():
 status_tooltips = [{status = TileStatus.ENHANCED, plastic = true}]


func _use():
 var target_tiles = get_tiles({
  amount = 1, 
  type = TileType.DEFENSE, 
  effect_priority = AMBIVALENT_EFFECT_PRIORITY, 
 })

 if target_tiles.is_empty():
  _end_use()
  return

 for tile in target_tiles:
  tile.add_status(TileStatus.ENHANCED)
  tile.add_poofcloud(Globals.COLORS.SMOKE)

 _post_use()
