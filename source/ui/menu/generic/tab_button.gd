@tool
class_name TabButton extends Control


signal tab_changed


enum GlyphState{
 NONE, 
 LEFT, 
 RIGHT, 
}


@export var selected: bool = false:
 set(value):
  selected = value
  if is_node_ready():
   update()
@export var button_group: ButtonGroup = null:
 set(value):
  button_group = value
  if is_node_ready():
   button.button_group = button_group
   update()
@export var string_key: String = "":
 set(value):
  string_key = value
  if is_node_ready():
   update()
@export var tab_control: Control = null
@export var glyph_state: GlyphState = GlyphState.NONE:
 set(value):
  glyph_state = value
  if is_node_ready():
   update_glyph()


@onready var hover_handler: HoverHandler = %HoverHandler
@onready var panel: Panel = %Panel
@onready var label: Label = %Label
@onready var label_margins: MarginContainer = %LabelMargins
@onready var button: Button = %Button
@onready var action_glyph: ActionGlyph = %ActionGlyph


func _ready() -> void :
 button.button_group = button_group
 button.button_pressed = selected
 update()
 update_glyph()


func update_glyph() -> void :
 if glyph_state == GlyphState.NONE:
  action_glyph.disabled = true
  action_glyph.action = &""
  return

 action_glyph.disabled = false
 if glyph_state == GlyphState.LEFT:
  action_glyph.position = Vector2(-18, 5)
  action_glyph.action = &"menu_tab_left"
 else:
  action_glyph.position = Vector2(61, 5)
  action_glyph.action = &"menu_tab_right"


func update() -> void :
 if StringManager.has_string(string_key):
  label.text = StringManager.get_string(string_key)

 if selected:
  z_index = 0
  panel.theme_type_variation = "MenuTicketTab"
  if not Engine.is_editor_hint():
   hover_handler.stop(true)
 else:
  z_index = -1
  panel.theme_type_variation = "MenuTicketTabDeselected"
  if not Engine.is_editor_hint():
   hover_handler.resume()
