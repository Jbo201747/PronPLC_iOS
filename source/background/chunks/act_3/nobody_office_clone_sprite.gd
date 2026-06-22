extends Sprite2D


func _ready() -> void :
 var target_sprite: Sprite2D = get_tree().get_first_node_in_group("nobody_smoke_viewport_sprite")
 if target_sprite == null:
  set_process(false)
  return

 texture = target_sprite.texture
 material = target_sprite.material


func _process(_delta: float) -> void :
 var target_sprite: Sprite2D = get_tree().get_first_node_in_group("nobody_smoke_viewport_sprite")
 if target_sprite == null:
  return

 global_transform = target_sprite.global_transform
