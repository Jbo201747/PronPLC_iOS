class_name WordHolder extends Node2D

signal updated
signal updated_tiles

const TILE_SEPARATION = {
 MAX = 26.0, 
 MIN = 17.0, 
 SQUISH_START = 16, 
 SQUISH_END = 24, 
}
const TILE_SEPARATION_THRESHOLDS = {
 0: 26.0, 
 13: 22.0, 
 20: 17.0, 
}

const BASE_TIME_PER_PERMUTATION = 1000
const REDUCE_TIME_PER_PERMUTATION = 200
const MIN_PERMUTATION_TIME = 200

var tiles: Array[Tile] = []
var clearing_tiles: Array[Tile] = []
var words_list: = WordList.new()

var is_removing: = false
var insertion_index: int = -1
var hovering_tile: Tile = null
var wave_time: float = 0.0
var wave_ramp_up: float = 0.0:
 set(value):
  wave_ramp_up = clamp(value, 0, 1)

var slot_multipliers: = PackedInt32Array()
var slots_active: = false
var adjusting_tiles: = false

@export var slot_scene: PackedScene

@export var max_tiles: int = -1
@export var waving: = false
@export var wave_scale: float = 0.0
@export var wave_offset: float = 0.0

@onready var slots_container: Node2D = %SlotsContainer
@onready var drag_handler: DragHandler = $DragHandler


func _process(_delta):
 if not is_removing:
  set_displaying_permutations()

 update_slot_visibility()


func _physics_process(delta):
 update_tile_wave(delta)


func update_slot_visibility() -> void :
 var all_tiles_idle: = not adjusting_tiles and not is_removing
 if all_tiles_idle:
  for tile in tiles:
   if tile.state != Tile.State.IDLE:
    all_tiles_idle = false

 var slots: = slots_container.get_children()
 for i in slots.size():
  var slot: TileSlot = slots[i]
  if i >= tiles.size() or not all_tiles_idle:
   slot.visible = true
  else:
   var tile: = tiles[i]
   if not tile.has_status(Globals.TileStatus.HOLE) and (tile.hover_handler.is_hovering()):
    slot.visible = false
   else:
    slot.visible = true


func show_slots(instant: = false) -> void :
 var existing_slots = slots_container.get_children()
 var num_multipliers = slot_multipliers.size()
 for i in max_tiles:
  var multiplier: int = 1
  if i < num_multipliers:
   multiplier = slot_multipliers[i]

  var slot: TileSlot = existing_slots.pop_front()
  if slot == null:
   slot = slot_scene.instantiate()
   slots_container.add_child(slot)

  slot.position = get_tile_index_position(i)
  slot.set_multiplier(multiplier)
  slot.visible = true

  if i == max_tiles - 1:
   await slot.appear(instant)
  else:
   slot.appear(instant)
   await Game.conditional_timeout(0.08, instant)

 slots_active = true

 for leftover in existing_slots:
  leftover.queue_free()


func hide_slots(instant: = false, free_slots: = false) -> void :
 var slots: = slots_container.get_children()
 if not slots_active:
  if free_slots:
   for slot: TileSlot in slots:
    slot.queue_free()

  return

 slots_active = false

 slots.reverse()
 for slot: TileSlot in slots:
  if slot == slots[-1]:
   await slot.disappear(instant, free_slots)
  else:
   slot.disappear(instant, free_slots)
   await Game.conditional_timeout(0.08, instant)



func using_tile_slots() -> bool:
 return max_tiles != -1


func add_tile(tile: Tile, insert_at: int = -1, swap: = false):
 if tile in tiles:
  tiles.erase(tile)

 if insert_at == -1:
  tiles.append(tile)
 else:
  if swap:
   var removing_tile = tiles[insert_at]
   tiles[insert_at] = tile
   return_tile(removing_tile)
  else:
   tiles.insert(insert_at, tile)

 updated_tiles.emit()

 tween_tile_in(tile)
 align_tiles(tile)


func tween_tile_in(tile: Tile):
 var dest = get_tile_position(tile)
 await tile.tween_position(dest)
 update_tile_multiplier(tile)


func update_tile_multiplier(tile: Tile, tile_index: = -1) -> void :
 if not slot_multipliers.is_empty():
  if tile_index == -1:
   tile_index = tiles.find(tile)

  if tile_index < slot_multipliers.size():
   tile.tile_sprite.set_multiplier(slot_multipliers[tile_index])


