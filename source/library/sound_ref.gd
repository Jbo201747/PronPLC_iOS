@tool
class_name SoundRef extends Resource


@export_enum("None") var groups: = PackedStringArray()
@export_enum("None") var sound: String = ""


func _validate_property(property: Dictionary) -> void :
 if not Engine.is_editor_hint():
  return

 if property.name in ["groups", "sound"]:
  Sounds.validate_sound_property(property, property.name == "groups", groups)
