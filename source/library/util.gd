class_name Util


static var _mobile_browser_cache: Variant = null
static var _last_mobile_tap_msec: int = -1000000


static func is_mobile() -> bool:
 return (
  OS.has_feature("mobile")
  or OS.has_feature("ios")
  or OS.has_feature("android")
  or OS.get_name() == "iOS"
  or OS.get_name() == "Android"
 )


static func is_mobile_tap(event: InputEvent, dedupe_ms: int = 150) -> bool:
 if not is_mobile():
  return false

 var is_tap: bool = (
  (event is InputEventScreenTouch and event.pressed)
  or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
 )
 if not is_tap:
  return false

 var now: int = Time.get_ticks_msec()
 if now - _last_mobile_tap_msec < dedupe_ms:
  return false

 _last_mobile_tap_msec = now
 return true


static func is_mobile_browser() -> bool:
 if not OS.has_feature("web"):
  return false
 if _mobile_browser_cache != null:
  return _mobile_browser_cache

 var is_mobile: bool = false
 if typeof(JavaScriptBridge) != TYPE_NIL:
  var result: Variant = JavaScriptBridge.eval("typeof navigator !== 'undefined' && /iPhone|iPad|iPod|Android/i.test(navigator.userAgent)", true)
  if result is bool:
   is_mobile = result

 _mobile_browser_cache = is_mobile
 return is_mobile


static func find_first_node_in_parents(node: Node, path: NodePath) -> Node:
 var parent: = node.get_parent()
 if parent == null:
  return null
 else:
  var found_node: = parent.get_node_or_null(path)
  if found_node != null:
   return found_node
  else:
   return find_first_node_in_parents(parent, path)


static func reduce_multidimensional_array(array: Array) -> Array:
 var out: Array = []
 for value: Variant in array:
  if value is Array:
   out.append_array(reduce_multidimensional_array(value))
  else:
   out.append(value)

 return out


static func copy(value: Variant, deep: bool = false) -> Variant:
 if value is Dictionary:
  return value.duplicate(deep)
 elif value is Array:
  return value.duplicate(deep)

 return value


static func deep_default(dictionary: Dictionary, defaults: Dictionary) -> void :
 for key in defaults:
  var default_value = defaults[key]
  if key in dictionary:
   if default_value is Dictionary:
    if dictionary[key] is not Dictionary:
     dictionary[key] = {}

    deep_default(dictionary[key], default_value)
  elif default_value is Array:
   dictionary[key] = default_value.duplicate()
  elif default_value is Dictionary:
   dictionary[key] = {}
   deep_default(dictionary[key], default_value)
  else:
   dictionary[key] = default_value


static func deep_merge(base_dictionary: Dictionary, merge_dictionary: Dictionary, overwrite: bool = true) -> Dictionary:
 var out_dictionary: Dictionary = {}
 for key in base_dictionary:
  var value: Variant = base_dictionary[key]
  if key in merge_dictionary:
   if value is Dictionary and merge_dictionary[key] is Dictionary:
    out_dictionary[key] = deep_merge(value, merge_dictionary[key])
   elif overwrite:
    out_dictionary[key] = copy(merge_dictionary[key], true)
   else:
    out_dictionary[key] = copy(value, true)
  else:
   out_dictionary[key] = copy(value, true)

 for key in merge_dictionary:
  if key not in out_dictionary:
   out_dictionary[key] = copy(merge_dictionary[key], true)

 return out_dictionary


static func sum_dictionaries(dictionary_a: Dictionary, dictionary_b: Dictionary, in_place: bool = false) -> Dictionary:
 var merge_to: Dictionary = dictionary_a
 if not in_place:
  merge_to = {}

 for key in dictionary_a:
  var value: Variant = dictionary_a[key]
  if key not in dictionary_b:
   merge_to[key] = value
   continue

  if value is int or value is float:
   merge_to[key] = value + dictionary_b[key]
  elif value is bool:
   merge_to[key] = value or dictionary_b[key]

 return merge_to


static func deep_accumulate(base_dictionary: Dictionary, path: Array, accumulate_into: Dictionary) -> void :
 if path.is_empty():
  Util.sum_dictionaries(accumulate_into, base_dictionary, true)
  return

 var current_index: Variant = path[0]
 if current_index == "*":
  for key in base_dictionary:
   if base_dictionary[key] is Dictionary:
    deep_accumulate(base_dictionary[key], path.slice(1), accumulate_into)
 elif current_index in base_dictionary:
  deep_accumulate(base_dictionary[current_index], path.slice(1), accumulate_into)


