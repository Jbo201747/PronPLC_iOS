extends Node

signal updated_daily
signal daily_changed


const TIME_ZONE_UNIX_OFFSET: int = - (60 * 60 * 13)
const DAY_LENGTH: int = 60 * 60 * 24
const EARLIEST_VISIBLE_DAILY = {year = 2026, month = 6, day = 1}

var CHARACTER_BAG = Globals.CHARACTERS.values()
var LOW_DIFFICULTY_BAG = [0, 1, 2, 3, 4]
var HIGH_DIFFICULTY_BAG = [5, 6, 7, 8, 9]

var current_daily: Daily = null
var current_date: Dictionary = {year = 0, month = 0, day = 0}
var hours_until_next: int = 24
var minutes_until_next: int = 60
var seconds_until_next: int = 60

var updating_daily: = false
var current_daily_friends: int = 0
var current_daily_was_played: = false

var saved_daily_metadata: Dictionary = {has_run = false}

var daily_redownload_timer: float = 60.0
var daily_update_timer: float = 1.0


func _ready() -> void :
 set_process(false)

 SaveManager.save_changed.connect(check_saved_daily)


func _process(delta: float) -> void :
 daily_update_timer -= delta
 if daily_update_timer <= 0.0:
  daily_update_timer += 1.0
  check_daily()
  updated_daily.emit()

 daily_redownload_timer -= delta
 if daily_redownload_timer <= 0.0:
  daily_redownload_timer += 60.0
  if not updating_daily:
   download_daily_info()


func get_daily_datetime(unix_time: int = -1, days_offset: int = 0, trim: = false) -> Dictionary:
 if unix_time == -1:
  unix_time = floori(Bridge.get_unix_time())

 var zone_adjusted_datetime = Time.get_datetime_dict_from_unix_time(unix_time + TIME_ZONE_UNIX_OFFSET + days_offset * DAY_LENGTH)
 if trim:
  return {year = zone_adjusted_datetime.year, month = zone_adjusted_datetime.month, day = zone_adjusted_datetime.day}
 else:
  return zone_adjusted_datetime


func get_daily_unix_time(datetime) -> int:
 if datetime.year == -1 or datetime.month == -1 or datetime.day == -1:
  return -1

 return Time.get_unix_time_from_datetime_dict(datetime) - TIME_ZONE_UNIX_OFFSET


func get_daily_identifier(daily_dict) -> String:
 return "1_%d%02d%02d" % [daily_dict.year, daily_dict.month, daily_dict.day]


func get_current_daily_identifier() -> String:
 return get_daily_identifier(current_date)


func get_month_dailies(start_of_month, print_dailies: = false) -> Dictionary:
 var start_of_month_unix = Time.get_unix_time_from_datetime_dict(start_of_month)
 var month_seed = str(start_of_month_unix).hash()
 var daily_rng = RNG.new()
 daily_rng.seed = month_seed

 var last_character = null
 var last_red_character = null
 var last_difficulty = null
 var last_high_difficulty = null
 var character_bag = ShuffleBag.new(CHARACTER_BAG, daily_rng)
 var difficult_character_bag = ShuffleBag.new(CHARACTER_BAG, daily_rng)
 var low_difficulty_bag = ShuffleBag.new(LOW_DIFFICULTY_BAG, daily_rng)
 var high_difficulty_bag = ShuffleBag.new(HIGH_DIFFICULTY_BAG, daily_rng)
 var days = {}
 for i in 31:
  var character
  var difficulty
  if i % 2 == 0:
   character = character_bag.pop([last_character, last_red_character])
   last_character = character
   last_difficulty = low_difficulty_bag.pop([last_difficulty])
   difficulty = last_difficulty
  else:
   character = difficult_character_bag.pop([last_character, last_red_character])
   last_red_character = character
   last_high_difficulty = high_difficulty_bag.pop([last_high_difficulty])
   difficulty = last_high_difficulty

  var natural_daily = {character = character, difficulty = difficulty, seed = daily_rng.randi()}
  var daily_datetime = {year = start_of_month.year, month = start_of_month.month, day = i + 1}

  if print_dailies:
   print(daily_datetime, " ", natural_daily)

  if daily_datetime in FixedDailies.DAILY_INFO:
   natural_daily.merge(FixedDailies.DAILY_INFO[daily_datetime], true)

  days[daily_datetime] = natural_daily

 return days


func get_daily_data(date: Dictionary) -> Daily:
 var start_of_month: = date.duplicate()
 start_of_month.merge({day = 1, hour = 1, minute = 1, second = 1}, true)
 var month_dailies = get_month_dailies(start_of_month)
 var daily: = Daily.new()
 daily.date = date
 daily.set_data(month_dailies[date])
 return daily


