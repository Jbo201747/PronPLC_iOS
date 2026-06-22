extends "res://source/enemies/urchin.gd"


var category_queue: Array[String] = []


func _init():
 super._init()

 id = Enemies.LUMP
 inherited_id = Enemies.URCHIN

 bat_anim = "bat_alt"
 moves = {
  riposte = {
   damage = {
    0: 2, 
    1: 3, 
    2: 4, 
    3: 5, 
   }, 
   next = "riposte", 
  }
 }


func _ready():
 super._ready()
 if not launching_from_enemy_scene:
  word_builder.post_tile_stats.connect(_on_word_builder_post_tile_stats)


func appear():
 pass


func prepare_next_turn():
 if next_move == "riposte":
  if category_queue.is_empty():
   category_queue = Globals.WORD_CATEGORIES.values()
   rng.move.shuffle(category_queue)
  else:
   var last_category: String = category_queue.pop_front()
   if category_queue.is_empty():
    category_queue = Globals.WORD_CATEGORIES.values()
    rng.move.shuffle(category_queue)
    if category_queue[0] == last_category:
     category_queue.pop_front()

 super.prepare_next_turn()


func display_intent():
 if next_move == "riposte":
  add_intent(Intent.ATTACK, {damage = moves.riposte.damage})
  add_intent(Intent.CATEGORY, {word_category = category_queue[0]})


func _on_word_builder_post_tile_stats(words: WordList) -> void :
 if next_move == "riposte" and not words.words.is_empty():
  if WordUtility.word_list_has_flag(words, Globals.WORD_CATEGORY_FLAGS[category_queue[0]]):
   word_builder.damage *= 2
   word_builder.defense *= 2
   word_builder.tile_defense *= 2
   word_builder.self_heal *= 2
   word_builder.add_intent(Globals.Intent.CATEGORY_MATCHED, {word_category = category_queue[0]})


func get_save_data():
 var save = super.get_save_data()
 save.category_queue = category_queue
 return save


func load_save_data(save):
 super.load_save_data(save)
 category_queue = save.category_queue
