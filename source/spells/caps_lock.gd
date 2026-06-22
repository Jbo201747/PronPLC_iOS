extends Spell


func set_status_tooltips():
 status_tooltips = [TileStatus.CRIT, TileStatus.CAPITAL]


func _use():
 var apply_crit = get_tiles({
  amount = 1, 
  effect_priority = STATUS_EFFECT_PRIORITY, 
  exclude_effects = [TileEffect.SHIMMERING], 
  has_face = true, 
  custom_tile_check = func(tile: Tile, _parameters): return tile.face in Letters.BEGINNING_LETTERS, 
 })

 if apply_crit.is_empty():
  _end_use()
  return

 for tile in apply_crit:
  tile.add_status(TileStatus.CRIT)
  tile.add_status(TileStatus.CAPITAL)
  tile.add_poofcloud(tile.get_color())

 _post_use()
