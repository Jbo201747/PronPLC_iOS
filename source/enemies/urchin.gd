extends Enemy


var bat_anim = "bat"


func _init():
 id = Enemies.URCHIN
 next_move = "riposte"

 moves = {
  guard = {
   defense = 99, 
   next = "riposte", 
  }, 
  riposte = {
   weak_damage = {
    0: 3, 
    2: 4, 
    3: 5, 
   }, 
   damage = {
    0: 5, 
    1: 6, 
    2: 7, 
    3: 8, 
   }, 
   parry = {
    0: 5, 
    1: 6, 
    2: 7, 
    3: 8, 
   }, 
   next = "guard", 
  }, 
 }


func display_intent():
 if next_move == "guard":
  add_intent(Intent.DEFEND, {defense = moves.guard.defense})

 elif next_move == "riposte":
  if get_needed_parry() != 0:
   if times_performed_move.riposte == 0:
    add_intent(Intent.ATTACK, {damage = moves.riposte.weak_damage})
   else:
    add_intent(Intent.ATTACK, {damage = moves.riposte.damage})

  add_parry_intent()


func _play_idle():
 if "parry" in moves[next_move] and not is_parried:
  anim_player.play("psych_idle")
  return

 anim_player.play("idle")


func appear():
 await guard()


func prepare_next_turn():
 super.prepare_next_turn()
 if next_move == "guard":
  (sprite as UrchinSprite).play_shield_loop()


func animate_flinch(damage):
 if is_parried:
  anim_player.play("psych_out")
 elif damage <= 0:
  anim_player.play("flinch_weak")
 else:
  anim_player.play("flinch")

 await anim_player.animation_finished


func guard():
 (sprite as UrchinSprite).stop_shield_loop()
 anim_player.play("psych_up")
 anim_player.queue("psych_idle")
 await anim_player.pend_animation_played("psych_idle")


func riposte():
 if is_parried:
  if anim_player.current_animation == "psych_idle":
   anim_player.play("psych_out")
   await anim_player.animation_finished
  return

 anim_player.play(bat_anim)
 anim_player.queue("idle")
 await sprite.hit

 if "weak_damage" in moves.riposte and times_performed_move.riposte == 0:
  hit_player(moves.riposte.weak_damage)
 else:
  hit_player(moves.riposte.damage)

 await anim_player.pend_animation_played("idle")


func load_save_data(save):
 super.load_save_data(save)
 _play_idle()
 if next_move == "guard":
  (sprite as UrchinSprite).play_shield_loop()
