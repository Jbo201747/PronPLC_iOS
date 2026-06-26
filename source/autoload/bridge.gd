extends Node



signal own_id_changed
signal reset_steam_stats
signal requesting_leaderboard_entries(leaderboard_name: String)
signal requesting_find_leaderboard(leaderboard_name: String)
signal request_create_leaderboard(leaderboard_name: String)
signal requesting_avatar(user_id)
signal requesting_username(user_id)
signal requesting_has_friend(user_id)
signal request_update_stats
signal requesting_own_id
signal received_own_id
signal uploading_score(leaderboard_name: String, leaderboard_entry: LeaderboardEntry)
signal request_global_stats(exclude_self: bool)
signal setting_rich_presence_key(key: String, token: String)
signal setting_rich_presence_display(token: String)
signal clearing_rich_presence
signal request_update_time
signal request_popup_keyboard(purpose: String, max_length: int, existing_text: String)
signal request_recover_achievements
signal leaderboard_created

signal received_leaderboard_entries(leaderboard: Leaderboard)

signal gamepad_text_received
signal gamepad_text_cancelled

const TIME_OFFSET = 0

var dailies_available: = true
var leaderboards_available: = false
var steam_initialized: = false
var is_steam_deck: = false
var use_system_time: = true
var unix_time: float = -1.0

var is_creating_leaderboard: = false

var requesting_leaderboard: String = ""
var leaderboard_strong_requests: Dictionary[String, bool] = {}
var leaderboard_request_queue: Array[String] = []

var leaderboards: Dictionary[String, Leaderboard] = {}
var users: Dictionary = {}
var own_user_id: Variant = null:
 set(value):
  if own_user_id != value:
   own_user_id = value
   own_id_changed.emit()

var rich_presence_context: Dictionary[String, String] = {}

var dev_console: Window = null


func _ready():
 StringManager.ensure_loaded()

 if Util.is_mobile():
  leaderboards_available = false

 if has_steam():
  var steam_manager = load("res://source/autoload/steam_manager.gd").new()
  add_child(steam_manager)

 if is_debug_build() and not Util.is_mobile():
  var debug_scene: PackedScene = load("res://source/autoload/debug/debug.tscn")
  add_child(debug_scene.instantiate())


func has_steam() -> bool:
 return OS.has_feature("editor") or OS.has_feature("steam")


func is_debug_build() -> bool:
 return OS.is_debug_build()


func version_has_leaderboards() -> bool:
 return has_steam()


func popup_keyboard(purpose: String, max_length: int = 64, existing_text: String = "") -> void :
 request_popup_keyboard.emit(purpose, max_length, existing_text)


func receive_gamepad_text(text: String) -> void :
 var focused_control: = get_viewport().gui_get_focus_owner()
 if focused_control is LineEdit:
  focused_control.text = text
  focused_control.text_changed.emit(text)
  focused_control.release_focus()
  gamepad_text_received.emit()


func receive_gamepad_text_cancelled() -> void :
 var focused_control: = get_viewport().gui_get_focus_owner()
 if focused_control is LineEdit:
  focused_control.release_focus()
  gamepad_text_cancelled.emit()


func has_user_id() -> bool:
 return own_user_id != null


func get_user_id() -> Variant:
 return own_user_id


func get_leaderboard(leaderboard_name: String) -> Leaderboard:
 if leaderboard_name not in leaderboards:
  var new_leaderboard: = Leaderboard.new(leaderboard_name)
  new_leaderboard.received_entries.connect(received_leaderboard_entries.emit.bind(new_leaderboard))
  leaderboards[leaderboard_name] = new_leaderboard


 return leaderboards[leaderboard_name]


func get_user(user_id) -> User:
 if user_id not in users:
  users[user_id] = User.new()
  requesting_username.emit(user_id)

 return users[user_id]


