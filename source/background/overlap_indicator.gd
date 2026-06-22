@tool
class_name BGOverlap extends Control

@export_range(-1, 32, 1) var threshold: int = -1:
 set(value):
  threshold = value
  queue_redraw()
 get:
  return min(threshold, size.x)


func _init():
 if not Engine.is_editor_hint():
  visible = false
  process_mode = Node.PROCESS_MODE_DISABLED


func _ready():
 if Engine.is_editor_hint():
  if not resized.is_connected(_on_resized):
   resized.connect(_on_resized)


func _validate_property(property: Dictionary) -> void :
 if property.name == "threshold":
  property.hint_string = "-1," + str(size.x) + ",1"


func _on_resized() -> void :
 notify_property_list_changed()


func should_be_visible():
 if not Engine.is_editor_hint():
  return false

 var editor_interface = Engine.get_singleton("EditorInterface")
 return owner == editor_interface.get_edited_scene_root() and get_parent() != null


func _draw():
 if should_be_visible():
  draw_rect(Rect2(Vector2(0, 0), size), Color.DARK_ORANGE, false, -4.0, false)

  if threshold != -1:
   var threshold_x = threshold
   if "Right" in get_parent().name:
    threshold_x = size.x - threshold
   draw_line(Vector2(threshold_x, 0), Vector2(threshold_x, size.y), Color.RED, -4.0, false)
