extends Enemy


const LETTERS = Letters.LETTERS
const LETTER_VALUES = Letters.LETTER_VALUES

const SWEARS = [
 "fuck", 
 "damn", 
 "shit", 
 "piss", 
 "hell", 
 "crap", 
]

var lotd_queue = {
 easy = [], 
 hard = [], 
}

var lotd = ""
var active_lotd = ""

var Fishbowl = preload("res://source/effects/fishbowl_projectile.tscn")

@onready var tile_marker = $Sprite / TileMarker
@onready var fish_marker = $Sprite / FishMarker


func _init():
 id = Enemies.ELMER
 next_move = "announce"

 moves = {
  announce = {
   damage = {
    0: 2, 
    1: 3, 
    3: 4, 
   }, 
   scrabble_pools = [
    [1], 
    [3, 2, 2, 1, 1, 1, 1], 
   ], 
   next = "interrogate", 
  }, 
  interrogate = {
   damage = {
    0: 5, 
    2: 6, 
    3: 7, 
   }, 
   cursed = 1, 
   use_rare = {
    0: false, 
    1: true, 
   }, 
   scrabble_pools = [
    [1], 
    [3, 2, 2, 1, 1, 1, 1], 
   ], 
   next = "announce", 
  }, 
  morose = {
   next = "morose", 
  }, 
 }


func _init_rng():
 super._init_rng()
 rng.swear = RNG.new()


func prepare_next_turn():
 if next_move != "morose":
  pick_lotd()

 if "scrabble_pools" in moves[next_move]:
  var multipliers = []

  for pool in moves[next_move].scrabble_pools:
   append_scrabble_pool(multipliers, pool)

  multipliers = audit_scrabble_pool(multipliers)

  if multipliers.size() != 0:
   word_builder.slot_multipliers = multipliers
 else:
  word_builder.slot_multipliers = []

 super.prepare_next_turn()


func display_intent():
 if next_move == "announce":
  add_intent(Intent.ATTACK, {damage = moves.announce.damage})

 elif next_move == "interrogate":
  add_intent(Intent.ATTACK, {damage = moves.interrogate.damage})
  add_intent(Intent.CURSED_CAPITAL, {count = moves.interrogate.cursed, letter = lotd})


func announce():
 anim_player.play("ask_deborah")
 anim_player.queue("idle")
 await sprite.hit
 await throw_fish()

 hit_player(moves.announce.damage)


func interrogate():
 active_lotd = lotd

 if rng.move.randi_range(0, 1) == 0:
  anim_player.play("announce")
 else:
  anim_player.play("announce_alt")

 await sprite.hit
 apply_cursed()

 await sprite.hit
 hit_player(moves.interrogate.damage)

 await anim_player.animation_finished
 anim_player.queue("idle")



func audit_scrabble_pool(multipliers):
 var has_early_mult = false
 var has_late_mult = false
 var i = 0

 for mult in multipliers:
  if mult > 1 and i < 4:
   has_early_mult = true
  elif mult > 1 and i >= 4:
   has_late_mult = true

  i += 1

 if not has_early_mult:
  multipliers = move_first_mult(multipliers, 1, 3)
 if not has_late_mult:
  multipliers = move_first_mult(multipliers, 4, 7)

 return multipliers


func move_first_mult(multipliers, from, to):
 var i = 0

 for mult in multipliers:
  if mult > 1:
   multipliers.remove_at(i)
   multipliers.insert(rng.move.randi_range(from, to), mult)
   break

  i += 1

 return multipliers


func apply_cursed():
 active_lotd = lotd

 var new_face = lotd
 var x_replacements = ["ax", "ex", "ox"]
 rng.move.shuffle(x_replacements)

 var target_tiles = get_tiles({
  amount = moves.interrogate.cursed, 
  effect_priority = DEFAULT_EFFECT_PRIORITY, 
 })

 for tile in target_tiles:
  if lotd == "q":
   new_face = "qu"
  elif lotd == "x":
   new_face = x_replacements.pop_back()

  tile.set_face(new_face)
  tile.set_type(TileType.DAMAGE)

  tile.add_status(TileStatus.CAPITAL)
  tile.add_status(TileStatus.CURSED)

  tile.add_poofcloud(tile.get_color())


