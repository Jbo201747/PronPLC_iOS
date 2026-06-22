@tool
class_name BGGroupEntry extends BGPatternEntry

var group_hint = "":
 set(value):
  group_hint = value
  notify_property_list_changed()

@export_enum("group") var id: String = ""

@export var auto_weight: bool = false

@export var flatten: bool = false


func _validate_property(property: Dictionary):
 if property.name == "id":
  property.hint_string = group_hint


func get_weight(layer: BGLayer) -> float:
 if not auto_weight:
  return weight

 var group: = layer.get_group(id)
 if group == null:
  return weight

 return weight * group.get_sum_weight(layer)
