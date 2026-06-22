class_name LeaderboardPanel extends MarginContainer


@export var top_of_screen_leaderboard: bool = false

var leaderboard_entry_scene = preload("res://source/ui/menu/leaderboard/leaderboard_entry.tscn")
var displaying_leaderboard: String = ""
var back_daily = null
var forward_daily = null
var update_friends_only: bool = false
var requesting_entries: bool = false
var active: = false:
 set(value):
  active = value
  if is_node_ready():
   filter_button.button.disabled = not active

@onready var sectioned_panel: SectionedPanel = %SectionedPanel

@onready var header: LabelSwitcher = %Header

@onready var info_container: CenterContainer = %InfoContainer
@onready var info_label: Label = %InfoLabel

@onready var filter_button: LeaderboardFilterButton = %LeaderboardFilterButton


func _ready() -> void :
 Bridge.received_leaderboard_entries.connect(_received_leaderboard_entries)

 if top_of_screen_leaderboard:
  sectioned_panel.mask_type = "MenuTicketMask"
  sectioned_panel.mask_no_aa_type = "MenuTicketMaskNoAA"

  filter_button.menu_icon.tooltip_vertical_alignment = TooltipCollision.TooltipVerticalAlignment.CENTER
  filter_button.menu_icon.tooltip_horizontal_alignment = TooltipCollision.TooltipHorizontalAlignment.RIGHT

 filter_button.button.disabled = not active


func _unhandled_input(event: InputEvent) -> void :
 if not active:
  return

 if (Input.is_action_just_pressed_by_event("ui_left", event, true) or Input.is_action_just_pressed_by_event("menu_tab_left", event)) and not header.left_button.disabled:
  if not sectioned_panel.scroll.has_focus():
   sectioned_panel.scroll.grab_focus()
  _on_header_left_pressed()
 elif (Input.is_action_just_pressed_by_event("ui_right", event, true) or Input.is_action_just_pressed_by_event("menu_tab_right", event)) and not header.right_button.disabled:
  if not sectioned_panel.scroll.has_focus():
   sectioned_panel.scroll.grab_focus()
  _on_header_right_pressed()


func reset_leaderboard() -> void :
 info_container.visible = true

 reset_entries()

 if not Bridge.leaderboards_available:
  info_label.text = StringManager.get_string("menu/leaderboard/unavailable")
 else:
  info_label.text = StringManager.get_string("menu/leaderboard/loading")


func set_leaderboard(leaderboard_name: String):
 reset_leaderboard()

 if not Bridge.leaderboards_available:
  return

 displaying_leaderboard = leaderboard_name
 requesting_entries = true
 Bridge.request_leaderboard_entries(leaderboard_name)


func set_daily_leaderboard(daily_dict):
 var leaderboard_name = DailyManager.get_daily_identifier(daily_dict)
 header.label.text = StringManager.get_string("menu/leaderboard/daily_title", {
  month = "%02d" % daily_dict.month, 
  day = "%02d" % daily_dict.day, 
  year = "%d" % daily_dict.year, 
 })
 set_leaderboard(leaderboard_name)

 DailyManager.check_daily()

 var unix_time: = DailyManager.get_daily_unix_time(daily_dict)
 back_daily = DailyManager.get_daily_datetime(unix_time, -1, true)
 forward_daily = DailyManager.get_daily_datetime(unix_time, 1, true)

 header.set_button_disabled(false, not DailyManager.can_view_leaderboard(back_daily), false)
 header.set_button_disabled(true, not DailyManager.can_view_leaderboard(forward_daily), false)


func reset_entries():
 var entries = get_tree().get_nodes_in_group("leaderboard_entries")
 for entry in entries:
  entry.get_parent().remove_child(entry)
  entry.queue_free()

 sectioned_panel.update_panels()


