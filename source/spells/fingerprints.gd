extends Spell


func _use() -> void :
 var first_tile: Tile = await get_selection()
 if first_tile == null:
  _end_use()
  return

 first_tile.animation.play("pressed")

 var second_tile: Tile = await get_selection([first_tile])
 if second_tile == null:
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.STAMP)

 first_tile.swap_face(second_tile)
 second_tile.add_poofcloud(Globals.COLORS.INK_BLACK)

 await Game.timeout(0.08)

 first_tile.add_poofcloud(Globals.COLORS.INK_BLACK)

 await Game.timeout(0.24)

 _post_use()


func is_tile_selectable(tile: Tile):
 return tile.has_face() and not tile.has_status(TileStatus.MYSTERY)
