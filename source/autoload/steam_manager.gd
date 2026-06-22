extends Node

signal leaderboard_find_finished

var stats_need_storing = false

var leaderboards: Dictionary[String, int] = {}
var leaderboard_find_callback: Callable = Callable()
var leaderboard_outstanding_requests: Dictionary[String, int] = {}
var downloading_leaderboards: Dictionary[String, bool] = {}

var download_leaderboard_call_queue: Array[Array] = []
var outstanding_download_leaderboard: = false

var finding_leaderboard: String = ""
var initialized: = false


func _ready():
 initialize_steam()

 if not initialized:
  return

 Bridge.reset_steam_stats.connect(_reset_steam_stats)
 Bridge.requesting_leaderboard_entries.connect(_request_leaderboard_entries)
 Bridge.requesting_find_leaderboard.connect(_request_find_leaderboard)
 Bridge.request_create_leaderboard.connect(_request_create_leaderboard)
 Bridge.requesting_avatar.connect(_request_avatar)
 Bridge.uploading_score.connect(_request_upload_leaderboard_score)
 Bridge.requesting_username.connect(_request_username)
 Bridge.request_global_stats.connect(print_global_stats)
 Bridge.request_update_stats.connect(_update_stats)
 Bridge.setting_rich_presence_key.connect(_set_rich_presence_key)
 Bridge.setting_rich_presence_display.connect(_set_rich_presence_display)
 Bridge.clearing_rich_presence.connect(_clear_rich_presence)
 Bridge.requesting_has_friend.connect(_request_has_friend)
 Bridge.request_update_time.connect(_request_update_time)
 Bridge.request_popup_keyboard.connect(_request_popup_keyboard)
 Bridge.request_recover_achievements.connect(_update_save_achievements_from_steam)
 AchievementManager.unlocked_achievement.connect(_unlock_game_achievement)
 SaveManager.save_changed.connect(_update_achievements)
 SaveManager.stored_save.connect(_update_stats)


func initialize_steam() -> void :
 Bridge.dailies_available = false

 if not OS.is_debug_build():
  var needs_restart = Steam.restartAppIfNecessary(3618850)
  if needs_restart:
   get_tree().quit()
   return

 var initialize_response: Dictionary = Steam.steamInitEx(3618850, true)
 if initialize_response.status != 0:
  print("Steam failed to initialize: %s " % initialize_response)
  return
 else:
  print("Steam initialized successfully.")

 initialized = true
 Bridge.steam_initialized = true
 Bridge.own_user_id = Steam.getSteamID()
 Bridge.dailies_available = true
 Bridge.leaderboards_available = true
 Bridge.use_system_time = false
 Bridge.is_steam_deck = Steam.isSteamRunningOnSteamDeck()

 Steam.hookScreenshots(true)

 Steam.leaderboard_find_result.connect(_found_leaderboard)
 Steam.leaderboard_scores_downloaded.connect(_downloaded_leaderboard)
 Steam.leaderboard_score_uploaded.connect(_on_leaderboard_score_uploaded)
 Steam.avatar_loaded.connect(_loaded_avatar)
 Steam.user_stats_stored.connect(_on_user_stats_stored)
 Steam.screenshot_requested.connect(_on_screenshot_requested)
 Steam.gamepad_text_input_dismissed.connect(_on_gamepad_text_input_dismissed)


func set_achievement_if_needed(id):
 var achievement_info = Steam.getAchievement(id)
 if achievement_info.ret and not achievement_info.achieved:
  Steam.setAchievement(id)
  store_stats_deferred()


func set_stat_if_needed(id, count, indicate_achievement: String = "", cap: int = -1, exclude: Array = []):
 if Steam.getStatInt(id) < count:
  Steam.setStatInt(id, count)
  if indicate_achievement != "":
   if count < cap and count not in exclude:
    Steam.indicateAchievementProgress(indicate_achievement, count, cap)
  store_stats_deferred()


func get_achievement_is_stat(id: String) -> bool:
 if not Globals.is_valid_achievement(id) or id in Globals.SUPER_SECRET_ACHIEVEMENTS:
  return false

 if id == Globals.ACHIEVEMENTS.OVERALL_MAX_DIFFICULTY:
  return false

 if id in Globals.DIFFICULTY_ACHIEVEMENTS:
  return true

 if id in Globals.ACHIEVEMENT_COUNTS:
  return true

 return false


func get_achievement_steam_id(id: String, count: int = -1) -> String:
 if not Globals.is_valid_achievement(id) or id in Globals.SUPER_SECRET_ACHIEVEMENTS:
  return ""

 if id in Globals.DIFFICULTY_ACHIEVEMENTS and id == Globals.ACHIEVEMENTS.OVERALL_MAX_DIFFICULTY:
  if count == -1:
   return ""
  else:
   return "beat_clearance_%s" % str(count)

 return id