static func get_deep_accumulated(base_dictionary: Dictionary, path: Array, accumulated_defaults: Dictionary) -> Dictionary:
 var accumulate_into: = accumulated_defaults.duplicate()
 deep_accumulate(base_dictionary, path, accumulate_into)
 return accumulate_into


static func get_file_paths_recursive(directory_path: String, extension: String = "") -> PackedStringArray:
 var file_paths: PackedStringArray = PackedStringArray()
 var dir: DirAccess = DirAccess.open(directory_path)
 if dir != null:
  dir.list_dir_begin()
  var file_name: String = dir.get_next()
  while file_name != "":
   if file_name in [".", ".."]:
    file_name = dir.get_next()
    continue

   if dir.current_is_dir():
    file_paths.append_array(get_file_paths_recursive(directory_path.path_join(file_name), extension))
   elif extension == "" or file_name.ends_with(extension):
    file_paths.append(directory_path.path_join(file_name))

   file_name = dir.get_next()
  dir.list_dir_end()
  return file_paths

 if directory_path.begins_with("res://"):
  for entry in ResourceLoader.list_directory(directory_path):
   if entry in [".", ".."]:
    continue

   var full_path: String = directory_path.path_join(entry)
   if DirAccess.dir_exists_absolute(full_path):
    file_paths.append_array(get_file_paths_recursive(full_path, extension))
   elif extension == "" or entry.ends_with(extension):
    if FileAccess.file_exists(full_path) or ResourceLoader.exists(full_path):
     file_paths.append(full_path)

 return file_paths


static func copy_files_recursive(directory_a: String, directory_b: String) -> void :
 var file_paths: = get_file_paths_recursive(directory_a)
 for path in file_paths:
  var trimmed_path: = path.trim_prefix(directory_a)
  var target_path: String = directory_b + "/" + trimmed_path
  var target_directory: String = target_path.get_base_dir()
  if not DirAccess.dir_exists_absolute(target_directory):
   DirAccess.make_dir_recursive_absolute(target_directory)

  DirAccess.copy_absolute(path, target_path)


static func remove_directory_recursive(directory: String) -> void :
 for dir in DirAccess.get_directories_at(directory):
  remove_directory_recursive(directory.path_join(dir))

 for file in DirAccess.get_files_at(directory):
  DirAccess.remove_absolute(directory.path_join(file))

 DirAccess.remove_absolute(directory)


static func regex(string: String) -> RegEx:
 var new_regex: = RegEx.new()
 new_regex.compile(string)
 return new_regex


static func shrink_label_to_bounds(label: Label, bounds: float, base_font_size: int = -1) -> void :
 var font: Font = label.get_theme_font(&"font")
 var active_font_size = label.get_theme_font_size("font_size")
 if base_font_size == -1:
  base_font_size = active_font_size
 var font_size: int = base_font_size

 var line = TextLine.new()
 line.direction = label.text_direction
 line.flags = label.justification_flags
 line.alignment = label.horizontal_alignment

 while font_size > 1:
  line.clear()
  line.add_string(label.text, font, font_size)
  if line.get_line_width() <= bounds:
   break
  else:
   font_size -= 1

 if font_size != active_font_size:
  label.add_theme_font_size_override(&"font_size", font_size)


static func strip_bbcode(string: String) -> String:
 return regex("\\[.+?\\]").sub(string, "", true)


static func type_text(label: Control, delay: float = 0.08, rate: int = 1, num_characters: int = -1, callback: = Callable()) -> void :
 var playback: = TypeTextPlayback.new()
 playback.play(label, delay, rate, num_characters, callback)
 await playback.finished


static func type_text_cancelable(label: Control, delay: float = 0.08, rate: int = 1, num_characters: int = -1, callback: = Callable(), complete_on_cancel: bool = false, control_string: String = "") -> TypeTextPlayback:
 var playback: = TypeTextPlayback.new()
 playback.play(label, delay, rate, num_characters, callback, complete_on_cancel, control_string)
 return playback


