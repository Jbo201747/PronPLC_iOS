class_name SaveMigration

const OLD_SAVE_FILENAME = "data.save"

const ACHIEVEMENTS = Globals.ACHIEVEMENTS
const SPELLS = Globals.SPELLS

const REMAPPING = {
 "0.4": {
  ACHIEVEMENTS = {
   "oliver_max_difficulty": ACHIEVEMENTS.LEXICOGRAPHER_MAX_DIFFICULTY, 
   "elise_max_difficulty": ACHIEVEMENTS.CHILD_MAX_DIFFICULTY, 
   "damaged_max_difficulty": ACHIEVEMENTS.CHILD_MAX_DIFFICULTY, 
   "clown_max_difficulty": ACHIEVEMENTS.JUBILIST_MAX_DIFFICULTY, 
   "valence_max_difficulty": ACHIEVEMENTS.ADDICT_MAX_DIFFICULTY, 
   "unlock_elise": ACHIEVEMENTS.UNLOCK_CHILD, 
   "unlock_damaged": ACHIEVEMENTS.UNLOCK_CHILD, 
   "unlock_clown": ACHIEVEMENTS.UNLOCK_JUBILIST, 
   "unlock_valence": ACHIEVEMENTS.UNLOCK_ADDICT, 
  }, 
  SPELLS = {
   "coffee_ration": SPELLS.TUMOR, 
   "dirty_rag": SPELLS.SEALED_PACKET, 
   "chapstick": SPELLS.LIP_BALM, 
   "acrylic_die": SPELLS.PRAXICE, 
  }
 }, 
 "0.4.1": {
  SPELLS = {
   "heart_tarts": SPELLS.SORGHUM_PINK, 
   "bandages": SPELLS.FIRST_AID, 
   "chocolate_chip_tampon": SPELLS.COTTON_CANDY_TAMPON, 
  }
 }, 
 "0.4.1.1": {
  ACHIEVEMENTS = {
   "beat_champion": SPELLS.DRAFT_CARD, 
  }, 
 }, 
 "0.4.1.13": {
  ENEMIES = {
   "human_resource": Enemies.RECEIVER, 
  }, 
 }, 
 "0.4.4.2": {
  ENEMIES = {
   "soylent": Enemies.PEOPLE, 
   "greyb": Enemies.UFO, 
   "bomber": Enemies.PARADIGM, 
  }, 
 }, 
 "0.5.2.1": {
  SPELLS = {
   "gift": SPELLS.GIFT_ENHANCING, 
   "gift_support": SPELLS.GIFT_PUZZLE, 
   "gift_offensive": SPELLS.GIFT_ENHANCING, 
   "gift_defensive": SPELLS.GIFT_DEFENSE, 
  }
 }, 
 "0.7.0.0": {
  RESET_PHONEBOOK = {
   Enemies.LUMP: true, 
  }, 
 }, 
 "0.7.0.1": {
  RESET_PHONEBOOK = {
   Enemies.SALT: true, 
   Enemies.JUVENILE: true, 
   Enemies.PURRGEOISIE: true, 
   Enemies.BROKER: true, 
  }, 
 }, 
 "0.7.1.0": {
  RESET_PHONEBOOK = {
   Enemies.FAT_CAT: true, 
   Enemies.UFO: true, 
  }
 }, 
 "0.8.1": {
  ACHIEVEMENTS = {
   SPELLS.FINGERNAIL: SPELLS.T_GEL, 
  }, 
 }, 
 "0.9.2.1": {
  CUTSCENES = {
   "": "", 
   "nobody/lexicographer/0": "nobody/lexicographer/intro", 
   "nobody/lexicographer/1": "nobody/lexicographer/wife", 
   "nobody/lexicographer/2": "", 
   "nobody/lexicographer/3": "nobody/lexicographer/razors", 

   "nobody/jubilist/0": "nobody/jubilist/intro", 
   "nobody/jubilist/1": "nobody/jubilist/forms", 
   "nobody/jubilist/2": "nobody/jubilist/crimes", 
   "nobody/jubilist/3": "nobody/jubilist/lime", 

   "nobody/child/0": "nobody/child/intro", 
   "nobody/child/1": "nobody/child/creep", 
   "nobody/child/2": "nobody/child/parents", 
   "nobody/child/3": "", 
   "nobody/child/4": "nobody/child/rape", 

   "nobody/fisher/0": "nobody/fisher/intro", 
   "nobody/fisher/1": "nobody/fisher/throw", 
   "nobody/fisher/2": "nobody/fisher/beard", 
   "nobody/fisher/3": "nobody/fisher/forms", 
   "nobody/fisher/4": "nobody/fisher/razors", 
   "nobody/fisher/5": "nobody/fisher/lesbian", 

   "nobody/addict/0": "nobody/addict/intro", 
   "nobody/addict/1": "nobody/addict/audit", 
   "nobody/addict/2": "nobody/addict/over", 
   "nobody/addict/3": "nobody/addict/butch", 
  }, 
 }, 
 "0.9.2.4": {
  CUTSCENES = {
   "credits/credits": "extra/credits", 
  }, 
 }, 
}

