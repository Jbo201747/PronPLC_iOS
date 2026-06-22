class_name SaveFile extends RefCounted


const SAVE_FORMAT_VERSION = 3

const SAVE_FILENAME = "progress.save"
const RUN_FILENAME = "run.save"
const DAILY_FILENAME = "daily.save"

const STATS_FILENAME = "stats.save"
const WORD_STATS_FILENAME = "word_stats.save"

const MOD_DATA_FILENAME = "mod_data.save"

const METADATA_DEFAULTS = {
 achievements_unlocked = 0, 
 achievements_unlocked_extra = -1, 
 any_difficulty_won = false, 
}

const SAVE_DEFAULTS = {
 achievements = {}, 
 achievement_metadata = {}, 
 obsolete_achievements = {}, 
 cutscenes_viewed = {}, 
 nobody_cutscenes_viewed = {}, 
 selected_phonebook_entry = "", 
 selected_phonebook_entries = {}, 
 selected_character = Globals.CHARACTERS.LEXICOGRAPHER, 
 selected_character_difficulty = {
  Globals.CHARACTERS.LEXICOGRAPHER: 0, 
  Globals.CHARACTERS.JUBILIST: 0, 
  Globals.CHARACTERS.CHILD: 0, 
  Globals.CHARACTERS.FISHER: 0, 
  Globals.CHARACTERS.ADDICT: 0, 
 }, 
 selected_difficulty = 0, 

 latest_played_daily = [-1, -1, -1], 
 stored_scores = {}, 
 seen_first_spell_select = false, 
 seen_tutorial = false, 
}

const STATS_DEFAULTS = {
 total_play_time = 0, 
 total_deliberation_time = 0, 
 discovered_spells = [], 
 difficulty = {}, 
 streak = 0, 
 best_streak = 0, 
 worst_streak = 0, 
 fastest_win = -1, 
 phonebook_entries_read = {
  enemy = {

  }, 
 }, 
}

const ENEMY_STAT_DEFAULTS = {
 encounters = 0, 
 kills = 0, 
 losses = 0, 
}

const DIFFICULTY_STAT_DEFAULTS = {
 wins = 0, 
 losses = 0, 
 streak = 0, 
 best_streak = 0, 
 worst_streak = 0, 
 initial_losses = 0, 
 enemy_stats = {}, 
 character_stats = {}, 
 spell_stats = {}, 
}

const CHARACTER_STAT_DEFAULTS = {
 wins = 0, 
 losses = 0, 
 fastest_win = -1, 
}

const SPELL_STAT_DEFAULTS = {
 found = 0, 
 taken = 0, 
 replaced = 0, 
 used = 0, 
 wins = 0, 
 losses = 0, 
}

var name: String

var metadata_loaded: bool = false
var metadata: Dictionary

var data_loaded: bool = false
var data: Dictionary

var stats_loaded: bool = false
var stats: Dictionary

var word_stats_loaded: bool = false
var word_stats: Dictionary

var mod_data_loaded: bool = false
var mod_data: Dictionary

var corrupt: = false


static func create_new(_name: String) -> SaveFile:
 var save_file: = SaveFile.new(_name)
 save_file.data = {}
 save_file.stats = {}
 save_file.word_stats = {}
 save_file.set_default_save_data()
 save_file.set_default_stats()
 return save_file


static func create_copy(_name: String, original: SaveFile) -> SaveFile:
 var save_file: = SaveFile.new(_name)
 save_file.copy_from(original)
 return save_file


func _init(_name: String):
 name = _name


func get_directory_path() -> String:
 return SaveManager.get_save_directory_path(name)


func get_filepath(filename: String) -> String:
 return get_directory_path().path_join(filename)


func has_directory() -> bool:
 return DirAccess.dir_exists_absolute(get_directory_path())


func has_file(filename: String) -> bool:
 return FileAccess.file_exists(get_filepath(filename))


func has_valid_file() -> bool:
 return has_file(SAVE_FILENAME) or has_file(SaveMigration.OLD_SAVE_FILENAME)


func delete_file(filename: String):
 if has_file(filename):
  DirAccess.remove_absolute(get_filepath(filename))


