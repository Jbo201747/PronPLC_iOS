extends Enemy

var launch_direction: float = -1

@onready var bomb_marker = $Sprite / BombMarker
@onready var afterimage_spawner = $Sprite / Sprite / AfterimageSpawner


func _init():
 id = Enemies.PARADIGM
 next_move = "toss"

 moves = {
  toss = {
   bomb = 2, 
   next = "detonate", 
  }, 
  detonate = {
   damage = {
    0: 4, 
    1: 5, 
    2: 6, 
    3: 8, 
   }, 
   next = "toss", 
  }, 
 }


func display_intent():
 if next_move == "detonate":
  add_intent(Intent.ATTACK, {damage = moves.detonate.damage})

 elif next_move == "toss":
  add_intent(Intent.CONVERT_STATUS, {statuses = get_bomb_intent_statuses(), count = moves.toss.bomb, bomb_turns = "2-3"})


func get_bomb_intent_statuses():
 return [TileEffect.SUFFIX, TileStatus.BOMB]


func animate_flinch_lethal():
 anim_player.play("suicide")
 await sprite.hit

 Game.screenshake(20, 0.24)
 sprite.blood_explode()

 blow_away_bombs()

 await anim_player.animation_finished

 await tile_board.wait_for_idle()


func blow_away_bombs() -> void :
 var bomb_tiles = get_tiles({include_effects = [TileStatus.BOMB]})
 tile_board.remove_tiles(bomb_tiles, {
  ignore_status = true, 
  delete_tiles = false, 
 })

 for tile: Tile in bomb_tiles:
  var dest = Vector2(tile.global_position.x + randf_range(80, 160) * launch_direction, 290)
  var projectile: = tile.launch(tile.global_position, dest, randf_range(48, 64), Vector2i.MIN, 1400, true, false, false)
  projectile.look_at_direction = false
  projectile.angular_velocity = PI * 10
  projectile.angular_deceleration = PI * 18
  projectile.decelerate_to = PI * 2



func toss():
 var used_long_timer = false
 var faces = get_bomb_faces()

 var target_coords = get_tiles({
  amount = moves.toss.bomb, 
  effect_priority = PURE_EFFECT_PRIORITY, 
  get_coords = true, 
 })

 num_projectiles = target_coords.size()

 anim_player.play("toss")
 await sprite.hit

 for coord in target_coords:
  var tile = tile_board.create_tile()
  var suffix = faces.pop_back()

  main.add_child(tile)
  tile.set_type(TileType.DAMAGE)
  tile.set_face(suffix)

  if not used_long_timer:
   tile.add_status(TileStatus.BOMB, 3)
   used_long_timer = true
  else:
   tile.add_status(TileStatus.BOMB, 2)

  tile.launch(bomb_marker.global_position, 
    tile_board.get_coord_position(coord), 
    60, coord, 800, false, true)
  tile.impacted.connect(_on_projectile_impacted)

  await Game.timeout(0.16)

 if num_projectiles > 0:
  await all_projectiles_impacted


func detonate():
 anim_player.play("detonate")

 await sprite.hit

 Game.screenshake(20, 0.24)
 hit_player(moves.detonate.damage)

 await anim_player.animation_finished


func get_bomb_faces():
 var suffixes = Letters.COMMON_SUFFIXES.duplicate()
 rng.move.shuffle(suffixes)
 return suffixes


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randi_range(1, 8) == 1:
  tile.add_status(TileStatus.BOMB, fish.rng.randi_range(1, 3))
