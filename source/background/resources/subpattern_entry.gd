@tool
class_name BGSubpatternEntry extends BGPlaceableEntry


var pattern_hint = "":
 set(value):
  pattern_hint = value
  notify_property_list_changed()

@export_enum("pattern") var id: String = ""

@export var randomize_start_and_end: bool = false


func _validate_property(property: Dictionary):
 if property.name == "id":
  property.hint_string = pattern_hint
