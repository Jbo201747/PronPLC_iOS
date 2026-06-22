extends Spell


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY, TileStatus.ACID]


func _use():
 var apply_acid = []
 for row in tile_board.get_row_coords(true):
  if row == 0:
   break

  var tiles_in_row = get_tiles({
   rows = [row], 
   exclude_effects = [TileStatus.ACID], 
   is_playable = true, 
   sorted = true, 
  })

  if not tiles_in_row.is_empty():
   apply_acid = tiles_in_row
   break

 var apply_candy = get_tiles({
  amount = 2, 
  effect_priority = STATUS_EFFECT_PRIORITY, 
  exclude_tiles = apply_acid, 
 })

 if apply_candy.is_empty():
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.SODA_CAN)

 for tile in apply_candy:
  tile.add_status(TileStatus.CANDY)
  tile.add_poofcloud(tile.get_color())
  await Game.timeout(0.4)

 for tile in apply_acid:
  tile.add_status(TileStatus.ACID)
  tile.add_poofcloud(tile.get_color())
  await Game.timeout(0.08)

 _post_use()
