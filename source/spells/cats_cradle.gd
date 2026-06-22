extends Spell


func set_status_tooltips():
 status_tooltips = [{status = TileStatus.BOMB, bomb_turns = 1}]


func _use():
 var target_tiles = get_tiles({
  amount = 1, 
  effect_priority = STATUS_EFFECT_PRIORITY, 
 })

 if target_tiles.is_empty():
  _end_use()
  return

 for tile in target_tiles:
  AudioManager.play_sound(Sounds.SPELLS.BOMB_SPAWN)
  tile.add_status(TileStatus.BOMB, 1)
  tile.add_poofcloud(Globals.COLORS.SMOKE)

 _post_use()
