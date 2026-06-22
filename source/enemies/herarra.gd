extends Enemy


func _init():
 id = Enemies.HERARRA
 next_move = "breakdown"

 moves = {
  all = {
   bruise = {
    0: 3, 
    1: 4, 
   }, 
  }, 
  breakdown = {
   damage = {
    0: 1, 
    2: 2, 
    3: 3, 
   }, 
   count = 3, 
   next = "shredder", 
  }, 
  shredder = {
   damage = {
    0: 4, 
    1: 5, 
    2: 6, 
    3: 7, 
   }, 
   next = "breakdown", 
  }, 
 }


func display_intent():
 if next_move == "breakdown":
  add_intent(Intent.ATTACK, 
    {damage = moves.breakdown.damage, count = moves.breakdown.count})

 elif next_move == "shredder":
  add_intent(Intent.ATTACK, {damage = moves.shredder.damage})

 add_intent(Intent.APPLY_STATUS, {status = TileStatus.BRUISE, count = moves.all.bruise})


func strike():
 anim_player.play("attack")

 await sprite.hit
 var apply_to = get_target_tiles()
 apply_status(apply_to, TileStatus.BRUISE)
 hit_player(moves[next_move].damage)

 await anim_player.animation_finished


func breakdown():
 await wrap_up_idle_flag()

 var apply_to = get_target_tiles()
 var apply_to_second = null
 if "second_status" in moves.all:
  apply_to_second = get_target_tiles(apply_to)

 for i in range(moves.breakdown.count):
  if i == 0:
   anim_player.play("slam_start")
   anim_player.queue("slam")
  elif i == moves.breakdown.count - 1:
   anim_player.play("slam_end")
  else:
   anim_player.play("slam")

  await pend_any_animation_played(["slam", "slam_end"])
  Game.screenshake(8, 0.24)

  await sprite.hit
  Game.screenshake(8, 0.24)

  if moves.breakdown.damage > 0:
   hit_player(moves.breakdown.damage, i == moves.breakdown.count - 1)

  apply_move_statuses(apply_to, apply_to_second, i == moves.breakdown.count - 1)

  await anim_player.animation_finished

 anim_player.play("idle")


func shredder():
 await wrap_up_idle_flag()

 var apply_to = get_target_tiles()
 var apply_to_second = null
 if "second_status" in moves.all:
  apply_to_second = get_target_tiles(apply_to)

 anim_player.play("shredder")

 for i in 3:
  await sprite.hit
  Game.screenshake(4, 0.16)

  apply_move_statuses(apply_to, apply_to_second, i == 2)

  if i == 0 and moves.shredder.damage > 0:
   hit_player(moves.shredder.damage)

 await anim_player.animation_finished

 anim_player.play("idle")


func apply_move_statuses(apply_to, apply_to_second, is_last_hit: bool) -> void :
 if apply_to.size() > 0:
  if is_last_hit:
   apply_status(apply_to, TileStatus.BRUISE)
  else:
   apply_status(apply_to, TileStatus.BRUISE, 1)

  if apply_to_second != null and apply_to_second.size() > 0:
   await Game.timeout(0.16)

 if apply_to_second != null and apply_to_second.size() > 0:
  if is_last_hit:
   apply_status(apply_to_second, moves.all.second_status)
  else:
   apply_status(apply_to_second, moves.all.second_status, 1)


func get_target_tiles(exclude_tiles = []):
 return get_tiles({
  amount = moves.all.bruise, 
  type_priority = TileType.DAMAGE, 
  effect_priority = DEFAULT_EFFECT_PRIORITY, 
  exclude_tiles = exclude_tiles
 })


func apply_status(target_tiles, status, count = -1):
 if count == -1:
  count = target_tiles.size()

 count = min(count, target_tiles.size())
 if count <= 0:
  return

 for i in count:
  var tile = target_tiles.pop_back()
  tile.add_status(status)
  tile.add_poofcloud(tile.get_color())


func apply_fish(tile: Tile, fish: Fish) -> void :
 if tile.is_type(TileType.DAMAGE) and fish.rng.randf() <= 0.25:
  tile.add_status(TileStatus.BRUISE)
