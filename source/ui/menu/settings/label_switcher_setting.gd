@tool
class_name LabelSwitcherSetting extends Setting


@export var options: Array[String] = []:
 set(value):
  options = value
  update_switcher()
@export var selected_option: int = 0:
 get():
  if main_control is LabelSwitcher:
   return main_control.selected_option

  return 0
 set(value):
  if main_control is LabelSwitcher:
   main_control.try_set_selected_option(value)
@export var switcher_string_key: bool = false:
 set(value):
  if main_control is LabelSwitcher:
   main_control.use_string_key = value
 get():
  if main_control is LabelSwitcher:
   return main_control.use_string_key

  return false
@export var allow_wrap_around: bool = true:
 set(value):
  allow_wrap_around = value
  update_switcher()


func _ready() -> void :
 super._ready()
 update_switcher()


func update_switcher() -> void :
 if not is_node_ready():
  return

 if main_control is LabelSwitcher:
  main_control.options = options
  main_control.allow_wrap_around = allow_wrap_around