func _unlock_game_achievement(id: String, count: int, _store: bool, do_indication: = true):
 if count <= 0 or not Globals.is_valid_achievement(id) or id in Globals.SUPER_SECRET_ACHIEVEMENTS:
  return

 var steam_id: = get_achievement_steam_id(id, count)
 var is_stat: = get_achievement_is_stat(id)
 if is_stat:
  if id in Globals.STAT_ACHIEVEMENT_STEAM_KEYS and do_indication:
   var exclude: Array = []
   if id in Globals.STAT_ACHIEVEMENT_NOTIFICATION_EXCLUDED_LEVELS:
    exclude = Globals.STAT_ACHIEVEMENT_NOTIFICATION_EXCLUDED_LEVELS[id]
   set_stat_if_needed(steam_id, count, Globals.STAT_ACHIEVEMENT_STEAM_KEYS[id], Globals.ACHIEVEMENT_COUNTS[id], exclude)
  else:
   set_stat_if_needed(steam_id, count)
 else:
  if id == Globals.ACHIEVEMENTS.OVERALL_MAX_DIFFICULTY:
   for i in count:
    if i < 10:
     set_achievement_if_needed(get_achievement_steam_id(id, i))
  else:
   set_achievement_if_needed(steam_id)


func _update_achievements():
 if OS.is_debug_build():
  return

 if SaveManager.has_valid_selected_save():
  var save_file = SaveManager.get_save()
  for achievement in Globals.ACHIEVEMENTS.values() + Globals.SPELL_ACHIEVEMENTS:
   var count = save_file.get_achievement_level(achievement)
   _unlock_game_achievement(achievement, count, false)


func _update_save_achievements_from_steam() -> void :
 if not SaveManager.has_valid_selected_save():
  return

 var save: = SaveManager.get_save()
 for achievement in Globals.ACHIEVEMENTS.values() + Globals.SPELL_ACHIEVEMENTS:
  if achievement == Globals.ACHIEVEMENTS.OVERALL_MAX_DIFFICULTY:
   for i in range(10, -1, -1):
    var steam_id: = get_achievement_steam_id(achievement, i)
    var achievement_info: = Steam.getAchievement(steam_id)
    if achievement_info.ret and achievement_info.achieved:
     save.set_achievement_level(achievement, i)
  else:
   var steam_id: = get_achievement_steam_id(achievement)
   var is_stat: = get_achievement_is_stat(achievement)
   if is_stat:
    save.set_achievement_level(achievement, Steam.getStatInt(steam_id))
   else:
    var achievement_info: = Steam.getAchievement(steam_id)
    if achievement_info.ret and achievement_info.achieved:
     save.set_achievement_level(achievement, 1)

 if save.has_achievement(Globals.ACHIEVEMENTS.FIRST_RUN, 1):
  save.set_viewed_tutorial(true)

 var has_full_phonebook: = save.has_achievement(Globals.ACHIEVEMENTS.READ_FULL_PHONEBOOK, Globals.ACHIEVEMENT_COUNTS[Globals.ACHIEVEMENTS.READ_FULL_PHONEBOOK])
 var has_act_champions: Dictionary[int, bool] = {
  0: save.has_achievement(Globals.ACHIEVEMENTS.UNLOCK_ACT_1_CHAMPIONS, 1), 
  1: save.has_achievement(Globals.ACHIEVEMENTS.UNLOCK_ACT_2_CHAMPIONS, 1), 
  2: save.has_achievement(Globals.ACHIEVEMENTS.UNLOCK_ACT_3_CHAMPIONS, 1), 
 }

 for enemy in Enemies.list():
  var stats: = save.get_enemy_stats(enemy, -1, false)
  if stats.kills < 1:
   var should_set: = false
   if has_full_phonebook:
    should_set = true
   elif not Enemies.is_shadow(enemy):
    var act: int = Enemies.get_act_and_floor(enemy).act
    if has_act_champions[act]:
     should_set = true

   if should_set:
    var created_stats: = save.get_enemy_stats(enemy, 0, true)
    created_stats.kills = maxi(created_stats.kills, 1)
    created_stats.encounters = maxi(created_stats.encounters, 1)
    save.track_enemy_read(enemy)

 SaveManager.save_changed.emit()


