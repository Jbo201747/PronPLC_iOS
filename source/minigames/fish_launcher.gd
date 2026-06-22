class_name FishLauncher extends RefCounted


signal finished

var FishProjectile = preload("res://source/effects/fish_projectile.tscn")
var num_projectiles = 0
var spell_ref: WeakRef
var spell: Spell:
 get():
  return spell_ref.get_ref()
 set(value):
  spell_ref = weakref(value)


func _init(_spell):
 spell = _spell


func launch_fish(caught_fish):
 num_projectiles = caught_fish.size()

 if caught_fish.is_empty():
  spell.end_minigame()
  return

 for fish in caught_fish:
  fish.hide()
  fish.reparent(Game.main)
  fish.is_projectile = true

 spell.end_minigame()
 launch_projectiles(caught_fish)

 await finished

 await Game.tile_board.settle_board()


func launch_projectiles(caught_fish):
 var coords = get_target_coords(caught_fish)
 var i = 0

 var difference = caught_fish.size() - coords.size()
 if difference > 0:
  for j in difference:
   caught_fish.pop_back().queue_free()
   num_projectiles -= 1

 for coord in coords:
  var fish = caught_fish[i]
  await launch_projectile(fish, coord)
  i += 1


func launch_projectile(fish, coord):
 var target_dest = Game.tile_board.get_coord_position(coord)
 var launch_force = randf_range(80, 90)

 var projectile = FishProjectile.instantiate()
 Game.main.add_child(projectile)

 projectile.impacted.connect(_on_projectile_impacted.bind(fish, coord))

 fish.reparent(projectile)
 fish.anim_player.play("RESET")
 fish.position = Vector2(0, 0)
 fish.rotation_degrees = randf_range(0, 360)
 fish.show()

 projectile.gravity *= randf_range(0.8, 1.0)

 projectile.launch(Vector2(240, 135), target_dest, launch_force)

 await Game.timeout(0.16)


func get_target_coords(caught_fish):
 var tile_board: = Game.tile_board
 var fish_count = caught_fish.size()
 var coords = tile_board.get_tiles({
  amount = fish_count, 
  get_coords = true, 
  empty = true, 
  row_priority = tile_board.get_row_coords(), 
  sorted = true, 
 })

 var empty_count = coords.size()
 if empty_count < fish_count:
  var replacing_coords = tile_board.get_tiles({
   amount = fish_count - empty_count, 
   get_coords = true, 
   empty = false, 
   row_priority = tile_board.get_row_coords(true), 
   sorted = true, 
  })
  coords.append_array(replacing_coords)

 return coords


func _on_projectile_impacted(fish, target_coord):
 var tile_board: = Game.tile_board
 var tile_container = Game.main.tile_container
 var new_tile = tile_board.create_tile()
 tile_container.add_child(new_tile)
 new_tile.global_position = fish.global_position
 fish.apply_to_tile(new_tile)
 tile_board.insert_tile(new_tile, target_coord, false)
 AudioManager.play_sound(Sounds.FISHER.FISH_LAND)

 num_projectiles -= 1
 if num_projectiles == 0:
  finished.emit()
