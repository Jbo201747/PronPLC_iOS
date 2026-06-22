class_name InputGuide extends HBoxContainer


var string_key: String = "":
 set(value):
  string_key = value
  update()

@onready var glyph: MultiActionGlyph = %Glyph
@onready var action: Label = %Action


func update() -> void :
 glyph.action_string = ""
 action.text = ""

 if not StringManager.has_string_group(string_key):
  glyph.update()
  return

 var group: = StringManager.get_string_group(string_key)
 if group.has_string("0"):
  glyph.action_string = group.get_string("0")
  glyph.update()

 if group.has_string("1"):
  action.text = group.get_string("1")
