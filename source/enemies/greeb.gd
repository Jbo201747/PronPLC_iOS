extends Enemy


signal targeted

var BongProjectile = preload("res://source/effects/bong_projectile.tscn")
var CoordTarget = preload("res://source/effects/coord_target.tscn")

var total_tile_value = 0

@onready var abduction_marker = $Sprite / Mask / Ship / AbductionMarker
@onready var projectile_marker = $Sprite / ProjectileMarker


func _init():
 id = Enemies.GREEB
 next_move = "abduction"

 moves = {
  target = {
   amount = {
    0: 3, 
    1: 4, 
    2: 5, 
    3: 6, 
   }, 
   rows = {
    0: [0, 1], 
    2: [0, 1, 2], 
   }, 
  }, 
  abduction = {
   next = "green_out", 
  }, 
  green_out = {
   ash = {
    0: 4, 
    3: 5, 
   }, 
   ash_rows = [-2, -3], 
   next = "abduction", 
  }, 
 }


func prepare_next_turn():
 super.prepare_next_turn()
 if next_move == "abduction":
  target_coords()


func display_intent():
 if next_move == "abduction":
  add_intent(Intent.ABDUCT)

 elif next_move == "green_out":
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.ASH, count = moves.green_out.ash})


func abduction():
 var targets = tile_board.get_targeted_coords()
 var tiles = []

 show_above_board()
 anim_player.play("abduct_start")
 await anim_player.animation_changed

 for target in targets:
  var coord = tile_board.get_status_coord(target)
  var tile = tile_board.get_tile_at(coord)

  if tile != null:
   tiles.append(tile)

  tile_board.set_coord_status(coord, null)
  target.clear()

 total_tile_value = 0
 num_projectiles = tiles.size()

 for tile in tiles:
  total_tile_value += tile.get_value()

 await abduct_tiles(tiles)

 anim_player.play("abduct_fire")
 await sprite.hit

 await fire_tiles(tiles)

 if num_projectiles > 0:
  await all_projectiles_impacted

 await pend_animation_played("idle")
 return_below_board()


func abduct_tiles(tiles):
 for tile in tiles:
  tile.animation.play("jitter")
  tile.z_index += 1

  await Game.timeout(0.08)

 await Game.timeout(0.5)

 for tile in tiles:
  tile.disable_shadow()
  var interval = randf_range(0.08, 0.24)

  await Game.timeout(interval)
  tile.tween_position(abduction_marker.global_position)


 await Game.timeout(0.35)


 tile_board.remove_tiles(tiles, {
  ignore_status = true, 
  delete_tiles = false, 
 })

 for tile in tiles:
  tile.hide()

 await sprite.pend_event("loop_break")


func fire_tiles(tiles):
 for tile in tiles:
  tile.impacted.connect(_on_projectile_impacted)

  tile.launch(
   abduction_marker.global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 
   player.get_projectile_target(), 
   randf_range(4, 8), Vector2i.MIN, randf_range(700, 900), true, true
  )
  AudioManager.play_sound(Sounds.GREEB.SHOOT)

  tile.show()
  await Game.timeout(randf_range(0.09, 0.11))


func animate_flinch_lethal():
 anim_player.play("die")
 await anim_player.animation_finished
 await Game.timeout(0.5)


func _on_projectile_impacted():
 if num_projectiles == 1:
  hit_player(total_tile_value)

 super._on_projectile_impacted()


func green_out():
 var bong_projectile = BongProjectile.instantiate()
 var projectile_start = projectile_marker.global_position
 var projectile_dest = get_bong_target()

 anim_player.play("bong_rip")
 await sprite.hit

 main.add_child(bong_projectile)
 bong_projectile.launch(projectile_start, projectile_dest, 50)
 await bong_projectile.impacted

 AudioManager.play_sound(Sounds.GREEB.BONG_EXPLODE)
 await on_bong_hit()

 await pend_animation_stopped("bong_rip")


func get_bong_target() -> Vector2:
 return Vector2(237, 180)


func on_bong_hit() -> void :
 var apply_ash = get_tiles({
  amount = moves.green_out.ash, 
  rows = moves.green_out.ash_rows, 
  effect_priority = AMBIVALENT_EFFECT_PRIORITY, 
 })

 for tile in apply_ash:
  tile.add_status(TileStatus.ASH)
  tile.add_poofcloud(Globals.COLORS.ASH)
  await Game.timeout(0.08)


func target_coords():
 if tile_board.get_targeted_coords().size() != 0:
  return

 var apply_to = get_tiles({
  amount = moves.target.amount, 
  exclude_coord_status = true, 
  get_coords = true, 
  rows = moves.target.rows, 
 })

 for coord in apply_to:
  var coord_target = CoordTarget.instantiate()
  tile_board.set_coord_status(coord, coord_target)


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randi_range(1, 3) == 1:
  tile.add_status(TileStatus.ASH)


func _on_sprite_event(event: String) -> void :
 super._on_sprite_event(event)
 if event == "hide_health":
  tile_board.clear_targets()
 elif event == "fade_music":
  AudioManager.fade_music(1.5)
