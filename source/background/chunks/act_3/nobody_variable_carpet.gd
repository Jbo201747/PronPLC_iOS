@tool
extends BackgroundChunk


const CARPET_SPRITES: Array[Texture2D] = [
 preload("res://arte/backgrounds/act_3/carpet_1.png"), 
 preload("res://arte/backgrounds/act_3/carpet_2.png"), 
 preload("res://arte/backgrounds/act_3/carpet_3.png"), 
 preload("res://arte/backgrounds/act_3/carpet_4.png"), 
]


@onready var variable_carpet_left: TextureRect = %VariableCarpetLeft
@onready var variable_carpet_right: TextureRect = %VariableCarpetRight
@onready var carpet_sprite: Sprite2D = %CarpetSprite


func get_bounds(_with_chunk = null, global = false) -> Rect2:
 return optional_global_rect(Rect2(0, 0, variable_carpet_right.get_rect().end.x, 0), global)


func generate_bounds(_rng: RNG, _force_mirror: = false, _overlap_override: float = -1.0, previous_chunk: BackgroundChunk = null) -> void :
 var previous_chunk_global_rect: = previous_chunk.get_bounds(null, true)
 var hallway: BackgroundChunk = get_tree().get_first_node_in_group("nobody_hallway")
 var hallway_global_rect: = hallway.get_bounds(null, true)
 var remaining_distance: float = (hallway_global_rect.end.x - previous_chunk_global_rect.end.x) * (1 / 0.9)

 var largest_valid_texture: Texture2D = null
 var largest_valid_width: int = -1
 for texture in CARPET_SPRITES:
  var width: = texture.get_width()
  if width < remaining_distance and width > largest_valid_width:
   largest_valid_width = width
   largest_valid_texture = texture

 if largest_valid_texture != null:
  remaining_distance -= largest_valid_width
  carpet_sprite.texture = largest_valid_texture

 var left_width: = floorf(remaining_distance / 2.0)
 variable_carpet_left.size.x = left_width

 if largest_valid_texture != null:
  carpet_sprite.position.x = variable_carpet_left.size.x
  variable_carpet_right.position.x = variable_carpet_left.size.x + largest_valid_width
 else:
  variable_carpet_right.position.x = variable_carpet_left.size.x

 variable_carpet_right.size.x = remaining_distance - left_width
