extends Node

signal unlocked_spell(spell: String)
signal unlocked_achievement(achievement: String, count: int, store: bool)

const TileType = Globals.TileType
const TileStatus = Globals.TileStatus
const TileEffect = Globals.TileEffect
const ACHIEVEMENTS = Globals.ACHIEVEMENTS
const SPELLS = Globals.SPELLS
const CHARACTER_DIFFICULTY_ACHIEVEMENTS = Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS
const CHAMPION_UNLOCK_ACHIEVEMENTS = {
 0: ACHIEVEMENTS.UNLOCK_ACT_1_CHAMPIONS, 
 1: ACHIEVEMENTS.UNLOCK_ACT_2_CHAMPIONS, 
 2: ACHIEVEMENTS.UNLOCK_ACT_3_CHAMPIONS
}

var unlock_popup_queue = []

var player:
 get:
  return Game.player

var enemy:
 get:
  return Game.enemy

var total_discovered_spells:
 get:
  return SaveManager.get_save().get_discovered_spells().size()


var run_unlocking_disabled = false
var run_locking_disabled = false
var total_damage_taken = 0
var total_health_healed = 0
var consecutive_five_letter_words = 0
var natural_crits = 0
var cursed_spells_selected = 0
var total_selected_spells = 0
var paradigm_bomb_exploded = false
var dew_acid_fell = false
var total_wildcard_defense = 0


func queue_unlock_popup(unlock_id):
 unlock_popup_queue.append(unlock_id)


func sort_unlock_queue(id_a: String, id_b: String, order: Array) -> bool:
 var priority_a: int = Globals.ACHIEVEMENT_POPUP_PRIORITY.get(id_a, 0)
 var priority_b: int = Globals.ACHIEVEMENT_POPUP_PRIORITY.get(id_b, 0)
 if priority_a < priority_b:
  return true
 elif priority_b < priority_a:
  return false
 else:
  return order.find(id_a) < order.find(id_b)


func process_unlock_queue():
 var original_order: Array = unlock_popup_queue.duplicate()
 unlock_popup_queue.sort_custom(sort_unlock_queue.bind(original_order))

 if not unlock_popup_queue.is_empty():
  if not Game.tile_board.is_slid_out:
   Game.tile_board.slide_out()
   await Game.timeout(0.2)

  for unlock_id in unlock_popup_queue:
   await achievement_popup(unlock_id)

  if Game.main.board_should_come_back():
   await Game.tile_board.slide_in()

 unlock_popup_queue = []


func achievement_popup(achievement_id):
 if not Game.is_in_run():
  push_error("Achievement popup called outside of run!")
  return

 var popup = load("res://source/ui/tooltip/unlock_popup.tscn").instantiate()

 if Game.is_in_run():
  Game.main.input_wall.show()
  Game.main.input_wall.add_child(popup)
  Game.main.game_state_updated.emit()

 if achievement_id in [ACHIEVEMENTS.PRONOUNS, ACHIEVEMENTS.HAZEL_PRONOUNS]:
  popup.set_pronouns(achievement_id, Game.player.id)
 else:
  popup.set_achievement(achievement_id)

 await popup.dismissed

 if Game.is_in_run():
  Game.main.input_wall.hide()
  Game.main.game_state_updated.emit()


func reset_run_data():
 if Game.active_daily:
  run_unlocking_disabled = false
  run_locking_disabled = true
 else:
  run_unlocking_disabled = Game.is_seeded or SaveManager.options.unlocks_disabled
  run_locking_disabled = SaveManager.options.unlocks_disabled

 total_damage_taken = 0
 total_health_healed = 0
 consecutive_five_letter_words = 0
 natural_crits = 0
 cursed_spells_selected = 0
 paradigm_bomb_exploded = false
 dew_acid_fell = false
 total_selected_spells = 0

 total_wildcard_defense = 0


