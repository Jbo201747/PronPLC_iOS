extends "res://source/enemies/people.gd"


func _init():
 id = Enemies.DECEDENT
 inherited_id = Enemies.PEOPLE
 next_move = "slam"

 moves = {
  slam = {
   poison = {
    0: 5, 
    1: 6, 
    3: 7, 
   }, 
   word_flag = {
    0: WordDictionary.WordFlags.VERY_COMMON, 
    2: null, 
   }, 
   next = "slam", 
  }, 
 }


func display_intent():
 add_intent(Intent.POISON_SCRAMBLE, {count = moves.slam.poison})


func slam():
 var common_word
 var word_length = moves.slam.poison

 if moves.slam.word_flag != null:
  common_word = WordUtility.dictionary.pick_random_flag_word(moves.slam.word_flag, word_length, rng.move)
 else:
  common_word = WordUtility.dictionary.pick_random_word(word_length, rng.move)

 var poison_targets = get_tiles({
  amount = moves.slam.poison, 
  type_priority = TileType.DAMAGE, 
  effect_priority = PURE_EFFECT_PRIORITY, 
 })

 await sprite.pend_event("idle_break")
 anim_player.play("attack")


 await sprite.hit

 for i in range(poison_targets.size()):
  var tile = poison_targets[i]
  var letter = common_word[i]

  tile.set_face(letter)
  tile.add_status(TileStatus.POISON)
  tile.add_poofcloud(tile.get_color())

  var interval = randf_range(0.04, 0.08)
  await Game.timeout(interval)