func try_add_tile(tile: Tile, insert_at: int = -1, swap: = false) -> void :
 if not can_add_tile(tile, swap):
  tile.animation.play("shake")
  return

 add_tile(tile, insert_at, swap)


func remove_tile(tile: Tile, emit_update: = true, remove_tiles_after: = true, base_pitch: float = 1.0):
 if emit_update:
  is_removing = true
  updated.emit()

 var index = tiles.find(tile)
 if remove_tiles_after:
  var tile_delay = 0.04
  while tiles[-1] != tile:
   remove_tile(tiles[-1], false, false, base_pitch)
   base_pitch = min(base_pitch + 0.025, 1.5)
   await Game.timeout(tile_delay)
   tile_delay = max(tile_delay - 0.005, 0.005)

 if tile.animation.is_playing() and tile.animation.current_animation == "jitter":
  tile.animation.play("RESET")

 tile.play_tile_sound(base_pitch)
 tiles.remove_at(index)

 if emit_update:
  updated_tiles.emit()

 return_tile(tile)
 align_tiles()

 if emit_update:
  is_removing = false
  updated.emit()


func return_tile(tile: Tile):
 tile.reset_wildcard_faces()
 tile.tile_face.set_displaying_permutation_face_index(-1)
 tile.tile_sprite.hide_multiplier()
 tile.tween_to_board()


func remove_tiles():
 while is_removing:
  await updated

 if not tiles.is_empty():
  await remove_tile(tiles[0])


func clear_tiles(tile_callback: = Callable(), remove_slots: = true):
 insertion_index = -1
 await align_tiles()

 clearing_tiles = tiles.duplicate()
 tiles.clear()

 var removed_tiles: Array[Tile] = []
 var eternal_tiles: Array[Tile] = []
 for tile in clearing_tiles:
  var eternal_status: Status = tile.get_status(Globals.TileStatus.ETERNAL)
  if eternal_status:
   eternal_status.played_this_turn = true
   eternal_tiles.append(tile)
  else:
   removed_tiles.append(tile)

 Game.tile_board.remove_tiles(removed_tiles, {
  restock = false, 
  settle = eternal_tiles.is_empty(), 
  ignore_status = true, 
  delete_tiles = false, 
 })

 var reveal_mystery_tiles: Array[Tile] = []
 for tile in clearing_tiles:
  if tile.has_status(Globals.TileStatus.MYSTERY):
   reveal_mystery_tiles.append(tile)

 if not reveal_mystery_tiles.is_empty():
  for tile in reveal_mystery_tiles:
   tile.remove_status(Globals.TileStatus.MYSTERY)
   tile.add_poofcloud(Globals.COLORS.INK_BLACK)
   if tile != reveal_mystery_tiles[-1]:
    await Game.timeout(0.08)

  await Game.timeout(1.0)

 var num_tiles = clearing_tiles.size()
 var tile_slots: = maxi(max_tiles, clearing_tiles.size())

 if remove_slots:
  slots_active = false

 var slot_nodes: = slots_container.get_children()
 var num_slots = slot_nodes.size()

 var tile_delay = 0.075
 for i in range(tile_slots - 1, -1, -1):
  if remove_slots and i < num_slots:
   var slot: TileSlot = slot_nodes[i]
   if i < num_tiles:
    slot.disappear(true)
   else:
    slot.disappear()
    await Game.timeout(tile_delay)
    tile_delay = max(tile_delay - 0.0075, 0.02)

  if i < num_tiles:
   var tile: = clearing_tiles[i]
   if tile_callback.is_valid():
    tile_callback.call(tile)

   tile.add_poofcloud(tile.get_color(), Globals.COLORS.BLEND_SMOKE)
   if tile in removed_tiles:
    tile.clear(false)
   else:
    tile.animation.play("shake")

   if i != clearing_tiles.size() - 1:
    await Game.timeout(tile_delay)
    tile_delay = max(tile_delay - 0.0075, 0.004)

 clearing_tiles.clear()

 if not eternal_tiles.is_empty():
  await Game.timeout(0.6)
  for tile in eternal_tiles:
   return_tile(tile)
   if tile != eternal_tiles[-1]:
    await Game.timeout(0.1)

  await Game.tile_board.wait_for_idle_tiles()
  await Game.timeout(0.2)
  await Game.tile_board.settle_board()


func get_active_tiles():
 var active_tiles = []
 for tile in tiles:
  if not tile.is_dragging():
   active_tiles.append(tile)

 return active_tiles


func get_tile_slots():
 var active_tiles = get_active_tiles()

 if insertion_index != -1:
  active_tiles.insert(insertion_index, null)

 return active_tiles


