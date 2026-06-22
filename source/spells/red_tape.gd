extends Spell


const PRIME_NUMBERS = [2, 3, 5, 7, 11, 13, 17, 19, 23]

var special_word: String = ""


func _first_spawn(is_transform: = false) -> void :
 special_word = WordUtility.dictionary.pick_random_flags_word(WordDictionary.COMMON_FLAGS, 5, rng.spell)
 super._first_spawn(is_transform)


func get_tooltip_context():
 return {special_word = special_word}


func _use():
 var words: WordList = word_builder.get_words()
 var word_in_word_builder: bool = word_builder.can_submit_tiles() and word_builder.can_submit_words(words)

 if word_in_word_builder:
  if await section_1(words):
   return

 var tile: Tile = await get_selection()
 if tile == null:
  _end_use()
  return

 await section_2(tile, words, word_in_word_builder)

 _post_use()


func section_1(words: WordList) -> bool:
 var spell_used: bool = true
 if WordUtility.word_list_has_flag(words, WordDictionary.WordFlags.SLUR):
  laced_deactivated = true
  Game.main.game_state_updated.emit()

  Game.pause_turn_timers.emit()

  Game.screenshake(2, 0.16)

  for tile: Tile in word_builder.tiles:
   tile.add_status(TileStatus.POOP)
   tile.add_poofcloud(tile.get_color())
   Game.word_builder.update()
   await Game.timeout(0.1)

  await Game.timeout(0.5)

  await word_builder.submit_without_ending_turn(false)
 elif WordUtility.word_list_has_flag(words, WordDictionary.WordFlags.SWEAR):
  Game.screenshake(2, 0.16)

  for tile: Tile in word_builder.tiles:
   if not tile.is_space():
    tile.add_status(TileStatus.MONEY)
    tile.set_face("*")
    tile.add_poofcloud(tile.get_color())
    await Game.timeout(0.1)
 elif special_word in words.words:
  laced_deactivated = true
  Game.main.game_state_updated.emit()
  Game.screenshake(2, 0.16)

  await word_builder.submit_word()

  if max_charge > 3:
   await remove_charge(99)
   remove_max_charge(max_charge - 2)
  else:
   add_max_charge(4 - max_charge)
   await add_charge(99)

  _post_use(false)
  return true
 else:
  var has_repeat: bool = false
  var has_shimmering_repeat: bool = false
  for sub_list in words.sub_lists:
   var sub_list_has_repeat: bool = word_builder.get_repeat_word(sub_list) != ""
   has_repeat = has_repeat or sub_list_has_repeat
   if sub_list_has_repeat and sub_list.permutations.size() > 1:
    has_shimmering_repeat = true

  if has_repeat:
   if Game.balance.no_repeat_words:
    laced_deactivated = true
    Game.main.game_state_updated.emit()
    Game.screenshake(2, 0.16)
    if has_shimmering_repeat:
     await word_builder.submit_word()
    else:
     remove_charge(999, true)
     await word_builder.submit_word()
   else:
    var shuffling_tiles: Array[Tile] = []
    for tile: Tile in word_builder.tiles:
     if tile.has_face():
      shuffling_tiles.append(tile)

    var shuffle_rng = RNG.new()
    shuffle_rng.reseed(rng.spell)

    Game.screenshake(2, 0.16)

    for i in shuffling_tiles.size():
     var swap_index = shuffle_rng.randi_range(0, shuffling_tiles.size() - 1)
     if swap_index == i:
      continue

     shuffling_tiles[i].swap_face(shuffling_tiles[swap_index])
     shuffling_tiles[i].animation.play("bounce")
     shuffling_tiles[swap_index].animation.play("bounce")
     await Game.timeout(0.04)
  else:
   spell_used = false

 if spell_used:
  _post_use()

 return spell_used