func get_save_data():
 var save = {
  run_unlocking_disabled = run_unlocking_disabled, 
  run_locking_disabled = run_locking_disabled, 
  total_damage_taken = total_damage_taken, 
  total_health_healed = total_health_healed, 
  consecutive_five_letter_words = consecutive_five_letter_words, 
  natural_crits = natural_crits, 
  cursed_spells_selected = cursed_spells_selected, 
  paradigm_bomb_exploded = paradigm_bomb_exploded, 
  dew_acid_fell = dew_acid_fell, 
  total_selected_spells = total_selected_spells, 
  total_wildcard_defense = total_wildcard_defense, 
 }

 return save


func load_save_data(save):
 run_unlocking_disabled = save.run_unlocking_disabled
 run_locking_disabled = save.run_locking_disabled
 total_damage_taken = save.total_damage_taken
 total_health_healed = save.total_health_healed
 consecutive_five_letter_words = save.consecutive_five_letter_words
 natural_crits = save.natural_crits
 cursed_spells_selected = save.cursed_spells_selected
 paradigm_bomb_exploded = save.get("paradigm_bomb_exploded", false)
 dew_acid_fell = save.dew_acid_fell
 total_selected_spells = save.total_selected_spells
 total_wildcard_defense = save.get("total_wildcard_defense", 0)


func completed_run():
 var save = SaveManager.get_save()
 if should_track_stats():
  save.track_character_won(player.id, Game.difficulty)
  save.track_difficulty_won(Game.difficulty)

  for spell: Spell in player.get_spells():
   if spell.secret_id != "":
    save.track_spell_won(spell.secret_id, Game.difficulty)

    if spell.secret_id in Globals.RED_LETTER_SPELLS:
     save.track_spell_won(SPELLS.RED_LETTER, Game.difficulty)

    continue

   if spell.is_clay:
    save.track_spell_won(SPELLS.TWELVE_GAUGE_CLAY, Game.difficulty)

   if spell.id in Globals.RED_LETTER_SPELLS:
    save.track_spell_won(SPELLS.RED_LETTER, Game.difficulty)

   save.track_spell_won(spell.id, Game.difficulty)


 var character_difficulty_achievement = CHARACTER_DIFFICULTY_ACHIEVEMENTS[player.id]
 unlock_achievement(ACHIEVEMENTS.OVERALL_MAX_DIFFICULTY, Game.difficulty + 1, false)

 var show_difficulty_beaten: = false
 if Game.difficulty == 9:
  show_difficulty_beaten = true

 if can_unlock_achievement(character_difficulty_achievement):
  if not has_achievement(character_difficulty_achievement, Game.difficulty + 1) and Game.difficulty < 9:
   var save_data = SaveManager.get_save_data()
   save_data.selected_character_difficulty[player.id] = Game.difficulty + 1

  if not has_achievement(character_difficulty_achievement, 1):
   queue_unlock_popup(ACHIEVEMENTS.PRONOUNS)
  elif not has_achievement(character_difficulty_achievement, 11) and Game.difficulty == 10:
   queue_unlock_popup(ACHIEVEMENTS.HAZEL_PRONOUNS)

 unlock_achievement(character_difficulty_achievement, Game.difficulty + 1, show_difficulty_beaten)

 var all_beige_beaten: = true
 var all_cerulean_beaten: = true
 for character in Globals.CHARACTERS.values():
  var other_difficulty_achievement = CHARACTER_DIFFICULTY_ACHIEVEMENTS[character]
  if not save.has_achievement(other_difficulty_achievement, 1):
   all_beige_beaten = false

  if not save.has_achievement(other_difficulty_achievement, 5):
   all_cerulean_beaten = false

 if all_beige_beaten:
  unlock_achievement(ACHIEVEMENTS.GOOD)

 if all_cerulean_beaten:
  unlock_achievement(ACHIEVEMENTS.PLUSGOOD)


 unlock_achievement(ACHIEVEMENTS.UNLOCK_JUBILIST, 1)


 check_child_achievement()


 var total_time = Game.main.run_stats.get_total_deliberation_time()
 if total_time < 1000 * 60 * 45:
  unlock_achievement(ACHIEVEMENTS.UNLOCK_ADDICT, 1)

 if player.id == Globals.CHARACTERS.LEXICOGRAPHER:
  unlock_achievement(SPELLS.RED_LETTER, 1)
  if Game.difficulty >= 4:
   unlock_achievement(SPELLS.FLOPPY_DISK, 1)

 elif player.id == Globals.CHARACTERS.JUBILIST:
  unlock_achievement(SPELLS.CLOWN_CACHE, 1)
  if Game.difficulty >= 4:
   unlock_achievement(SPELLS.PRAXICE, 1)

 elif player.id == Globals.CHARACTERS.CHILD:
  unlock_achievement(SPELLS.T_GEL, 1)
  if Game.difficulty >= 4:
   unlock_achievement(SPELLS.DAMAGED_GOODS, 1)

 elif player.id == Globals.CHARACTERS.FISHER:
  unlock_achievement(SPELLS.CORKLINE, 1)
  if Game.difficulty >= 4:
   unlock_achievement(SPELLS.FISHING_RIFLE, 1)

 elif player.id == Globals.CHARACTERS.ADDICT:
  unlock_achievement(SPELLS.DIME, 1)
  if Game.difficulty >= 4:
   unlock_achievement(SPELLS.PANIC_BUTTON, 1)


 if total_damage_taken == 0:
  unlock_achievement(SPELLS.LIP_BALM, 1)


 if total_selected_spells == 0:
  unlock_achievement(SPELLS.FUEL_RATION, 1)

 if Game.difficulty >= 4:
  unlock_achievement(SPELLS.POLITICAL_COMPASS, 1)

 if Game.difficulty >= 9:
  unlock_achievement(SPELLS.RED_TAPE, 1)

 if Game.active_daily:
  unlock_achievement(SPELLS.SSN, 1)


 var has_unused_party_ration: = false
 for spell: Spell in player.get_spells():
  if spell.id == SPELLS.PARTY_RATION and spell.secret_id == "":
   if not (spell as PartyRationSpell).was_used:
    has_unused_party_ration = true
    break

 if has_unused_party_ration:
  unlock_achievement(SPELLS.EXPIRED_RATION, 1)


