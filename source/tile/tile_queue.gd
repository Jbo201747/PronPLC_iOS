class_name TileQueue

signal filling_queue(census, needed_vowels, needed_consonants)
signal queue_updated(census)

const CAPITAL_PERIOD_STALL_LIMIT = 10




var queue: Dictionary[Vector2i, Dictionary] = {}

var preemptive_queue = []
var num_columns = 4
var target_coords = []
var immediate_coords = []

var rng = {
 letter = RNG.new(), 
 variation = RNG.new(), 
 placement = RNG.new(), 
 preemptive = RNG.new(), 
 fixing = RNG.new(), 
}

var capital_stall = 0
var period_stall = 0


func reseed(game_rng):
 RNG.reseed_rng_group(rng, game_rng)


func set_columns(column_count = 4):
 num_columns = column_count


func clear_outside_columns():
 for coord in queue.keys():
  if coord.x > num_columns - 1:
   queue.erase(coord)


func clear():
 queue = {}


func get_at_coord(coord):
 return queue[coord]


func get_queued_tile_coord(queued_tile: Dictionary) -> Vector2i:
 return queue.find_key(queued_tile)


func shift(by: Vector2i) -> void :
 var shifting = []
 for coord in queue:
  shifting.append({coord = coord, queued = queue[coord]})

 for shift_data in shifting:
  if is_same(queue[shift_data.coord], shift_data.queued):
   queue.erase(shift_data.coord)

  queue[shift_data.coord + by] = shift_data.queued


func get_tiles(only_immediate = false, depth = 999):
 var tiles = []
 for coord in queue:
  if only_immediate and coord not in immediate_coords:
   continue

  if (coord.y + 1) > depth:
   continue

  tiles.append(queue[coord])

 return tiles


func get_preview(column, index):
 var preview_index = 0
 var coord = Vector2i(column, 0)
 while coord in queue:
  var queued_tile = queue[coord]
  if "no_preview" not in queued_tile:
   if preview_index == index:
    return queued_tile

   preview_index += 1

  coord.y += 1

 return null


func prepare_to_fall(board_emptiness, preview_rows):
 target_coords = []
 immediate_coords = []
 for x in board_emptiness.size():
  var needed_count = board_emptiness[x] + preview_rows
  if needed_count == 0:
   continue

  for y in needed_count:
   var coord = Vector2i(x, y)
   target_coords.append(coord)
   if y < board_emptiness[x]:
    immediate_coords.append(coord)


func get_open_coords(coords):
 var open_coords = []
 for coord in coords:
  if coord not in queue:
   open_coords.append(coord)

 return open_coords


func get_top(coord: Vector2i) -> Vector2i:
 while coord in queue:
  coord.y += 1

 return coord


func get_above_coords():
 var above_coords = []
 for x in num_columns:
  above_coords.append(get_top(Vector2i(x, 0)))

 return above_coords


func get_target_coord(prefer_immediate = false):
 var target = null
 if prefer_immediate:
  var open_immediates = get_open_coords(immediate_coords)
  if open_immediates.size() > 0:
   target = rng.placement.pick_random(open_immediates)

 if not target:
  var open_targets = get_open_coords(target_coords)
  if open_targets.size() > 0:
   target = rng.placement.pick_random(open_targets)
  else:
   target = rng.placement.pick_random(get_above_coords())

 return target


func add_letter_to_census(census, letter):
 census[letter] = census.get_or_add(letter, 0) + 1


func generate_queued_tile(face = null, allow_variation = true, census = null, add_to_census = true, letter_rng: RNG = rng.letter, variation_rng: RNG = rng.variation) -> Dictionary:
 var queued_tile = {
  faces = [], 
 }

 if face != null:
  queued_tile.faces.append(face)
 else:
  if Game.player.crits_are_wildcards() and Game.tile_board.roll_crit():
   queued_tile.faces.append("*")
  else:
   if Game.main.tutorial.active:
    queued_tile.faces.append(Letters.get_random_letter(census, letter_rng, Game.main.tutorial.exclude_letters))
   else:
    queued_tile.faces.append(Letters.get_random_letter(census, letter_rng))

 if allow_variation:
  apply_tile_variation(queued_tile, variation_rng)

 if census != null and add_to_census:
  if queued_tile.faces.size() == 1 and queued_tile.faces[0] in Letters.LETTERS:
   add_letter_to_census(census, queued_tile.faces[0])

 return queued_tile


func insert_queued_tile_at(queued_tile, coord):
 if coord in queue:
  var top = get_top(coord)
  while top.y > coord.y:
   var below = Vector2i(top.x, top.y - 1)
   queue[top] = queue[below]
   queue.erase(below)
   top.y -= 1

 queue[coord] = queued_tile


func queue_tile(queued_tile, prefer_immediate = false, handle_q = true, coord = null, census = null):
 if coord == null:
  coord = get_target_coord(prefer_immediate)

 insert_queued_tile_at(queued_tile, coord)
 queue_updated.emit(census)
 if handle_q and "q" in queued_tile.faces:
  queue_tile(generate_queued_tile("u", false, census), coord in immediate_coords, false)




