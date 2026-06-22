extends Enemy


@onready var coal_marker = $Sprite / CoalMarker


func _init():
 id = Enemies.STOKER
 next_move = "shovel"

 moves = {
  shovel = {
   coal = {
    0: 3, 
    1: 4, 
   }, 
   next = "strike", 
  }, 
  strike = {
   damage = {
    0: 3, 
    2: 4, 
    3: 5, 
   }, 
   next = "shovel", 
  }, 
 }


func display_intent():
 if next_move == "shovel":
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.COAL, target = "top", count = moves.shovel.coal})

 elif next_move == "strike":
  add_intent(Intent.ATTACK, {damage = moves.strike.damage})


func shovel():
 anim_player.play("shovel")
 await sprite.hit

 var target_coords = get_tiles({
  amount = moves.shovel.coal, 
  rows = [-1], 
  get_coords = true, 
  empty = null, 
  sorted = true, 
 })

 num_projectiles = target_coords.size()

 for coord in target_coords:
  var tile = tile_board.create_tile()

  main.add_child(tile)
  tile.add_status(TileStatus.COAL)

  tile.launch(coal_marker.global_position, tile_board.get_coord_position(coord), randf_range(48, 80), coord, 800, false, true)
  tile.impacted.connect(_on_projectile_impacted)

 if num_projectiles > 0:
  await all_projectiles_impacted


func strike():
 anim_player.play("bash")

 await sprite.hit
 hit_player(moves.strike.damage)

 await anim_player.animation_finished


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= 0.2:
  tile.add_status(TileStatus.COAL)
