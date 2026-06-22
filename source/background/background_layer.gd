@tool
class_name GameBGLayer extends Parallax2D

var deadzone = 32
var size = 480
var queued_pattern = null
var active_pattern = []
var last_step_terminates: = true
var active_chunks: Array[Node2D] = []
var entry_delays: Dictionary[String, int] = {}
var overlap_override = -1.0
var prior_transform = null
var motion_offset: Vector2 = Vector2.ZERO
var empty_distance: int = 0
var force_generate_chunks: int = 0
var rng = RNG.new()

var debug_adding_pattern_labels: bool = false
var debug_add_pattern_labels: Array[String] = []

@export var layer_data: BGLayer:
 set(value):
  layer_data = value
  z_index = layer_data.z_index
  scroll_scale = Vector2(layer_data.motion_scale, layer_data.motion_scale)
  deadzone += layer_data.extra_deadzone
  if layer_data.motion_scale_y > -1.0:
   scroll_scale.y = layer_data.motion_scale_y

  if Engine.is_editor_hint() and is_node_ready():
   editor_reload()
@export_tool_button("Reroll Layer") var button = editor_reload


func _ready():
 follow_viewport = false
 reset()

 if Engine.is_editor_hint():
  editor_reload()


func reset():
 for chunk in active_chunks:
  chunk.queue_free()

 queued_pattern = null
 active_pattern = []
 active_chunks = []
 entry_delays.clear()


func do_editor_preview():
 reset()
 play_pattern("loop", true)


func editor_reload():
 do_editor_preview()


func get_pattern_steps_data(pattern: BGPattern, random_start = false, random_end = false):
 if pattern.steps.size() == 0:
  return []

 var starting_index = 0
 if random_start:
  starting_index = rng.randi_range(0, pattern.steps.size() - 1)

 var ending_index = pattern.steps.size()
 if random_end:
  ending_index = rng.randi_range(starting_index + 1, ending_index)

 var steps = []
 for i in range(starting_index, ending_index):
  var step = pattern.steps[i]
  var repeat_index = rng.rand_weighted(step.repeat_count.values())
  var repeat = step.repeat_count.keys()[repeat_index]
  if repeat == 0:
   continue

  var step_data = {
   pattern = pattern.id, 
   index = i, 
   step = step, 
   repeat = repeat, 
   initial = true, 
  }

  steps.append(step_data)

 if pattern.next != "":
  steps.append({pattern = pattern.id, next = pattern.next})

 return steps


func play_pattern(id, force = false, fill = true):
 var pattern: = layer_data.get_pattern(id)
 if pattern == null:
  return

 force_generate_chunks += pattern.force_generate_chunks

 var steps = get_pattern_steps_data(pattern, active_chunks.is_empty() and layer_data.randomize_start)
 if steps.is_empty():
  return

 if force or last_step_terminates:
  active_pattern = []

 var termination_point = active_pattern.find_custom( func(value): return "step" in value and value.step.can_terminate_pattern)
 if termination_point != -1:
  active_pattern.resize(termination_point + 1)

 if termination_point != -1 or active_pattern.is_empty():
  active_pattern.append_array(steps)
 else:
  queued_pattern = id

 if fill:
  fill_chunks()


func prepend_pattern(id: String, random_start: = false, random_end: = false):
 var pattern: = layer_data.get_pattern(id)
 if pattern == null:
  return

 force_generate_chunks += pattern.force_generate_chunks

 var steps = get_pattern_steps_data(pattern, random_start, random_end)
 if steps.is_empty():
  return

 var active_pattern_copy = active_pattern.duplicate()
 active_pattern = steps
 active_pattern.append_array(active_pattern_copy)


func get_next_chunk() -> BGPlaceableEntry:
 if active_pattern.size() == 0:
  return null

 var step_data = active_pattern[0]
 if "next" in step_data:
  active_pattern.remove_at(0)
  prepend_pattern(step_data.next)
  return get_next_chunk()

 var step: BGPatternStep = step_data.step

 last_step_terminates = step.can_terminate_pattern

 var is_first_repeat = "initial" in step_data
 if is_first_repeat:
  step_data.erase("initial")

 if step.can_terminate_pattern and queued_pattern != null:
  step_data.repeat = 1

 step_data.repeat -= 1

 if step_data.repeat == 0:
  if step.can_terminate_pattern and queued_pattern != null:
   play_pattern(queued_pattern, true, false)
   queued_pattern = null
  else:
   active_pattern.remove_at(0)

 var entry: = step.pick_entry(rng, layer_data, entry_delays)
 if entry is BGSubpatternEntry:
  if debug_adding_pattern_labels:
   debug_add_pattern_labels.append(entry.id)

  var randomize_start = entry.randomize_start_and_end and is_first_repeat
  var randomize_end = entry.randomize_start_and_end and step_data.repeat == 0
  prepend_pattern(entry.id, randomize_start, randomize_end)
 elif entry is BGPlaceableEntry:
  return entry

 return get_next_chunk()


func get_chunk_global_bounds(chunk) -> Rect2:
 var bounds = chunk.get_bounds()
 var bounds_global_pos = chunk.to_global(bounds.position)
 return Rect2(bounds_global_pos, bounds.size)