class TypeTextPlayback extends RefCounted:
 signal finished

 var valid: bool = true
 var is_finished: bool = false
 var is_canceled: bool = false
 var timer: CancelableTimeout


 func get_character_delay(character: String, default_delay: float, comma_delay: float, period_delay: float) -> float:
  if character == ",":
   return comma_delay
  elif character in [".", "!", "?"]:
   return period_delay

  return default_delay


 func play(label: Control, delay: float = 0.08, rate: int = 1, num_characters: int = -1, callback: = Callable(), complete_on_cancel: bool = false, control_string: String = "", comma_delay: float = 0.16, period_delay: float = 0.16) -> void :
  var custom_num_characters: = num_characters != -1
  if num_characters == -1:
   if label is RichTextLabel:
    num_characters = label.get_total_character_count()
   else:
    num_characters = len(label.text)

  if control_string == "":
   if label is RichTextLabel:
    control_string = label.get_parsed_text()
   elif label is Label:
    control_string = label.text
  else:
   if label is RichTextLabel:
    var label_text: String = label.text
    label.text = control_string
    control_string = label.get_parsed_text()
    label.text = label_text

   if not custom_num_characters:
    num_characters = len(control_string)

  var total_text_length: int = len(control_string)

  var remaining_characters: int = num_characters
  for i in num_characters:
   label.visible_characters += rate

   if callback.is_valid():
    callback.call(self)

   var use_delay: float = delay
   if rate == 1:
    var previous_character: String = "" if label.visible_characters - 2 < 0 else control_string[label.visible_characters - 2]
    var current_character: String = control_string[label.visible_characters - 1]
    var next_character: String = "" if label.visible_characters >= total_text_length else control_string[label.visible_characters]

    if current_character in ["\"", "”"]:
     use_delay = get_character_delay(previous_character, delay, comma_delay, period_delay)
    elif next_character not in ["\"", "”"]:
     use_delay = get_character_delay(current_character, delay, comma_delay, period_delay)

   remaining_characters -= 1
   timer = CancelableTimeout.new(label.get_tree(), use_delay)
   await timer.cancel_or_timeout
   if is_canceled or not is_instance_valid(label) or label.is_queued_for_deletion() or not label.is_inside_tree():
    break

  if complete_on_cancel and is_canceled:
   label.visible_characters += remaining_characters * rate

  is_finished = true
  valid = false
  finished.emit()


 func cancel() -> void :
  valid = false
  is_canceled = true
  if timer:
   timer.cancel()


static func point_in_collision_object(collision_object: CollisionObject2D, point: Vector2) -> bool:
 collision_object.set_collision_layer_value(32, true)
 var query: = PhysicsPointQueryParameters2D.new()
 query.position = point
 query.collision_mask = collision_object.collision_layer
 query.collision_mask = 2147483648
 query.collide_with_areas = collision_object is Area2D
 query.collide_with_bodies = collision_object is PhysicsBody2D

 var canvas_layer: = collision_object.get_canvas_layer_node()
 if canvas_layer != null:
  query.canvas_instance_id = canvas_layer.get_instance_id()

 var space_state: = collision_object.get_world_2d().direct_space_state
 var query_result: = space_state.intersect_point(query, 1)
 var intersects: = not query_result.is_empty()
 collision_object.set_collision_layer_value(32, false)

 return intersects


static func get_collision_object_rect(collision_object: CollisionObject2D) -> Rect2:
 var rect_initialized: = false
 var rect: = Rect2()
 for owner_id in collision_object.get_shape_owners():
  var owner: = collision_object.shape_owner_get_owner(owner_id)
  if owner is CollisionShape2D:
   if owner.disabled:
    continue

  var owner_transform: = (collision_object.global_transform * collision_object.shape_owner_get_transform(owner_id)).affine_inverse()
  for shape_id in collision_object.shape_owner_get_shape_count(owner_id):
   var shape: = collision_object.shape_owner_get_shape(owner_id, shape_id)
   var shape_rect: = shape.get_rect() * owner_transform
   if not rect_initialized:
    rect_initialized = true
    rect = shape_rect
   else:
    rect = rect.merge(shape_rect)

 return rect


static func get_collision_object_shape_centers(collision_object: CollisionObject2D) -> Array[Vector2]:
 var centers: Array[Vector2] = []
 for owner_id in collision_object.get_shape_owners():
  var owner: = collision_object.shape_owner_get_owner(owner_id)
  if owner is CollisionShape2D:
   if owner.disabled:
    continue

  var owner_transform: = (collision_object.global_transform * collision_object.shape_owner_get_transform(owner_id)).affine_inverse()
  for shape_id in collision_object.shape_owner_get_shape_count(owner_id):
   var shape: = collision_object.shape_owner_get_shape(owner_id, shape_id)
   centers.append(shape.get_rect().get_center() * owner_transform)

 return centers


