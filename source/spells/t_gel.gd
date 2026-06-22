extends Spell


func get_tooltip_context():
 if Game.is_in_run():
  return {wildcard = player.crits_are_wildcards()}
 else:
  return {}


func _use():
 var e_tiles = get_tiles({letters = ["e"]})
 if e_tiles.is_empty():
  _end_use()
  return

 tile_board.add_crit_chance(0.05 * e_tiles.size())
 await tile_board.remove_tiles(e_tiles, {interval = 0.08, tile_color = true})

 _post_use()