func request_leaderboard_entries(leaderboard_name: String, strong: = false) -> void :
 var leaderboard: = get_leaderboard(leaderboard_name)
 if leaderboard.waiting_for_entries:
  return

 if (
   Time.get_ticks_msec() < leaderboard.last_time_entries_downloaded + 10000
 ):
  leaderboard.received_entries.emit()
  return

 if requesting_leaderboard == "":
  requesting_leaderboard = leaderboard_name
  leaderboard.waiting_for_entries = true
  leaderboard.last_time_entries_downloaded = Time.get_ticks_msec()
  requesting_leaderboard_entries.emit(leaderboard_name)
 else:
  for i in range(leaderboard_request_queue.size() - 1, -1, -1):
   var requested_leaderboard: = leaderboard_request_queue[i]
   if requested_leaderboard not in leaderboard_strong_requests:
    leaderboard_request_queue.remove_at(i)

  leaderboard_request_queue.append(leaderboard_name)
  if strong:
   leaderboard_strong_requests[leaderboard_name] = true


func get_leaderboard_entries(leaderboard_name: String) -> Array[LeaderboardEntry]:
 var leaderboard: = get_leaderboard(leaderboard_name)
 request_leaderboard_entries(leaderboard_name, true)
 if leaderboard.waiting_for_entries:
  await leaderboard.received_entries

 return leaderboard.get_entries()


func receive_leaderboard_entries(leaderboard_name: String, entries: Array[LeaderboardEntry], failed_to_find: = false, has_outstanding_requests: = false):
 requesting_leaderboard = ""

 var leaderboard: = get_leaderboard(leaderboard_name)
 leaderboard.exists = true

 if has_outstanding_requests:
  if not failed_to_find:
   leaderboard.last_time_entries_downloaded = Time.get_ticks_msec()

  if not entries.is_empty():
   leaderboard.add_entries(entries)

  return

 leaderboard.waiting_for_entries = false

 if not leaderboard_request_queue.is_empty():
  var next_request: String = leaderboard_request_queue.pop_front()
  if next_request in leaderboard_strong_requests:
   leaderboard_strong_requests.erase(next_request)

  request_leaderboard_entries(next_request)

 if failed_to_find:
  leaderboard.received_entries.emit()
  return

 leaderboard.last_time_entries_downloaded = Time.get_ticks_msec()
 leaderboard.add_entries(entries)
 leaderboard.successfully_found_entries = true
 leaderboard.received_entries.emit()


func check_leaderboard_exists(leaderboard_name: String):
 var leaderboard: = get_leaderboard(leaderboard_name)
 requesting_find_leaderboard.emit(leaderboard_name)
 await leaderboard.found
 return leaderboard.exists


func receive_leaderboard_found(leaderboard_name: String, failed_to_find: bool = false) -> void :
 var leaderboard: = get_leaderboard(leaderboard_name)
 leaderboard.exists = leaderboard.successfully_found_entries or not failed_to_find
 leaderboard.found.emit()


func get_avatar(user_id) -> ImageTexture:
 var user: = get_user(user_id)
 if user.has_avatar:
  return user.avatar

 requesting_avatar.emit(user_id)
 await user.received_avatar
 if user.has_avatar:
  return user.avatar
 else:
  return ImageTexture.new()


func receive_avatar(user_id, avatar: ImageTexture):
 var user: = get_user(user_id)
 user.avatar = avatar
 user.has_avatar = true
 user.received_avatar.emit()


func get_username(user_id) -> String:
 var user: = get_user(user_id)
 return user.username


func set_username(user_id, username: String):
 var user: = get_user(user_id)
 user.username = username


func upload_score(leaderboard_name: String, entry: LeaderboardEntry) -> bool:
 var already_on: = await is_user_on_leaderboard(leaderboard_name, Bridge.own_user_id)
 if already_on:
  return true

 var leaderboard: = get_leaderboard(leaderboard_name)
 uploading_score.emit(leaderboard_name, entry)
 await leaderboard.score_uploaded


 if leaderboard.score_successfully_uploaded:
  leaderboard.last_time_entries_downloaded = -10001

 return leaderboard.score_successfully_uploaded


func confirm_score_uploaded(leaderboard_name: String, successful: bool):
 var leaderboard: = get_leaderboard(leaderboard_name)
 leaderboard.score_successfully_uploaded = successful
 leaderboard.score_uploaded.emit()


func try_upload_score(leaderboard_name: String, entry: LeaderboardEntry) -> void :
 var uploaded_successfully: bool = false
 if entry.user_id == own_user_id and leaderboards_available:
  uploaded_successfully = await upload_score(leaderboard_name, entry)

 if not uploaded_successfully and entry.user_id != null:
  var save: = SaveManager.get_save()
  save.data.stored_scores[leaderboard_name] = entry.get_save_data()


