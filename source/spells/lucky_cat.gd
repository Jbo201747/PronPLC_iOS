extends Spell


func set_status_tooltips():
 status_tooltips = [TileStatus.CRIT]


func _use():
 var target_tiles = get_tiles({
  amount = 1, 
  exclude_letters = ["7"], 
  effect_priority = FACE_EFFECT_PRIORITY, 
 })

 if target_tiles.is_empty():
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.DICE_ROLL_3)

 for tile in target_tiles:
  tile.set_face("7")

  if rng.spell.randi_range(0, 3) == 0:
   tile.add_status(TileStatus.CRIT)
   tile.add_poofcloud(tile.get_color())
  else:
   tile.add_poofcloud(Globals.COLORS.INK_BLACK)

 _post_use()