static func random_point_in_collision_object(collision_object: CollisionObject2D, rng: RNG, max_iterations: = 20) -> Vector2:
 var rect: = get_collision_object_rect(collision_object)

 for i in max_iterations:
  var point: = rng.random_in_rect(rect)
  if point_in_collision_object(collision_object, point):
   return point

 var centers: = get_collision_object_shape_centers(collision_object)
 if centers.is_empty():
  return collision_object.global_position
 else:
  return rng.pick_random(centers)


static func organize_weight_table(weights: Dictionary, minimum_weight: float = 0.0, snap: float = 0.001) -> Dictionary[Variant, float]:
 var total: float = 0.0
 for key in weights:
  total += weights[key]

 var included_keys: Array = []
 var included_total: float = 0.0
 for key in weights:
  var normalized_weight: = float(weights[key]) / total * 100.0
  if normalized_weight > minimum_weight:
   included_total += weights[key]
   included_keys.append(key)

 included_keys.sort_custom( func(a, b): return weights[a] < weights[b])

 var sorted_weights: Dictionary[Variant, float] = {}
 for key in included_keys:
  var normalized_weight: = float(weights[key]) / included_total * 100.0
  normalized_weight = snappedf(normalized_weight, snap)
  sorted_weights[key] = normalized_weight

 return sorted_weights


static func can_grab_focus(control: Control) -> bool:
 if control.has_method(&"can_grab_focus"):
  return control.can_grab_focus()
 elif not control.is_visible_in_tree():
  return false
 else:
  var focus_mode: = control.get_focus_mode_with_override()
  return focus_mode != Control.FOCUS_NONE and focus_mode != Control.FOCUS_ACCESSIBILITY


static func has_focus(control: Control, ignore_hidden_focus: bool = false) -> bool:
 if control.has_focus(ignore_hidden_focus):
  return true
 elif control.has_method(&"get_focus_controls"):
  var sub_controls: Array[Control] = control.get_focus_controls()
  for sub_control in sub_controls:
   if has_focus(sub_control, ignore_hidden_focus):
    return true

 return false


static func set_focus_neighbor(control: Control, side: Side, neighbor: Control, only_if_default: = false) -> void :
 if not only_if_default or control.get_focus_neighbor(side) == NodePath(""):
  control.set_focus_neighbor(side, control.get_path_to(neighbor))

 if control.has_method(&"get_focus_controls"):
  var sub_controls: Array[Control] = control.get_focus_controls()
  for sub_control in sub_controls:
   set_focus_neighbor(sub_control, side, neighbor, only_if_default)


static func set_focus_previous(control: Control, neighbor: Control, only_if_default: = false) -> void :
 if not only_if_default or control.focus_previous == NodePath(""):
  control.set_focus_previous(control.get_path_to(neighbor))

 if control.has_method(&"get_focus_controls"):
  var sub_controls: Array[Control] = control.get_focus_controls()
  for sub_control in sub_controls:
   set_focus_previous(sub_control, neighbor)


static func set_focus_next(control: Control, neighbor: Control, only_if_default: = false) -> void :
 if not only_if_default or control.focus_next == NodePath(""):
  control.set_focus_next(control.get_path_to(neighbor))

 if control.has_method(&"get_focus_controls"):
  var sub_controls: Array[Control] = control.get_focus_controls()
  for sub_control in sub_controls:
   set_focus_next(sub_control, neighbor)


static func disable_focus_for_controls(controls: Array[Control], only_if_default: = false, do_previous_next: = true, sides: Array[Side] = [SIDE_TOP, SIDE_BOTTOM, SIDE_LEFT, SIDE_RIGHT]) -> void :
 for control in controls:
  if do_previous_next:
   set_focus_previous(control, control, only_if_default)
   set_focus_next(control, control, only_if_default)

  for side in sides:
   set_focus_neighbor(control, side, control, only_if_default)


static func set_all_focus(control: Control, focus_on: Control) -> void :
 set_focus_previous(control, focus_on)
 set_focus_next(control, focus_on)
 for side in [SIDE_TOP, SIDE_BOTTOM, SIDE_LEFT, SIDE_RIGHT]:
  set_focus_neighbor(control, side, focus_on)


