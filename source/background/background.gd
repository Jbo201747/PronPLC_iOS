@tool
class_name GameBG extends CanvasLayer

signal almost_stopped_scrolling
signal stopped_scrolling
signal enemy_spawn_triggered

const TOP_WALK_SPEED: = 96.0
const WALK_ACCELERATION: = 96.0 * 2.0
const WALK_DURATION: = 5.0

var scrolling: = false
var finishing_scroll: = false
var scroll_time_remaining: = 0.0
var current_walk_speed: = 0.0
var scroll_destination: = 0.0
var precise_remaining_scroll: float = -1.0
var scrolling_nodes: Array[Node2D] = []
var enemy_spawn_position: Vector2 = Vector2.ZERO

var scroll_base_offset: Vector2 = Vector2.ZERO:
 set(value):
  scroll_base_offset = value
  for bg_layer: GameBGLayer in get_children():
   update_layer_scroll(bg_layer)

var editor_seed = null

@export var size: int = 480
@export var deadzone: int = 32
@export var layers: BGLayers = null
@export_range(0.0, 1.0, 0.05) var overlap_override: float = -1.0:
 set(value):
  overlap_override = value
  editor_reload()
@export var show_patterns: bool = false
@export_tool_button("Reroll Background") var button: = editor_randomize


func _ready():
 if Engine.is_editor_hint() and layers != null:
  editor_randomize()


func play_pattern(id, force = false):
 for bg_layer in get_children():
  if bg_layer.is_queued_for_deletion():
   continue

  bg_layer.play_pattern(id, force)


func initialize_layers():
 for child in get_children():
  child.free()

 for node in scrolling_nodes:
  if not is_instance_valid(node) or node.is_queued_for_deletion():
   continue

  if node.is_in_group("bg_free_offscreen"):
   node.queue_free()

 scrolling_nodes.clear()

 scroll_base_offset = Vector2(0, 0)

 for layer_data in layers.layers:
  var layer_node = GameBGLayer.new()
  layer_node.size = size
  if layer_data.motion_scale == 0:
   layer_node.deadzone = 0
  else:
   layer_node.deadzone = deadzone
  layer_node.layer_data = layer_data
  layer_node.overlap_override = overlap_override
  if layer_data.start_hidden:
   layer_node.visible = false

  layer_node.debug_adding_pattern_labels = Engine.is_editor_hint() and show_patterns

  add_child(layer_node)


func set_layer_visible(layer_index: int, value: bool) -> void :
 get_child(layer_index).visible = value


func reseed(parent_rng):
 for bg_layer in get_children():
  if bg_layer.is_queued_for_deletion():
   continue
  bg_layer.rng.reseed(parent_rng)


func editor_randomize():
 if layers != null:
  layers = ResourceLoader.load(layers.resource_path, "", ResourceLoader.CACHE_MODE_REPLACE)

 initialize_layers()
 editor_seed = randi()
 editor_reload()


func editor_reload():
 var rng = RNG.new()
 rng.seed = editor_seed
 reseed(rng)
 for bg_layer in get_children():
  if bg_layer.is_queued_for_deletion():
   continue
  bg_layer.reset()
  bg_layer.overlap_override = overlap_override

 play_pattern("loop", true)


func calculate_distance_travelled(initial_velocity: float, acceleration: float, time: float) -> float:
 return (initial_velocity * time) + (0.5 * acceleration * (time ** 2))


func get_scroll_accel_distance() -> float:
 return calculate_distance_travelled(0.0, WALK_ACCELERATION, TOP_WALK_SPEED / WALK_ACCELERATION)


func get_scroll_decel_distance() -> float:
 return calculate_distance_travelled(TOP_WALK_SPEED, - WALK_ACCELERATION, TOP_WALK_SPEED / WALK_ACCELERATION)


func get_walk_duration_for_target_distance(target_distance: float) -> float:
 var minimum_distance = get_scroll_accel_distance() + get_scroll_decel_distance()
 target_distance -= minimum_distance
 if target_distance <= 0.0:
  return 0.0
 else:
  return target_distance / TOP_WALK_SPEED


func calculate_scroll_destination() -> float:
 return get_scroll_accel_distance() + get_scroll_decel_distance() + TOP_WALK_SPEED * WALK_DURATION


func start_scrolling(for_duration: float = WALK_DURATION):
 precise_remaining_scroll = -1.0
 current_walk_speed = 0.0
 scroll_time_remaining = for_duration
 scrolling = true
 finishing_scroll = false
 scroll_destination = calculate_scroll_destination()


func trigger_enemy_spawn(spawn_pos: Vector2):
 enemy_spawn_position = spawn_pos
 enemy_spawn_triggered.emit()


func interrupt_scrolling(use_deceleration: bool = false, remaining_distance: float = -1.0) -> void :
 if not scrolling:
  return

 if use_deceleration:
  if remaining_distance != -1.0:
   precise_remaining_scroll = remaining_distance

  finishing_scroll = true
  almost_stopped_scrolling.emit()
 else:
  if remaining_distance != -1.0:
   scroll(remaining_distance)

  scrolling = false
  almost_stopped_scrolling.emit()
  stopped_scrolling.emit()


func add_scrolling_node(node: Node2D):
 scrolling_nodes.append(node)


func remove_scrolling_node(node: Node2D):
 scrolling_nodes.erase(node)