func apply_tile_variation(queued_tile, variation_rng: RNG):
 if capital_stall > 0:
  capital_stall -= 1

 if period_stall > 0:
  period_stall -= 1

 if queued_tile.faces.size() != 1:
  return

 var face = queued_tile.faces[0]

 var can_apply_status = []
 if capital_stall == 0:
  can_apply_status.append(Globals.TileStatus.CAPITAL)

 if period_stall == 0:
  can_apply_status.append(Globals.TileStatus.PERIOD)

 if (can_apply_status.size() > 0 and variation_rng.randf() < Game.balance.capital_period_chance):
  queued_tile.statuses = [variation_rng.pick_random(can_apply_status)]
  if Globals.TileStatus.CAPITAL in queued_tile.statuses:
   queued_tile.faces = [Letters.get_random_capital_letter(variation_rng)]
   capital_stall = CAPITAL_PERIOD_STALL_LIMIT
  else:
   queued_tile.faces = [Letters.get_random_period_letter(variation_rng)]
   period_stall = CAPITAL_PERIOD_STALL_LIMIT
 elif variation_rng.randf() < Game.balance.bigram_chance and face in Letters.ALPHABET:
  if variation_rng.randf() < Game.balance.bigram_become_trigram_chance:
   queued_tile.faces = [Letters.get_random_trigram(variation_rng)]
  else:
   queued_tile.faces = [Letters.get_random_bigram(null, variation_rng)]


func queue_word(word: String) -> Array:
 var queued_tiles = []
 for letter in word:
  var queued_tile = generate_queued_tile(letter, false)
  queue_tile(queued_tile, true, false)
  queued_tiles.append(queued_tile)

 return queued_tiles


func queue_common_word():
 var common_word = WordUtility.dictionary.pick_random_flags_word(WordDictionary.COMMON_FLAGS, 5, rng.placement)
 if not Game.debug_force_words.is_empty():
  common_word = Game.debug_force_words.pop_front()


 if Bridge.is_debug_build():
  print("Starting word: ", common_word, "\n")

 queue_word(common_word)


func set_initial_queued_type(defense_amount = 3):
 var queued_tiles = get_tiles(true)
 rng.placement.shuffle(queued_tiles)

 for queued_tile in queued_tiles:
  if "type" in queued_tile:
   continue

  if defense_amount > 0:
   queued_tile.type = Globals.TileType.DEFENSE
   defense_amount -= 1
  else:
   queued_tile.type = Globals.TileType.DAMAGE


func queued_tile_counts_to_requirements(queued_tile):
 return queued_tile.faces.size() == 1 and queued_tile.faces[0] in Letters.LETTERS


func fill_queue(needed_vowels = 0, needed_consonants = 0, census = null):
 filling_queue.emit(census, needed_vowels, needed_consonants)
 if preemptive_queue.size() > 0:
  var displace_immediates = immediate_coords.duplicate()
  rng.preemptive.shuffle(displace_immediates)
  if displace_immediates.size() > preemptive_queue.size():
   displace_immediates = displace_immediates.slice(0, preemptive_queue.size())

  displace_immediates.sort()

  rng.preemptive.shuffle(preemptive_queue)

  for coord in displace_immediates:
   var queued_tile = preemptive_queue.pop_back()
   queued_tile.no_preview = true
   insert_queued_tile_at(queued_tile, coord)

 var replaceable_immediate_tiles = []
 var replaceable_other_tiles = []
 var open_coords = get_open_coords(target_coords)
 while open_coords.size() > 0:
  var coord = rng.placement.pick_random(open_coords)
  var queued_tile = generate_queued_tile(null, true, census)
  queue_tile(queued_tile, false, true, coord, census)

  open_coords = get_open_coords(target_coords)

  if coord in immediate_coords:
   if queued_tile_counts_to_requirements(queued_tile):
    if queued_tile.faces[0] in Letters.VOWELS:
     needed_vowels -= 1
    else:
     needed_consonants -= 1

   replaceable_immediate_tiles.append(queued_tile)
  else:
   replaceable_other_tiles.append(queued_tile)

 for queued_tile in replaceable_immediate_tiles + replaceable_other_tiles:
  var counts_to_requirements = queued_tile_counts_to_requirements(queued_tile)
  var is_vowel = queued_tile.faces[0] in Letters.VOWELS
  if needed_vowels > 0:

   if counts_to_requirements and is_vowel:
    continue

   needed_vowels -= 1
   queued_tile.faces = [Letters.get_random_letter(census, rng.fixing, [], Letters.VOWELS)]
   add_letter_to_census(census, queued_tile.faces[0])
   if Bridge.is_debug_build():
    queued_tile.forced_vowel = true
    queue_updated.emit(census)
  elif needed_consonants > 0:

   if counts_to_requirements and not is_vowel:
    continue

   needed_consonants -= 1
   queued_tile.faces = [Letters.get_random_letter(census, rng.fixing, [], Letters.CONSONANTS)]
   add_letter_to_census(census, queued_tile.faces[0])
   if Bridge.is_debug_build():
    queued_tile.forced_consonant = true
    queue_updated.emit(census)
  else:
   break


func clear_targeted_coords():
 immediate_coords = []
 target_coords = []


func queue_face(face):
 var queued_tile = generate_queued_tile(face, false)
 queue_tile(queued_tile)


func pop_queue(column):
 var coord = Vector2i(column, 0)
 if not coord in queue:
  push_error("Queue was not properly filled when pop was called")

 var queued_tile = queue[coord]

 coord.y += 1
 while coord in queue:
  queue[Vector2i(coord.x, coord.y - 1)] = queue[coord]
  queue.erase(coord)
  coord.y += 1

 return queued_tile


func get_save_data():
 return {
  queue = queue, 
  capital_stall = capital_stall, 
  period_stall = period_stall, 
  rng = RNG.get_rng_group_save(rng), 
 }


func load_save_data(save):
 queue = save.queue
 capital_stall = save.capital_stall
 period_stall = save.period_stall
 RNG.load_rng_group_save(rng, save.rng)