static func migrate_save(_filepath, _file_version) -> bool:
 return false


static func migrate_run(_filepath, _file_version) -> bool:
 return false


static func migrate_old_data_metadata_file(filepath: String, store_filepath: String) -> bool:
 var data_metadata: Dictionary = {metadata = {}, data = {}}

 var bytes: = FileAccess.get_file_as_bytes(filepath)

 if bytes.has_encoded_var(4, false):
  var metadata_length: = bytes.decode_var_size(4, false)
  var metadata: Variant = bytes.decode_var(4, false)
  if metadata is Dictionary:
   data_metadata.metadata = metadata

   if bytes.has_encoded_var(metadata_length + 8, false):
    var data: Variant = bytes.decode_var(metadata_length + 8, false)
    if data is Dictionary:
     data_metadata.data = data
    else:
     push_error("File had invalid encoded data ", filepath, " ", store_filepath)
     return false
   else:
    push_warning("File had metadata but not data ", filepath, " ", store_filepath)
  else:
   return false
 else:
  push_warning("Failed to migrate file ", filepath, " ", store_filepath)
  return false

 return SaveFile.store_data_metadata_file(store_filepath, data_metadata.metadata, data_metadata.data)


static func migrate_old_save_format(save_file: SaveFile) -> void :
 if not migrate_old_data_metadata_file(save_file.get_filepath(OLD_SAVE_FILENAME), save_file.get_filepath(SaveFile.SAVE_FILENAME)):
  save_file.corrupt = true
  return

 if save_file.has_file(SaveFile.RUN_FILENAME):
  migrate_old_data_metadata_file(save_file.get_filepath(SaveFile.RUN_FILENAME), save_file.get_filepath(SaveFile.RUN_FILENAME))

 if save_file.has_file(SaveFile.DAILY_FILENAME):
  migrate_old_data_metadata_file(save_file.get_filepath(SaveFile.DAILY_FILENAME), save_file.get_filepath(SaveFile.DAILY_FILENAME))


static func migrate_data_file(filepath: String, file_version: int) -> bool:
 var bytes: = FileAccess.get_file_as_bytes(filepath)
 if bytes.size() < 8:
  return false

 var _version: = bytes.decode_s64(0)
 if file_version == 1:
  if bytes.has_encoded_var(12, false):
   var data: Variant = bytes.decode_var(12, false)
   if data is Dictionary:
    SaveFile.store_data_file(filepath, data)
    return true
 elif file_version == 2:
  if bytes.size() < 20:
   return false

  var decompressed_size: = bytes.decode_s64(8)
  if bytes.has_encoded_var(20, false):
   var compressed_data: Variant = bytes.decode_var(20, false)
   if compressed_data is PackedByteArray:
    var decompressed: PackedByteArray = compressed_data.decompress(decompressed_size, FileAccess.COMPRESSION_ZSTD)
    if decompressed.has_encoded_var(0, false):
     var data: Variant = decompressed.decode_var(0, false)
     if data is Dictionary:
      SaveFile.store_data_file(filepath, data)
      return true

 return false


