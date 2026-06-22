extends Spell


func set_status_tooltips():
 status_tooltips = [TileStatus.FROZEN]


func _use():
 var apply_frozen = get_tiles({
  rows = [0], 
  has_face = true, 
 })

 if apply_frozen.is_empty():
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.SODA_CAN)

 for tile in apply_frozen:
  tile.add_status(TileStatus.FROZEN)
  tile.add_poofcloud(Globals.COLORS.ICE)
  await Game.timeout(0.1)

 _post_use()