static func substitute_control_focus(old_control: Control, new_control: Control) -> void :
 if old_control.focus_previous == NodePath("."):
  set_focus_previous(new_control, new_control)
 else:
  set_focus_previous(new_control, old_control.get_node(old_control.focus_previous))

 if old_control.focus_next == NodePath("."):
  set_focus_next(new_control, new_control)
 else:
  set_focus_next(new_control, old_control.get_node(old_control.focus_next))

 for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
  var old_neighbor: = old_control.get_focus_neighbor(side)
  if old_neighbor == NodePath("."):
   set_focus_neighbor(new_control, side, new_control)
  else:
   set_focus_neighbor(new_control, side, old_control.get_node(old_neighbor))


static func set_control_focus_sequence(controls: Array[Control], vertical: = false, no_previous_next: = false) -> void :
 var prev_side: Side
 var next_side: Side
 if vertical:
  prev_side = SIDE_TOP
  next_side = SIDE_BOTTOM
 else:
  prev_side = SIDE_LEFT
  next_side = SIDE_RIGHT

 var visible_controls: Array[Control] = []
 for control in controls:
  if control.is_visible_in_tree():
   visible_controls.append(control)

 var num_controls: = visible_controls.size()
 for i in num_controls:
  var control: = visible_controls[i]
  var prev_control: = visible_controls[posmod(i - 1, num_controls)]
  var next_control: = visible_controls[posmod(i + 1, num_controls)]
  set_focus_neighbor(control, prev_side, prev_control)
  set_focus_neighbor(control, next_side, next_control)

  if not no_previous_next:
   set_focus_previous(control, prev_control)
   set_focus_next(control, prev_control)


static func set_control_grid_focus(controls: Array[Array], vertical: = true, centered: = true) -> void :
 var prev_in_layer: Side
 var next_in_layer: Side
 var prev_layer: Side
 var next_layer: Side
 if vertical:
  prev_in_layer = SIDE_LEFT
  next_in_layer = SIDE_RIGHT
  prev_layer = SIDE_TOP
  next_layer = SIDE_BOTTOM
 else:
  prev_in_layer = SIDE_TOP
  next_in_layer = SIDE_BOTTOM
  prev_layer = SIDE_LEFT
  next_layer = SIDE_RIGHT

 var all_controls: Array[Control] = []
 for layer in controls:
  for control in layer:
   all_controls.append(control)

 var num_controls_overall: = all_controls.size()

 var num_layers: = controls.size()
 for i in num_layers:
  var layer: = controls[i]
  var num_controls: = layer.size()

  var prev_layer_list: Array = controls[posmod(i - 1, num_layers)]
  var prev_layer_size: = prev_layer_list.size()

  var next_layer_list: Array = controls[posmod(i + 1, num_layers)]
  var next_layer_size: = next_layer_list.size()

  for j in num_controls:
   var control: Control = layer[j]
   var prev_control: Control = layer[posmod(j - 1, num_controls)]
   var next_control: Control = layer[posmod(j + 1, num_controls)]
   set_focus_neighbor(control, prev_in_layer, prev_control)
   set_focus_neighbor(control, next_in_layer, next_control)

   var prev_layer_control: Control = prev_layer_list[posmod(j, prev_layer_size)]
   if prev_layer_size < num_controls:
    prev_layer_control = prev_layer_list[mini(j, prev_layer_size - 1)]
   elif prev_layer_size > num_controls and centered:
    prev_layer_control = prev_layer_list[floori(prev_layer_size / 2.0)]

   set_focus_neighbor(control, prev_layer, prev_layer_control)

   var next_layer_control: Control = next_layer_list[posmod(j, next_layer_size)]
   if next_layer_size < num_controls:
    next_layer_control = next_layer_list[mini(j, next_layer_size - 1)]
   elif prev_layer_size > num_controls and centered:
    next_layer_control = next_layer_list[floori(next_layer_size / 2.0)]

   set_focus_neighbor(control, next_layer, next_layer_control)

   var control_overall_index: = all_controls.find(control)
   var prev_control_overall: Control = all_controls[posmod(control_overall_index - 1, num_controls_overall)]
   set_focus_previous(control, prev_control_overall)

   var next_control_overall: Control = all_controls[posmod(control_overall_index + 1, num_controls_overall)]
   set_focus_next(control, next_control_overall)


static func get_parent_in_group(node: Node, group: StringName) -> Node:
 var parent: = node.get_parent()
 while parent != null and not parent.is_in_group(group):
  parent = parent.get_parent()

 return parent


static func has_parent_in_group(node: Node, group: StringName) -> bool:
 return get_parent_in_group(node, group) != null


static func disconnect_signal(sig: Signal, method: Callable) -> void :
 if sig.is_connected(method):
  sig.disconnect(method)
