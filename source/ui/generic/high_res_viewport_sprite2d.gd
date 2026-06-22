@tool
class_name HighResViewportSprite2D extends Sprite2D


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
  _on_viewport_scale_updated(Vector2(0, 0))
 texture = viewport.get_texture()


func _on_viewport_scale_updated(screen_ratio: Vector2):
 if Engine.is_editor_hint():
  screen_ratio = Vector2(8.0, 8.0)

 scale = Vector2.ONE / screen_ratio

 if material != null and is_instance_valid(material) and material is ShaderMaterial:
  material.set_shader_parameter("viewport_scale", screen_ratio)

 queue_redraw()