func enemy_attacked(damage_received, damage_taken, defense):

 if damage_taken >= 8:
  unlock_achievement(SPELLS.EIGHT_BALL, 1)


 if (Enemies.is_enemy_or_shadow(enemy.id, Enemies.VAMPIRE) and enemy.last_move == "bite"
   and defense == 0):
  unlock_achievement(SPELLS.VAMPIRE_TEETH, 1)


 if damage_received >= 6 and total_wildcard_defense >= 6:
  unlock_achievement(SPELLS.ICE_IX, 1)


func player_hurt(amount):
 total_damage_taken += amount


func player_healed(amount, is_candy: bool):

 if amount > 0 and is_candy:
  total_health_healed += amount
  if total_health_healed >= 26:
   unlock_achievement(SPELLS.TAFFY_HOOK, 1)


func player_died():
 if should_track_stats():
  var save = SaveManager.get_save()
  save.track_character_lost(player.id, Game.difficulty)
  save.track_difficulty_lost(Game.difficulty)

  for spell in player.get_spells():
   if spell.secret_id != "":
    save.track_spell_lost(spell.secret_id, Game.difficulty)

    if spell.secret_id in Globals.RED_LETTER_SPELLS:
     save.track_spell_lost(SPELLS.RED_LETTER, Game.difficulty)

    continue

   if spell.is_clay:
    save.track_spell_lost(SPELLS.TWELVE_GAUGE_CLAY, Game.difficulty)

   if spell.id in Globals.RED_LETTER_SPELLS:
    save.track_spell_lost(SPELLS.RED_LETTER, Game.difficulty)

   save.track_spell_lost(spell.id, Game.difficulty)


 unlock_achievement(Globals.ACHIEVEMENTS.UNLOCK_CHILD, 1)

 if Game.enemy != null:
  if Game.enemy.id == Enemies.FOREIGN_BODY and Game.enemy.is_gold:
   unlock_achievement(Globals.ACHIEVEMENTS.PEE_YOUR_PANTS)