func get_tile_separation(num_tiles: int) -> float:
 if num_tiles > TILE_SEPARATION.SQUISH_START:
  return remap(num_tiles, TILE_SEPARATION.SQUISH_START, TILE_SEPARATION.SQUISH_END, TILE_SEPARATION.MAX, TILE_SEPARATION.MIN)
 else:
  return TILE_SEPARATION.MAX


func get_tile_separation_threshold(num_tiles: int) -> float:
 var last_threshold_value: float = TILE_SEPARATION_THRESHOLDS[0]
 for threshold in TILE_SEPARATION_THRESHOLDS:
  if num_tiles < threshold:
   return last_threshold_value

  last_threshold_value = TILE_SEPARATION_THRESHOLDS[threshold]

 return last_threshold_value


func get_tile_index_position(tile_index, num_tiles: int = max_tiles):
 var separation: = get_tile_separation_threshold(num_tiles)
 var tile_size: float = num_tiles * separation
 var left_tile_x = - (tile_size / 2.0) + separation / 2.0
 return Vector2(left_tile_x + separation * tile_index, 0.0)


func get_tile_position(tile, active_tiles = tiles) -> Vector2:
 var index = active_tiles.find(tile)
 if using_tile_slots():
  return to_global(get_tile_index_position(index))
 else:
  return to_global(get_tile_index_position(index, active_tiles.size()))


func set_tile_positions():
 for tile in tiles:
  tile.global_position = get_tile_position(tile)


func update_drag_handler_size(tile_slots) -> void :
 var using_slots: = using_tile_slots()
 if tile_slots.is_empty() and not using_slots:
  drag_handler.position.x = -91
  drag_handler.size.x = 182.0
  return

 var tile_left_zone_start
 var tile_right_zone_end
 if using_tile_slots():
  tile_left_zone_start = get_tile_index_position(0).x - 52
  tile_right_zone_end = get_tile_index_position(max_tiles - 1).x + 52
 else:
  tile_left_zone_start = to_local(get_tile_position(tile_slots[0], tile_slots)).x - 52
  tile_right_zone_end = to_local(get_tile_position(tile_slots[-1], tile_slots)).x + 52

 drag_handler.position.x = min(drag_handler.position.x, tile_left_zone_start)
 drag_handler.size.x = max(drag_handler.size.x, tile_right_zone_end - drag_handler.position.x)


func align_tiles(excluding_tile = null):
 var active_tiles = get_tile_slots()
 update_drag_handler_size(active_tiles)
 update_slot_visibility()

 if active_tiles.is_empty():
  return

 adjusting_tiles = true
 var last_move_tween: Tween = null
 for tile in active_tiles:
  if tile == excluding_tile or tile == null:
   continue

  update_tile_multiplier(tile, active_tiles.find(tile))

  var dest = get_tile_position(tile, active_tiles)
  if not is_equal_approx(tile.global_position.x, dest.x):
   var tween = tile.create_tween()
   tween.set_trans(tween.TRANS_QUAD)
   tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
   tween.tween_property(tile, "global_position:x", dest.x, 0.35)
   last_move_tween = tween

 if last_move_tween:
  await last_move_tween.finished

 adjusting_tiles = false


func is_waving():
 return waving


func update_tile_wave(delta):
 wave_time += delta

 if is_waving():
  wave_ramp_up += 0.01 * 60 * delta
 else:
  wave_ramp_up -= 0.01 * 60 * delta

 var index = -1
 var buffer = -0.2
 var frequency = 5
 var amplitude = 150

 var wave_tiles: = tiles
 if tiles.is_empty() and not clearing_tiles.is_empty():
  wave_tiles = clearing_tiles

 for tile in wave_tiles:
  index += 1
  if not tile_is_valid(tile) or tile.is_moving():
   continue

  var wave = cos((wave_time + index * buffer + wave_offset * PI) * frequency)
  var movement = wave * amplitude

  movement = movement * wave_scale * wave_ramp_up
  tile.global_position.y = get_tile_position(tile).y + movement * 1.0 / 60.0


func tile_is_valid(tile):
 return is_instance_valid(tile) and not tile.is_queued_for_deletion()


func display_permutation(sub_list, permutation_index):
 if sub_list.last_displayed_permutation == permutation_index:
  return

 sub_list.last_displayed_permutation = permutation_index

 var permutation: WordList.Permutation = sub_list.permutations[permutation_index]
 var tile_index = -1
 for tile in sub_list.tiles:
  tile_index += 1
  if not tile_is_valid(tile):
   continue

  var face_set: WordList.FaceSet = sub_list.tiles[tile]
  var face = permutation.faces[tile_index]
  var face_index: int = face_set.faces.find(face)
  tile.tile_face.set_displaying_permutation_face_index(face_index)