func read_bytes_from_file(file: FileAccess, filepath: String) -> PackedByteArray:
 var length: = file.get_length()
 if length < file.get_position() + 9:
  push_error("Failed to read byte array in file ", filepath, ": File corrupted. (Invalid file header)")
  return PackedByteArray()

 var is_compressed: = file.get_8()
 var bytes_size: = file.get_64()
 var compression_mode: int = -1
 var decompressed_bytes: int = -1
 if is_compressed == 1:
  if length < file.get_position() + 9:
   push_error("Failed to read byte array in file ", filepath, ": File corrupted. (Invalid compression header)")
   return PackedByteArray()

  compression_mode = file.get_8()
  if compression_mode < 0 or compression_mode > 4:
   push_error("Failed to read byte array in file ", filepath, ": File corrupted. (Invalid compression mode)")
   return PackedByteArray()

  decompressed_bytes = file.get_64()

 if length < file.get_position() + bytes_size:
  push_error("Failed to read byte array in file ", filepath, ": File corrupted. (Invalid byte array size)")
  return PackedByteArray()

 var byte_array: = file.get_buffer(bytes_size)
 if compression_mode != -1:
  byte_array = byte_array.decompress(decompressed_bytes, compression_mode)

 return byte_array


func read_dictionary_from_file(file: FileAccess, filepath: String) -> Dictionary:
 var bytes: = read_bytes_from_file(file, filepath)

 if bytes.has_encoded_var(0, false):
  var dict: Variant = bytes.decode_var(0)
  if dict == null or dict is not Dictionary:
   push_error("Failed to load file ", filepath, ": Invalid encoded dictionary. (Non-dictionary type)")
   return {load_failed = true}
  else:
   return dict
 else:
  push_error("Failed to load file ", filepath, ": Invalid encoded dictionary.")

 return {load_failed = true}


func open_save_file(filepath: String, migration_function: Callable) -> FileAccess:
 var file = FileAccess.open(filepath, FileAccess.READ)
 var file_length: = file.get_length()
 if not file or file_length < 8:
  push_error("Failed to load file ", filepath, ": File empty.")
  return null

 var version: = file.get_64()
 if version != SAVE_FORMAT_VERSION:
  if migration_function.is_valid():
   file = null
   var result: bool = migration_function.call(filepath, version)
   if result:
    return open_save_file(filepath, migration_function)
   else:
    return null

 return file


func load_data_file(filepath: String, migration_function: Callable) -> Dictionary:
 var file: = open_save_file(filepath, migration_function)
 if not file:
  push_error("Failed to load data file ", filepath, ".")
  return {load_failed = true}

 return read_dictionary_from_file(file, filepath)


func load_data_metadata_file(filepath: String, migration_function: Callable, load_data: bool) -> Dictionary:
 var file: = open_save_file(filepath, migration_function)
 if not file:
  push_error("Failed to load data file ", filepath, ".")
  return {}

 var out: Dictionary = {}
 var read_metadata: = read_dictionary_from_file(file, filepath)
 if "load_failed" not in read_metadata:
  out.metadata = read_metadata

 if load_data:
  var read_data: = read_dictionary_from_file(file, filepath)
  if "load_failed" not in read_data:
   out.data = read_data

 return out


func load_progress_file(filepath: String, load_data: = true) -> void :
 var file_data: = load_data_metadata_file(filepath, SaveMigration.migrate_save, load_data)

 if file_data.is_empty() or file_data.metadata.is_empty():
  return

 metadata = file_data.metadata
 set_default_metadata()
 metadata_loaded = true

 if load_data:
  if "data" not in file_data or file_data.data.is_empty():
   return

  data = file_data.data
  set_default_save_data()

  if not "game_version" in metadata or metadata.game_version != SaveManager.game_version:
   SaveMigration.generic_migration(self)

  generate_metadata()
  data_loaded = true


func load_stats_file(filepath: String) -> void :
 var dictionary: = load_data_file(filepath, SaveMigration.migrate_stats)
 if "load_failed" in dictionary:
  return

 stats = dictionary
 set_default_stats()
 stats_loaded = true


