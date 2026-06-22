extends Spell


var payout_chance = 1


func set_status_tooltips():
 status_tooltips = [TileStatus.CRIT]


func _use():
 var target_tiles = get_tiles({
  amount = 1, 
  effect_priority = STATUS_EFFECT_PRIORITY, 
 })

 if target_tiles.is_empty():
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.BOX_SHUFFLE)
 if rng.spell.randf() <= payout_chance:
  for tile in target_tiles:
   tile.add_status(TileStatus.CRIT)
   tile.add_poofcloud(tile.get_color())

  payout_chance = max(0.05, snappedf(payout_chance * 0.8, 0.05))

 _post_use()


func get_save_data():
 var save = super.get_save_data()
 save.payout_chance = payout_chance

 return save


func load_save_data(save):
 super.load_save_data(save)
 payout_chance = save.payout_chance
