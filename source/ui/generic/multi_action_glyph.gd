class_name MultiActionGlyph extends HBoxContainer


const ACTION_GLYPH_SCENE = preload("res://source/ui/generic/action_glyph.tscn")
const SEPARATOR_SCENE = preload("res://source/ui/generic/multi_action_glyph_separator.tscn")


var action_string: String


func update() -> void :
 for child in get_children():
  remove_child(child)
  child.queue_free()

 var actions: = action_string.split(" ", false)
 for action in actions:
  if InputMap.has_action(action):
   var glyph: ActionGlyph = ACTION_GLYPH_SCENE.instantiate()
   glyph.action = action
   add_child(glyph)
  else:
   var separator: MarginContainer = SEPARATOR_SCENE.instantiate()
   var separator_label: Label = separator.get_node("%Label")
   separator_label.text = action
   add_child(separator)
