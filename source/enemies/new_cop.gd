extends Enemy


const MAX_WEAK_FLINCH_DAMAGE = 5

var is_deflated = false
var is_btfod = false
var pop_on_deflate: = false

var CoordTarget = preload("res://source/effects/coord_target.tscn")


func _init():
 id = Enemies.NEW_COP
 next_move = "warning_shot"

 moves = {
  warning_shot = {
   holes = 1, 
   ash = false, 
   next = "real_shot", 
  }, 
  real_shot = {
   damage = {
    0: 8, 
    1: 10, 
    2: 12, 
    3: 14, 
   }, 
   next = "warning_shot", 
  }, 
  headshot = {
   damage = 99, 
   next = "headshot", 
  }, 
 }


func end_turn():
 if is_deflated and next_move != "headshot":
  next_move = "headshot"

 super.end_turn()


func prepare_first_turn() -> void :
 AudioManager.play_sound(Sounds.NEW_COP.ENGAGE)
 await Game.timeout(1.15)
 AudioManager.play_sound(Sounds.NEW_COP.GUN_COCK)


func prepare_next_turn():
 super.prepare_next_turn()

 if next_move != "warning_shot" or tile_board.get_targeted_coords().size() != 0:
  return

 var target_coords = get_tiles({
  amount = moves.warning_shot.holes, 
  rows = range(tile_board.restock_depth), 
  get_coords = true, 
  exclude_coord_status = true, 
 })

 for coord in target_coords:
  var coord_target = CoordTarget.instantiate()
  tile_board.set_coord_status(coord, coord_target)


func display_intent():
 if next_move == "warning_shot":
  add_intent(Intent.HOLE_PUNCH, {holes = moves.warning_shot.holes, ash = moves.warning_shot.ash})

 elif next_move == "real_shot":
  add_intent(Intent.ATTACK, {damage = moves.real_shot.damage})

 elif next_move == "headshot":
  add_intent(Intent.ATTACK, {damage = moves.headshot.damage})


func animate_flinch(damage):
 if health <= 5 and not is_deflated:
  clear_intent()

  if pop_on_deflate:
   await animate_flinch_pop(true)
   return

  is_deflated = true

  if not main.is_player_turn:
   is_btfod = true
  else:
   next_move = "headshot"

  anim_player.play("flinch_deflate")

 elif is_deflated:
  anim_player.play("flinch_deflated")

 elif damage <= MAX_WEAK_FLINCH_DAMAGE:
  anim_player.play("flinch_weak")

 else:
  anim_player.play("flinch")

 await anim_player.animation_finished

 if main.is_player_turn:
  update_intents()


func animate_flinch_lethal():
 if is_deflated:
  anim_player.play("flinch_deflated_lethal")
  await anim_player.animation_finished

  leave_corpse()
  sprite.blood_explode()

 else:
  await animate_flinch_pop()


func _play_idle():
 if is_deflated:
  anim_player.play("idle_deflated")
 else:
  anim_player.play("idle")


func animate_flinch_pop(zero_health: = false) -> void :
 anim_player.play("flinch_pop")
 await sprite.hit

 if zero_health:
  health = 0

 sprite.blood_explode()
 Game.screenshake(12, 0.32)

 await anim_player.animation_finished
 leave_corpse()


func leave_corpse():
 if is_deflated:
  add_node_to_background(sprite.get_node("Vomit"))
  for letter in ["A", "B", "C"]:
   add_node_to_background(sprite.get_node("VomitFleck" + letter))
 else:
  add_node_to_background(sprite.get_node("Sprite"))

 sprite.hide()


func warning_shot():
 if is_btfod:
  is_btfod = false
  clear_targets()
  return

 if is_deflated:
  anim_player.play("shoot_deflated")
 elif moves.warning_shot.holes > 1:
  anim_player.play("pop_pop")
 else:
  anim_player.play("pop")

 var whiffed: = false
 var targets = tile_board.get_targeted_coords()
 if targets.size() > 0:
  for target in targets:
   await sprite.hit
   Game.screenshake(8, 0.32)

   var coord = tile_board.get_status_coord(target)
   var tile = tile_board.get_tile_at(coord)

   if tile:
    if not tile.has_status(TileStatus.HOLE):
     if moves.warning_shot.ash:
      tile.add_status(TileStatus.ASH)

     tile.apply_hole(false)
    else:
     delayed_whiff_sound()
     whiffed = true

    tile.add_poofcloud(Globals.COLORS.SMOKE)
   else:
    delayed_whiff_sound()
    whiffed = true

   tile_board.set_coord_status(coord, null)
   target.clear()

 await anim_player.animation_finished

 if whiffed:
  AudioManager.play_sound(Sounds.NEW_COP.WHIFF)

 _play_idle()


func delayed_whiff_sound() -> void :
 await Game.timeout(0.1)
 AudioManager.play_sound(Sounds.CHILD.DODGE)


func real_shot():
 if is_btfod:
  is_btfod = false
  return

 if is_deflated:
  anim_player.play("shoot_deflated")
 else:
  anim_player.play("shoot")

 await sprite.hit
 hit_player(moves.real_shot.damage)
 Game.screenshake(8, 0.32)

 await anim_player.animation_finished
 _play_idle()


func headshot():
 anim_player.play("shoot_deflated")

 await sprite.hit
 hit_player(moves.headshot.damage)
 Game.screenshake(8, 0.32)

 await anim_player.animation_finished


func clear_targets():
 var targets = tile_board.get_targeted_coords()

 if targets.size() > 0:
  var target = targets[0]
  var coord = tile_board.get_status_coord(target)

  tile_board.set_coord_status(coord, null)
  target.clear()


func _on_sprite_event(event: String) -> void :
 super._on_sprite_event(event)

 if event == "hide_health":
  tile_board.clear_targets()


func get_save_data():
 var save = super.get_save_data()

 save["is_deflated"] = is_deflated

 return save


func load_save_data(save):
 super.load_save_data(save)

 is_deflated = save.is_deflated
 _play_idle()


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= 0.25:
  tile.add_status(TileStatus.BRUISE)
