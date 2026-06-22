@tool
class_name RefMarker extends Marker2D

@export_file("*.tscn") var file_path: String = ""

func _ready():
 if not Engine.is_editor_hint() or file_path == "":
  return

 var editor_interface = Engine.get_singleton("EditorInterface")
 if owner != editor_interface.get_edited_scene_root():
  return

 if file_path != "":
  for child in get_children():
   if child.has_meta("ref_marker_ref"):
    child.queue_free()

  var packed_scene: PackedScene = load(file_path)
  var instance: = packed_scene.instantiate()
  instance.set_meta("ref_marker_ref", true)
  add_child(instance)
