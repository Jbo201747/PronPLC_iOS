class_name ActionButton extends Button


@export var action: StringName = &"":
 set(value):
  action = value
  update_action()

var action_listener: InputManager.ActionListener
var was_pressed: = false


func update_action() -> void :
 if action_listener != null:
  action_listener.pressed.disconnect(_on_action_pressed)
  action_listener.released.disconnect(_on_action_released)

 if action != &"":
  action_listener = InputManager.get_action_listener(action)
  action_listener.pressed.connect(_on_action_pressed)
  action_listener.released.connect(_on_action_released)


func is_interactable() -> bool:
 return not disabled and is_visible_in_tree() and InputManager.can_take_focus()


func trigger_action() -> void :
 was_pressed = false

 if toggle_mode:
  button_pressed = not button_pressed

 pressed.emit()


func _on_action_pressed() -> void :
 if not is_interactable():
  was_pressed = false
  return

 was_pressed = true
 button_down.emit()
 if action_mode == Button.ACTION_MODE_BUTTON_PRESS:
  trigger_action()


func _on_action_released() -> void :
 if not is_interactable():
  was_pressed = false
  return

 button_up.emit()
 if action_mode == Button.ACTION_MODE_BUTTON_RELEASE:
  if was_pressed:
   trigger_action()

 was_pressed = false