func set_displaying_permutations():
 if tiles.size() == 0:
  return

 var current_time = Time.get_ticks_msec()
 for sub_list in words_list.sub_lists:
  var permutation_count = sub_list.permutations.size()
  if permutation_count == 0:
   continue
  elif permutation_count == 1:
   display_permutation(sub_list, 0)

  var extra_permutations: float = permutation_count - 1
  var time_per_permutation: float = BASE_TIME_PER_PERMUTATION - (REDUCE_TIME_PER_PERMUTATION * extra_permutations)
  time_per_permutation = maxf(time_per_permutation, MIN_PERMUTATION_TIME)
  var total_permutation_time: float = time_per_permutation * permutation_count
  var adjusted_current_time: float = fmod(current_time, total_permutation_time)
  var selected_permutation_index: int = floori(adjusted_current_time / time_per_permutation)
  display_permutation(sub_list, selected_permutation_index)


func can_add_tile(tile: Tile, swap: = false) -> bool:
 if tile in tiles or swap:
  return true
 else:
  return max_tiles == -1 or tiles.size() < max_tiles


func has_max_tiles() -> bool:
 return max_tiles != -1 and tiles.size() == max_tiles


func get_insertion_target_positions(moving_tile: Tile) -> Dictionary[int, Vector2]:
 var target_positions: Dictionary[int, Vector2] = {}
 var swapping: = is_swapping(moving_tile)
 if swapping:
  for i in tiles.size():
   target_positions[i] = get_tile_position(tiles[i])
 else:
  var tile_count = tiles.size()
  if moving_tile not in tiles:
   tile_count += 1

  var tiles_limited: = using_tile_slots()

  for i in tile_count:
   if tiles_limited:
    target_positions[i] = to_global(get_tile_index_position(i))
   else:
    target_positions[i] = to_global(get_tile_index_position(i, tile_count))

 return target_positions


func is_swapping(moving_tile: Tile) -> bool:
 return has_max_tiles() and moving_tile not in tiles


func release_hovered_tile() -> void :
 if Tile.is_tile_valid(hovering_tile):
  if hovering_tile.word_holder_hovered:
   hovering_tile.word_holder_hovered = false

  if hovering_tile in tiles:
   update_tile_multiplier(hovering_tile)
  else:
   hovering_tile.tile_sprite.hide_multiplier()

 hovering_tile = null


func _on_drag_handler_received(other_handler: DragHandler, _current_pos: Vector2) -> void :
 if insertion_index != -1:
  var insert_at = insertion_index
  insertion_index = -1
  release_hovered_tile()
  try_add_tile(other_handler.get_owner(), insert_at, is_swapping(other_handler.get_owner()))


func _on_drag_handler_hovering(other_handler: DragHandler, current_pos: Vector2) -> void :
 var new_insertion_index = 0

 var swap_mode: = is_swapping(other_handler.get_owner())
 if swap_mode:
  var closest_tile: Tile
  var closest_tile_dist: float = INF
  for tile in tiles:
   var dist: float = abs(tile.position.x - current_pos.x)
   if dist < closest_tile_dist:
    closest_tile = tile
    closest_tile_dist = dist

  new_insertion_index = tiles.find(closest_tile)
 else:
  var active_tiles = get_active_tiles()
  var active_slots = get_tile_slots()
  for tile in active_tiles:
   if tile == null:
    continue

   var tile_pos = get_tile_position(tile, active_slots).x
   if current_pos.x > tile_pos or current_pos.x == tile_pos and insertion_index == new_insertion_index:
    new_insertion_index += 1

 if new_insertion_index != insertion_index:
  insertion_index = new_insertion_index

  var tile = other_handler.get_owner()
  update_tile_multiplier(tile, insertion_index)

  if swap_mode:
   release_hovered_tile()
   hovering_tile = tiles[insertion_index]
   hovering_tile.word_holder_hovered = true
   hovering_tile.tile_sprite.hide_multiplier()
  else:
   align_tiles()


func _on_drag_handler_unhovered(other_handler: DragHandler, _current_pos: Vector2) -> void :
 var tile = other_handler.get_owner()
 tile.tile_sprite.hide_multiplier()
 release_hovered_tile()
 insertion_index = -1
 align_tiles()
