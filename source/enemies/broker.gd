extends "res://source/enemies/stoker.gd"


func _init():
 id = Enemies.BROKER
 inherited_id = Enemies.STOKER
 next_move = "shovel"

 moves = {
  shovel = {
   money = 2, 
   next = "strike", 
  }, 
  strike = {
   damage = {
    0: 4, 
    1: 5, 
    2: 6, 
    3: 7, 
   }, 
   next = "shovel", 
  }, 
 }


func display_intent():
 if next_move == "shovel":
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.MONEY, target = "top", count = moves.shovel.money})

 elif next_move == "strike":
  add_intent(Intent.ATTACK, {damage = moves.strike.damage})


func shovel():
 var money_coords = get_tiles({
  amount = moves.shovel.money, 
  include_effects = [TileStatus.MONEY], 
  get_coords = true, 
 })

 var target_coords = get_tiles({
  amount = moves.shovel.money - money_coords.size(), 
  effect_priority = DEFAULT_EFFECT_PRIORITY, 
  type_priority = TileType.DAMAGE, 
  get_coords = true, 
 })

 target_coords += money_coords

 anim_player.play("shovel")
 await sprite.hit

 num_projectiles = target_coords.size()

 for coord in target_coords:
  var tile = tile_board.create_tile()

  main.add_child(tile)
  tile.add_status(TileStatus.MONEY)
  tile.set_face("*")

  tile.launch(coal_marker.global_position, tile_board.get_coord_position(coord), randf_range(48, 80), coord, 800, false, true)
  tile.impacted.connect(_on_projectile_impacted)

 if num_projectiles > 0:
  await all_projectiles_impacted


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= (1.0 / 15.0):
  tile.add_status(TileStatus.MONEY)
  tile.set_face("*")