func load_word_stats_file(filepath: String) -> void :
 var dictionary: = load_data_file(filepath, SaveMigration.migrate_word_stats)
 if "load_failed" in dictionary:
  return

 word_stats = dictionary
 word_stats_loaded = true


func load_mod_data_file(filepath: String) -> void :
 var dictionary: = load_data_file(filepath, Callable())
 if "load_failed" in dictionary:
  return

 mod_data = dictionary

 for mod in ModLoader.get_active_mods():
  if mod.mod_data.id in mod_data:
   mod.load_save_data(mod_data[mod.mod_data.id])

 mod_data_loaded = true


func load_file(load_data: = true) -> void :
 metadata_loaded = false
 if load_data:
  data_loaded = false
  stats_loaded = false
  word_stats_loaded = false

 if load_data:
  if not stats_loaded:
   if has_file(STATS_FILENAME):
    load_stats_file(get_filepath(STATS_FILENAME))
    if not stats_loaded:
     corrupt = true
   else:
    stats = {}
    set_default_stats()

  if not word_stats_loaded:
   if has_file(WORD_STATS_FILENAME):
    load_word_stats_file(get_filepath(WORD_STATS_FILENAME))
    if not word_stats_loaded:
     corrupt = true
   else:
    word_stats = {}

  if not mod_data_loaded:
   if has_file(MOD_DATA_FILENAME):
    load_mod_data_file(get_filepath(MOD_DATA_FILENAME))

    if not mod_data_loaded:
     corrupt = true
   else:
    mod_data = {}

 if has_file(SAVE_FILENAME):
  load_progress_file(get_filepath(SAVE_FILENAME), load_data)
 elif has_file(SaveMigration.OLD_SAVE_FILENAME):
  SaveMigration.migrate_old_save_format(self)
  if not corrupt and has_file(SAVE_FILENAME):
   load_progress_file(get_filepath(SAVE_FILENAME), load_data)

 if not metadata_loaded:
  corrupt = true

 if load_data and not data_loaded:
  corrupt = true


static func store_dictionary_to_file(file: FileAccess, dictionary: Dictionary, compression: int = -1) -> void :
 var bytes: = var_to_bytes(dictionary)
 var compressed_bytes: PackedByteArray
 if compression != -1:
  file.store_8(1)
  compressed_bytes = bytes.compress(compression)
  file.store_64(compressed_bytes.size())
  file.store_8(compression)
  file.store_64(bytes.size())
  file.store_buffer(compressed_bytes)
 else:
  file.store_8(0)
  file.store_64(bytes.size())
  file.store_buffer(bytes)


static func start_writing_save_file(filepath: String) -> FileAccess:
 var file: = FileAccess.open(filepath + ".tmp", FileAccess.WRITE)
 if not file:
  var error = FileAccess.get_open_error()
  push_error("Error opening file for write " + filepath + " " + str(error))
  return null

 file.store_64(SAVE_FORMAT_VERSION)
 return file


static func finish_writing_save_file(file: FileAccess, filepath: String) -> bool:
 if file.get_length() == 0:
  file.close()
  push_error("Temp file written to incorrectly ", filepath)
  return false

 file.close()

 var error: = DirAccess.rename_absolute(filepath + ".tmp", filepath)
 if error != OK:
  push_error("Error writing file ", filepath, " when copying from tmp: ", str(error))
  return false

 return true


static func store_data_metadata_file(filepath: String, file_metadata: Dictionary, file_data: Dictionary, compression: int = -1) -> bool:
 var file: = start_writing_save_file(filepath)
 if not file:
  return false

 store_dictionary_to_file(file, file_metadata, compression)
 store_dictionary_to_file(file, file_data, compression)

 return finish_writing_save_file(file, filepath)


func store_save_file(filepath: String) -> bool:
 return store_data_metadata_file(filepath, metadata, data)


static func store_data_file(filepath: String, file_data: Dictionary) -> bool:
 var file: = start_writing_save_file(filepath)
 if not file:
  return false

 store_dictionary_to_file(file, file_data, FileAccess.COMPRESSION_ZSTD)

 return finish_writing_save_file(file, filepath)


