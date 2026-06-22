@tool
class_name Setting extends HBoxContainer

signal slider_drag_start
signal slider_drag_end
signal value_changed

@export var setting_name: String = "Option":
 set(value):
  setting_name = value
  update_setting_name()
@export var use_string_key: bool = true
@export var value_label: Label
@export var main_control: Control
@export var disabled: bool = false:
 set(value):
  disabled = value
  update_disabled()

var set_value_method: Callable
var get_value_method: Callable

@onready var label: Label = %Label


func _ready() -> void :
 update_setting_name()
 update_disabled()


func update_setting_name() -> void :
 if is_node_ready():
  if use_string_key and StringManager.has_string(setting_name):
   label.text = StringManager.get_string(setting_name)
  else:
   label.text = setting_name


func set_setting_methods(get_value: Callable, set_value: Callable) -> void :
 get_value_method = get_value
 set_value_method = set_value
 SaveManager.updated_settings.connect(load_setting)
 load_setting()


func load_setting() -> void :
 if not get_value_method.is_valid():
  return

 var value: Variant = get_value_method.call()
 if main_control is BaseButton:
  main_control.set_pressed_no_signal(value)
 elif main_control is Range:
  main_control.set_value_no_signal(value)
  update_value_label(value)
 elif main_control is LabelSwitcher:
  main_control.selected_option = value


func update_value_label(value: float) -> void :
 if value_label != null:
  value_label.text = str(floori(value * 100))


func update_disabled() -> void :
 if not is_node_ready():
  return

 if disabled:
  label.add_theme_color_override("font_color", Color(2658695423))
  if value_label != null:
   value_label.add_theme_color_override("font_color", Color(2658695423))
 else:
  label.add_theme_color_override("font_color", Color.BLACK)
  if value_label != null:
   value_label.add_theme_color_override("font_color", Color.BLACK)

 if main_control is BaseButton:
  main_control.disabled = disabled
 elif main_control is LabelSwitcher:
  main_control.disabled = disabled


func _button_toggled(toggled_on: bool) -> void :
 if set_value_method.is_valid():
  set_value_method.call(toggled_on)

 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 Game.menu_shake(true)
 value_changed.emit()


func _value_changed(value: float) -> void :
 if set_value_method.is_valid():
  set_value_method.call(value)

 AudioManager.play_sound(Sounds.UI.SLIDER)
 update_value_label(value)
 value_changed.emit()


func _label_switcher_value_changed(value: int) -> void :
 if set_value_method.is_valid():
  set_value_method.call(value)

 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
 Game.menu_shake(true)
 value_changed.emit()


func _slider_drag_start() -> void :
 slider_drag_start.emit()


func _slider_drag_end(_slider_value_changed: bool) -> void :
 slider_drag_end.emit()