func section_2(tile: Tile, words: WordList, word_in_word_builder: bool) -> void :
 var coord: Vector2i = tile.get_coord()


 if coord.y == tile_board.num_rows - 1:
  await word_builder.remove_tiles()
  await tile_board.wait_for_idle_tiles()

  var tiles_in_row = get_tiles({sorted = true, rows = [coord.y]})
  var word_list: WordList = word_builder.resolve_tile_words(tiles_in_row)
  if word_builder.can_submit_words(word_list):
   laced_deactivated = true
   Game.main.game_state_updated.emit()

   Game.pause_turn_timers.emit()

   for row_tile in tiles_in_row:
    word_builder.try_add_tile(row_tile)
    await Game.timeout(0.08)

   await tile_board.wait_for_idle_tiles()
   await Game.timeout(0.5)
   Game.screenshake(2, 0.16)

   await word_builder.submit_without_ending_turn(false)
  else:
   var tiles_in_column = get_tiles({sorted = true, columns = [coord.x], has_face = true})
   for i in range(tiles_in_column.size() - 1, -1, -1):
    var tile_a: Tile = tiles_in_column[i]

    if i == 0:
     break

    var tile_b: Tile = tiles_in_column[posmod(i - 1, tiles_in_column.size())]
    tile_a.swap_face(tile_b)

   Game.screenshake(2, 0.16)
   for i in tiles_in_column.size():
    var column_tile: Tile = tiles_in_column[i]
    column_tile.animation.play("bounce")
    await Game.timeout(0.08)
 elif tile.has_effect(TileEffect.SHIMMERING):
  var all_single_letters: bool = true
  var numberified: Array = []
  for face in tile.faces:
   if face not in Letters.ALPHABET:
    all_single_letters = false
   else:
    numberified.append(Letters.get_keypad_number(face))

  if all_single_letters:
   tile.set_face(numberified)
   tile.poof_ink()
  elif tile.has_status(TileStatus.BOMB):
   await word_builder.remove_tiles()
   await tile_board.wait_for_idle_tiles()
   await tile_board.remove_tile(tile)
  else:
   tile.add_status(TileStatus.BOMB, 1)
   tile.add_poofcloud(tile.get_color())
 elif tile.has_harmful_status():
  tile.poof_ink()
  var face_length = len(tile.face)
  if tile.has_effect(TileEffect.SLASHED):
   var first_number: = Letters.get_random_number(rng.spell)
   var second_number: = Letters.get_random_number(rng.spell, first_number)
   tile.set_slashed([first_number, second_number])
  elif face_length == 1:
   if tile.face in Letters.LETTER_VALUES:
    var value: = Letters.LETTER_VALUES[tile.face]
    if value == 1:
     tile.set_face(Letters.get_random_number(rng.spell))
    else:
     var include_letters: Array = []
     for letter in Letters.LETTER_VALUES:
      if Letters.LETTER_VALUES[letter] == value - 1:
       include_letters.append(letter)

     tile.set_face(Letters.get_random_letter(null, rng.spell, [], include_letters))
   elif tile.face == "*":
    tile.set_face("null")
   else:
    tile.set_face("*")
  elif face_length == 2:
   if tile.has_effect(TileEffect.SUIT):
    tile.randomize_similar_face(rng.spell)
   else:
    tile.set_slashed([tile.face[0], tile.face[1]])
  elif face_length == 3:
   var current_seconds: int = main.run_stats.get_current_encounter_time() / 1000
   if current_seconds % 2 == 0:
    tile.set_face(tile.face.substr(0, 2))
   else:
    tile.set_face(tile.face.substr(1, 2))
  else:

   pass
 elif word_in_word_builder and not tile.in_word() and words.words.size() == 1 and words.sub_lists.size() == 1 and words.sub_lists[0].permutations.size() == 1:
  if words.maximum_length > 3:
   if tile.is_single_letter(false):
    tile.poof_ink()
    var new_face: = Letters.shift_face(
     tile.face, 
     [Letters.ALPHABET], 
     words.maximum_length
    )
    tile.set_face(new_face)
   elif tile.face.count("*") == len(tile.face):
    tile.add_status(TileStatus.ETERNAL)
    tile.add_poofcloud(tile.get_color())
   else:
    tile.poof_ink()
    tile.randomize_similar_face(rng.spell)
  else:
   tile.poof_ink()
   tile.set_face(words.words[0])
 else:
  await section_3(tile)


func section_3(tile: Tile) -> void :
 if tile.is_type(TileType.DAMAGE):
  var plastic_tiles = get_tiles({type = TileType.DEFENSE})
  if plastic_tiles.is_empty():
   tile.set_type(TileType.DEFENSE)
  else:
   var total_plastic_value: int = 0
   for plastic_tile: Tile in plastic_tiles:
    total_plastic_value += Letters.get_face_value(plastic_tile.faces)

   if total_plastic_value < 3:
    Game.screenshake(2, 0.16)
    tile.animation.play("bounce")
    plastic_tiles[0].animation.play("bounce")
    tile.swap_face(plastic_tiles[0])
   else:
    var neighboring_plastic: Array[Tile]
    for neighbor in tile.get_board_neighbors():
     if neighbor.is_type(TileType.DEFENSE):
      neighboring_plastic.append(neighbor)

    if not neighboring_plastic.is_empty():
     await word_builder.remove_tiles()
     await tile_board.wait_for_idle_tiles()
     await tile_board.remove_tiles(neighboring_plastic, {interval = 0.08, tile_color = true})
    else:

     if get_tiles({amount = 1, sorted = true, include_effects = [TileStatus.CRIT]}).is_empty():
      if player.has_natural_crits() and Game.tile_board.crit_chance >= 0.1:
       tile.add_status(TileStatus.CRIT)
       tile.add_poofcloud(tile.get_color())
      elif get_tiles({amount = 1, sorted = true, include_effects = [TileStatus.BOMB]}).is_empty():
       tile.add_status(TileStatus.BOMB, rng.spell.randi_range(1, 3))
       tile.add_poofcloud(tile.get_color())
      else:

       pass

     else:
      tile.add_status(TileStatus.ENHANCED)
      tile.add_poofcloud(tile.get_color())


 else:
  if not tile.has_only_statuses([TileStatus.DEFAULT]):
   await BugSpray.spray_tile(tile)
  else:
   if player.health in PRIME_NUMBERS:
    tile.add_status(TileStatus.CRIT)
   elif player.health <= player.max_health / 2:
    tile.add_status(TileStatus.CANDY)
   elif get_tiles({type = TileType.DEFENSE}).size() == 1:
    tile.add_status(TileStatus.ENHANCED)
   else:
    tile.set_type(TileType.DAMAGE)

   tile.add_poofcloud(tile.get_color())


func generate_player_spell_tooltip(tooltip: GameTooltip) -> void :
 tooltip.add_mega_tooltip(StringManager.get_string("spell/red_tape/documentation", {special_word = special_word}))


func has_spell_select_tooltip() -> bool:
 return not has_curse(CURSE.CENSORED)


func generate_spell_select_tooltip(tooltip: GameTooltip) -> void :
 tooltip.add_mega_tooltip(StringManager.get_string("spell/red_tape/documentation", {special_word = special_word}))


func get_save_data():
 var save = super.get_save_data()
 save.special_word = special_word
 return save


func load_save_data(save):
 super.load_save_data(save)
 special_word = save.special_word
