class_name PartyRationSpell extends Spell


var was_used: = false


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY]


func _use():
 var candy_targets = get_tiles({
  amount = 8, 
  effect_priority = NONPOSITIVE_EFFECT_PRIORITY, 
  exclude_effects = [TileStatus.CANDY], 
  has_face = true, 
 })

 if candy_targets.is_empty():
  _end_use()
  return

 was_used = true

 AudioManager.play_sound(Sounds.SPELLS.SODA_CAN)

 for tile in candy_targets:
  tile.add_status(TileStatus.CANDY)
  tile.add_poofcloud(tile.get_color())

  await Game.timeout(0.08)

 _post_use()


func get_save_data():
 var save = super.get_save_data()
 save.was_used = was_used
 return save


func load_save_data(save):
 super.load_save_data(save)
 was_used = save.get("was_used", false)
