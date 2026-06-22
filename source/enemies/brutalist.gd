extends Enemy


var topped_up_defense = false


func _init():
 id = Enemies.BRUTALIST
 next_move = "sprawl"

 moves = {
  heartbeat_weak = {
   custom_call = "multiattack", 
   damage = {
    0: 1, 
    1: 2, 
    2: 3, 
    3: 4, 
   }, 
   count = {
    0: 3, 
    1: 5, 
   }, 
   next = "heartbeat_strong", 
  }, 
  heartbeat_strong = {
   custom_call = "multiattack", 
   damage = {
    0: 3, 
    1: 4, 
    2: 6, 
   }, 
   count = {
    0: 3, 
    3: 4, 
   }, 
   next = "final_hit", 
  }, 
  final_hit = {
   damage = {
    0: 1, 
    1: 2, 
    2: 3, 
    3: 4, 
   }, 
   next = "sprawl", 
  }, 
  sprawl = {
   damage = {
    0: 2, 
    1: 3, 
    2: 4, 
   }, 
   next = "lock_board"
  }, 
  lock_board = {
   next = "heartbeat_weak", 
  }, 
 }


func start_appearing() -> void :
 anim_player.play("appear")
 anim_player.advance(0.0)
 anim_player.stop(false)

 await Game.timeout(1.25)
 AudioManager.play_sound(Sounds.BRUTALIST.APPEAR)


func appear() -> void :
 anim_player.play("appear")
 await sprite.pend_event("shake")
 Game.screenshake(10, 0.5)
 await sprite.pend_event("shake")
 Game.screenshake(10, 0.5)
 await anim_player.animation_finished


func display_intent():
 if next_move == "sprawl":
  add_intent(Intent.ATTACK, {damage = moves.sprawl.damage})
  add_intent(Intent.SPRAWL)
 elif next_move == "lock_board":
  add_intent(Intent.LOCK_RESTOCK, {turns = 3})
 elif next_move == "final_hit":
  add_intent(Intent.ATTACK, {damage = moves.final_hit.damage})
 else:
  add_intent(Intent.ATTACK, {damage = moves[next_move].damage, count = moves[next_move].count})


func prepare_next_turn():
 super.prepare_next_turn()

 if next_move == "sprawl" and not topped_up_defense:
  tile_board.top_up_bag(TileType.DEFENSE, 1)
  topped_up_defense = true


func animate_flinch_lethal() -> void :
 if sprite.heart_sprite.visible:
  anim_player.play("die")
  await sprite.hit

  tile_board.slide_out()
  player.anim_player.play("blowback")

  await anim_player.animation_finished

  sprite.heart_sprite.visible = false
  sprite.blood_explode()

  await Game.timeout(1.0)

  await transition_outside()
  await tile_board.fill_board()

 anim_player.play("die")

 await sprite.pend_event("remove_concrete")

 remove_concrete()

 await sprite.pend_event("shake")
 Game.screenshake(10, 0.5)
 await sprite.pend_event("shake")
 Game.screenshake(10, 0.5)

 await anim_player.pend_animation_stopped("die")

 var sidewalk: = add_node_to_background(sprite.get_node("WallSprite/Sidewalk"))
 var chasm: = add_node_to_background(sprite.get_node("WallSprite/Sidewalk/Chasm"))
 chasm.reparent(sidewalk)
 chasm.add_to_group("bg_scroll_child")

 sprite.hide()


func remove_concrete() -> void :
 for tile: Tile in get_tiles({include_effects = [TileStatus.ENHANCED], type = TileType.DEFENSE}):
  tile.add_poofcloud(tile.get_color())
  tile.remove_status(TileStatus.ENHANCED)
  tile.animation.play("shake")
  await Game.timeout(0.08)


func lock_restock():
 tile_board.lock_restock(3)