func store_file() -> bool:
 generate_metadata()

 if not has_directory():
  DirAccess.make_dir_recursive_absolute(get_directory_path())

 var save_stored: = store_save_file(get_filepath(SAVE_FILENAME))
 var stats_stored: = store_data_file(get_filepath(STATS_FILENAME), stats)
 var word_stats_stored: = store_data_file(get_filepath(WORD_STATS_FILENAME), word_stats)

 for mod in ModLoader.get_active_mods():
  var save_data: = mod.get_save_data()
  if not save_data.is_empty():
   mod_data[mod.mod_data.id] = save_data
  elif mod.mod_data.id in mod_data:
   mod_data.erase(mod.mod_data.id)

 var mod_data_stored: = store_data_file(get_filepath(MOD_DATA_FILENAME), mod_data)

 if save_stored and stats_stored and word_stats_stored and mod_data_stored:
  return true

 return false


func rename(new_name) -> bool:
 if name == new_name:
  return false

 var old_dir_path: = get_directory_path()
 var new_dir_path: = SaveManager.get_save_directory_path(new_name)
 if DirAccess.dir_exists_absolute(old_dir_path) and not DirAccess.dir_exists_absolute(new_dir_path):
  DirAccess.rename_absolute(old_dir_path, new_dir_path)
  if is_selected():
   SaveManager.select_save(new_name)

  return true

 return false


func delete():
 var deleting_selected_save: = is_selected()
 if deleting_selected_save:
  SaveManager.deselect_save()

 if has_directory():
  Util.remove_directory_recursive(get_directory_path())

 if deleting_selected_save:
  SaveManager.ensure_selected_save()


func copy_from(other: SaveFile) -> void :
 metadata = other.metadata
 metadata_loaded = other.metadata_loaded
 data = other.data
 data_loaded = other.data_loaded
 stats = other.stats
 stats_loaded = other.stats_loaded
 word_stats = other.word_stats
 word_stats_loaded = other.word_stats_loaded


func set_default_metadata() -> void :
 Util.deep_default(metadata, METADATA_DEFAULTS)
 if metadata.achievements_unlocked_extra == -1:
  metadata.achievements_unlocked_extra = metadata.achievements_unlocked


func set_default_save_data() -> void :
 Util.deep_default(data, SAVE_DEFAULTS)


func set_default_stats() -> void :
 Util.deep_default(stats, STATS_DEFAULTS)


func is_selected() -> bool:
 return SaveManager.get_selected_save_name() == name


func generate_metadata() -> void :
 metadata = {
  game_version = SaveManager.game_version, 
  time_spent = stats.total_play_time, 
 }

 metadata.any_difficulty_won = won_any_difficulty()
 metadata.achievements_unlocked = count_achievements()
 metadata.achievements_unlocked_extra = count_achievements(true)

 set_default_metadata()


func has_achievement(achievement, minimum_count: int) -> bool:
 return achievement in data.achievements and data.achievements[achievement] >= minimum_count


func get_achievement_level(achievement: String) -> int:
 if achievement in data.achievements:
  return data.achievements[achievement]
 else:
  return 0


func set_achievement_level(achievement: String, level: int) -> void :
 data.achievements[achievement] = level


func get_achievement_metadata(achievement: String) -> Dictionary:
 return data.achievement_metadata.get(achievement, {})


func set_achievement_metadata(achievement: String, achievement_metadata: Dictionary) -> void :
 data.achievement_metadata[achievement] = achievement_metadata


func get_last_played_daily_datetime() -> Dictionary:
 return {
  year = data.latest_played_daily[0], 
  month = data.latest_played_daily[1], 
  day = data.latest_played_daily[2]
 }


func can_play_daily(daily_date: Dictionary) -> bool:
 var last_played_daily = get_last_played_daily_datetime()
 var last_daily_unix = DailyManager.get_daily_unix_time(last_played_daily)
 var daily_unix = DailyManager.get_daily_unix_time(daily_date)
 return daily_unix > last_daily_unix


func set_daily_played(daily_datetime: Dictionary) -> void :
 data.latest_played_daily = [daily_datetime.year, daily_datetime.month, daily_datetime.day]