func get_current_month_dailies() -> Dictionary:
 var start_of_month = get_daily_datetime().duplicate()
 start_of_month.merge({day = 1, hour = 1, minute = 1, second = 1}, true)
 return get_month_dailies(start_of_month)


func get_countdown_string() -> String:
 return "%02d:%02d:%02d" % [hours_until_next, minutes_until_next, seconds_until_next]


func check_daily() -> void :
 var daily_time = get_daily_datetime()

 hours_until_next = 23 - daily_time.hour
 minutes_until_next = 59 - daily_time.minute
 seconds_until_next = 59 - daily_time.second

 if daily_time.year != current_date.year or daily_time.month != current_date.month or daily_time.day != current_date.day:
  current_date = {year = daily_time.year, month = daily_time.month, day = daily_time.day}
  current_daily = get_daily_data(current_date)

  updating_daily = true
  updated_daily.emit()
  reset_daily_info()
  refresh_daily()


func refresh_daily() -> void :
 check_saved_daily()
 download_daily_info()


func reset_daily_info() -> void :
 current_daily_was_played = false
 current_daily_friends = 0


func download_daily_info() -> void :
 if not Bridge.version_has_leaderboards():
  return

 var leaderboard_name: = get_current_daily_identifier()
 var entries: = await Bridge.get_leaderboard_entries(leaderboard_name)
 var leaderboard: Bridge.Leaderboard = Bridge.get_leaderboard(leaderboard_name)
 if leaderboard.successfully_found_entries:
  reset_daily_info()
  current_daily_was_played = Bridge.is_user_in_entries(entries, Bridge.own_user_id)
  for entry in entries:
   if await Bridge.has_friend(entry.user_id):
    current_daily_friends += 1

 updating_daily = false
 updated_daily.emit()


func has_saved_daily(check: = true) -> bool:
 if check:
  check_saved_daily()

 return saved_daily_metadata.has_run


func check_saved_daily() -> void :
 if not SaveManager.has_valid_selected_save() or Game.is_in_run():
  return

 var save: = SaveManager.get_save()

 saved_daily_metadata = save.get_saved_daily(false).metadata
 if has_saved_daily(false):
  var is_invalid: bool = "daily" not in saved_daily_metadata or saved_daily_metadata.daily != current_date
  if not is_invalid and current_daily_was_played:
   is_invalid = not saved_daily_metadata.get("debug", false)

  if is_invalid:
   if Bridge.version_has_leaderboards() and "forfeit_entry" in saved_daily_metadata:
    var entry: = Bridge.LeaderboardEntry.from_save(saved_daily_metadata.forfeit_entry)
    Bridge.try_upload_score(get_daily_identifier(saved_daily_metadata.daily), entry)

   save.clear_saved_daily()
   saved_daily_metadata = {has_run = false}


func get_saved_daily_playable() -> Dictionary:
 return SaveFile.get_run_playable(saved_daily_metadata, true)


func can_view_daily() -> bool:
 if not SaveManager.has_valid_selected_save():
  return false

 if not SaveManager.get_unlocks_disabled():
  var save: = SaveManager.get_save()
  if save.get_enemy_stats(Enemies.CAT, -1, false).encounters == 0:
   return false

 return true


func can_play_daily() -> bool:
 if not can_view_daily() or not Bridge.dailies_available:
  return false

 if not ModLoader.get_active_mod_ids(true).is_empty():
  return false

 var save: = SaveManager.get_save()
 if not save.can_play_daily(current_date) or current_daily_was_played:
  return false

 if not SaveManager.get_unlocks_disabled():
  if not Globals.is_character_unlocked(current_daily.character):
   return false

 return true


func can_view_leaderboards() -> bool:
 if not Bridge.version_has_leaderboards() or not can_view_daily():
  return false

 return true


func is_date_invalid_daily(daily_date: Dictionary) -> bool:
 var unix: = get_daily_unix_time(daily_date)
 var current_unix: = get_daily_unix_time(current_date)

 if unix > current_unix:
  return true
 elif unix < get_daily_unix_time(EARLIEST_VISIBLE_DAILY):
  return true

 return false


func can_view_leaderboard(daily_date: Dictionary = current_date) -> bool:
 if not can_view_leaderboards():
  return false

 var unix: = get_daily_unix_time(daily_date)
 var current_unix: = get_daily_unix_time(current_date)
 if is_date_invalid_daily(daily_date):
  return false
 elif unix < current_unix:
  return true

 if (
  current_daily_was_played
  or (Game.is_in_run() and Game.active_daily.date == current_date)
 ):
  return true

 return false