static func migrate_stats(filepath: String, file_version: int) -> bool:
 return migrate_data_file(filepath, file_version)


static func migrate_word_stats(filepath: String, file_version: int) -> bool:
 return migrate_data_file(filepath, file_version)


static func build_remapping_table(old_version: String) -> Dictionary:
 var remapping: Dictionary = {}
 for version in REMAPPING:
  if SaveManager.is_version_lower(old_version, version):
   remapping = Util.deep_merge(remapping, REMAPPING[version])

 return remapping


static func generic_migration(save: SaveFile):
 var data = save.data
 print("Performing save migration.")

 var old_version = save.metadata.get("game_version", "0")
 if SaveManager.is_version_lower(old_version, "0.4.1.8"):
  if "run" in data:
   data.erase("run")

  if "stats" in data:
   if "total_contemplation_time" in data.stats:
    data.stats.total_play_time = data.stats.total_contemplation_time
    data.stats.erase("total_contemplation_time")

  if "stored_daily_scores" in data:
   for daily_dict in data.stored_daily_scores:
    data.stored_scores[DailyManager.get_daily_identifier(daily_dict)] = data.stored_daily_scores[daily_dict]

   data.erase("stored_daily_scores")


 var needs_to_fix_stats: bool = SaveManager.is_version_lower(old_version, "0.5.2.0")
 if SaveManager.is_version_lower(old_version, "0.6.0.1"):
  if "difficulty" not in save.stats or save.stats.difficulty.is_empty():
   needs_to_fix_stats = true
   if "old_stats" in data:
    data.stats = data.old_stats

 if needs_to_fix_stats:
  if "stats" in data:
   for key in ["total_play_time", "total_deliberation_time", "discovered_spells"]:
    if key in data.stats:
     save.stats[key] = data.stats[key]

   if "enemy" in data.stats:
    for enemy in data.stats.enemy:
     if data.stats.enemy[enemy].get("read", false):
      save.track_enemy_read(enemy)

     var new_stats = save.get_enemy_stats(enemy, -99, true)
     for stat in new_stats:
      if stat in data.stats.enemy[enemy]:
       new_stats[stat] = data.stats.enemy[enemy][stat]

   if "spell" in data.stats:
    for spell in data.stats.spell:
     var new_stats = save.get_spell_stats(spell, -99, true)
     for stat in new_stats:
      if stat in data.stats.spell[spell]:
       new_stats[stat] = data.stats.spell[spell][stat]

   if "character" in data.stats:
    for character in data.stats.character:
     var new_stats = save.get_character_stats(character, -99, true)
     for stat in new_stats:
      if stat in data.stats.character[character]:
       new_stats[stat] = data.stats.character[character][stat]

   if "difficulty" in data.stats:
    for difficulty in data.stats.difficulty:
     var new_stats = save.get_difficulty_stats(difficulty, true)
     for stat in new_stats:
      if stat in data.stats.difficulty[difficulty]:
       new_stats[stat] = data.stats.difficulty[difficulty][stat]

   save.stats_loaded = true
   data.old_stats = data.stats.duplicate()
   data.erase("stats")

 if SaveManager.is_version_lower(old_version, "0.6.3.3"):
  if "win_streak" in save.stats:
   save.stats.streak = maxi(save.stats.win_streak, save.stats.streak)
   save.stats.best_streak = maxi(save.stats.best_win_streak, save.stats.best_streak)
   save.stats.worst_streak = mini(save.stats.worst_win_streak, save.stats.worst_streak)
   save.stats.erase("win_streak")
   save.stats.erase("best_win_streak")
   save.stats.erase("worst_win_streak")

  if "max_difficulty_streak" in save.stats:
   var red_clearance_stats: = save.get_difficulty_stats(9)
   red_clearance_stats.streak = maxi(red_clearance_stats.streak, save.stats.max_difficulty_streak)
   red_clearance_stats.best_streak = maxi(red_clearance_stats.best_streak, save.stats.best_max_difficulty_streak)
   red_clearance_stats.worst_streak = mini(red_clearance_stats.worst_streak, save.stats.worst_max_difficulty_streak)
   save.stats.erase("max_difficulty_streak")
   save.stats.erase("best_max_difficulty_streak")
   save.stats.erase("worst_max_difficulty_streak")

  var overall_difficulty_stats = Util.get_deep_accumulated(save.stats.difficulty, ["*"], {wins = 0, losses = 0})

  var most_winless_losses: int = 0
  var most_lossless_wins: int = 0
  if overall_difficulty_stats.losses == 0:
   most_lossless_wins = overall_difficulty_stats.wins
   save.stats.streak = maxi(most_lossless_wins, save.stats.streak)
  elif overall_difficulty_stats.wins == 0:
   most_winless_losses = overall_difficulty_stats.losses
   save.stats.streak = mini( - most_winless_losses, save.stats.streak)

  for i in Globals.DIFFICULTY_COUNT:
   var difficulty_stats: = save.get_difficulty_stats(i)
   if difficulty_stats.losses == 0:
    most_lossless_wins = maxi(most_lossless_wins, difficulty_stats.wins)
    difficulty_stats.streak = maxi(difficulty_stats.streak, difficulty_stats.wins)
    difficulty_stats.best_streak = maxi(difficulty_stats.best_streak, difficulty_stats.wins)
   elif difficulty_stats.wins == 0:
    most_winless_losses = maxi(most_winless_losses, difficulty_stats.losses)
    difficulty_stats.streak = mini(difficulty_stats.streak, - difficulty_stats.losses)
    difficulty_stats.worst_streak = mini(difficulty_stats.worst_streak, - difficulty_stats.losses)

  save.stats.best_streak = maxi(save.stats.best_streak, most_lossless_wins)
  save.stats.worst_streak = mini(save.stats.worst_streak, - most_winless_losses)



 var remapping = build_remapping_table(old_version)
 if "SPELLS" in remapping:
  for old_id in remapping.SPELLS:
   var new_id = remapping.SPELLS[old_id]
   if old_id in save.stats.discovered_spells:
    var index = save.stats.discovered_spells.find(old_id)
    save.stats.discovered_spells[index] = new_id
    print("Remapping discovered spell ", old_id, " ", new_id)

   save.remap_key_across_difficulties(old_id, new_id, "spell_stats")

   if old_id in data.achievements:
    data.achievements[new_id] = data.achievements[old_id]
    data.achievements.erase(old_id)
    print("Remapping spell achievement ", old_id, " ", new_id)

   if old_id in data.obsolete_achievements:
    data.achievements[new_id] = data.obsolete_achievements[old_id]
    data.obsolete_achievements.erase(old_id)
    print("Remapping obsolete spell achievement ", old_id, " ", new_id)

 if "ACHIEVEMENTS" in remapping:
  for old_id in remapping.ACHIEVEMENTS:
   var new_id = remapping.ACHIEVEMENTS[old_id]
   if old_id in data.achievements:
    data.achievements[new_id] = data.achievements[old_id]
    data.achievements.erase(old_id)
    print("Remapping achievement ", old_id, " ", new_id)

   if old_id in data.obsolete_achievements:
    data.achievements[new_id] = data.obsolete_achievements[old_id]
    data.obsolete_achievements.erase(old_id)
    print("Remapping obsolete achievement ", old_id, " ", new_id)

 if "ENEMIES" in remapping:
  for old_id in remapping.ENEMIES:
   var new_id = remapping.ENEMIES[old_id]
   save.remap_key_across_difficulties(old_id, new_id, "enemy_stats")

   if old_id in save.stats.phonebook_entries_read.enemy:
    save.stats.phonebook_entries_read.enemy[new_id] = save.stats.phonebook_entries_read.enemy[old_id]
    save.stats.phonebook_entries_read.enemy.erase(old_id)

   if old_id == data.selected_phonebook_entry:
    data.selected_phonebook_entry = new_id
    print("Remapping selected phonebook entry ", old_id, " ", new_id)

   if old_id in data.selected_phonebook_entries:
    data.selected_phonebook_entries[new_id] = data.selected_phonebook_entries[old_id]
    data.selected_phonebook_entries.erase(old_id)
    print("Remapping selected phonebook entries ", old_id, " ", new_id)

 if "RESET_PHONEBOOK" in remapping:
  for id in remapping.RESET_PHONEBOOK:
   save.stats.phonebook_entries_read.enemy.erase(id)

 if "CUTSCENES" in remapping:
  for id: String in remapping.CUTSCENES:
   var map_to: String = remapping.CUTSCENES[id]
   if id in save.data.cutscenes_viewed:
    if map_to != "":
     save.data.cutscenes_viewed[map_to] = save.data.cutscenes_viewed[id]
    save.data.cutscenes_viewed.erase(id)

   if id in save.data.nobody_cutscenes_viewed:
    if map_to != "":
     save.data.nobody_cutscenes_viewed[map_to] = save.data.nobody_cutscenes_viewed[id]
    save.data.nobody_cutscenes_viewed.erase(id)

 if "fingernail_tile" in data:
  if "statuses" in data.fingernail_tile and data.fingernail_tile.statuses.size() > 0 and data.fingernail_tile.statuses[0] is Dictionary:
   data.erase("fingernail_tile")

 var all_achievements = Globals.ACHIEVEMENTS.values() + Globals.SPELL_ACHIEVEMENTS
 for id in data.achievements:
  if id not in all_achievements:
   data.obsolete_achievements[id] = data.achievements[id]
   data.achievements.erase(id)
   print("Hiding obsolete achievement ", id)