func count_achievements(count_extra: = false) -> int:
 var total_count: int = 0
 for achievement in data.achievements:
  if Globals.is_valid_achievement(achievement):
   var completion_count = Globals.get_achievement_completion_count(achievement, data.achievements[achievement], count_extra)
   total_count += completion_count

 return total_count


func get_percent(count_extra: = false) -> int:
 if data_loaded:
  return Globals.get_achievement_percent(count_achievements(), count_achievements(true), count_extra)
 elif metadata_loaded:
  return Globals.get_achievement_percent(metadata.achievements_unlocked, metadata.achievements_unlocked_extra, count_extra)
 else:
  return 0


func load_run_file(filename: String, load_data: = true) -> Dictionary:
 if not has_file(filename):
  return {metadata = {has_run = false}}

 var run_info: = load_data_metadata_file(get_filepath(filename), SaveMigration.migrate_run, load_data)
 if "metadata" not in run_info:
  return {metadata = {has_run = false}}

 if "has_run" not in run_info.metadata:
  run_info.metadata.has_run = false

 return run_info


func save_run_file(filename: String, run_metadata: Dictionary, run_data: Dictionary) -> void :
 run_metadata.has_run = not run_data.is_empty()
 store_data_metadata_file(get_filepath(filename), run_metadata, run_data)


func get_saved_run(load_data: = true) -> Dictionary:
 return load_run_file(RUN_FILENAME, load_data)


func has_saved_run() -> bool:
 return get_saved_run(false).metadata.has_run


func get_saved_daily(load_data: = true) -> Dictionary:
 return load_run_file(DAILY_FILENAME, load_data)


func has_saved_daily() -> bool:
 return get_saved_daily(false).metadata.has_run


func save_run(run_metadata: Dictionary, run_data: Dictionary) -> void :
 save_run_file(RUN_FILENAME, run_metadata, run_data)


func save_daily(run_metadata: Dictionary, run_data: Dictionary) -> void :
 save_run_file(DAILY_FILENAME, run_metadata, run_data)


func clear_saved_run(overwriting: bool = false) -> void :
 if overwriting:
  var saved_run_metadata: Dictionary = get_saved_run(false).metadata
  if saved_run_metadata.has_run:
   var difficulty: int = saved_run_metadata.get("difficulty", 0)
   if saved_run_metadata.get("turn_taken", false):
    track_difficulty_lost(difficulty)

 save_run_file(RUN_FILENAME, {has_run = false}, {})


func clear_saved_daily() -> void :
 save_run_file(DAILY_FILENAME, {has_run = false}, {})


static func get_run_playable(run_metadata: Dictionary, daily: bool) -> Dictionary:
 var playable_info: Dictionary = {
  playable = true, 
  warning = "", 
  daily_mismatch = false, 
  debug = run_metadata.get("debug", false), 
 }

 if not run_metadata.has_run:
  playable_info.playable = false
 else:
  if "content_mods" in run_metadata:
   if run_metadata.content_mods != ModLoader.get_active_mod_ids(true):
    playable_info.warning = StringManager.get_string("menu/main/mods_incompatible")
    playable_info.playable = false

  if daily != ("daily" in run_metadata):
   playable_info.daily_mismatch = true

 return playable_info


func get_or_create_stats(index: Variant, stats_table: Dictionary, default_stats: Dictionary, create_if_not: = true) -> Dictionary:
 if index not in stats_table:
  if create_if_not:
   stats_table[index] = {}
   Util.deep_default(stats_table[index], default_stats)
  else:
   var default = {}
   Util.deep_default(default, default_stats)
   return default

 stats_table[index].merge(default_stats)
 return stats_table[index]


func remap_key_across_difficulties(old_key: Variant, new_key: Variant, stats_index: String) -> void :
 for difficulty in stats.difficulty:
  var difficulty_stats: Dictionary = stats.difficulty[difficulty]
  if stats_index not in difficulty_stats:
   continue

  if old_key not in difficulty_stats[stats_index]:
   continue

  difficulty_stats[stats_index][new_key] = difficulty_stats[stats_index][old_key]
  difficulty_stats[stats_index].erase(old_key)



