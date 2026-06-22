@tool
class_name HighResViewportSprite3D extends Sprite3D


@export var viewport: HighResViewport:
 set(value):
  viewport = value
  setup_viewport()


func _ready():
 setup_viewport()


func setup_viewport():
 if not Engine.is_editor_hint():
  if not viewport.scale_updated.is_connected(_on_viewport_scale_updated):
   viewport.scale_updated.connect(_on_viewport_scale_updated)

  viewport.update_resolution()
 else:
  _on_viewport_scale_updated(Vector2(8.0, 8.0))
 texture = viewport.get_texture()


func _on_viewport_scale_updated(screen_ratio: Vector2):
 pixel_size = 0.08 / screen_ratio.x
