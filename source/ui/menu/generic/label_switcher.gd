@tool
class_name LabelSwitcher extends HBoxContainer

signal left_pressed
signal right_pressed
signal value_changed(value: int)

@export var options: Array[String] = []:
 set(value):
  options = value
  update()
@export var allow_wrap_around: bool = true
@export var use_string_key: bool = false

@export var update_self: bool = true
@export var disabled: bool = false:
 set(value):
  disabled = value
  update()

var selected_option: int = 0:
 set(value):
  selected_option = value
  update()

@onready var label: Label = %Label

@onready var left_button: Button = %LeftButton
@onready var left_sprite: Sprite2D = %LeftSprite

@onready var right_button: Button = %RightButton
@onready var right_sprite: Sprite2D = %RightSprite


func _ready() -> void :
 focus_entered.connect(_on_focus_entered)
 focus_exited.connect(_on_focus_exited)
 update()


func update() -> void :
 if not is_node_ready() or not update_self:
  return

 if disabled:
  label.add_theme_color_override("font_color", Color(2658695423))
 else:
  label.add_theme_color_override("font_color", Color.BLACK)

 if disabled:
  set_button_disabled(false, true, false)
  set_button_disabled(true, true, false)
 elif not allow_wrap_around:
  var disable_left: bool = not options.is_empty() and selected_option == 0
  set_button_disabled(true, disable_left, disable_left)
  var disable_right: bool = not options.is_empty() and selected_option == options.size() - 1
  set_button_disabled(false, disable_right, disable_right)
 else:
  set_button_disabled(false, false, false)
  set_button_disabled(true, false, false)

 if options.is_empty():
  label.text = ""
 else:
  if selected_option >= options.size():
   selected_option = options.size() - 1

  if use_string_key and StringManager.has_string(options[selected_option]):
   label.text = StringManager.get_string(options[selected_option])
  else:
   label.text = options[selected_option]


func set_button_disabled(right: bool, value: bool, hide_button: bool) -> void :
 if right:
  right_button.disabled = value
  right_sprite.visible = not hide_button
  right_sprite.frame = 3 if value else 1
 else:
  left_button.disabled = value
  left_sprite.visible = not hide_button
  left_sprite.frame = 2 if value else 0


func try_set_selected_option(selected: int) -> void :
 if options.is_empty():
  selected_option = 0
  return

 if allow_wrap_around:
  selected_option = posmod(selected, options.size())
 else:
  selected_option = clampi(selected, 0, options.size() - 1)


func _on_left_button_pressed() -> void :
 if left_button.disabled:
  return

 left_pressed.emit()

 if update_self:
  try_set_selected_option(selected_option - 1)
  value_changed.emit(selected_option)


func _on_right_button_pressed() -> void :
 if right_button.disabled:
  return

 right_pressed.emit()

 if update_self:
  try_set_selected_option(selected_option + 1)
  value_changed.emit(selected_option)


func _on_ui_pressed(direction: InputManager.Direction) -> void :
 if direction == InputManager.Direction.LEFT:
  _on_left_button_pressed()
  get_viewport().set_input_as_handled()
 elif direction == InputManager.Direction.RIGHT:
  _on_right_button_pressed()
  get_viewport().set_input_as_handled()


func _on_focus_entered() -> void :
 InputManager.ui_pressed.connect(_on_ui_pressed)


func _on_focus_exited() -> void :
 InputManager.ui_pressed.disconnect(_on_ui_pressed)