func _update_stats():
 var save: = SaveManager.get_save()
 set_stat_if_needed("vocabulary_size", save.word_stats.size())

 var stats = save.stats
 for difficulty in Globals.DIFFICULTY_COUNT:
  var difficulty_stats: = save.get_difficulty_stats(difficulty, false)
  for stat in ["wins", "losses"]:
   set_stat_if_needed("difficulty_%s_%s" % [difficulty, stat], difficulty_stats[stat])

 for character in Globals.CHARACTERS:
  var character_id = Globals.CHARACTERS[character]
  var character_stats: = SaveManager.get_save().get_character_stats(character_id, -1, false)
  for stat in ["wins", "losses"]:
   set_stat_if_needed("%s_%s" % [character_id, stat], character_stats[stat])

 var hours_played = int(stats.total_play_time / (1000 * 60 * 60))
 set_stat_if_needed("hours_played", hours_played)


func print_global_stats(exclude_self: bool = false):
 Steam.requestGlobalStats(0)
 await Steam.global_stats_received

 for i in Globals.DIFFICULTY_COUNT:
  var base = "difficulty_%s_%s"
  var wins = Steam.getGlobalStatInt(base % [i, "wins"])
  var losses = Steam.getGlobalStatInt(base % [i, "losses"])
  if exclude_self:
   wins -= Steam.getStatInt(base % [i, "wins"])
   losses -= Steam.getStatInt(base % [i, "losses"])
  print("Difficulty %s Stats: Wins %s | Losses %s" % [i, wins, losses])

 for character in Globals.CHARACTERS.values():
  var base = "%s_%s"
  var wins = Steam.getGlobalStatInt(base % [character, "wins"])
  var losses = Steam.getGlobalStatInt(base % [character, "losses"])
  if exclude_self:
   wins -= Steam.getStatInt(base % [character, "wins"])
   losses -= Steam.getStatInt(base % [character, "losses"])

  print("Character %s Stats: Wins %s | Losses %s" % [character, wins, losses])

 var hours = Steam.getGlobalStatInt("hours_played")
 if exclude_self:
  hours -= Steam.getStatInt("hours_played")
 print("Global Hours Played: %s" % [hours])


func store_stats_deferred():
 if not stats_need_storing:
  stats_need_storing = true
  Game.add_exit_blocker("storing_stats")
  check_store_stats.call_deferred()


func check_store_stats():
 if stats_need_storing:
  stats_need_storing = false
  Steam.storeStats()


func _on_user_stats_stored(_game_id, _result):
 Game.remove_exit_blocker("storing_stats")


func _reset_steam_stats():
 Steam.resetAllStats(true)


func _find_leaderboard(leaderboard_name: String, callback: Callable = Callable(), create: = false) -> void :
 while finding_leaderboard != "":
  await leaderboard_find_finished

 if leaderboard_name in leaderboards:
  if callback.is_valid():
   callback.call(leaderboard_name, 1)

  return

 finding_leaderboard = leaderboard_name
 leaderboard_find_callback = callback

 if create:
  Steam.findOrCreateLeaderboard(
   leaderboard_name, 
   Steam.LeaderboardSortMethod.LEADERBOARD_SORT_METHOD_DESCENDING, 
   Steam.LeaderboardDisplayType.LEADERBOARD_DISPLAY_TYPE_NUMERIC
  )
 else:
  Steam.findLeaderboard(leaderboard_name)


func _found_leaderboard(leaderboard_handle: int, found: int) -> void :
 if found != 0:
  var leaderboard_name: = Steam.getLeaderboardName(leaderboard_handle)
  if leaderboard_name != finding_leaderboard:
   push_error("Found incorrect leaderboard, expected " + finding_leaderboard + " but got " + leaderboard_name)
   finding_leaderboard = ""
   leaderboard_find_finished.emit()
   return

  leaderboards[leaderboard_name] = leaderboard_handle

 Bridge.receive_leaderboard_found(finding_leaderboard, found == 0)

 if leaderboard_find_callback.is_valid():
  leaderboard_find_callback.call(finding_leaderboard, found)

 finding_leaderboard = ""
 leaderboard_find_finished.emit()


func _request_leaderboard_entries(leaderboard_name: String) -> void :
 _find_leaderboard(leaderboard_name, _download_leaderboard, false)


func _request_find_leaderboard(leaderboard_name: String) -> void :
 _find_leaderboard(leaderboard_name)


func _request_create_leaderboard(leaderboard_name: String) -> void :
 _find_leaderboard(leaderboard_name, _on_leaderboard_created, true)


func _on_leaderboard_created(leaderboard_name: String, found: int) -> void :
 if found == 0:
  print("Failed to create leaderboard ", leaderboard_name)

 Bridge.receive_created_leaderboard()


func queue_download_leaderboard(start: int, end: int, type: Steam.LeaderboardDataRequest, handle: int) -> void :
 var call_args: Array = [start, end, type, handle]
 if call_args in download_leaderboard_call_queue:
  return

 download_leaderboard_call_queue.append(call_args)
 if not outstanding_download_leaderboard:
  pop_download_leaderboard_queue()