func enemy_died():

 if player.health < 3:
  unlock_achievement(SPELLS.BROKEN_HEART, 1)


 if Enemies.is_shadow(enemy.id):
  unlock_achievement(SPELLS.DRAFT_CARD, 1)


 var save = SaveManager.get_save()
 if save.get_play_time() > 1000 * 60 * 60 * 8:
  unlock_achievement(SPELLS.SKINNER_BOX, 1)


 if enemy.id == Enemies.NEW_COP:
  if enemy.is_deflated:
   unlock_achievement(SPELLS.SIX_SHOOTER, 1)


 elif Enemies.is_enemy_or_shadow(enemy.id, Enemies.PARADIGM):
  if not paradigm_bomb_exploded:
   unlock_achievement(SPELLS.C4, 1)


 elif Enemies.is_enemy_or_shadow(enemy.id, Enemies.DEW_JUBILIST):
  if not dew_acid_fell:
   unlock_achievement(SPELLS.VERIFICATION_CAN, 1)

 try_unlock_champions()


func found_spell(spell: Spell) -> void :
 if should_track_stats():
  SaveManager.get_save().track_spell_found(spell.id, Game.difficulty)


func used_spell(spell: Spell) -> void :
 if should_track_stats():
  var save: = SaveManager.get_save()
  save.track_spell_used(spell.id, Game.difficulty)
  if spell.secret_id != "" and spell.secret_id != spell.id:
   save.track_spell_used(spell.secret_id, Game.difficulty)

 check_modern_heart()


func replaced_spell(spell: Spell) -> void :
 if should_track_stats():
  SaveManager.get_save().track_spell_replaced(spell.id, Game.difficulty)


func selected_spell(spell: Spell) -> void :
 total_selected_spells += 1

 discover_spell(spell.id)
 if should_track_stats():
  SaveManager.get_save().track_spell_taken(spell.id, Game.difficulty)


 if total_discovered_spells >= 30:
  unlock_achievement(SPELLS.TWELVE_GAUGE_CLAY, 1)


 if spell.is_cursed():
  cursed_spells_selected += 1

 if cursed_spells_selected >= 3:
  unlock_achievement(SPELLS.SOBRIETY_TEST, 1)


