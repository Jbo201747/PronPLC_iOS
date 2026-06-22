extends Enemy


func _init():
 id = Enemies.PEOPLE
 next_move = "slam"

 moves = {
  slam = {
   poison = {
    0: 3, 
    1: 4, 
    2: 5, 
    3: 6, 
   }, 
   next = "slam", 
  }, 
 }


func display_intent():
 add_intent(Intent.APPLY_STATUS, {status = TileStatus.POISON, count = moves.slam.poison})


func slam():
 var apply_to = get_tiles({
  amount = moves.slam.poison, 
  effect_priority = DEFAULT_EFFECT_PRIORITY, 
 })

 await sprite.pend_event("idle_break")
 anim_player.play("attack")


 await sprite.hit

 for tile in apply_to:
  tile.add_status(TileStatus.POISON)
  tile.add_poofcloud(tile.get_color())

  var interval = randf_range(0.04, 0.08)
  await Game.timeout(interval)


func animate_flinch_lethal():
 anim_player.play("flinch_lethal")
 await anim_player.animation_finished
 sprite.blood_explode()
 sprite.hide()
 await Game.timeout(1)


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randi_range(1, 3) == 1:
  tile.add_status(TileStatus.POISON)