func pop_download_leaderboard_queue() -> void :
 if download_leaderboard_call_queue.is_empty():
  return

 var next_call_args: Array = download_leaderboard_call_queue.pop_front()
 outstanding_download_leaderboard = true
 Steam.downloadLeaderboardEntries.callv(next_call_args)


func leaderboard_in_download_queue(leaderboard_name: String) -> bool:
 if leaderboard_name not in leaderboards:
  return false

 var handle: = leaderboards[leaderboard_name]
 for call_args in download_leaderboard_call_queue:
  if call_args[3] == handle:
   return true

 return false


func _download_leaderboard(leaderboard_name: String, found: int) -> void :
 if found == 0:
  Bridge.receive_leaderboard_entries(leaderboard_name, [], true)
  return

 queue_download_leaderboard(-5, 5, Steam.LeaderboardDataRequest.LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER, leaderboards[leaderboard_name])
 queue_download_leaderboard(0, 20, Steam.LeaderboardDataRequest.LEADERBOARD_DATA_REQUEST_GLOBAL, leaderboards[leaderboard_name])
 queue_download_leaderboard(0, 0, Steam.LeaderboardDataRequest.LEADERBOARD_DATA_REQUEST_FRIENDS, leaderboards[leaderboard_name])


func _downloaded_leaderboard(_message: String, leaderboard_handle: int, leaderboard_entries: Array) -> void :
 var leaderboard_name = leaderboards.find_key(leaderboard_handle)
 var out_leaderboard_entries: Array[Bridge.LeaderboardEntry] = []
 for steam_entry in leaderboard_entries:
  var entry: = Bridge.LeaderboardEntry.from_steam(steam_entry)
  out_leaderboard_entries.append(entry)

 Bridge.receive_leaderboard_entries(
  leaderboard_name, 
  out_leaderboard_entries, 
  false, 
  leaderboard_in_download_queue(leaderboard_name), 
 )

 outstanding_download_leaderboard = false
 pop_download_leaderboard_queue()



func _request_avatar(user_id: int) -> void :
 Steam.getPlayerAvatar(Steam.AVATAR_LARGE, user_id)


func _loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void :
 var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
 var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
 Bridge.receive_avatar(user_id, avatar_texture)


func _request_upload_leaderboard_score(leaderboard_name: String, leaderboard_entry: Bridge.LeaderboardEntry):
 _find_leaderboard(leaderboard_name, _upload_leaderboard_score.bind(leaderboard_entry), true)


func _upload_leaderboard_score(leaderboard_name: String, found: int, leaderboard_entry: Bridge.LeaderboardEntry):
 if found == 0:
  Bridge.confirm_score_uploaded(leaderboard_name, false)
  return

 Steam.uploadLeaderboardScore(leaderboard_entry.get_score(), false, leaderboard_entry.get_steam_details(), leaderboards[leaderboard_name])


func _on_leaderboard_score_uploaded(success: int, leaderboard_handle: int, _score: Dictionary) -> void :
 var leaderboard_name = leaderboards.find_key(leaderboard_handle)
 Bridge.confirm_score_uploaded(leaderboard_name, success == 1)


func _request_username(user_id: int) -> void :
 Bridge.set_username(user_id, Steam.getFriendPersonaName(user_id))


func _set_rich_presence_key(key: String, value: String) -> void :
 Steam.setRichPresence(key, value)


func _set_rich_presence_display(key: String) -> void :
 Steam.setRichPresence("steam_display", key)


func _clear_rich_presence() -> void :
 Steam.clearRichPresence()


func _request_has_friend(user_id) -> void :
 Bridge.receive_has_friend(user_id, Steam.hasFriend(user_id, Steam.FRIEND_FLAG_IMMEDIATE))


func _on_screenshot_requested() -> void :
 var screenshot_image: = await Game.take_screenshot()
 screenshot_image.convert(Image.FORMAT_RGB8)
 Steam.writeScreenshot(screenshot_image.get_data(), screenshot_image.get_width(), screenshot_image.get_height())


func _request_update_time() -> void :
 Bridge.unix_time = Steam.getServerRealTime()


func _request_popup_keyboard(purpose: String, max_length: int, existing_text: String) -> void :
 Steam.showGamepadTextInput(Steam.GAMEPAD_TEXT_INPUT_MODE_NORMAL, Steam.GAMEPAD_TEXT_INPUT_LINE_MODE_SINGLE_LINE, purpose, max_length, existing_text)


func _on_gamepad_text_input_dismissed(submitted: bool, text: String, _app_id: int) -> void :
 if submitted:
  Bridge.receive_gamepad_text(text)
 else:
  Bridge.receive_gamepad_text_cancelled()