func submitted_words(words: WordList, tiles, damage, _defense, _healing, tile_defense):
 if "alright" in words.words:
  unlock_achievement(ACHIEVEMENTS.LINGUISTIC_DRIFT)

 for sub_list in words.sub_lists:

  if sub_list.maximum_length >= 10:
   unlock_achievement(Globals.ACHIEVEMENTS.UNLOCK_FISHER, 1)


  if (sub_list.maximum_length >= 8
   and sub_list.tiles_list[-1].has_status(TileStatus.PERIOD)):
    unlock_achievement(SPELLS.COTTON_CANDY_TAMPON, 1)


 for sub_list in words.sub_lists:
  if sub_list.minimum_length == 5 and sub_list.maximum_length == 5:
   consecutive_five_letter_words += 1
  else:
   consecutive_five_letter_words = 0
   break

 if consecutive_five_letter_words >= 5:
  unlock_achievement(SPELLS.PENTAMETER, 1)


 var num_linked_tiles = 0

 if Enemies.is_enemy_or_shadow(enemy.id, Enemies.UMAMI):
  for tile in tiles:
   if tile.has_status(TileStatus.LINKED):
    num_linked_tiles += 1

  if num_linked_tiles >= 4:
   unlock_achievement(SPELLS.SEALED_PACKET, 1)


 for sub_list in words.sub_lists:
  var num_yuri = 0
  var num_yaoi = 0
  for tile in sub_list.tiles:
   if tile.has_status(TileStatus.GAY):
    if tile.is_type(TileType.DAMAGE):
     num_yuri += 1
    else:
     num_yaoi += 1

  if num_yuri >= 3 and num_yaoi >= 3:
   unlock_achievement(SPELLS.SLASHFIC, 1)


 for word in words.words:
  var num_double_letters = 0
  var skip_next_letter = false

  for i in range(word.length()):
   if i == word.length() - 1:
    break



   if skip_next_letter:
    skip_next_letter = false
    continue

   var letter = word[i]
   var next_letter = word[i + 1]

   if letter == next_letter:
    num_double_letters += 1
    skip_next_letter = true

  if num_double_letters >= 2:
   unlock_achievement(SPELLS.GRAY_GOO, 1)
   break


 for sub_list in words.sub_lists:
  var num_shimmering_tiles = 0
  for tile in sub_list.tiles:
   if tile.is_shimmering():
    num_shimmering_tiles += 1

  if num_shimmering_tiles >= 2:
   unlock_achievement(SPELLS.GIRL_CHUNKS, 1)
   break


 if damage < 0 and Enemies.is_enemy_or_shadow(enemy.id, Enemies.AGE_REGRESSOR) and not player.is_defeated:
  unlock_achievement(SPELLS.RETZ, 1)


 if damage >= 40:
  unlock_achievement(SPELLS.GUROLAGA, 1)


 for tile in tiles:
  if (tile.has_effect(TileEffect.WILDCARD)
    and (tile.is_type(TileType.DEFENSE)
    or tile.has_status(TileStatus.FROZEN))):
   total_wildcard_defense += tile.get_value()


 var sub_total_tile_value = 0

 for sub_list in words.sub_lists:
  sub_total_tile_value = 0

  if sub_list.maximum_length >= 6:
   for tile in sub_list.tiles:
    sub_total_tile_value += tile.get_value()

   if sub_total_tile_value == 0:
    unlock_achievement(SPELLS.TUMOR, 1)


 for sub_list in words.sub_lists:
  var total_statuses = []
  for tile: Tile in sub_list.tiles:
   const EXEMPT_STATUSES = [TileStatus.DEFAULT, TileStatus.CAPITAL, TileStatus.PERIOD]

   for status in tile.get_statuses():
    if status.is_space() or status.face_status:
     continue

    var status_id: = status.id

    var status_ref: Variant = status_id
    if status.type_unique_status:
     status_ref = {id = status_id, type = tile.type}

    if (status_ref not in total_statuses
      and status_ref not in EXEMPT_STATUSES):
     total_statuses.append(status_ref)

  if total_statuses.size() >= 5:
   unlock_achievement(SPELLS.DNA_TWEEZERS, 1)


 for tile in tiles:
  if tile.get_value() >= 9:
   unlock_achievement(SPELLS.SOCKPUPPET, 1)


 for sub_list in words.sub_lists:
  if sub_list.maximum_length >= 5:
   var only_numbers = true
   for tile in sub_list.tiles:
    for face in tile.faces:
     for letter in face:
      if not letter in Letters.NUMPAD_CHARACTERS:
       only_numbers = false
       break

     if not only_numbers:
      break

    if not only_numbers:
     break

   if only_numbers:
    unlock_achievement(SPELLS.ROTARY_DIAL, 1)

 for sub_list in words.sub_lists:
  if sub_list.maximum_length == 3 and sub_list.minimum_length == 3:
   unlock_achievement(SPELLS.MBA, 1)
   break


 if tile_defense >= 20:
  unlock_achievement(SPELLS.PERFECT_METAL_CARAPACE, 1)


 if WordUtility.word_list_has_flag(words, WordDictionary.WordFlags.SLUR):
  unlock_achievement(SPELLS.JO_PERMIT, 1)


 for sub_list in words.sub_lists:
  if sub_list.maximum_length >= 8 and sub_list.tiles.size() <= 4:
   unlock_achievement(SPELLS.WAX_STAMP)
   break


 if words.sub_lists.size() >= 4:
  unlock_achievement(SPELLS.MOOD_SCREW)

 var save: = SaveManager.get_save()
 for word in words.words:
  save.track_word(word)

 var vocabulary_size: = mini(save.word_stats.size(), Globals.QOL_ADJUSTMENT_COUNT)
 unlock_achievement(ACHIEVEMENTS.QUALITY_OF_LIFE_ADJUSTMENT, vocabulary_size, vocabulary_size >= Globals.QOL_ADJUSTMENT_COUNT)

 Bridge.request_update_stats.emit()


