extends Spell


var minigame_scene = preload("res://source/minigames/star_filled_minigame.tscn")
var minigame: StarFilledMinigame = null


func _use():
 var tile = await get_selection()

 if tile == null:
  _end_use()
  return

 start_minigame(tile)
 await minigame.finished

 var new_face: String = minigame.get_current_letter()
 await end_minigame()

 if new_face == "" or new_face == tile.face:
  _end_use()
  return

 tile.set_face(new_face)
 tile.add_poofcloud(Globals.COLORS.INK_BLACK)
 tile.play_tile_sound()

 _post_use()


func is_tile_selectable(tile):
 return tile.is_single_letter(false, false) and not tile.has_status(TileStatus.MYSTERY)


func start_minigame(tile: Tile):
 minigame = minigame_scene.instantiate()
 minigame.start()
 minigame.set_tile(tile)
 minigame.appear()


func end_minigame():
 await minigame.disappear()
 minigame.end()
