extends Spell


func set_status_tooltips():
 status_tooltips = [TileEffect.SLASHED]


func _use():
 var apply_to = get_tiles({
  amount = 3, 
  single_letter = true, 
  exclude_effects = [TileStatus.MYSTERY] + Globals.FULL_WILDCARD_EFFECTS, 
 })

 if apply_to.is_empty():
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.BOX_SHUFFLE)
 for tile: Tile in apply_to:
  tile.apply_slashed(rng.spell)
  tile.add_poofcloud(Globals.COLORS.INK_BLACK)

  await Game.timeout(0.08)

 _post_use()