func is_user_on_leaderboard(leaderboard_name: String, user_id: Variant) -> bool:
 if not leaderboards_available:
  return false

 var leaderboard: = get_leaderboard(leaderboard_name)
 if leaderboard.successfully_found_entries and is_user_in_entries(leaderboard.get_entries(), user_id):
  return true

 var entries: = await get_leaderboard_entries(leaderboard_name)
 return is_user_in_entries(entries, user_id)


func is_user_in_entries(entries: Array[LeaderboardEntry], user_id: Variant) -> bool:
 for entry in entries:
  if entry.user_id == user_id:
   return true

 return false


func clear_rich_presence() -> void :

 clearing_rich_presence.emit()


func set_rich_presence_key(key: String, value: String) -> void :
 rich_presence_context[key] = value
 setting_rich_presence_key.emit(key, value)


func set_rich_presence_display(key: String) -> void :



 setting_rich_presence_display.emit(key)


func has_friend(user_id) -> bool:
 var user: = get_user(user_id)
 if user.has_is_friend:
  return user.is_friend
 else:
  user.searching_for_friend = true
  requesting_has_friend.emit(user_id)
  if user.searching_for_friend:
   await user.received_is_friend

  return user.is_friend


func receive_has_friend(user_id, is_friend: bool) -> void :
 var user: = get_user(user_id)
 user.has_is_friend = true
 user.is_friend = is_friend
 user.searching_for_friend = false
 user.received_is_friend.emit()


func get_unix_time() -> float:
 if use_system_time:
  return Time.get_unix_time_from_system() + TIME_OFFSET
 else:
  request_update_time.emit()
  return unix_time + TIME_OFFSET


func create_leaderboard(leaderboard_name: String) -> void :
 is_creating_leaderboard = true
 request_create_leaderboard.emit(leaderboard_name)
 if is_creating_leaderboard:
  await leaderboard_created


func receive_created_leaderboard() -> void :
 is_creating_leaderboard = false
 leaderboard_created.emit()


class Leaderboard extends RefCounted:
 signal found
 signal received_entries
 signal score_uploaded

 var leaderboard_name: String = ""
 var ranked_entries: Dictionary[int, LeaderboardEntry] = {}
 var last_time_entries_downloaded: int = -10001
 var successfully_found_entries: bool = false
 var waiting_for_entries: bool = false
 var score_successfully_uploaded: bool = false
 var exists: bool = false


 func _init(_leaderboard_name: String) -> void :
  leaderboard_name = _leaderboard_name


 func add_entry(entry: LeaderboardEntry) -> void :
  for rank in ranked_entries.keys():
   var existing_entry: = ranked_entries[rank]
   if existing_entry.user_id == entry.user_id:
    ranked_entries.erase(rank)

  ranked_entries[entry.global_rank] = entry


 func add_entries(entries: Array[LeaderboardEntry]) -> void :
  for entry in entries:
   add_entry(entry)


 func get_entries() -> Array[LeaderboardEntry]:
  var keys = ranked_entries.keys()
  keys.sort()
  var entries: Array[LeaderboardEntry] = []
  for key in keys:
   entries.append(ranked_entries[key])

  return entries


class User extends RefCounted:
 signal received_avatar
 signal received_is_friend

 var searching_for_friend: = false
 var id
 var username: String = ""
 var avatar: ImageTexture
 var has_avatar: = false
 var has_is_friend: = false
 var is_friend: = false


