extends Enemy


var value_pool: Array[int] = []
var mystery_seed: int = 0

@onready var prodigy_mask = $Sprite / Sprite / ProdigyMask
@onready var prodigy_mask_anim_player = $Sprite / Sprite / ProdigyMask / AnimPlayer


func _init():
 id = Enemies.PRODIGY
 next_move = "wail"

 moves = {
  wail = {
   damage = {
    0: 1, 
    3: 3, 
   }, 
   count = 2, 
   mystery = 2, 
   next = "shriek", 
  }, 
  shriek = {
   damage = {
    0: 3, 
    1: 4, 
    2: 5, 
    3: 6, 
   }, 
   count = 2, 
   next = "shriek_two", 
  }, 
  shriek_two = {
   damage = {
    0: 3, 
    1: 4, 
    2: 5, 
    3: 6, 
   }, 
   count = 2, 
   custom_call = "shriek", 
   next = "wail", 
  }, 
 }


func display_intent():
 if next_move == "wail":
  prodigy_mask.frame = 0
  add_intent(Intent.ATTACK, {damage = moves.wail.damage, count = moves.wail.count})
  add_mystery_intent()

 elif next_move == "shriek" or next_move == "shriek_two":
  prodigy_mask.frame = 1
  add_intent(Intent.ATTACK, {damage = moves[next_move].damage, count = moves[next_move].count})

 prodigy_mask_anim_player.play("fade_in")


func add_mystery_intent() -> void :
 add_intent(Intent.MYSTERY_CRIT, {count = moves.wail.mystery})


func clear_intent():
 if intent_container != null:
  prodigy_mask_anim_player.play("fade_out")

 await super.clear_intent()


func wail():
 show_above_board()
 var apply_to = get_tiles({
  amount = moves.wail.mystery, 
  include_effects = [TileStatus.MYSTERY]
 })

 if apply_to.size() < moves.wail.mystery:
  apply_to.append_array(get_tiles({
   amount = moves.wail.mystery - apply_to.size(), 
   effect_priority = DEFAULT_EFFECT_PRIORITY, 
  }))

 mystery_seed = rng.move.randi()

 var chosen_face = choose_face()

 anim_player.play("wail")

 for i in moves.wail.count:
  await sprite.hit
  hit_player(moves.wail.damage, i == moves.wail.count - 1)
  handle_mystery(apply_to, chosen_face, i)

 await anim_player.animation_finished
 return_below_board()


func handle_mystery(apply_to, chosen_face, _hit_index):
 var tile = apply_to.pop_back()
 if tile != null:
  apply_mystery(tile, chosen_face)


func shriek():
 show_above_board()
 anim_player.play("shriek")

 for i in moves[next_move].count:
  await sprite.hit
  hit_player(moves[next_move].damage, i == moves[next_move].count - 1)

 await anim_player.animation_finished
 return_below_board()


func choose_face() -> String:
 refill_value_pool()

 var next_value: int = value_pool.pop_back()
 refill_value_pool(next_value)

 var face_pool: Array[String] = []
 for face in get_mystery_face_options():
  if Letters.get_face_value(face) == next_value:
   face_pool.append(face)

 return rng.move.pick_random(face_pool)


func get_mystery_face_options() -> Array:
 var options = Letters.ALPHABET.duplicate()
 options.erase("q")
 return options


func get_base_value_pool() -> Array[int]:
 return [1, 2, 3]


func refill_value_pool(avoid_value: int = -1) -> void :
 if value_pool.is_empty():
  value_pool = get_base_value_pool()
  rng.move.shuffle(value_pool)
  if avoid_value != -1 and value_pool[0] == avoid_value:
   value_pool.append(value_pool.pop_front())


func apply_mystery(tile: Tile, face):
 tile.set_type(TileType.DEFENSE)
 tile.remove_statuses()
 tile.add_status(TileStatus.MYSTERY, mystery_seed)
 tile.add_status(TileStatus.CRIT)
 tile.set_face(face, true, false)
 tile.add_poofcloud(tile.get_color())
 tile.animation.play("shake")


func get_save_data():
 var save = super.get_save_data()
 save.value_pool = value_pool
 return save


func load_save_data(save):
 super.load_save_data(save)
 value_pool = save.value_pool