func get_difficulty_stats(difficulty: int, create_if_not: = true) -> Dictionary:
 return get_or_create_stats(difficulty, stats.difficulty, DIFFICULTY_STAT_DEFAULTS, create_if_not)


func track_difficulty_won(difficulty: int) -> void :
 if stats.streak < 0:
  stats.streak = 0

 stats.streak += 1
 stats.best_streak = maxi(stats.streak, stats.best_streak)

 var difficulty_stats: = get_difficulty_stats(difficulty)
 difficulty_stats.wins += 1

 if difficulty_stats.wins == 1:
  difficulty_stats.initial_losses = difficulty_stats.losses

 if difficulty_stats.streak < 0:
  difficulty_stats.streak = 0

 difficulty_stats.streak += 1
 difficulty_stats.best_streak = maxi(difficulty_stats.streak, difficulty_stats.best_streak)


func track_difficulty_lost(difficulty: int) -> void :
 if stats.streak > 0:
  stats.streak = 0

 stats.streak -= 1
 stats.worst_streak = mini(stats.worst_streak, stats.streak)

 var difficulty_stats: = get_difficulty_stats(difficulty)

 difficulty_stats.losses += 1

 if difficulty_stats.streak > 0:
  difficulty_stats.streak = 0

 difficulty_stats.streak -= 1
 difficulty_stats.worst_streak = maxi(difficulty_stats.streak, difficulty_stats.worst_streak)


func get_enemy_stats(enemy: String, difficulty: int, create_if_not = true) -> Dictionary:
 if difficulty == -1:
  return Util.get_deep_accumulated(stats.difficulty, ["*", "enemy_stats", enemy], ENEMY_STAT_DEFAULTS)

 var difficulty_stats: = get_difficulty_stats(difficulty, create_if_not)
 return get_or_create_stats(enemy, difficulty_stats.enemy_stats, ENEMY_STAT_DEFAULTS, create_if_not)


func track_enemy_encounter(enemy: String, difficulty: int) -> void :
 get_enemy_stats(enemy, difficulty).encounters += 1


func track_enemy_loss(enemy, difficulty: int) -> void :
 get_enemy_stats(enemy, difficulty).losses += 1


func track_enemy_kill(enemy, difficulty: int) -> void :
 get_enemy_stats(enemy, difficulty).kills += 1


func get_character_stats(character: String, difficulty: int, create_if_not: = true) -> Dictionary:
 if difficulty == -1:
  return Util.get_deep_accumulated(stats.difficulty, ["*", "character_stats", character], CHARACTER_STAT_DEFAULTS)

 var difficulty_stats: = get_difficulty_stats(difficulty, create_if_not)
 return get_or_create_stats(character, difficulty_stats.character_stats, CHARACTER_STAT_DEFAULTS, create_if_not)


func track_character_won(character: String, difficulty: int) -> void :
 get_character_stats(character, difficulty).wins += 1


func track_character_lost(character: String, difficulty: int) -> void :
 get_character_stats(character, difficulty).losses += 1


func get_spell_stats(spell: String, difficulty: int, create_if_not: = true) -> Dictionary:
 if difficulty == -1:
  return Util.get_deep_accumulated(stats.difficulty, ["*", "spell_stats", spell], SPELL_STAT_DEFAULTS)

 var difficulty_stats: = get_difficulty_stats(difficulty, create_if_not)
 return get_or_create_stats(spell, difficulty_stats.spell_stats, SPELL_STAT_DEFAULTS, create_if_not)


func track_spell_found(spell: String, difficulty: int) -> void :
 get_spell_stats(spell, difficulty).found += 1


func track_spell_taken(spell: String, difficulty: int) -> void :
 get_spell_stats(spell, difficulty).taken += 1


func track_spell_replaced(spell: String, difficulty: int) -> void :
 get_spell_stats(spell, difficulty).replaced += 1


func track_spell_used(spell: String, difficulty: int) -> void :
 get_spell_stats(spell, difficulty).used += 1


func track_spell_won(spell: String, difficulty: int) -> void :
 get_spell_stats(spell, difficulty).wins += 1


func track_spell_lost(spell: String, difficulty: int) -> void :
 get_spell_stats(spell, difficulty).losses += 1