func set_entries_for_leaderboard(leaderboard: Bridge.Leaderboard):
 reset_entries()

 var save: = SaveManager.get_save()
 var entries: = leaderboard.get_entries()
 var has_friend_entry: = false
 if leaderboard.successfully_found_entries:
  var own_rank = -1
  var has_friends_achievement: = save.has_achievement(Globals.ACHIEVEMENTS.BEAT_FRIENDS_DAILY, 1)
  var friend_entries: Array[Bridge.LeaderboardEntry] = []
  for entry in entries:
   if entry.invalid:
    push_warning("Invalid entry from user: ", str(entry.user_id))
    continue

   if entry.user_id == Bridge.own_user_id:
    own_rank = entry.global_rank
   elif await Bridge.has_friend(entry.user_id):
    has_friend_entry = true
    if not has_friends_achievement:
     friend_entries.append(entry)

   var entry_scene = leaderboard_entry_scene.instantiate()
   sectioned_panel.contents_box.add_child(entry_scene)
   entry_scene.add_to_group("leaderboard_entries")
   entry_scene.set_leaderboard_entry(entry)

  if own_rank != -1 and not has_friends_achievement:
   var beaten_friends: = 0
   for entry in friend_entries:
    if entry.global_rank > own_rank:
     beaten_friends += 1

   if beaten_friends >= 2:
    AchievementManager.unlock_achievement(Globals.ACHIEVEMENTS.BEAT_FRIENDS_DAILY, 1, false)

 if update_friends_only:
  filter_button.set_friends_only(has_friend_entry)
  update_friends_only = false

 update_entry_visibility()


func update_entry_visibility() -> void :
 var any_entries: = false
 var any_entries_visible: = false
 var show_friends_only: bool = filter_button.is_friends_only()
 var own_entry: LeaderboardMenuEntry = null
 for entry in sectioned_panel.contents_box.get_children():
  if entry is LeaderboardMenuEntry and not entry.is_queued_for_deletion():
   if not show_friends_only:
    entry.visible = true
   else:
    entry.visible = entry.entry.user_id == Bridge.own_user_id or await Bridge.has_friend(entry.entry.user_id)

   if entry.entry.user_id == Bridge.own_user_id:
    own_entry = entry

   any_entries = true
   if entry.visible:
    any_entries_visible = true

 if any_entries and not any_entries_visible:
  info_container.visible = true
  info_label.text = StringManager.get_string("menu/leaderboard/no_friends")
 else:
  info_container.visible = not any_entries
  info_label.text = StringManager.get_string("menu/leaderboard/no_entries")

 sectioned_panel.update_panels()

 if own_entry != null:
  get_tree().process_frame.connect(_ensure_entry_visible.bind(own_entry), ConnectFlags.CONNECT_ONE_SHOT)


func _ensure_entry_visible(entry: LeaderboardMenuEntry) -> void :
 if is_instance_valid(entry) and not entry.is_queued_for_deletion():
  sectioned_panel.scroll.ensure_control_visible(entry)


func generate_leaderboard() -> void :
 reset_leaderboard()

 update_friends_only = true
 if Game.is_in_run() and Game.active_daily:
  set_daily_leaderboard(Game.active_daily.date)
 else:
  DailyManager.check_daily()
  if DailyManager.can_view_leaderboard():
   set_daily_leaderboard(DailyManager.current_date)
  else:
   set_daily_leaderboard(DailyManager.get_daily_datetime(-1, -1, true))


func _on_header_left_pressed() -> void :
 if back_daily != null:
  Game.menu_shake(true)
  AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
  set_daily_leaderboard(back_daily)


func _on_header_right_pressed() -> void :
 if forward_daily != null:
  Game.menu_shake(true)
  AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
  set_daily_leaderboard(forward_daily)


func _received_leaderboard_entries(leaderboard: Bridge.Leaderboard) -> void :
 if leaderboard.leaderboard_name == displaying_leaderboard and requesting_entries:
  requesting_entries = false
  set_entries_for_leaderboard(leaderboard)


func _on_leaderboard_filter_button_toggled() -> void :
 update_entry_visibility()
