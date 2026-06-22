extends Enemy


func _init():
 id = Enemies.CAT
 next_move = "swipe"

 moves = {
  pounce = {
   damage = {
    0: 2, 
    2: 3, 
   }, 
   next = "swipe", 
  }, 
  swipe = {
   damage = {
    0: 1, 
    3: 2, 
   }, 
   count = {
    0: 3, 
    1: 4, 
    2: 5, 
   }, 
   next = "pounce", 
  }, 
 }


func _ready():
 super._ready()
 sprite = $Sprite
 anim_player = $Sprite / AnimPlayer


func display_intent():
 if main.tutorial.active and main.tutorial.hide_enemy_intent:
  return

 if next_move == "pounce":
  add_intent(Intent.ATTACK, {damage = moves.pounce.damage})

 elif next_move == "swipe":
  if moves.swipe.damage == 0:
   add_intent(Intent.HARMLESS_ATTACK, {damage = moves.swipe.damage, count = moves.swipe.count})
  else:
   add_intent(Intent.ATTACK, {damage = moves.swipe.damage, count = moves.swipe.count})


func pounce():
 anim_player.play("bite")
 anim_player.queue("idle")

 await sprite.hit
 hit_player(moves.pounce.damage)

 await anim_player.animation_finished


func swipe():
 anim_player.play("swipe_start")
 await anim_player.animation_finished

 for i in range(moves.swipe.count):
  if i % 2 == 0:
   anim_player.play("swipe_a")
  else:
   anim_player.play("swipe_b")

  await sprite.hit
  hit_player(moves.swipe.damage, i == moves.swipe.count - 1)

  await anim_player.animation_finished

 anim_player.play("swipe_end")
 anim_player.queue("idle")
 await anim_player.animation_finished


func prepare_next_turn():
 if main.tutorial.active:
  can_take_lethal_damage = next_move == "pounce"
  if next_move == "swipe":
   main.tutorial.speech_bubble = sprite.spawn_speech_bubble()
   await main.tutorial.start_first_turn()
  elif next_move == "pounce":
   await main.tutorial.start_second_turn()

 super.prepare_next_turn()


func has_custom_battle_transition() -> bool:
 return main.tutorial.active


func custom_battle_transition(skipping: bool = false) -> void :
 main.show_health()
 if skipping or not main.tutorial.active:
  return

 var versus_label: Label = main.versus_label
 versus_label.text = StringManager.get_string("tutorial/tutorial")
 versus_label.visible_characters = 0
 versus_label.show()
 await Util.type_text(versus_label, 0.025)
 await Game.timeout(1)
 await Util.type_text(versus_label, 0.02, -1)
 versus_label.hide()
