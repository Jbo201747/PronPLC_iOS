@tool
class_name HighResViewport extends SubViewport


signal scale_updated(screen_ratio: Vector2)


func _ready():
 canvas_transform = Transform2D(0, Vector2(size_2d_override) / 2)
 if not Engine.is_editor_hint():
  update_resolution()
  get_tree().root.size_changed.connect(update_resolution)
 else:
  size = size_2d_override * 8


func update_resolution():
 var window = get_window()
 var screen_ratio = Vector2(window.size) / Vector2(window.content_scale_size)
 size = Vector2i(Vector2(size_2d_override) * screen_ratio)
 scale_updated.emit(screen_ratio)
