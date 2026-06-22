extends Enemy

var fireball_sound = Sounds.BOOKWORM.FIREBALL
var fireball_final_sound = Sounds.BOOKWORM.FIREBALL_FINAL
var Fireball = preload("res://source/effects/fireball.tscn")

@onready var projectile_marker = $Sprite / ProjectileMarker
@onready var muzzleflash_anim_player = $Sprite / MuzzleFlash / AnimPlayer


func _init():
 id = Enemies.BOOKWORM
 next_move = "purify"

 moves = {
  purify = {
   status = TileStatus.SPICY, 
   fish_chance = 0.25, 
   exclude_rows = [], 
   spicy = {
    0: 5, 
    1: 6, 
    2: 8, 
    3: 9, 
   }, 
   next = "lunge", 
  }, 
  lunge = {
   damage = {
    0: 3, 
    2: 4, 
    3: 5, 
   }, 
   next = "purify", 
  }, 
 }


func display_intent():
 if next_move == "purify":
  add_intent(Intent.APPLY_STATUS, {status = moves.purify.status, count = moves.purify.spicy})
  if get_purify_damage() > 0:
   add_intent(Intent.ATTACK, {damage = get_purify_damage()})

 elif next_move == "lunge":
  add_intent(Intent.ATTACK, {damage = moves.lunge.damage})


func get_purify_damage():
 return 0


func purify():
 var apply_to = get_tiles({
  amount = moves.purify.spicy, 
  exclude_rows = moves.purify.exclude_rows, 
  effect_priority = AMBIVALENT_EFFECT_PRIORITY, 
 })

 num_projectiles = apply_to.size()
 anim_player.play("spit")

 await sprite.hit

 AudioManager.reset_sound(fireball_sound)
 for tile in apply_to:
  var fireball = Fireball.instantiate()

  main.add_child(fireball)
  fireball.impacted.connect(_on_projectile_impacted.bind(false, tile.get_coord()))
  fireball.launch(projectile_marker.global_position, tile.global_position, randi_range(70, 80))
  if tile == apply_to[-1] and get_purify_damage() == 0:
   AudioManager.play_sound(fireball_final_sound)
  else:
   AudioManager.play_sound(fireball_sound)

  if muzzleflash_anim_player.current_animation == "flash":
   muzzleflash_anim_player.seek(0)
  else:
   muzzleflash_anim_player.play("flash")

  await Game.timeout(0.2)

 if get_purify_damage() > 0:
  num_projectiles += 1

  var fireball = Fireball.instantiate()
  main.add_child(fireball)
  fireball.gravity -= 100
  fireball.impacted.connect(_on_projectile_impacted.bind(true))
  fireball.launch(projectile_marker.global_position, player.get_projectile_target(), randi_range(95, 105))

  AudioManager.play_sound(fireball_final_sound)

 if num_projectiles > 0:
  await all_projectiles_impacted

 await pend_animation_stopped("spit")
 anim_player.play("idle")


func lunge():
 anim_player.play("lunge")

 await sprite.hit
 hit_player(moves.lunge.damage)

 await anim_player.animation_finished
 anim_player.play("idle")


func _on_projectile_impacted(impacted_player: = false, target_coord: = Vector2i.ZERO) -> void :
 AudioManager.play_sound(Sounds.STATUS_SOUNDS[moves.purify.status])
 if impacted_player:
  hit_player(get_purify_damage())
 else:
  var target_tile = tile_board.get_tile_at(target_coord)
  if target_tile != null:
   target_tile.add_status(moves.purify.status)

 super._on_projectile_impacted()


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= moves.purify.fish_chance:
  tile.add_status(moves.purify.status)
