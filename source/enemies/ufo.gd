extends "res://source/enemies/greeb.gd"


func _init():
 super._init()

 id = Enemies.UFO
 inherited_id = Enemies.GREEB

 flinch_animation = "flinch_foucault"
 moves.target.amount = {
  0: 3, 
  3: 4, 
 }
 moves.abduction = {next = "swoop"}
 moves.swoop = {
  damage = {
   0: 6, 
   1: 7, 
   2: 8, 
   3: 11, 
  }, 
  next = "abduction", 
 }


func display_intent():
 if next_move == "abduction":
  add_intent(Intent.SWAP_TYPE, {count = moves.target.amount})

 elif next_move == "swoop":
  add_intent(Intent.ATTACK, {damage = moves.swoop.damage})


func abduction():
 var targets = tile_board.get_targeted_coords()
 var tiles: Array[Tile] = []

 show_above_board()
 anim_player.play("abduct_start_unfunny")
 await anim_player.animation_changed

 for target in targets:
  var coord = tile_board.get_status_coord(target)
  var tile: = tile_board.get_tile_at(coord)

  if tile != null:
   tiles.append(tile)

  tile_board.set_coord_status(coord, null)
  target.clear()

 for tile in tiles:
  tile.animation.play("jitter")
  tile.z_index += 1

  await Game.timeout(0.08)

 await Game.timeout(0.5)

 Game.random.shuffle(tiles)

 for tile in tiles:
  if tile.is_type(TileType.DAMAGE):
   tile.set_type(TileType.DEFENSE)
  else:
   tile.set_type(TileType.DAMAGE)

  tile.animation.play("shake")

  tile.add_poofcloud(tile.get_color())
  await Game.timeout(0.08)

 for tile in tiles:
  tile.update_z_index()

 anim_player.play("abduct_end")
 await anim_player.animation_changed
 return_below_board()


func get_bong_target() -> Vector2:
 return player.get_projectile_target()


func swoop():
 show_above_board()
 anim_player.play("swoop")

 await sprite.hit
 hit_player(moves.swoop.damage)

 await anim_player.pend_animation_played("idle")
 return_below_board()


func animate_flinch_lethal():
 anim_player.play("die_foucault")
 await anim_player.animation_finished


func apply_fish(_tile: Tile, _fish: Fish) -> void :
 pass
