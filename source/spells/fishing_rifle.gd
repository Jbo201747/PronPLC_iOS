extends Spell


var minigame_scene = preload("res://source/minigames/firing_minigame.tscn")
var minigame: FiringMinigame = null

var fish_launcher = FishLauncher.new(self)


func _use():
 var tiles = get_tiles()
 if tiles.is_empty():
  _end_use()
  return

 tile_board.remove_tiles(tiles, {
  settle = false, 
  restock = false, 
  delete_tiles = false, 
  ignore_status = true, 
 })

 for tile in tiles:
  tile.visible = false

 AudioManager.play_sound(Sounds.NEW_COP.GUN_COCK)
 start_minigame(tiles)
 await minigame.finished

 var caught_fish = minigame.caught_fish.duplicate(true)
 await fish_launcher.launch_fish(caught_fish)

 await tile_board.settle_board()
 await tile_board.fill_board()

 _post_use()


func start_minigame(source_tiles):
 tile_board.visible = false
 minigame = minigame_scene.instantiate()
 minigame.source_tiles = source_tiles
 minigame.reseed(rng.spell)
 minigame.start()


func end_minigame():
 minigame.queue_free()
 minigame.end()
 tile_board.visible = true
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