func get_spell_max_difficulty(spell: String) -> int:
 var max_difficulty: int = -1
 for difficulty in stats.difficulty:
  var spell_stats: = get_spell_stats(spell, difficulty, false)
  if spell_stats.wins > 0:
   max_difficulty = maxi(difficulty, max_difficulty)

 return max_difficulty


func track_play_time(time_ms: int) -> void :
 stats.total_play_time += time_ms


func track_deliberation_time(time_ms: int) -> void :
 stats.total_deliberation_time += time_ms


func get_play_time() -> int:
 return stats.total_play_time


func get_deliberation_time() -> int:
 return stats.total_deliberation_time


func track_enemy_read(enemy: String) -> void :
 stats.phonebook_entries_read.enemy[enemy] = true


func has_enemy_been_read(enemy: String) -> bool:
 if enemy not in stats.phonebook_entries_read.enemy:
  return false

 return stats.phonebook_entries_read.enemy[enemy]


func is_phonebook_unlocked() -> bool:
 for enemy in Enemies.list(true):
  var enemy_stats: Dictionary = get_enemy_stats(enemy, -1, false)
  if enemy_stats.kills > 0:
   return true

 return false


func is_phonebook_unread() -> bool:
 for enemy in Enemies.list(true):
  if has_enemy_been_read(enemy):
   continue

  var enemy_stats: Dictionary = get_enemy_stats(enemy, -1, false)
  if enemy_stats.kills > 0:
   return true

 return false


func won_any_difficulty() -> bool:
 for difficulty in stats.difficulty:
  var difficulty_stats = stats.difficulty[difficulty]
  if difficulty_stats.wins > 0:
   return true

 return false


func get_discovered_spells() -> Array:
 return stats.discovered_spells


func discover_spell(spell: String) -> void :
 if spell not in stats.discovered_spells:
  stats.discovered_spells.append(spell)


func track_word(word: String) -> void :
 if word not in word_stats:
  word_stats[word] = 0

 word_stats[word] += 1


func track_win_time(win_time: int, character: String, difficulty: int) -> void :
 if stats.fastest_win == -1:
  stats.fastest_win = win_time
 else:
  stats.fastest_win = mini(win_time, stats.fastest_win)

 var character_stats: = get_character_stats(character, difficulty, true)
 if character_stats.fastest_win == -1:
  character_stats.fastest_win = win_time
 else:
  character_stats.fastest_win = mini(win_time, character_stats.fastest_win)


func get_character_fastest_win(character: String) -> int:
 var fastest_win: int = -1
 for difficulty in Globals.DIFFICULTY_COUNT:
  var character_stats: = get_character_stats(character, difficulty, false)
  if character_stats.fastest_win != -1:
   if fastest_win == -1:
    fastest_win = character_stats.fastest_win
   else:
    fastest_win = mini(fastest_win, character_stats.fastest_win)

 return fastest_win


func track_viewed_cutscene(cutscene_id: String) -> void :
 data.cutscenes_viewed[cutscene_id] = true


func has_viewed_cutscene(cutscene_id: String) -> bool:
 if cutscene_id in data.cutscenes_viewed:
  return data.cutscenes_viewed[cutscene_id]

 return false


func set_viewed_tutorial(viewed: bool) -> void :
 data.seen_tutorial = viewed


func set_viewed_nobody_cutscene(cutscene_id: String):
 data.nobody_cutscenes_viewed[cutscene_id] = true


func has_viewed_nobody_cutscene(cutscene_id: String) -> bool:
 if cutscene_id in data.nobody_cutscenes_viewed:
  return data.nobody_cutscenes_viewed[cutscene_id]

 return false


func try_upload_stored_scores() -> void :
 if not Bridge.leaderboards_available:
  return

 for leaderboard_name in data.stored_scores.keys():
  var entry: = Bridge.LeaderboardEntry.from_save(data.stored_scores[leaderboard_name])
  if entry.user_id != Bridge.own_user_id:
   if entry.user_id == null:
    data.stored_scores.erase(leaderboard_name)

   continue

  var upload_success: = await Bridge.upload_score(leaderboard_name, entry)
  if upload_success:
   data.stored_scores.erase(leaderboard_name)
