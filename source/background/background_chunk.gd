@tool
class_name BackgroundChunk extends Node2D

var bounds = {}
var inner = {left = - INF, right = INF}

@export var can_mirror: bool = false
@export var debug_rect: bool = false
@onready var left_overlap = $LeftOverlap
@onready var right_overlap = $RightOverlap
@onready var interrupt_markers: Array[BGInterruptMarker] = []


func _ready():
 if Engine.is_editor_hint() and not has_node("Guidelines"):
  var editor_interface = Engine.get_singleton("EditorInterface")
  if self == editor_interface.get_edited_scene_root():
   var guidelines: = Sprite2D.new()
   if "act_3" in scene_file_path:
    guidelines.texture = load("res://arte/backgrounds/guidelines_act_3.png")
   else:
    guidelines.texture = load("res://arte/backgrounds/guidelines.png")

   guidelines.modulate = Color(1.0, 1.0, 1.0, 74.0 / 255.0)
   add_child(guidelines)

 interrupt_markers.clear()
 interrupt_markers.append_array(find_children("*", "BGInterruptMarker", false))


func optional_global_rect(rect, global) -> Rect2:
 if global:
  rect.position = to_global(rect.position)

 return rect


func get_bounds_rect(bound, global) -> Rect2:
 var rect = Rect2(bound.left, 0, bound.right - bound.left, 0)
 return optional_global_rect(rect, global)


func get_bounds(with_chunk = null, global = false) -> Rect2:
 if bounds.is_empty():
  var sprite = get_node_or_null("Sprite2D")
  if sprite != null and sprite is Sprite2D:
   var sprite_rect: Rect2 = sprite.get_rect()
   sprite_rect.position += sprite.position
   return optional_global_rect(sprite_rect, global)

  return optional_global_rect(Rect2(0, 0, 0, 0), global)

 if with_chunk != null:
  for bound_name in bounds:
   if bound_name in with_chunk.bounds:
    return get_bounds_rect(bounds[bound_name], global)

  return get_bounds_rect(bounds.values()[-1], global)

 return get_bounds_rect(get_innermost_bounds(), global)


func get_innermost_bounds():
 return inner


func generate_overlap_range_data(overlap_range, rng, overlap_override = -1.0):
 var data = {}
 var overlap_rng = RNG.new()
 overlap_rng.reseed(rng)
 if overlap_override >= 0.0:
  data.overlap = roundi(lerpf(0.0, float(overlap_range.size.x), overlap_override))
 else:
  data.overlap = overlap_rng.randi_range(0, overlap_range.size.x)
 data.threshold = overlap_range.threshold
 data.pos = overlap_range.position.x
 data.size = overlap_range.size.x
 return data


func mirror():
 var left_overlap_indicators = $LeftOverlap.get_children()
 var right_overlap_indicators = $RightOverlap.get_children()

 var sprite_bounds: = get_bounds(null, false)
 var sprite_center: = sprite_bounds.get_center().x

 for indicator in left_overlap_indicators:
  var from_center = indicator.position.x - sprite_center
  indicator.position.x = sprite_center - from_center - indicator.size.x
  $LeftOverlap.remove_child(indicator)

 for indicator in right_overlap_indicators:
  var from_center = indicator.position.x - sprite_center
  indicator.position.x = sprite_center - from_center - indicator.size.x
  $RightOverlap.remove_child(indicator)

 for indicator in left_overlap_indicators:
  $RightOverlap.add_child(indicator)

 for indicator in right_overlap_indicators:
  $LeftOverlap.add_child(indicator)

 $Sprite2D.flip_h = true


func generate_bounds(rng: RNG, force_mirror: = false, overlap_override: float = -1.0, _previous_chunk: BackgroundChunk = null):
 if force_mirror or (can_mirror and rng.randi_range(0, 1) == 0):
  mirror()

 var favor_left = rng.randi_range(0, 1) == 0

 var clamp_rng = RNG.new()
 clamp_rng.reseed(rng)

 var overlap_data = {
  left = {}, 
  right = {}, 
 }

 var to_clamp = null

 for overlap_range in left_overlap.get_children():
  var data = generate_overlap_range_data(overlap_range, rng, overlap_override)
  overlap_data.left[overlap_range.name] = data
  if data.overlap < data.threshold and favor_left:
   to_clamp = overlap_data.right

 for overlap_range in right_overlap.get_children():
  var data = generate_overlap_range_data(overlap_range, rng, overlap_override)
  overlap_data.right[overlap_range.name] = data
  if data.overlap < data.threshold and not favor_left:
   to_clamp = overlap_data.left

 if to_clamp != null:
  for range_name in to_clamp:
   var data = to_clamp[range_name]
   if overlap_override >= 0.0:
    data.overlap = roundi(lerpf(float(data.threshold), float(data.size), overlap_override))
   else:
    data.overlap = clamp_rng.randi_range(data.threshold, data.size)

 for range_name in overlap_data.left:
  var left_data = overlap_data.left[range_name]
  var right_data = overlap_data.right[range_name]

  inner.left = max(inner.left, left_data.pos + left_data.size)
  inner.right = min(inner.right, right_data.pos)

  bounds[range_name] = {
   left = left_data.pos + left_data.overlap, 
   right = (right_data.pos + right_data.size) - right_data.overlap
  }


func get_save_data():
 return {
  bounds = bounds, 
  inner = inner
 }


func load_save_data(save):
 bounds = save.bounds
 inner = save.inner


func _on_child_exiting_tree(node: Node) -> void :
 if node in interrupt_markers:
  interrupt_markers.erase(node)
