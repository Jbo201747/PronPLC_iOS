extends Enemy


func _init():
 id = Enemies.AGE_REGRESSOR
 next_move = "small_word"

 moves = {
  small_word = {
   scrabble_pools = {
    0: [
     [1, 1, 1, 1, 1, 1], 
    ], 
    1: [
     [1, 1, 1, 1, 1]
    ], 
   }, 
   next = "big_word", 
  }, 
  big_word = {
   damage = {
    0: 5, 
    1: 6, 
    2: 7, 
    3: 8, 
   }, 
   scrabble_pools = {
    0: [
     [1], 
     [-1, 1, 1], 
     [-1, 1, 1], 
     [1], 
    ], 
    3: [
     [1], 
     [-2, 1, 1], 
     [-1, 1, 1], 
     [1], 
    ], 
   }, 
   next = "small_word", 
  }, 
 }


func display_intent():
 if next_move == "big_word":
  add_intent(Intent.ATTACK, {damage = moves.big_word.damage})


func prepare_next_turn():
 if "scrabble_pools" in moves[next_move]:
  var multipliers = []

  for pool in moves[next_move].scrabble_pools:
   append_scrabble_pool(multipliers, pool)

  if multipliers.size() != 0:
   word_builder.slot_multipliers = multipliers
 else:
  word_builder.slot_multipliers = []

 super.prepare_next_turn()


func small_word():
 pass


func big_word():
 anim_player.play("attack")

 await sprite.hit
 hit_player(moves.big_word.damage)

 await anim_player.animation_finished


func animate_flinch_lethal():
 word_builder.slot_multipliers = []

 anim_player.play("flinch_lethal")
 await anim_player.animation_finished

 sprite.hide()
 await Game.timeout(0.5)


func get_save_data():
 var save = super.get_save_data()

 if word_builder.slot_multipliers.size() != 0:
  save["multipliers"] = word_builder.slot_multipliers

 return save


func load_save_data(save):
 super.load_save_data(save)

 if "multipliers" in save:
  word_builder.slot_multipliers = save.multipliers
