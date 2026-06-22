@tool
class_name InputGlyph extends Control

enum GlyphType{
 KEY, 
 JOY_BUTTON, 
 JOY_AXIS, 
}

const LABEL_POSITIONS: Dictionary[int, Vector2] = {
 0: Vector2(4, 4), 
 2: Vector2(4, 4), 
 3: Vector2(5, 4), 
 4: Vector2(4, 4), 
 5: Vector2(6, 6), 
 6: Vector2(2, 6), 
 9: Vector2(4, 4), 
}

const LABEL_SIZES: Dictionary[int, Vector2] = {
 0: Vector2(16, 14), 
 2: Vector2(16, 16), 
 3: Vector2(15, 14), 
 4: Vector2(15, 14), 
 5: Vector2(16, 12), 
 6: Vector2(16, 12), 
 9: Vector2(16, 16), 
}

const LABEL_FONT_SIZES: Dictionary[int, int] = {
 0: 8, 
 2: 7, 
 3: 6, 
 4: 6, 
 5: 6, 
 6: 6, 
 9: 7, 
}

@export var glyph_type: GlyphType = GlyphType.KEY:
 set(value):
  glyph_type = value
  if is_node_ready() and not set_no_update:
   update()
@export var glyph_id: int:
 set(value):
  glyph_id = value
  if is_node_ready() and not set_no_update:
   update()
@export var key: Key = Key.KEY_NONE:
 set(value):
  key = value
  if key != KEY_NONE:
   joy_button = JoyButton.JOY_BUTTON_INVALID
   joy_axis = JoyAxis.JOY_AXIS_INVALID
   glyph_type = GlyphType.KEY
   glyph_id = value
@export var joy_button: JoyButton = JoyButton.JOY_BUTTON_INVALID:
 set(value):
  joy_button = value
  if value != JoyButton.JOY_BUTTON_INVALID:
   joy_axis = JoyAxis.JOY_AXIS_INVALID
   key = KEY_NONE
   glyph_type = GlyphType.JOY_BUTTON
   glyph_id = value
@export var joy_axis: JoyAxis = JoyAxis.JOY_AXIS_INVALID:
 set(value):
  joy_axis = value
  if value != JoyAxis.JOY_AXIS_INVALID:
   joy_button = JoyButton.JOY_BUTTON_INVALID
   key = KEY_NONE
   glyph_type = GlyphType.JOY_AXIS
   glyph_id = value

var set_no_update: = false

@onready var sprite: Sprite2D = %Sprite2D
@onready var label: DebossLabel = %DebossLabel


func _ready() -> void :
 update()


func _validate_property(property: Dictionary) -> void :
 if not Engine.is_editor_hint():
  return

 if property.name in ["keycode", "joy_button", "joy_axis"]:
  property.usage = property.usage & ( ~ PropertyUsageFlags.PROPERTY_USAGE_STORAGE)


func update() -> void :
 if glyph_type == GlyphType.KEY:
  sprite.frame = 0
  label.text = OS.get_keycode_string(glyph_id)
 elif glyph_type == GlyphType.JOY_BUTTON:
  match glyph_id:
   JoyButton.JOY_BUTTON_DPAD_LEFT, JoyButton.JOY_BUTTON_DPAD_RIGHT, JoyButton.JOY_BUTTON_DPAD_DOWN, JoyButton.JOY_BUTTON_DPAD_UP:
    sprite.frame = 1
   JoyButton.JOY_BUTTON_LEFT_SHOULDER:
    sprite.frame = 5
    label.text = "LB"
   JoyButton.JOY_BUTTON_RIGHT_SHOULDER:
    sprite.frame = 6
    label.text = "RB"
   JoyButton.JOY_BUTTON_BACK:
    sprite.frame = 7
   JoyButton.JOY_BUTTON_START:
    sprite.frame = 8
   JoyButton.JOY_BUTTON_A:
    sprite.frame = 9
    label.text = "A"
   JoyButton.JOY_BUTTON_B:
    sprite.frame = 9
    label.text = "B"
   JoyButton.JOY_BUTTON_X:
    sprite.frame = 9
    label.text = "X"
   JoyButton.JOY_BUTTON_Y:
    sprite.frame = 9
    label.text = "Y"
 elif glyph_type == GlyphType.JOY_AXIS:
  match glyph_id:
   JoyAxis.JOY_AXIS_LEFT_X, JoyAxis.JOY_AXIS_LEFT_Y:
    sprite.frame = 2
    label.text = "L"
   JoyAxis.JOY_AXIS_RIGHT_X, JoyAxis.JOY_AXIS_RIGHT_Y:
    sprite.frame = 2
    label.text = "R"
   JoyAxis.JOY_AXIS_TRIGGER_LEFT:
    sprite.frame = 3
    label.text = "LT"
   JoyAxis.JOY_AXIS_TRIGGER_RIGHT:
    sprite.frame = 4
    label.text = "RT"

 if sprite.frame in LABEL_POSITIONS:
  label.visible = true
  label.font_size = LABEL_FONT_SIZES[sprite.frame]
  label.position = LABEL_POSITIONS[sprite.frame]
  label.size = LABEL_SIZES[sprite.frame]
 else:
  label.visible = false

 if sprite.frame in [5, 6, 7, 8]:
  custom_minimum_size = Vector2(20, 16)
  sprite.position = Vector2(-2, -4)
  reset_size()
 else:
  custom_minimum_size = Vector2(16, 16)
  sprite.position = Vector2(-4, -4)
  reset_size()