func start_player_turn() -> void :
 total_wildcard_defense = 0


func turn_ended():
 natural_crits = 0
 check_modern_heart()


func rolled_crit():
 natural_crits += 1


 if natural_crits >= 4:
  unlock_achievement(SPELLS.LUCKY_CAT, 1)


func bomb_exploded():

 unlock_achievement(SPELLS.CATS_CRADLE, 1)

 if Enemies.is_enemy_or_shadow(enemy.id, Enemies.PARADIGM):
  paradigm_bomb_exploded = true


func acid_fell():
 if Enemies.is_enemy_or_shadow(enemy.id, Enemies.DEW_JUBILIST):
  dew_acid_fell = true


func deliberation_tracked(time_ms):
 SaveManager.get_save().track_deliberation_time(time_ms)


func play_time_tracked(time_ms):
 SaveManager.get_save().track_play_time(time_ms)


func discover_spell(spell_id):
 if run_unlocking_disabled:
  return

 SaveManager.get_save().discover_spell(spell_id)


func check_modern_heart():
 if unlocking_disabled():
  return


 if Game.tile_board.restock_locked:
  var tiles = Game.tile_board.get_tiles({sorted = true})
  if tiles.is_empty():
   unlock_achievement(SPELLS.MODERN_HEART, 1)


func check_child_achievement() -> void :
 if not can_unlock_progression():
  return

 var beaten_with_all_characters: = true
 for character_id in Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS:
  if character_id == Globals.CHARACTERS.CHILD:
   continue

  var achievement = Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS[character_id]
  if not has_achievement(achievement, 1):
   beaten_with_all_characters = false

 if beaten_with_all_characters:
  unlock_achievement(ACHIEVEMENTS.UNLOCK_CHILD, 1, true, {alternate_unlock = true})


func started_run():
 unlock_achievement(ACHIEVEMENTS.FIRST_RUN, 1, false)


func champions_unlocked_for_act(act):
 return has_achievement(CHAMPION_UNLOCK_ACHIEVEMENTS[act])


func try_unlock_champions_for_act(act):
 var act_pool = Enemies.POOLS[act]
 var num_killed = 0
 for enemy_set in act_pool:
  for enemy_id in enemy_set:
   if enemy_id == Enemies.NOBODY:
    continue

   var stats = SaveManager.get_save().get_enemy_stats(enemy_id, -1, false)
   if stats.kills > 0:
    num_killed += 1

 var achievement_id = CHAMPION_UNLOCK_ACHIEVEMENTS[act]
 if num_killed == Globals.ACHIEVEMENT_COUNTS[achievement_id]:
  unlock_achievement(achievement_id, num_killed)
 else:
  unlock_achievement(achievement_id, num_killed, false)


func try_unlock_champions():
 for act in range(3):
  try_unlock_champions_for_act(act)


func try_unlock_phonebook_finished(only_if_complete = false):
 var read_entries = 0
 for enemy_id in Enemies.list():
  if SaveManager.get_save().has_enemy_been_read(enemy_id):
   read_entries += 1

 if read_entries == Globals.ACHIEVEMENT_COUNTS[ACHIEVEMENTS.READ_FULL_PHONEBOOK] or not only_if_complete:
  unlock_achievement(ACHIEVEMENTS.READ_FULL_PHONEBOOK, read_entries, false)


func should_track_stats() -> bool:
 return not Game.is_seeded or Game.active_daily


func unlocking_disabled(ignore_tutorial: = false):
 if Game.is_in_run():
  if Game.main.tutorial.active and not ignore_tutorial:
   return true
  else:
   return run_unlocking_disabled
 else:
  return SaveManager.get_unlocks_disabled()


func locking_disabled():
 if Game.is_in_run():
  return run_locking_disabled
 else:
  return SaveManager.get_unlocks_disabled()


