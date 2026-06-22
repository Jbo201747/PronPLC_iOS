@tool
class_name ActionGlyph extends InputGlyph

@export var action: StringName = &"":
 set(value):
  action = value
  if is_node_ready():
   update()
@export var show_keyboard_action: bool = false:
 set(value):
  show_keyboard_action = value
  if is_node_ready():
   update()
@export var controller_mode_only: bool = false
@export var with_setting_only: bool = false

var disabled: bool = false:
 set(value):
  disabled = value
  if is_node_ready():
   update()


func _ready() -> void :
 if not Engine.is_editor_hint():
  InputManager.input_mode_changed.connect(update)
  InputManager.controller_type_changed.connect(update)
  SaveManager.updated_settings.connect(update)

 super._ready()


func update_glyph() -> void :
 if Engine.is_editor_hint():
  return

 if InputMap.has_action(action):
  var events: = InputMap.action_get_events(action)
  var has_non_keyboard_actions: = false
  for event in events:
   if event is not InputEventKey:
    has_non_keyboard_actions = true
    break

  for event in InputMap.action_get_events(action):
   if show_keyboard_action or not has_non_keyboard_actions:
    if event is InputEventKey:
     glyph_type = GlyphType.KEY
     glyph_id = event.physical_keycode
     return
   else:
    if event is InputEventJoypadButton:
     glyph_type = GlyphType.JOY_BUTTON
     glyph_id = event.button_index
     return
    elif event is InputEventJoypadMotion:
     glyph_type = GlyphType.JOY_AXIS
     glyph_id = event.axis
     return

 glyph_type = GlyphType.KEY
 glyph_id = KEY_0


func update() -> void :
 set_no_update = true
 update_glyph()
 set_no_update = false

 if not Engine.is_editor_hint():
  visible = true

  if disabled or action == &"":
   visible = false

  if controller_mode_only and InputManager.get_input_mode() != InputManager.InputMode.CONTROLLER:
   visible = false

  if with_setting_only and not SaveManager.get_gamepad_prompts_enabled():
   visible = false

 super.update()