static func migrate_files_to_folders() -> void :
 const SAVES_FOLDER = SaveManager.SAVES_FOLDER
 if not DirAccess.dir_exists_absolute(SAVES_FOLDER.trim_suffix("/")):
  return

 for filename in DirAccess.get_files_at(SAVES_FOLDER):
  if filename.get_extension() == "save":
   var save = SaveFile.new(filename.trim_suffix(".save"))
   save.load_file_path(SAVES_FOLDER + filename, true)
   if save.data_loaded:
    generic_migration(save)
    if save.store_file():
     DirAccess.remove_absolute(SAVES_FOLDER + filename)
   else:
    push_warning("Corrupt Save? " + filename)


static func migrate_leaderboard_entry(entry: Bridge.LeaderboardEntry) -> void :
 if entry.format_number < 3:
  entry.spell_data.resize(entry.spells.size())
  for i in entry.spells.size():
   var spell_id: = entry.spells[i]
   var original_spell_id: = spell_id


   for category in Globals.SPELL_CATEGORY.values():
    if spell_id.ends_with(category):
     spell_id = "gift_" + category

   if spell_id != original_spell_id:
    entry.spells[i] = spell_id

   entry.spell_data[i] = PackedByteArray()

 var remapping = build_remapping_table(entry.game_version)
 if "SPELLS" in remapping:
  for old_id in remapping.SPELLS:
   for i in entry.spells.size():
    if entry.spells[i] == old_id:
     entry.spells[i] = remapping.SPELLS[old_id]