func _physics_process(delta: float) -> void :
 if scrolling:
  if finishing_scroll:
   current_walk_speed -= WALK_ACCELERATION * delta
  else:
   current_walk_speed += WALK_ACCELERATION * delta

  current_walk_speed = clampf(current_walk_speed, 0.0, TOP_WALK_SPEED)

  var altered_scroll: bool = false
  if precise_remaining_scroll > 0.0:
   var next_walk_distance = current_walk_speed * delta
   if next_walk_distance > precise_remaining_scroll or current_walk_speed <= 0.0:
    altered_scroll = true
    current_walk_speed = precise_remaining_scroll / delta

  if current_walk_speed >= TOP_WALK_SPEED and not finishing_scroll:
   scroll_time_remaining -= delta
   if scroll_time_remaining <= 0.0:
    finishing_scroll = true
    almost_stopped_scrolling.emit()
  elif finishing_scroll and current_walk_speed <= 0.0:
   scrolling = false
   stopped_scrolling.emit()
   precise_remaining_scroll = -1.0
   return

  if precise_remaining_scroll > 0.0:
   precise_remaining_scroll -= current_walk_speed * delta

  scroll(current_walk_speed * delta)

  if altered_scroll:
   current_walk_speed = 0.0


func scroll(distance: float) -> void :
 scroll_base_offset -= Vector2(distance, 0.0)

 for i in range(scrolling_nodes.size() - 1, -1, -1):
  var node = scrolling_nodes[i]
  if not is_instance_valid(node) or node.is_queued_for_deletion():
   scrolling_nodes.remove_at(i)
   continue

  if node.is_in_group("bg_scroll_child"):
   continue

  node.position.x -= distance
  if node.is_in_group("bg_free_offscreen") and not node.is_queued_for_deletion():
   if node is Sprite2D:
    var rect = node.get_rect()
    rect.position = node.to_global(rect.position)
    if rect.end.x < - deadzone:
     node.queue_free()
     scrolling_nodes.remove_at(i)


func update_layer_scroll(bg_layer: GameBGLayer) -> void :
 if bg_layer.layer_data.is_static:
  return

 bg_layer.scroll_offset = (scroll_base_offset * bg_layer.scroll_scale) + bg_layer.motion_offset


func _process(delta: float) -> void :
 if Engine.is_editor_hint():
  return

 for bg_layer: GameBGLayer in get_children():
  if bg_layer.is_queued_for_deletion():
   continue

  var velocity = bg_layer.layer_data.x_velocity
  if velocity != 0:
   bg_layer.motion_offset.x += velocity * delta
   update_layer_scroll(bg_layer)


func get_act_background(act_id: int) -> BGLayers:
 if act_id == 0:
  return preload("res://data/backgrounds/act_1/background.tres")
 elif act_id == 1:
  return preload("res://data/backgrounds/act_2/background.tres")
 else:
  return preload("res://data/backgrounds/act_3/background.tres")


func set_background_for_act(act_id: int) -> void :
 var background_data: = get_act_background(act_id)
 if layers != background_data:
  layers = background_data


func get_save_data():
 var save = {
  scroll = scroll_base_offset, 
  layers = [], 
  scrolling_nodes = [], 
 }

 for i in range(scrolling_nodes.size() - 1, -1, -1):
  var node: Node2D = scrolling_nodes[i]
  if not is_instance_valid(node) or node.is_queued_for_deletion():
   scrolling_nodes.remove_at(i)
   continue

  if node is Sprite2D and not node.is_in_group("bg_scroll_no_save"):
   var node_data = {
    name = node.name, 
    position = node.position, 
    parent = get_path_to(node.get_parent()), 
    texture = node.texture.resource_path, 
    hv_frames = Vector2i(node.hframes, node.vframes), 
    frame = node.frame, 
    modulate = node.modulate, 
    visible = node.visible, 
    z_index = node.z_index, 
    offset = node.offset, 
    centered = node.centered, 
    free_offscreen = node.is_in_group("bg_free_offscreen"), 
    scroll_child = node.is_in_group("bg_scroll_child"), 
   }
   save.scrolling_nodes.append(node_data)

 for bg_layer in get_children():
  save.layers.append(bg_layer.get_save_data())

 return save


func load_save_data(save):
 var layer_index = 0
 for bg_layer in get_children():
  bg_layer.load_save_data(save.layers[layer_index])
  layer_index += 1

 scroll_base_offset = save.scroll

 if "scrolling_nodes" in save:
  for node_data in save.scrolling_nodes:
   var parent: = get_node_or_null(node_data.parent)
   if parent == null:
    push_error("Was unable to respawn background object, could not find parent. ", node_data)
    continue

   var sprite: = Sprite2D.new()
   sprite.name = node_data.name
   sprite.texture = load(node_data.texture)
   sprite.hframes = node_data.hv_frames.x
   sprite.vframes = node_data.hv_frames.y
   sprite.frame = node_data.frame
   sprite.offset = node_data.offset
   sprite.centered = node_data.centered
   sprite.modulate = node_data.modulate
   sprite.visible = node_data.visible
   sprite.z_index = node_data.z_index
   parent.add_child(sprite)
   sprite.position = node_data.position
   if node_data.free_offscreen:
    sprite.add_to_group("bg_free_offscreen")

   if node_data.scroll_child:
    sprite.add_to_group("bg_scroll_child")

   scrolling_nodes.append(sprite)