func multiattack():
 await sprite.pend_flag("beating", false)

 var num_heartbeats = moves[next_move].count

 for i in range(num_heartbeats):
  if i == 0:
   anim_player.play(next_move + "_start")
  else:
   anim_player.play(next_move + "_loop")

  await sprite.hit
  Game.screenshake(4, 0.5)

  hit_player(moves[next_move].damage, i == num_heartbeats - 1)

  if anim_player.is_playing():
   await anim_player.animation_finished

  if i == num_heartbeats - 1:
   anim_player.play(next_move + "_end")
   await anim_player.animation_finished

 anim_player.play("idle")


func switch_inside():
 for i in [8, 9, 10]:
  main.background.set_layer_visible(i, true)

 sprite.set_active_sub_sprite(sprite.heart_sprite)
 anim_player.play("idle")


func switch_outside():
 for i in [8, 9, 10]:
  main.background.set_layer_visible(i, false)

 sprite.set_active_sub_sprite(sprite.wall_sprite)


func transition_outside() -> void :
 await main.screen_wipe.wipe_in()

 await Game.timeout(0.25)

 switch_outside()
 player.anim_player.play("flinch_idle")

 await main.screen_wipe.wipe_out()

 player.anim_player.play("recompose")

 tile_board.unlock_restock(true)
 await tile_board.slide_in()


func final_hit():
 await sprite.pend_flag("beating", false)

 anim_player.play("inflate")

 await sprite.hit
 deal_damage(player, moves.final_hit.damage, DamageType.DIRECT, true, true)

 if player.is_dead:
  return

 tile_board.slide_out()
 player.anim_player.play("blowback")
 await anim_player.animation_finished

 await transition_outside()


func suck():
 tile_board.slide_out()
 anim_player.play("suck")
 await anim_player.animation_finished
 anim_player.play("sucking")
 sprite.wind_anim_player.play("suck")
 player.anim_player.play("suck")
 player.health_bar.disappear()
 await player.anim_player.animation_finished
 player.hide()
 anim_player.play("swallow")
 sprite.stop_wind()
 await anim_player.animation_finished
 await main.screen_wipe.wipe_in()
 await Game.timeout(0.25)
 AudioManager.effects.brutalist.set_enabled(false, 0.5)

 switch_inside()
 player.show()
 player.health_bar.appear()
 player.anim_player.play("flinch_idle")
 await main.screen_wipe.wipe_out()
 player.anim_player.play("recompose")
 await tile_board.slide_in()


func sprawl():
 anim_player.play("sprawl")

 await sprite.hit
 hit_player(moves.sprawl.damage)

 var defense_tiles = get_tiles({
  type = TileType.DEFENSE, 
  include_effects = [TileStatus.DEFAULT], 
  has_face = true, 
 })

 for tile in defense_tiles:
  tile.add_status(TileStatus.ENHANCED)
  tile.add_poofcloud(tile.get_color())
  await Game.timeout(0.08)

 await pend_animation_stopped("sprawl")
 topped_up_defense = false


func lock_board():
 await suck()
 lock_restock()


func play_battle_music(_from_save: = false, _skipping_transition: = false) -> void :
 super.play_battle_music()

 if next_move in ["sprawl", "lock_board"] and times_performed_move.lock_board == 0:
  AudioManager.effects.brutalist.set_enabled(true, 0.0)
 else:
  AudioManager.effects.brutalist.set_enabled(false, 0.0)


func end_battle_music() -> void :
 AudioManager.effects.brutalist.set_enabled(false, 0.0)
 super.end_battle_music()


func get_save_data():
 var save = super.get_save_data()
 save.topped_up_defense = topped_up_defense

 return save


func load_save_data(save):
 super.load_save_data(save)
 topped_up_defense = save.topped_up_defense

 if next_move not in ["sprawl", "lock_board"]:
  switch_inside()


func apply_any_fish(tile: Tile, fish: Fish) -> void :
 if tile_board.restock_locked and not tile.has_status(TileStatus.LINKED):
  tile.add_status(TileStatus.LINKED, {color = fish.minigame.pick_linked_color(), turns = tile_board.lock_amount})
