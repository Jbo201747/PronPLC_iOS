@tool
extends BackgroundChunk


@onready var smoke: Sprite2D = %Smoke
@onready var smoke_outline: Sprite2D = %SmokeOutline
@onready var smoke_inner_outline: Sprite2D = %SmokeInnerOutline
@onready var smoke_viewport: SubViewport = %SmokeViewport
@onready var smoke_viewport_sprite: Sprite2D = %SmokeViewportSprite


func _ready():
 super._ready()

 update_window_size()
 get_window().size_changed.connect(update_window_size)

 if not Engine.is_editor_hint() and Game.main.force_skip_transition:
  var particle_spawners: = get_tree().get_nodes_in_group("act_3_particle_spawner")
  for spawner in particle_spawners:
   spawner.color = Color(3465577727)


func _process(delta: float) -> void :
 if not Engine.is_editor_hint():
  smoke.region_rect.position.x += 5.0 * delta
  smoke_outline.region_rect = smoke.region_rect
  smoke_inner_outline.region_rect = smoke.region_rect


func update_window_size() -> void :
 smoke_viewport.size = Vector2i((Vector2(get_window().size) / Vector2(480.0, 270.0)) * Vector2(smoke_viewport.size_2d_override))
 smoke_viewport_sprite.scale = Vector2(smoke_viewport.size_2d_override) / Vector2(smoke_viewport.size)
 (smoke_viewport_sprite.material as ShaderMaterial).set_shader_parameter("sprite_scale", smoke_viewport_sprite.scale)


func _on_bg_interrupt_marker_triggered() -> void :
 %SmokeAnimPlayer.play_advance("appear")
