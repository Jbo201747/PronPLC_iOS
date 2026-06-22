extends Enemy


var dew_projectile_scene: PackedScene = preload("res://source/effects/dew_projectile.tscn")

@onready var projectile_marker = $Sprite / ProjectileMarker


func _init():
 id = Enemies.DEW_JUBILIST
 next_move = "wicked_elixir"

 moves = {
  wicked_elixir = {
   acid = {
    0: 5, 
    1: 6, 
    3: 8, 
   }, 
   next = "pranxis", 
  }, 
  pranxis = {
   damage = {
    0: 3, 
    2: 4, 
   }, 
   next = "wicked_elixir", 
  }, 
 }


func display_intent():
 if next_move == "wicked_elixir":
  add_acid_intent()
 elif next_move == "pranxis":
  add_intent(Intent.ATTACK, {damage = moves.pranxis.damage, count = 2})


func add_acid_intent():
 add_intent(Intent.APPLY_STATUS, {status = TileStatus.ACID, target = "top", near = true, count = moves[next_move].acid})



func wicked_elixir():
 anim_player.play("wicked_elixir")
 anim_player.queue("idle")
 await sprite.hit

 num_projectiles = 1
 await throw_acid_dew()


func throw_acid_dew():
 var dew_projectile: = launch_dew(Vector2(237, 160), 75)
 await dew_projectile.impacted

 AudioManager.play_sound(Sounds.TILE.BOMB_DETONATE)

 await Game.timeout(0.3)

 var apply_to = get_tiles({
  amount = moves[next_move].acid, 
  rows = [-1, -2], 
  effect_priority = AMBIVALENT_EFFECT_PRIORITY, 
 })

 for tile in apply_to:
  tile.add_status(TileStatus.ACID)
  tile.add_poofcloud(Globals.COLORS.ACID)
  var pause = randf_range(0.04, 0.08)
  await Game.timeout(pause)

 num_projectiles -= 1


func pranxis():
 anim_player.play("pranxis")
 anim_player.queue("idle")

 num_projectiles = 2
 for i in range(2):
  await sprite.hit
  throw_player_dew(moves.pranxis.damage, i == 1)

 if num_projectiles > 0:
  await all_projectiles_impacted


func launch_dew(dest: Vector2, height: int) -> ArcingProjectile:
 var projectile: ArcingProjectile = dew_projectile_scene.instantiate()
 projectile.angular_velocity = PI * 10
 projectile.angular_deceleration = PI * 18
 projectile.decelerate_to = PI * 2
 projectile.rotation = randf_range(0.0, TAU)

 main.add_child(projectile)
 projectile.launch(projectile_marker.global_position, dest, height)

 return projectile


func throw_player_dew(damage, is_last_hit):
 var dew_projectile: = launch_dew(player.get_projectile_target(), 90)
 dew_projectile.impacted.connect(_on_projectile_impacted.bind(damage, is_last_hit))


func _on_projectile_impacted(damage: int = 0, is_last_hit: bool = false) -> void :
 AudioManager.play_sound(Sounds.TILE.BOMB_DETONATE)
 hit_player(damage, is_last_hit)
 super._on_projectile_impacted()


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= 0.25:
  tile.add_status(TileStatus.ACID)
