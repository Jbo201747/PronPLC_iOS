class_name LeaderboardFilterButton extends MarginContainer

signal toggled

@onready var label: Label = %Label
@onready var menu_icon: MenuIcon = %MenuIcon
@onready var button: Button = %Button


func _ready() -> void :
 update_state()


func set_friends_only(active: bool) -> void :
 button.set_pressed_no_signal(active)
 update_state()


func is_friends_only() -> bool:
 return button.button_pressed


func update_state() -> void :
 if is_friends_only():
  menu_icon.frame = 0
  label.text = StringManager.get_string("menu/leaderboard/friends")
  update_minimum_size()
  menu_icon.string_identifier = "menu/leaderboard/toggle_global"
 else:
  menu_icon.frame = 1
  label.text = StringManager.get_string("menu/leaderboard/global")
  update_minimum_size()
  menu_icon.string_identifier = "menu/leaderboard/toggle_friends"


func _on_button_toggled(_toggled_on: bool) -> void :
 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 Game.menu_shake(true)
 update_state()
 toggled.emit()