func get_last_chunk_bounds() -> Rect2:
 if active_chunks.size() > 0:
  return active_chunks[-1].get_bounds(null, true)
 else:
  return Rect2( - deadzone, 0, 0, 0)


func place_chunk(entry: BGChunkEntry) -> void :
 var new_chunk_scene = entry.chunk
 var new_chunk = new_chunk_scene.instantiate()
 add_child(new_chunk)
 new_chunk.position.y = layer_data.y_offset + 135

 var chunk_rng = RNG.new()
 chunk_rng.reseed(rng)

 var previous_chunk: BackgroundChunk = null
 if active_chunks.size() > 0:
  previous_chunk = active_chunks[-1]

 new_chunk.generate_bounds(chunk_rng, entry.mirrored, overlap_override, previous_chunk)

 var bounds = new_chunk.get_bounds(previous_chunk)
 if previous_chunk != null:
  new_chunk.global_position.x = previous_chunk.get_bounds(new_chunk, true).end.x + empty_distance
 else:
  new_chunk.position.x = - deadzone + layer_data.start_x_offset
  if layer_data.motion_scale > 0.0 and layer_data.randomize_start:
   new_chunk.position.x -= rng.randi_range(0, bounds.size.x)


 new_chunk.position.x -= bounds.position.x

 if debug_adding_pattern_labels and not debug_add_pattern_labels.is_empty():
  var y_offset = 0
  for id in debug_add_pattern_labels:
   var label: = Label.new()
   label.text = id
   label.position.y = y_offset
   label.z_index = 100
   y_offset += 12
   new_chunk.add_child(label)

  debug_add_pattern_labels.clear()

 active_chunks.append(new_chunk)


func get_border_x() -> int:
 if scroll_scale == Vector2.ZERO or layer_data.is_static:
  return size
 else:
  return size + deadzone


func last_bounds_needs_continuation(last_bounds: Rect2) -> bool:
 var border_x: = get_border_x()
 return (last_bounds.end.x + empty_distance) < border_x


func fill_chunks():
 if active_pattern.is_empty():
  return

 if active_chunks.size() > 0:
  for i in range(active_chunks.size() - 1, -1, -1):
   var chunk = active_chunks[i]
   if get_chunk_global_bounds(chunk).end.x < - deadzone:
    chunk.queue_free()
    active_chunks.remove_at(i)


 var last_bounds: Rect2 = get_last_chunk_bounds()
 var last_x = -100
 var stuck_chunks = 0
 while last_bounds_needs_continuation(last_bounds) or force_generate_chunks > 0:
  if force_generate_chunks > 0:
   force_generate_chunks -= 1

  if last_bounds.position.x <= last_x:
   stuck_chunks += 1
   if stuck_chunks > 50:
    push_error("Got stuck in a loop adding bg chunks")
    return
  else:
   last_x = last_bounds.position.x

  var next_chunk: = get_next_chunk()
  if next_chunk == null:
   push_error("Couldn't get next chunk for bg layer")
   return

  if next_chunk is BGEmptyEntry:
   empty_distance += rng.randi_range(next_chunk.minimum_distance, next_chunk.maximum_distance)
  elif next_chunk is BGChunkEntry:
   place_chunk(next_chunk)
   empty_distance = 0

  last_bounds = get_last_chunk_bounds()

 for chunk in active_chunks:
  for interrupt_marker in chunk.interrupt_markers:
   if is_instance_valid(interrupt_marker) and not interrupt_marker.is_queued_for_deletion():
    interrupt_marker.update(get_parent())


func _process(_delta) -> void :
 if Engine.is_editor_hint():
  return

 var new_transform = get_global_transform()
 if new_transform != prior_transform:
  prior_transform = new_transform
  fill_chunks()


func get_save_data():
 var save = {
  entry_delays = entry_delays, 
  motion_offset = motion_offset, 
  rng = rng.get_save_data(), 
  queued_pattern = queued_pattern, 
  active_chunks = [], 
  active_pattern = [], 
  empty_distance = empty_distance, 
  last_step_terminates = last_step_terminates, 
 }

 for step_data in active_pattern:
  var duplicated = step_data.duplicate()
  if "step" in step_data:
   duplicated.erase("step")

  save.active_pattern.append(duplicated)

 for chunk in active_chunks:
  save.active_chunks.append({
   file = chunk.scene_file_path, 
   save = chunk.get_save_data(), 
   position = chunk.position, 
  })

 return save


func load_save_data(save):
 reset()

 queued_pattern = save.queued_pattern
 entry_delays = save.entry_delays
 motion_offset = save.motion_offset
 last_step_terminates = save.last_step_terminates
 empty_distance = save.get("empty_distance", 0)
 rng.load_save_data(save.rng)

 for step_data in save.active_pattern:
  var pattern = layer_data.get_pattern(step_data.pattern)
  if "index" in step_data:
   var step = pattern.steps[step_data.index]
   step_data.step = step
  active_pattern.append(step_data)

 for chunk in save.active_chunks:
  var chunk_packed = load(chunk.file)
  var inst = chunk_packed.instantiate()
  add_child(inst)
  active_chunks.append(inst)
  inst.position = chunk.position
  inst.load_save_data(chunk.save)