func can_unlock_achievement(id, ignore_tutorial: = true):
 if id in Globals.ALWAYS_UNLOCKABLE_ACHIEVEMENTS:
  return true

 if unlocking_disabled(ignore_tutorial):
  return false

 if Game.is_in_run() and Game.active_daily and id in Globals.DAILY_BLOCKED_ACHIEVEMENTS:
  return false
 else:
  return true


func can_unlock_progression() -> bool:
 return can_unlock_achievement(Globals.ACHIEVEMENTS.OVERALL_MAX_DIFFICULTY)


func has_achievement(achievement: String, minimum_count: int = -1) -> bool:
 if not SaveManager.has_valid_selected_save():
  return false

 if locking_disabled():
  return true

 if minimum_count == -1:
  if achievement in Globals.ACHIEVEMENT_COUNTS:
   minimum_count = Globals.ACHIEVEMENT_COUNTS[achievement]
   if achievement in Globals.ACHIEVEMENT_EXTRA_COUNTS:
    minimum_count -= Globals.ACHIEVEMENT_EXTRA_COUNTS[achievement]
    minimum_count = maxi(minimum_count, 1)
  else:
   minimum_count = 1

 var save: = SaveManager.get_save()
 return save.get_achievement_level(achievement) >= minimum_count


func get_achievement_level(achievement, max_if_disabled = false):
 if locking_disabled() and max_if_disabled:
  if achievement in Globals.ACHIEVEMENT_COUNTS:
   return Globals.ACHIEVEMENT_COUNTS[achievement]
  else:
   return 1

 var save: = SaveManager.get_save()
 return save.get_achievement_level(achievement)


func unlock_achievement(achievement, count = 1, popup: bool = true, metadata: Dictionary = {}):
 if Game.debug_print_achievement_unlocks:
  print("Unlocked achievement ", achievement)

 if Game.is_in_run() and not can_unlock_achievement(achievement, false):
  return

 if achievement in Globals.ACHIEVEMENT_COUNTS and Globals.ACHIEVEMENT_COUNTS[achievement] == 0:
  if popup:
   queue_unlock_popup(achievement)

  return

 var store = true

 var save: = SaveManager.get_save()
 if not save.has_achievement(achievement, count):
  save.set_achievement_level(achievement, count)
  if not metadata.is_empty():
   save.set_achievement_metadata(achievement, metadata)

  if achievement in Globals.SPELL_ACHIEVEMENTS:
   unlocked_spell.emit(achievement)
 else:
  store = false

 unlocked_achievement.emit(achievement, count, store)

 if store:
  if popup:
   queue_unlock_popup(achievement)

  SaveManager.store_selected_save()

 if achievement != ACHIEVEMENTS.DOUBLEPLUSGOOD:
  if save.count_achievements() >= Globals.get_total_achievement_count() - 1:
   unlock_achievement(ACHIEVEMENTS.DOUBLEPLUSGOOD)


func get_achievement_string_group(id: String) -> StringManager.StringGroup:
 if id in Globals.SPELL_ACHIEVEMENTS:
  return StringManager.get_string_group("spell/" + id)
 else:
  return StringManager.get_string_group("achievements/" + id)


func get_achievement_title(id: String, for_popup: = false) -> String:
 var context: Dictionary = {}
 if SaveManager.has_valid_selected_save():
  context = SaveManager.get_save().get_achievement_metadata(id)

 var group: = get_achievement_string_group(id)
 var title: = group.get_string("name", context)
 if for_popup:
  if group.has_string("unlock_name"):
   return group.get_string("unlock_name", context)
  else:
   return StringManager.get_string("achievements/unlocked_name", {achievement = title})
 elif not has_achievement(id):
  return StringManager.get_string("achievements/locked")

 return title


func get_achievement_description(id: String) -> String:
 var context: Dictionary = {}
 if SaveManager.has_valid_selected_save():
  context = SaveManager.get_save().get_achievement_metadata(id)

 context.locked = not has_achievement(id)
 var group: = get_achievement_string_group(id)
 var description: = group.get_string("unlock", context)
 return description