class LeaderboardEntry extends RefCounted:
 const FORMAT_NUMBER = 5

 var user_id: Variant = null
 var format_number: int = 0
 var game_version: String = "0"
 var kills: int = 0
 var died: bool = false
 var forfeited: bool = false
 var turns_taken: int = 0
 var longest_word: String = ""
 var damage_taken: int = 0
 var time_taken: int = 0
 var global_rank: int = 0
 var spells: Array[String] = []
 var spell_data: Array[PackedByteArray] = []
 var last_enemy: String = ""
 var invalid: bool = false


 func get_steam_details() -> PackedInt32Array:
  var data = SimpleByteArray.new(PackedByteArray())
  data.store_u32(FORMAT_NUMBER)
  data.store_string(game_version)
  data.store_u32(turns_taken)
  data.store_u32(kills)
  data.store_string(longest_word)
  data.store_u32(damage_taken)
  data.store_u32(time_taken)
  data.store_string_array(spells)

  for spell_info in spell_data:
   data.store_byte_array(spell_info)

  if died or forfeited:
   data.store_u8(1 if died else 2)
   data.store_string(last_enemy)
  else:
   data.store_u8(0)

  return data.get_packed_int32_array()


 func get_score() -> int:

  var score: int = 0
  var counted_kills: = mini(kills, 15)
  if not died and not forfeited:
   score = score | 1 << 31
   counted_kills = 15


  score = score | (counted_kills << 27)


  var turns_taken_score: int = 127 - mini(turns_taken, 127)
  score = score | (turns_taken_score << 20)


  var damage_taken_score: int = 127 - mini(damage_taken, 127)
  score = score | (damage_taken_score << 13)


  var time_taken_seconds: int = time_taken / 1000
  var time_taken_score: int = 8191 - mini(time_taken_seconds, 8191)
  score = score | time_taken_score


  return score - (1 << 31)


 func get_save_data() -> Dictionary:
  return {
   format_number = format_number, 
   game_version = game_version, 
   kills = kills, 
   died = died, 
   forfeited = forfeited, 
   last_enemy = last_enemy, 
   turns_taken = turns_taken, 
   longest_word = longest_word, 
   damage_taken = damage_taken, 
   time_taken = time_taken, 
   spells = spells, 
   spell_data = spell_data, 
   user_id = user_id, 
  }


 func load_save_data(save: Dictionary) -> void :
  format_number = save.get("format_number", 1)
  game_version = save.get("game_version", "0")
  kills = save.kills
  died = save.died
  forfeited = save.get("forfeited", false)
  last_enemy = save.get("last_enemy", save.get("died_to", ""))
  turns_taken = save.turns_taken
  longest_word = save.longest_word
  damage_taken = save.damage_taken
  time_taken = save.time_taken
  spells = save.spells
  spell_data = save.get("spell_data", [])
  user_id = save.get("user_id", null)


 func try_migrate():
  if SaveManager.is_version_lower(SaveManager.game_version, game_version):
   invalid = true
  elif game_version != SaveManager.game_version:
   SaveMigration.migrate_leaderboard_entry(self)


 static func create() -> LeaderboardEntry:
  var entry: = LeaderboardEntry.new()
  entry.format_number = FORMAT_NUMBER
  entry.game_version = SaveManager.game_version
  entry.user_id = Bridge.own_user_id
  return entry


 static func from_save(save: Dictionary) -> LeaderboardEntry:
  var entry: = LeaderboardEntry.new()
  entry.load_save_data(save)
  entry.try_migrate()
  return entry


 static func from_steam(steam_entry: Dictionary) -> LeaderboardEntry:
  var entry: = LeaderboardEntry.new()
  entry.user_id = steam_entry.steam_id
  entry.global_rank = steam_entry.global_rank

  var details = PackedInt32Array(steam_entry.details)
  var data = SimpleByteArray.new(details.to_byte_array())
  entry.format_number = data.get_u32()
  if FORMAT_NUMBER < entry.format_number:
   entry.invalid = true
   return entry

  if entry.format_number > 1:
   entry.game_version = data.get_string()
  else:
   entry.game_version = "0"

  entry.turns_taken = data.get_u32()
  entry.kills = data.get_u32()
  entry.longest_word = data.get_string()
  entry.damage_taken = data.get_u32()
  entry.time_taken = data.get_u32()
  entry.spells = data.get_string_array()

  if entry.format_number > 2:
   for spell in entry.spells:
    var spell_info: = data.get_byte_array()
    entry.spell_data.append(spell_info)

  var died_int = data.get_u8()
  entry.died = died_int == 1
  entry.forfeited = died_int == 2
  if entry.died or entry.forfeited:
   entry.last_enemy = data.get_string()

  if data.invalid or SaveManager.is_version_lower(SaveManager.game_version, entry.game_version):
   entry.invalid = true
  else:
   entry.try_migrate()

  return entry