func throw_fish():
 var fishbowl = Fishbowl.instantiate()
 var start = fish_marker.global_position
 var dest = Game.player.hit_marker.global_position

 main.add_child(fishbowl)
 fishbowl.launch(start, dest, 60)

 await fishbowl.impacted
 AudioManager.play_sound(Sounds.ELMER.DEBORAH_IMPACT)


func swear():
 next_move_override = "morose"

 var start = tile_marker.global_position

 var swear_pool = SWEARS
 var swear_word = Array(rng.swear.pick_random(swear_pool).split())

 var target_coords = get_tiles({
  amount = swear_word.size(), 
  rows = [rng.swear.pick_random(tile_board.get_row_coords())], 
  get_coords = true, 
  empty = null, 
  sorted = true, 
 })

 var tile_types = [TileType.DAMAGE, TileType.DAMAGE, TileType.DEFENSE, TileType.DEFENSE]
 rng.swear.shuffle(tile_types)

 anim_player.play("crash_out")
 await sprite.hit

 num_projectiles = target_coords.size()
 for coord in target_coords:
  var tile = tile_board.create_tile()

  main.add_child(tile)
  tile.impacted.connect(_on_projectile_impacted)

  tile.set_face(swear_word.pop_front())
  tile.add_status(TileStatus.CURSED)
  tile.add_status(TileStatus.CAPITAL)
  tile.set_type(tile_types.pop_back())

  tile.launch(start, tile_board.get_coord_position(coord), randf_range(60, 100), coord, 800, false, true)
  await Game.timeout(0.16)

 if num_projectiles > 0:
  await all_projectiles_impacted



func pick_lotd():
 var total_lotds = (times_performed_move.interrogate)

 if lotd_queue.easy.is_empty() and lotd_queue.hard.is_empty():
  fill_lotd_queue()

 if total_lotds % 2 == 0 or lotd_queue.hard.is_empty():
  lotd = lotd_queue.easy.pop_front()

 elif total_lotds % 2 != 0 or lotd_queue.easy.is_empty():
  lotd = lotd_queue.hard.pop_front()




func fill_lotd_queue():
 lotd_queue.easy = []
 lotd_queue.hard = []

 for letter in LETTERS:
  if LETTER_VALUES[letter] == 3 and not moves.interrogate.use_rare:
   continue

  if LETTER_VALUES[letter] == 1:
   lotd_queue.easy.append(letter)
  else:
   lotd_queue.hard.append(letter)



 for key in lotd_queue:
  var queue = lotd_queue[key]
  rng.move.shuffle(queue)

  if queue[0] == lotd:
   queue.pop_front()
   queue.append(lotd)


func morose():
 anim_player.play("flinch")
 await anim_player.animation_finished

 if times_performed_move.morose >= 2:
  hurt(999)


func flinch(_damage):
 clear_intent()
 await super.flinch(_damage)
 if main.is_player_turn:
  update_intents()


func animate_flinch(damage):
 var was_sworn_at: = false
 if word_builder.is_submitting:
  var words: WordList = word_builder.get_words()
  if WordUtility.word_list_has_flag(words, WordDictionary.SWEAR_FLAGS):
   was_sworn_at = true

 if not was_sworn_at:
  await super.animate_flinch(damage)
 else:
  anim_player.play("flinch_sock_mupper")
  await anim_player.animation_finished


func animate_flinch_lethal():
 word_builder.slot_multipliers = []

 AudioManager.play_sound(Sounds.ELMER.DEATH_2)
 anim_player.play("dying")

 for _i in range(3):
  await sprite.animation_looped

 anim_player.play("die")
 await anim_player.animation_finished


func get_save_data():
 var save = super.get_save_data()

 save["lotd"] = lotd
 save["active_lotd"] = active_lotd
 save["lotd_queue"] = lotd_queue
 if word_builder.slot_multipliers.size() != 0:
  save["multipliers"] = word_builder.slot_multipliers

 return save


func load_save_data(save):
 super.load_save_data(save)

 lotd = save.lotd
 lotd_queue = save.lotd_queue

 if "multipliers" in save:
  word_builder.slot_multipliers = save.multipliers
