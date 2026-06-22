class_name TileBoard extends Node2D


signal rerolled_board
signal state_updated
signal tiles_changed
signal tiles_updated
signal turn_ended
signal all_columns_filled


const TURN_END_STEP_DELAY = 0.5

const GRID_SIZE = 22

const BOARD_MARGIN_TL = Vector2(6, 2)

const BOARD_MARGIN_BR = Vector2(6, 10)

const PREVIEW_WIDTH_OFFSET = 4

const TILE_OFFSET = Vector2(1, 3)

const TILE_MASK_OFFSET = Vector2(-1, -1)

const TILE_TO_PREVIEW = 6
const PREVIEW_ROW_HEIGHT = 12
const BOARD_BOTTOM_Y = 226

const WORD_BUILDER_OFFSET = -50
const WORD_BUILDER_MAX_Y = 58

const TileType = Globals.TileType
const TileStatus = Globals.TileStatus
const TileEffect = Globals.TileEffect

enum ExpandMode{
 BOTTOM_LEFT, 
 CENTER, 
 TOP_RIGHT
}


var tile_map: Dictionary[Vector2i, Tile] = {}
var num_columns = 4
var num_rows = 4
var restock_depth = 4
var preview_rows = 1

var coord_statuses = {}

var queue: = TileQueue.new()

var min_vowels = 3
var min_consonants = 5
var idle = true
var doomed_columns: Array = []
var defense_bag = []
var flags: = PackedStringArray()
var crit_chance = 0.02

var is_slid_out: = false

var is_removing = false
var is_restocking = false
var is_settling = false
var is_removing_acid = false

var filling_columns: = 0:
 set(value):
  if value != filling_columns:
   filling_columns = value
   if filling_columns == 0:
    all_columns_filled.emit()

var preview_labels: Array[BoardPreviewLabel] = []

var rng = {

 bag = RNG.new(), 
 fill_gen = RNG.new(), 
 fill = RNG.new(), 
 crit = RNG.new(), 
}

var tile_scene = preload("res://source/tile/tile.tscn")

var big_chain_texture: Texture2D = preload("res://arte/ui/preview_chain.png")
var small_chain_texture: Texture2D = preload("res://arte/ui/preview_chain_small.png")

var restock_just_locked: = false
var stay_off_screen: = false
var prevent_filling: = false

var board_state_recently_changed: = false

var lock_amount = 0:
 set(value):
  lock_amount = clamp(value, 0, 9)

var restock_locked:
 get:
  return lock_amount > 0

@onready var main = Game.main
@onready var word_builder = Game.word_builder

@onready var board = %Board
@onready var preview_mask = %PreviewMask
@onready var chain_anim_player = $BoardPosition / Board / Chains / AnimPlayer
@onready var tile_mask = %TileMask
@onready var tile_box: Control = %TileBox
@onready var anim_player: AnimPlayer = %AnimPlayer
@onready var center_focus_holder: FocusHolder = %CenterFocusHolder
@onready var blank_space_focus_container: Control = %BlankSpaceFocusContainer


func _init():
 Game.tile_board = self


func reseed(game_rng):
 RNG.reseed_rng_group(rng, game_rng)
 queue.reseed(game_rng)


func initialize_crit_chance() -> void :
 crit_chance = Game.player.get_crit_chance().MIN


func reset_board():
 flags.clear()
 set_size(4, 4, null, null, true)
 pregenerate()


func pregenerate(initial_defense: int = 3):
 defense_bag = []
 queue.clear()
 prepare_queue()

 if main.tutorial.active:
  var cat = queue.queue_word("cat")
  for queued_tile in cat:
   queued_tile.type = TileType.DEFENSE

  queue.queue_word("qe")
 else:
  queue.queue_common_word()

 fill_queue()

 queue.set_initial_queued_type(0 if main.tutorial.active else initial_defense)
 queue.clear_targeted_coords()


func prepare_queue():
 var board_emptiness = []
 for x in num_columns:
  board_emptiness.append(get_column_needed_tiles(x))

 queue.prepare_to_fall(board_emptiness, max(preview_rows, 1))


func get_column_needed_tiles(column: int, ignore_restock_depth: bool = false) -> int:
 var needed_tiles: int = 0

 for row in range(num_rows - 1, -1, -1):
  if get_tile_at(Vector2i(column, row)) != null:
   break
  elif row < restock_depth or ignore_restock_depth:
   needed_tiles += 1

 return needed_tiles


func fill_queue(clear_previews = true, use_preview_columns = num_columns, use_preview_rows = preview_rows, offset_by: Vector2i = Vector2i.ZERO):
 queue.fill_queue(min_vowels - get_letters_total(Letters.VOWELS, true), min_consonants - get_letters_total(Letters.CONSONANTS, true), get_letter_census())
 update_previews(clear_previews, use_preview_columns, use_preview_rows, offset_by)


func prepare_to_animate() -> void :
 for tile in get_tiles():
  if tile.get_parent() == main.tile_container:
   tile.sway_handler.disabled = true
   tile.reparent(tile_mask)


func finish_animating() -> void :
 for tile in get_tiles():
  if tile.get_parent() == tile_mask:
   tile.sway_handler.disabled = false
   tile.reparent(main.tile_container)


func slide_in(instant = false):
 is_slid_out = false

 anim_player.play("slide_in")
 if instant:
  anim_player.advance(anim_player.current_animation_length)
 else:
  AudioManager.play_sound(Sounds.GENERIC.BOARD_IN)
  await anim_player.animation_finished

 finish_animating()


func slide_out(instant = false):
 is_slid_out = true

 prepare_to_animate()

 anim_player.play_backwards("slide_in")

 if instant:
  anim_player.advance(anim_player.current_animation_length)
 else:
  AudioManager.play_sound(Sounds.GENERIC.BOARD_OUT)
  await anim_player.animation_finished


func screenshake(intensity, duration):
 Game.screenshake(intensity, duration)


func get_tile_box_size():
 var size: = Vector2(GRID_SIZE * num_columns, GRID_SIZE * num_rows) + Vector2(2, 6)
 return Vector2(
  maxf(size.x, 6), 
  maxf(size.y, 10), 
 )


func get_preview_height():
 if preview_rows == 0:
  return 4
 else:
  return preview_rows * PREVIEW_ROW_HEIGHT


func get_preview_size():
 return Vector2(get_tile_box_size().x + BOARD_MARGIN_TL.x + BOARD_MARGIN_BR.x - PREVIEW_WIDTH_OFFSET, get_preview_height())


func get_tile_box_position():
 return Vector2(0, get_preview_height()) + BOARD_MARGIN_TL


func get_tile_mask_position():
 return get_tile_box_position() + Vector2(2, 4)


func get_tile_mask_size():
 return get_tile_box_size() - Vector2(4, 6)


func get_total_size():
 return get_tile_box_size() + Vector2(0, get_preview_height()) + BOARD_MARGIN_TL + BOARD_MARGIN_BR


func get_board_position():
 return - (get_total_size() / 2)


func get_target_global_position():
 return Vector2(global_position.x, - get_total_size().y / 2 + BOARD_BOTTOM_Y)


func get_target_global_top_left():
 var total_size = get_total_size()
 return Vector2(global_position.x - total_size.x / 2.0, - total_size.y + BOARD_BOTTOM_Y)


func get_top_left_tile_position():
 return tile_box.global_position + Vector2(GRID_SIZE / 2.0, GRID_SIZE / 2.0) + TILE_OFFSET


func get_top_left_tile_local_position():
 return Vector2(GRID_SIZE / 2.0, GRID_SIZE / 2.0) + TILE_MASK_OFFSET


func get_word_builder_y_position():
 return min(get_target_global_top_left().y + WORD_BUILDER_OFFSET, WORD_BUILDER_MAX_Y)


func set_size(columns = 4, rows = 4, new_preview_rows = null, new_restock_depth = null, loading = false, duration = 0.33, expand_mode: ExpandMode = ExpandMode.TOP_RIGHT):
 if new_restock_depth == null:
  if Game.player.id == Globals.CHARACTERS.FISHER:
   new_restock_depth = rows - 1
  else:
   new_restock_depth = rows

 if new_preview_rows == null:
  if Game.player.id == Globals.CHARACTERS.ADDICT:
   new_preview_rows = 0
  else:
   new_preview_rows = 1

 var prev_columns = num_columns
 var prev_rows = num_rows
 var prev_preview_rows = preview_rows

 num_columns = columns
 num_rows = rows
 restock_depth = new_restock_depth
 preview_rows = new_preview_rows

 var size_difference = Vector2i(num_columns, num_rows) - Vector2i(prev_columns, prev_rows)
 var shift_by: = Vector2i.ZERO
 if expand_mode == ExpandMode.BOTTOM_LEFT:
  shift_by = size_difference
 elif expand_mode == ExpandMode.CENTER:
  shift_by = size_difference / 2

 var pop_tiles = []
 var tiles_to_update = []
 for coords in tile_map:
  var tile = tile_map[coords]
  tile.update_z_index()
  if loading:
   tile.global_position = get_coord_position(coords)
   continue

  tiles_to_update.append({tile = tile, coords = coords})

 for tile_data in tiles_to_update:
  var tile = tile_data.tile
  var coords = tile_data.coords
  if shift_by != Vector2i.ZERO:
   set_tile_coords(tile, coords + shift_by)

  if not are_coords_valid(coords + shift_by):
   pop_tiles.append(tile)

  if tile.get_parent() != tile_mask:
   tile.reparent(tile_mask)

 var blank_spaces: = get_blank_spaces()
 for x in num_columns:
  for y in num_rows:
   var blank_space: BoardBlankSpaceFocus = blank_spaces.pop_front()
   if blank_space == null or blank_space.is_queued_for_deletion():
    blank_space = BoardBlankSpaceFocus.new()
    blank_space_focus_container.add_child(blank_space)

   blank_space.coord = Vector2i(x, y)

 for leftover in blank_spaces:
  leftover.queue_free()

 queue.set_columns(num_columns)
 if shift_by != Vector2i.ZERO:
  queue.shift(shift_by)

 if loading:
  preview_mask.modulate = Color.TRANSPARENT if preview_rows == 0 else Color.WHITE
  preview_mask.size = get_preview_size()
  board.size = get_total_size()
  board.position = get_board_position()
  tile_box.position = get_tile_box_position()
  tile_box.size = get_tile_box_size()
  tile_mask.position = get_tile_mask_position()
  tile_mask.size = get_tile_mask_size()
  global_position = get_target_global_position()
  word_builder.global_position.y = get_word_builder_y_position()

  return

 prepare_queue()
 fill_queue(false, max(num_columns, prev_columns), max(preview_rows, prev_preview_rows), Vector2i( - shift_by.x, 0))

 var tween = create_tween()
 tween.set_ease(Tween.EASE_OUT)
 tween.set_trans(Tween.TRANS_BOUNCE)
 tween.set_parallel(true)

 var tile_tweens = {}

 var new_tile_size = get_tile_box_size()
 for coords in tile_map:
  var tile = tile_map[coords]
  var tile_tween = create_tween()
  tile_tween.set_ease(Tween.EASE_OUT)
  tile_tween.set_trans(Tween.TRANS_BOUNCE)
  tile_tween.tween_property(tile, "position", get_coord_position(coords, true), duration)
  tile_tweens[tile] = tile_tween

 for preview in preview_labels:
  tween.tween_property(preview, "position", get_preview_position(preview.coordinate), duration)


 tween.tween_method(pop_crushed_tiles.bind(pop_tiles, tile_tweens), 0.0, 1.0, duration)
 tween.tween_property(preview_mask, "modulate", Color.TRANSPARENT if preview_rows == 0 else Color.WHITE, duration)
 tween.tween_property(preview_mask, "size", get_preview_size(), duration)
 tween.tween_property(tile_box, "position", get_tile_box_position(), duration)
 tween.tween_property(tile_box, "size", new_tile_size, duration)
 tween.tween_property(tile_mask, "position", get_tile_mask_position(), duration)
 tween.tween_property(tile_mask, "size", get_tile_mask_size(), duration)
 tween.tween_property(board, "size", get_total_size(), duration)
 tween.tween_property(board, "position", get_board_position(), duration)
 tween.tween_property(self, "global_position", get_target_global_position(), duration)
 tween.tween_property(word_builder, "global_position:y", get_word_builder_y_position(), duration)

 await tween.finished

 queue.clear_outside_columns()
 update_previews()

 for tile in pop_tiles:
  pop_tile(tile)

 await settle_board()
 await fill_board()


func pop_crushed_tiles(_progress, popping_tiles, tile_tweens):
 for i in range(popping_tiles.size() - 1, -1, -1):
  var tile = popping_tiles[i]
  if tile.position.x > tile_mask.size.x or tile.position.x < 0 or tile.position.y <= 0 or tile.position.y > tile_mask.size.y:
   if tile in tile_tweens:
    tile_tweens[tile].kill()
    tile_tweens.erase(tile)

   pop_tile(tile)
   popping_tiles.remove_at(i)


func get_row(row_coord):
 return get_tiles({rows = [row_coord], sorted = true})


func get_column(column_coord):
 return get_tiles({columns = [column_coord], sorted = true})


func _get_row_or_column_coords(count, is_rows, reverse = false, include_empty = true, pivot = null, above_pivot = true, include_pivot = false):
 var coords
 if pivot:
  if above_pivot:
   if include_pivot:
    coords = range(pivot, count)
   else:
    coords = range(pivot + 1, count)
  else:
   if include_pivot:
    coords = range(pivot + 1)
   else:
    coords = range(pivot)
 else:
  coords = range(count)

 if reverse:
  coords.reverse()

 if not include_empty:
  var stocked_coords = []
  for coord in coords:
   if is_rows and not get_row(coord).is_empty():
    stocked_coords.append(coord)
   elif not is_rows and not get_column(coord).is_empty():
    stocked_coords.append(coord)

  return stocked_coords

 return coords


func get_row_coords(reverse = false, include_empty = true, pivot = null, above_pivot = true, include_pivot = false):
 return _get_row_or_column_coords(num_rows, true, reverse, include_empty, pivot, above_pivot, include_pivot)


func get_column_coords(reverse = false, include_empty = true, pivot = null, above_pivot = true, include_pivot = false):
 return _get_row_or_column_coords(num_columns, false, reverse, include_empty, pivot, above_pivot, include_pivot)


func are_coords_valid(coords: Vector2i) -> bool:
 return coords.x >= 0 and coords.y >= 0 and coords.x < num_columns and coords.y < num_rows


func wrap_coords(coords: Vector2i, wrap_add: Vector2i = Vector2i.ZERO) -> Vector2i:
 var wrapped: = Vector2i(posmod(coords.x, num_columns), posmod(coords.y, num_rows))
 if wrapped != coords and wrap_add != Vector2i.ZERO:
  return wrap_coords(wrapped + wrap_add)

 return wrapped


func optional_wrap_coords(coords: Vector2i, do_wrap: bool, wrap_add: Vector2i = Vector2i.ZERO) -> Vector2i:
 if not do_wrap:
  return coords
 else:
  return wrap_coords(coords, wrap_add)


func pop_from_bag():
 if defense_bag.is_empty():
  for i in range(Game.balance.damage_in_bag):
   defense_bag.append(TileType.DAMAGE)

  for i in range(Game.balance.defense_in_bag):
   defense_bag.append(TileType.DEFENSE)

  rng.bag.shuffle(defense_bag)

 return defense_bag.pop_back()


func top_up_bag(type, amount = 1):
 for _i in range(amount):
  defense_bag.append(type)


func get_tile_census(tiles: Array, letters = Letters.LETTERS) -> Dictionary:
 var census = {}
 var total = 0
 for tile in tiles:
  if tile.faces.size() != 1 or tile.faces[0] not in letters:
   continue

  var letter = tile.faces[0]
  census.get_or_add(letter, 0)
  census[letter] += 1
  total += 1

 return {
  census = census, 
  total = total, 
 }


func get_census_tiles(only_immediate: = false) -> Array:
 var tiles = get_tiles()
 return tiles + queue.get_tiles(only_immediate)


func get_letters_total(letters = Letters.LETTERS, only_immediate: = false) -> int:
 return get_tile_census(get_census_tiles(only_immediate), letters).total



func get_letter_census(letters = Letters.LETTERS, only_immediate = false) -> Dictionary:
 return get_tile_census(get_census_tiles(only_immediate), letters).census


func fade_previews(instant: = false) -> void :
 for label: BoardPreviewLabel in preview_labels:
  if instant:
   label.modulate = Color.TRANSPARENT
  else:
   label.create_tween().tween_property(label, "modulate", Color.TRANSPARENT, 0.5)


func fade_previews_in(instant: = false) -> void :
 for label: BoardPreviewLabel in preview_labels:
  if instant:
   label.modulate = Color.WHITE
  else:
   label.create_tween().tween_property(label, "modulate", Color.WHITE, 0.5)


func get_preview_position(preview_coord: Vector2i) -> Vector2:
 var x = get_top_left_tile_local_position().x + preview_coord.x * GRID_SIZE + TILE_TO_PREVIEW - GRID_SIZE / 2
 var y = get_preview_height() - (preview_coord.y + 1) * PREVIEW_ROW_HEIGHT + PREVIEW_ROW_HEIGHT / 2
 return Vector2(x, y - 10)


func update_previews(clear_previews = true, columns = num_columns, rows = preview_rows, offset_by: Vector2i = Vector2i.ZERO):
 var unused_preview_labels = preview_labels.duplicate()
 for x in columns:
  for y in rows:
   var preview
   if unused_preview_labels.size() > 0:
    preview = unused_preview_labels.pop_front()
   else:
    preview = BoardPreviewLabel.new()
    preview_labels.append(preview)
    preview_mask.add_child(preview)

   var coord = Vector2i(x, y)
   preview.coordinate = coord
   var queued_tile = queue.get_preview(x, y)
   if queued_tile:
    if queued_tile.faces.size() > 0:
     preview.text = queued_tile.faces[0]
    else:
     preview.text = ""

    if "statuses" in queued_tile:
     if TileStatus.CAPITAL in queued_tile.statuses:
      preview.text = preview.text.to_upper()
     elif TileStatus.PERIOD in queued_tile.statuses:
      preview.text += "."
   else:
    preview.text = "?"



   preview.position = get_preview_position(coord + offset_by)

 if clear_previews:
  for unused_label in unused_preview_labels:
   preview_labels.erase(unused_label)
   unused_label.queue_free()


func _posmod_array(array, mod_by):
 var array_size = array.size()
 if array_size == 0 or mod_by == 0:
  return

 for i in array_size:
  array[i] = posmod(array[i], mod_by)


func coordinate_distance(tile_coord: Vector2i, from_coord: Vector2i) -> int:
 if from_coord.x == -1:
  return abs(tile_coord.x - from_coord.x)
 elif from_coord.y == -1:
  return abs(tile_coord.y - from_coord.y)
 else:
  return abs(tile_coord.x - from_coord.x) + abs(tile_coord.y - from_coord.y)









func get_tiles(parameters = {}):
 var tiles = []

 var default_parameters = {
  amount = null, 
  columns = get_column_coords(), 

  rows = get_row_coords(true), 
  exclude_columns = [], 
  exclude_rows = [], 
  column_priority = null, 
  row_priority = null, 
  by_distance_from = null, 
  max_distance = null, 
  group_by_priority = false, 
  harmful = null, 
  type = null, 
  type_priority = null, 
  include_effects = null, 
  must_include_effects = null, 
  exclude_effects = null, 
  only_effects = null, 
  effect_priority = null, 
  exclude_tiles = [], 
  max_faces = INF, 
  min_faces = 0, 
  face = null, 
  letters = null, 
  exclude_letters = null, 
  single_letter = false, 
  sorted = false, 
  reverse_sorted = false, 
  no_final_shuffle = false, 
  has_face = null, 
  is_playable = null, 
  custom_tile_check = null, 
  get_coords = false, 
  exclude_coords = [], 
  empty = false, 
  exclude_coord_status = false, 
  in_word = null, 
  rng = Game.random, 
 }

 parameters.merge(default_parameters)

 if parameters.amount != null and parameters.amount <= 0:
  return []

 if parameters.effect_priority and not parameters.only_effects:
  parameters.only_effects = Util.reduce_multidimensional_array(parameters.effect_priority)


 _posmod_array(parameters.rows, num_rows)
 _posmod_array(parameters.columns, num_columns)
 _posmod_array(parameters.exclude_rows, num_rows)
 _posmod_array(parameters.exclude_columns, num_columns)

 if parameters.row_priority:
  _posmod_array(parameters.row_priority, num_rows)

 if parameters.column_priority:
  _posmod_array(parameters.column_priority, num_columns)


 for x in parameters.columns:
  if x in parameters.exclude_columns:
   continue

  for y in parameters.rows:
   if y in parameters.exclude_rows:
    continue

   var coords = Vector2i(x, y)
   if coords in parameters.exclude_coords:
    continue

   if parameters.max_distance and coordinate_distance(Vector2i(x, y), parameters.by_distance_from) > parameters.max_distance:
    continue

   if parameters.exclude_coord_status and coords in coord_statuses:
    continue

   var has_tile = coords in tile_map
   if has_tile == parameters.empty:
    continue

   var tile_info = {coords = coords}
   if has_tile:
    tile_info.tile = tile_map[coords]
    if not _is_tile_valid(tile_info.tile, parameters):
     continue

   if has_tile or parameters.get_coords:
    tiles.append(tile_info)

 if parameters.reverse_sorted:
  tiles.reverse()
 elif not parameters.sorted:
  parameters.rng.shuffle(tiles)

 var priority_sorted = (
  parameters.effect_priority != null
  or parameters.row_priority != null
  or parameters.column_priority != null
  or parameters.type_priority != null
  or parameters.by_distance_from != null
 )
 if priority_sorted:
  var unsorted_tiles = tiles.duplicate()
  tiles = []


  for tile_info in unsorted_tiles:
   tile_info.combined_priority = 0
   if parameters.effect_priority and "tile" in tile_info:
    tile_info.combined_priority += tile_info.tile.get_effect_priority(parameters.effect_priority) * 1000

   if parameters.type_priority != null and "tile" in tile_info:
    if tile_info.tile.type != parameters.type_priority:
     tile_info.combined_priority += 100000

   if parameters.by_distance_from != null:
    var coords = parameters.by_distance_from
    tile_info.combined_priority += coordinate_distance(tile_info.coords, coords)

   if parameters.row_priority:
    tile_info.combined_priority += parameters.row_priority.find(tile_info.coords.y)

   if parameters.column_priority:
    tile_info.combined_priority += parameters.column_priority.find(tile_info.coords.x)

   var insertion_index = 0
   for tile_index in range(tiles.size() - 1, -1, -1):
    var comparing_tile = tiles[tile_index]
    if parameters.group_by_priority and tile_info.combined_priority == comparing_tile.combined_priority:
     insertion_index = -1
     comparing_tile.tiles.append(tile_info.tile)
     comparing_tile.coords.append(tile_info.coords)
     break
    elif tile_info.combined_priority >= comparing_tile.combined_priority:
     insertion_index = tile_index + 1
     break

   if parameters.group_by_priority:
    if insertion_index != -1:
     tiles.insert(insertion_index, {combined_priority = tile_info.combined_priority, tiles = [tile_info.tile], coords = [tile_info.coords]})
   else:
    tiles.insert(insertion_index, tile_info)


  if parameters.group_by_priority:
   var groups = []
   for group in tiles:
    if parameters.get_coords:
     groups.append(group.coords)
    else:
     groups.append(group.tiles)

   return groups

 if parameters.amount != null:
  tiles = tiles.slice(0, parameters.amount)


 for tile_index in tiles.size():
  if parameters.get_coords:
   tiles[tile_index] = tiles[tile_index].coords
  else:
   tiles[tile_index] = tiles[tile_index].tile


 if priority_sorted and not (parameters.sorted or parameters.reverse_sorted or parameters.no_final_shuffle):
  parameters.rng.shuffle(tiles)

 return tiles


func _is_tile_valid(tile: Tile, parameters, do_custom_check = true):
 if parameters.custom_tile_check != null and do_custom_check:
  if not parameters.custom_tile_check.call(tile, parameters):
   return false

 if tile in parameters.exclude_tiles:
  return false

 if parameters.type != null:
  if tile.type != parameters.type:
   return false

 if parameters.harmful != null:
  if tile.has_harmful_status() != parameters.harmful:
   return false

 if parameters.include_effects != null:
  if not tile.has_any_effect(PackedStringArray(parameters.include_effects)):
   return false

 if parameters.must_include_effects != null:
  if not tile.has_all_effects(PackedStringArray(parameters.must_include_effects)):
   return false

 if parameters.exclude_effects != null:
  if tile.has_any_effect(PackedStringArray(parameters.exclude_effects)):
   return false

 if parameters.only_effects != null:
  if not tile.has_only_effects(PackedStringArray(parameters.only_effects)):
   return false

 if parameters.face != null:
  if parameters.face not in tile.faces:
   return false

 if parameters.letters != null:
  if not tile.has_any_letter(parameters.letters):
   return false

 if parameters.exclude_letters != null:
  if tile.has_any_letter(parameters.exclude_letters):
   return false

 if parameters.single_letter:
  if not tile.is_single_letter():
   return false

 var num_faces = tile.faces.size()
 if num_faces > parameters.max_faces or num_faces < parameters.min_faces:
  return false

 if parameters.has_face != null and tile.has_face() != parameters.has_face:
  return false

 if parameters.is_playable != null and tile.is_playable() != parameters.is_playable:
  return false

 if parameters.in_word != null and tile.in_word() != parameters.in_word:
  return false

 return true


func get_preview_tiles():
 return queue.get_tiles(false, max(preview_rows, 1))


func get_tile_coords(tile):
 return tile_map.find_key(tile)


func set_tile_coords(tile: Tile, coord: Vector2i) -> void :
 var previous_coord = get_tile_coords(tile)
 if previous_coord != null:
  tile_map.erase(previous_coord)
 elif not tile.updated.is_connected(_on_tile_updated):
  tile.updated.connect(_on_tile_updated)
  tile.board_state_changed.connect(_on_tile_board_state_changed)

 tile_map[coord] = tile
 tile.update_z_index()


func swap_coords(coord_a: Vector2i, coord_b: Vector2i, settle: = true, settle_duration: = 0.08, settle_grid_duration: = 0.16) -> void :
 var swap = null
 if coord_a in tile_map:
  swap = tile_map[coord_a]

 if coord_b in tile_map:
  tile_map[coord_a] = tile_map[coord_b]

 if swap:
  tile_map[coord_b] = swap

 if settle:
  await settle_board(false, settle_duration, settle_grid_duration)


func swap_tiles(tile_a: Tile, tile_b: Tile, settle_duration: = 0.08, settle_grid_duration: = 0.16) -> void :
 await swap_coords(get_tile_coords(tile_a), get_tile_coords(tile_b), false)

 tile_a.tween_to_board(tile_a.get_settle_duration(settle_duration, settle_grid_duration))
 tile_b.tween_to_board(tile_b.get_settle_duration(settle_duration, settle_grid_duration))

 await wait_for_idle_tiles()

 update_state()
 tiles_changed.emit()


func get_tile_at(coords: Vector2i, allow_in_word: bool = true) -> Tile:
 if coords in tile_map:
  if not allow_in_word and tile_map[coords].in_word():
   return null

  return tile_map[coords]
 else:
  return null


func get_blank_spaces() -> Array[BoardBlankSpaceFocus]:
 var blank_spaces: Array[BoardBlankSpaceFocus] = []
 blank_spaces.assign(blank_space_focus_container.get_children())
 return blank_spaces


func get_blank_space_at(coords: Vector2i) -> BoardBlankSpaceFocus:
 for blank_space: BoardBlankSpaceFocus in blank_space_focus_container.get_children():
  if blank_space.coord == coords:
   return blank_space

 return null


func get_tile_or_blank_space_at(coords: Vector2i, allow_in_word: bool = true) -> Variant:
 var tile: = get_tile_at(coords, allow_in_word)
 if tile != null:
  return tile

 return get_blank_space_at(coords)


func get_neighbor_tile(coords: Vector2i, direction: Vector2i, wrap_around: bool = false, allow_in_word: bool = true, wrap_add: Vector2i = Vector2i.ZERO) -> Tile:
 var check_coords: = optional_wrap_coords(coords + direction, wrap_around, wrap_add)
 return get_tile_at(check_coords, allow_in_word)


func get_neighbor_tile_or_blank(coords: Vector2i, direction: Vector2i, wrap_around: bool = false, allow_in_word: bool = true, wrap_add: Vector2i = Vector2i.ZERO) -> Variant:
 var check_coords: = optional_wrap_coords(coords + direction, wrap_around, wrap_add)
 return get_tile_or_blank_space_at(check_coords, allow_in_word)


func get_neighbor_tile_collision_or_blank(coords: Vector2i, direction: Vector2i, wrap_around: bool = false, allow_in_word: bool = true, wrap_add: Vector2i = Vector2i.ZERO) -> Control:
 var neighbor: Variant = get_neighbor_tile_or_blank(coords, direction, wrap_around, allow_in_word, wrap_add)
 if neighbor != null and neighbor is Tile:
  return neighbor.tile_collision

 return neighbor


func drop_from_coords(coords):
 var check_coord = coords + Vector2i(0, -1)
 while check_coord.y > -1:
  if check_coord in tile_map:
   return check_coord + Vector2i(0, 1)

  check_coord.y -= 1

 return check_coord + Vector2i(0, 1)


func calculate_crit_bonus(word_lists: Array[WordList]) -> float:
 var player_crit_chance: Dictionary = Game.player.get_crit_chance()
 if player_crit_chance.BONUS_PER_LETTER <= 0.0:
  return 0.0

 var total_crit_bonus: = 0.0

 for word_list in word_lists:
  var bonus_length = (word_list.maximum_length - player_crit_chance.MINIMUM_WORD_LENGTH)
  var crit_bonus: float = bonus_length * player_crit_chance.BONUS_PER_LETTER
  crit_bonus = maxf(0.0, crit_bonus)
  total_crit_bonus += crit_bonus

 return total_crit_bonus


func calculate_added_crit_chance(bonus: float) -> float:
 var player_crit_chance = Game.player.get_crit_chance()
 var new_crit_chance: = clampf(crit_chance + bonus, player_crit_chance.MIN, player_crit_chance.MAX)
 var snapped_chance: = snappedf(new_crit_chance, 0.0001)
 return snapped_chance




func add_crit_bonus(word_lists: Array[WordList]):
 var prev_crit_chance = crit_chance
 var bonus: = calculate_crit_bonus(word_lists)
 add_crit_chance(bonus)

 if Bridge.is_debug_build():
  var debug_string = "Crit odds: " + str(prev_crit_chance * 100) + "%"
  if bonus > 0:
   debug_string += " + " + str(bonus * 100) + "%"
   debug_string += " = " + str(crit_chance * 100) + "%"

  print(debug_string)


func add_crit_chance(chance: float) -> void :
 crit_chance = calculate_added_crit_chance(chance)


func roll_crit() -> bool:
 if crit_chance <= 0.0:
  return false

 var player_crit_chance = Game.player.get_crit_chance()

 if rng.crit.randf() <= crit_chance:
  crit_chance = clampf(crit_chance / player_crit_chance.DIVIDE_BY, player_crit_chance.MIN, player_crit_chance.MAX)
  if "CUTOFF" in player_crit_chance and crit_chance < player_crit_chance.CUTOFF:
   crit_chance = player_crit_chance.MIN

  return true
 else:
  return false


func fill_board(instant = false):
 if prevent_filling:
  return


 if restock_locked and not instant:
  return

 prepare_queue()
 fill_queue()

 var immediate_queued_tiles = queue.get_tiles(true)
 rng.fill.shuffle(immediate_queued_tiles)
 for queued_tile in immediate_queued_tiles:
  if "as_save" in queued_tile:
   continue

  if "type" not in queued_tile:
   queued_tile.type = pop_from_bag()

  var has_non_shared_status: bool = false
  if "statuses" in queued_tile:
   for status in queued_tile.statuses:
    if Status.status_is_exclusive(status):
     has_non_shared_status = true

  var coord: = queue.get_queued_tile_coord(queued_tile)
  if coord.x in doomed_columns or main.tutorial.active:
   continue

  if ( not has_non_shared_status or "can_crit" in queued_tile) and not Game.player.crits_are_wildcards() and roll_crit():
   queued_tile.get_or_add("statuses", []).append(TileStatus.CRIT)
   AchievementManager.rolled_crit()

 queue.clear_targeted_coords()

 is_restocking = true
 update_state()

 var shuffled_indices = range(num_columns)
 shuffled_indices.shuffle()
 var last_index = shuffled_indices[-1]

 var columns_to_fill = {}
 for x in shuffled_indices:
  var needed_tiles: = get_column_needed_tiles(x)
  if needed_tiles > 0:
   columns_to_fill[x] = needed_tiles
   filling_columns += 1

 for x in columns_to_fill:
  var needed_tiles = columns_to_fill[x]
  _fill_column(x, needed_tiles, instant)
  if not instant and x != last_index:
   await Game.timeout(0.16)

 if filling_columns > 0:
  await all_columns_filled

 await wait_for_idle_tiles()
 is_restocking = false

 update_state()
 tiles_changed.emit()


func _fill_column(x, needed_tiles, instant = false):
 for i in needed_tiles:
  _add_tile_at(x, true, instant)

  if not instant:
   await Game.timeout(0.2)

 filling_columns -= 1

 await wait_for_idle_tiles()


func create_tile() -> Tile:
 return tile_scene.instantiate()


func _add_tile_at(column, update = true, instant = false):
 var tile = create_tile()
 var queued_tile = queue.pop_queue(column)
 update_previews()
 var initial_coords = Vector2i(column, num_rows)

 tile_mask.add_child(tile)

 var tile_coord = drop_from_coords(initial_coords)
 set_tile_coords(tile, tile_coord)

 tile.load_save_data(queued_tile, false)

 if instant:
  tile.global_position = get_coord_position(tile_coord)
 else:
  tile.global_position = get_coord_position(initial_coords)

 if instant:
  tile.settle(0, 0)
 else:
  tile.settle()

 if update:
  update_state()
  tiles_changed.emit()


func insert_tile(tile, coord, settle: = true) -> Tile:
 var old_tile = get_tile_at(coord)

 if tile.get_parent() == null:
  tile_mask.add_child(tile)
 else:
  tile.reparent(tile_mask)

 if old_tile != null:
  _replace_tile(old_tile, tile)
  return old_tile

 tile.rotation = 0.0
 set_tile_coords(tile, coord)
 tile.global_position = get_coord_position(coord)

 if settle:
  _settle_tile(tile)

 return tile


func _replace_tile(old_tile, new_tile):

 if old_tile.is_indestructible():
  launch_tile(new_tile)
  return

 old_tile.copy_tile(new_tile)
 new_tile.clear()


func launch_tile(tile: Tile, fixed_direction: int = 0, launch_multiplier: float = 1.0):
 var bounce_offset = randf_range(24, 64)
 bounce_offset *= launch_multiplier

 if fixed_direction != 0:
  bounce_offset *= fixed_direction
 elif randi_range(0, 1) == 0:
  bounce_offset = - bounce_offset

 var dest = Vector2(tile.global_position.x + bounce_offset, 290)
 tile.launch(tile.global_position, dest, 32, Vector2i.MIN, 800, true, false, false)


func pop_tile(tile: Tile, fixed_direction: int = 0, launch_multiplier: float = 1.0):
 tile_map.erase(get_tile_coords(tile))
 launch_tile(tile, fixed_direction, launch_multiplier)



func remove_tile(tile, parameters = {}):
 await remove_tiles([tile], parameters)



func remove_tiles(tiles, parameters = {}):
 var default_parameters = {
  interval = null, 
  poof_color = null, 
  poof_blend = null, 
  settle = true, 
  restock = true, 
  tile_color = false, 
  ignore_status = false, 
  delete_tiles = true, 
  sound = null, 
 }
 parameters.merge(default_parameters)

 is_removing = true
 update_state()

 var index = 0
 var last_index = tiles.size() - 1

 for tile: Tile in tiles:
  if not tile.is_indestructible() or parameters.ignore_status:
   tile_map.erase(get_tile_coords(tile))
   if tile.updated.is_connected(_on_tile_updated):
    tile.updated.disconnect(_on_tile_updated)
    tile.board_state_changed.disconnect(_on_tile_board_state_changed)

  if tile.has_status(TileStatus.BOMB) and not parameters.ignore_status:
   var bomb_status = tile.get_status(TileStatus.BOMB)
   if not bomb_status.is_exploded:
    await bomb_status.explode()

  elif not tile.is_indestructible() or parameters.ignore_status:
   if parameters.sound != null:
    AudioManager.play_sound(parameters.sound)

   var poof_color = parameters.poof_color
   if parameters.tile_color:
    poof_color = tile.get_color()

   if poof_color != null:
    tile.add_poofcloud(poof_color, parameters.poof_blend, false)

  if tile.is_indestructible() and not parameters.ignore_status:
   tile.animation.play("shake")
  elif parameters.delete_tiles:
   tile.clear(false)

  if parameters.interval != null and index != last_index:
   if parameters.interval is Array:
    var rand_interval = randf_range(parameters.interval[0], parameters.interval[1])
    await Game.timeout(rand_interval)
   else:
    await Game.timeout(parameters.interval)

  index += 1

 if parameters.settle:
  await settle_board()

 if parameters.restock:
  await fill_board()

 is_removing = false
 tiles_changed.emit()
 update_state()


func remove_tile_at(coords):
 var tile = get_tile_at(coords)
 if tile:
  await remove_tile(tile)


func get_coord_position(coord, local: = false):
 var adjusted_column = (num_rows - 1) - coord.y
 if local:
  return get_top_left_tile_local_position() + Vector2(coord.x * GRID_SIZE, adjusted_column * GRID_SIZE)
 else:
  return get_top_left_tile_position() + Vector2(coord.x * GRID_SIZE, adjusted_column * GRID_SIZE)


func get_coord_status(coords):
 if coords in coord_statuses:
  return coord_statuses[coords]
 else:
  return null


func set_coord_status(coords, status):
 if status == null:
  coord_statuses.erase(coords)
 else:
  coord_statuses[coords] = status

 if status != null:
  board.add_child(status)
  status.global_position = get_coord_position(coords)


func get_status_coord(status):
 return coord_statuses.find_key(status)


func get_targeted_coords():
 return coord_statuses.values()


func clear_targets():
 var targets = get_targeted_coords()

 for target in targets:
  var coord = get_status_coord(target)
  set_coord_status(coord, null)
  target.clear()


func clear_coord_statuses():
 for coords in coord_statuses:
  clear_coord_status(coords)


func clear_coord_status(coords):
 if coords in coord_statuses:
  board.remove_child(coord_statuses[coords])
  coord_statuses[coords].queue_free()
  coord_statuses.erase(coords)


func reroll_board():
 var all_tiles = get_tiles({sorted = true, exclude_effects = [TileStatus.ETERNAL]})
 await remove_tiles(all_tiles, {restock = false, ignore_status = true})
 pregenerate(Game.balance.reroll_defense)
 await fill_board(true)


 var tile_groups = get_tiles({
  row_priority = get_row_coords(true), 
  column_priority = get_column_coords(), 
  sorted = true, 
  group_by_priority = true
 })

 for tiles in tile_groups:
  for tile in tiles:
   tile.animation.play("reroll")

  if tiles != tile_groups[-1]:
   await Game.timeout(0.04)

 await Game.timeout(TURN_END_STEP_DELAY)

 update_state()
 rerolled_board.emit()
 tiles_changed.emit()


func _settle_tile(tile: Tile, base_duration = 0.08, per_grid_duration = 0.16):
 if tile.can_fall():
  var current_coords = get_tile_coords(tile)
  var dropped_coords = drop_from_coords(current_coords)
  if dropped_coords != current_coords:
   set_tile_coords(tile, dropped_coords)

 tile.settle(base_duration, per_grid_duration)


func _settle_column(x, base_duration = 0.08, per_grid_duration = 0.16):
 var tiles = get_tiles({columns = [x], sorted = true, reverse_sorted = true})
 for tile in tiles:
  _settle_tile(tile, base_duration, per_grid_duration)


func settle_board(instant = false, base_duration = 0.08, per_grid_duration = 0.16):
 board_state_recently_changed = false
 is_settling = true
 update_state()

 for x in range(num_columns):
  if instant:
   _settle_column(x, 0, 0)
  else:
   _settle_column(x, base_duration, per_grid_duration)

 await wait_for_idle_tiles()

 is_settling = false
 update_state()


func turn_end(reroll = false):
 turn_ended.emit()

 rng.fill.reseed(rng.fill_gen)
 rng.crit.reseed(rng.fill_gen)

 await wait_for_idle_tiles()
 await wait_for_idle()

 await trigger_linked()
 await trigger_coal()
 await trigger_ash()
 await trigger_gay()
 await trigger_poison()
 await trigger_haze()
 await trigger_bleed()
 await trigger_cursed()
 await trigger_eternal()
 await trigger_bomb()
 await trigger_acid()
 await trigger_bottom_acid_tiles(true)
 await trigger_spicy()
 await trigger_frozen()
 await trigger_poop()
 await trigger_screw()

 if reroll:
  await reroll_board()
 else:
  await fill_board()

 await wait_for_idle()


func enemy_turn_end():
 await trigger_bottom_acid_tiles(false)

 if restock_locked and not restock_just_locked:
  lock_amount -= 1
  if lock_amount == 0:
   unlock_restock()

 restock_just_locked = false

 await fill_board()


func battle_end():
 await trigger_eternal_remove()
 await fill_board()
 await wait_for_idle()


func trigger_linked():
 var linked_tiles = get_tiles({include_effects = [TileStatus.LINKED]})

 if linked_tiles.is_empty():
  return

 for tile in linked_tiles:
  var linked_status = tile.get_status(TileStatus.LINKED)
  linked_status.turns -= 1
  if linked_status.turns == 0:
   AudioManager.play_sound(Sounds.TILE.LINKED)
   tile.add_poofcloud(Globals.COLORS.SMOKE, null, false)
   tile.remove_status(TileStatus.LINKED)

  if tile != linked_tiles[-1]:
   await Game.timeout(0.08)

 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_coal():
 var coal_tiles = get_tiles({include_effects = [TileStatus.COAL]})
 var expired_coal = []

 if coal_tiles.is_empty():
  return

 for tile in coal_tiles:
  var coal_status = tile.get_status(TileStatus.COAL)

  coal_status.turns -= 1

  if coal_status.turns == 0:
   expired_coal.append(tile)
  else:
   tile.animation.play("shake")
   tile.add_poofcloud(tile.get_color())
   tile.update()
   await Game.timeout(0.08)

 await remove_tiles(expired_coal, {
  interval = 0.08, 
  restock = false, 
  tile_color = true, 
  sound = Sounds.TILE.COAL_CRUMBLE, 
 })
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_ash():
 var ash_tiles = get_tiles({include_effects = [TileStatus.ASH]})

 if ash_tiles.is_empty():
  return

 await remove_tiles(ash_tiles, {
  interval = 0.08, 
  restock = false, 
  tile_color = true, 
  sound = Sounds.TILE.ASH, 
 })
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_gay():
 var gay_tiles = get_tiles({include_effects = [TileStatus.GAY]})

 if gay_tiles.is_empty():
  return

 await remove_tiles(gay_tiles, {
  interval = 0.08, 
  restock = false, 
  tile_color = true, 
  sound = Sounds.TILE.ASH, 
 })
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_poop():
 var poop_tiles = get_tiles({include_effects = [TileStatus.POOP]})

 if poop_tiles.is_empty():
  return

 for tile in poop_tiles:
  AudioManager.play_sound(Sounds.TILE.TARNISHED)
  tile.add_poofcloud(tile.get_color(), null, false)
  tile.remove_status(TileStatus.POOP)

  if tile != poop_tiles[-1]:
   await Game.timeout(0.08)

 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_poison():
 var poison_tiles = get_tiles({include_effects = [TileStatus.POISON]})

 if poison_tiles.is_empty():
  return

 var poison_damage = 0
 for tile in poison_tiles:
  poison_damage += tile.get_status(TileStatus.POISON).get_status_value()

 await remove_tiles(poison_tiles, {
  interval = 0.08, 
  restock = false, 
  tile_color = true, 
  sound = Sounds.TILE.POISON, 
 })
 Game.player.hurt(poison_damage)
 word_builder.remove_intent(Globals.Intent.POISON)
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_haze():
 var haze_tiles = get_tiles({include_effects = [TileStatus.HAZE]})

 if haze_tiles.is_empty():
  return

 var haze_damage = 0
 for tile in haze_tiles:
  haze_damage += Game.balance.bleed_damage

 await remove_tiles(haze_tiles, {
  interval = 0.08, 
  restock = false, 
  tile_color = true, 
  sound = Sounds.TILE.ASH, 
 })
 Game.player.hurt(haze_damage)
 word_builder.remove_intent(Globals.Intent.HAZE)
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_bleed():
 var bleed_tiles = get_tiles({include_effects = [TileStatus.BLEED]})

 if bleed_tiles.is_empty():
  return

 var bleed_damage = 0
 for tile in bleed_tiles:
  bleed_damage += Game.balance.bleed_damage

  AudioManager.play_sound(Sounds.TILE.BLEED)
  tile.animation.play("shake")
  tile.add_poofcloud(tile.get_color(), null, false)

  if tile != bleed_tiles[-1]:
   await Game.timeout(0.08)

 await Game.timeout(0.16)
 Game.player.hurt(bleed_damage)
 word_builder.remove_intent(Globals.Intent.BLEED)
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_cursed():
 var cursed_tiles = get_tiles({include_effects = [TileStatus.CURSED]})

 if cursed_tiles.is_empty():
  return

 var cursed_damage = 0
 for tile in cursed_tiles:
  cursed_damage += tile.get_status(TileStatus.CURSED).get_status_value()

  AudioManager.play_sound(Sounds.TILE.CURSED)
  tile.animation.play("shake")
  tile.add_poofcloud(tile.get_color(), null, false)

  if tile != cursed_tiles[-1]:
   await Game.timeout(0.08)

 await Game.timeout(0.16)
 Game.player.hurt(cursed_damage)
 word_builder.remove_intent(Globals.Intent.CURSED)
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_eternal():
 var eternal_tiles = get_tiles({include_effects = [TileStatus.ETERNAL]})

 if eternal_tiles.is_empty():
  return

 var harming_eternal_tiles: Array[Tile] = []
 for tile in eternal_tiles:
  var status: Status = tile.get_status(TileStatus.ETERNAL)
  if status.played_this_turn:
   status.played_this_turn = false
  else:
   harming_eternal_tiles.append(tile)

 if harming_eternal_tiles.is_empty():
  return

 var eternal_damage = 0
 for tile in harming_eternal_tiles:
  eternal_damage += tile.get_status(TileStatus.ETERNAL).get_status_value()

  AudioManager.play_sound(Sounds.TILE.ETERNAL)
  tile.animation.play("shake")
  tile.add_poofcloud(tile.get_color(), null, false)

  if tile != harming_eternal_tiles[-1]:
   await Game.timeout(0.08)

 await Game.timeout(0.16)
 Game.player.hurt(eternal_damage)
 word_builder.remove_intent(Globals.Intent.ETERNAL)
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_eternal_remove():
 var eternal_tiles = get_tiles({include_effects = [TileStatus.ETERNAL]})

 if eternal_tiles.is_empty():
  return

 await remove_tiles(eternal_tiles, {
  interval = 0.08, 
  restock = false, 
  ignore_status = true, 
  tile_color = true, 
  sound = Sounds.TILE.ETERNAL, 
 })
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_bomb():
 var bomb_tiles = get_tiles({include_effects = [TileStatus.BOMB]})
 var exploded_bombs = []

 if bomb_tiles.is_empty():
  return

 var play_addict_stop: = false
 var exploding_bombs = []
 if Game.player.id == Globals.CHARACTERS.ADDICT and Game.player.defense == 0:
  var bomb_damage: int = 0
  for tile in bomb_tiles:
   var bomb_status = tile.get_status(TileStatus.BOMB)
   if bomb_status.turns == 1:
    bomb_damage = maxi(bomb_damage, bomb_status.get_status_value())
    exploding_bombs.append(tile)

  if exploding_bombs.size() >= 3:
   play_addict_stop = true

 var played_warning: = false
 for tile in bomb_tiles:
  var bomb_status = tile.get_status(TileStatus.BOMB)

  bomb_status.turns -= 1

  if bomb_status.turns == 0:
   await bomb_status.explode(play_addict_stop and tile == exploding_bombs[1])
   exploded_bombs.append(tile)
  elif bomb_status.turns == 1 and not played_warning:
   played_warning = true
   AudioManager.play_sound(Sounds.TILE.BOMB_WARNING)

 if not exploded_bombs.is_empty():
  await remove_tiles(exploded_bombs, {restock = false})
  word_builder.remove_intent(Globals.Intent.BOMB)

 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_acid():
 var target_tiles = []
 var target_bombs = []

 for tile: Tile in get_tiles({include_effects = [TileStatus.ACID]}):
  if not tile.can_fall():
   continue

  var below_tile = tile.get_board_neighbor(Vector2i(0, -1))

  if not (below_tile == null or below_tile.has_status(TileStatus.ACID)):
   if below_tile.has_status(TileStatus.BOMB):
    target_bombs.append(below_tile)
   else:
    target_tiles.append(below_tile)

 if target_tiles.is_empty() and target_bombs.is_empty():
  return

 for tile in target_bombs:
  await remove_tile(tile, {restock = false})

 AudioManager.play_sound(Sounds.TILE.ACID_MELT)

 await remove_tiles(target_tiles, {restock = false})
 await wait_for_idle()
 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_spicy():
 var spicy_tiles = get_tiles({include_effects = [TileStatus.SPICY]})

 if spicy_tiles.is_empty():
  return

 for tile in spicy_tiles:
  AudioManager.play_sound(Sounds.TILE.BURNING_BURN_OUT)
  tile.add_poofcloud(tile.get_color(), Globals.COLORS.COAL, false)
  tile.add_status(TileStatus.COAL)

  if tile != spicy_tiles[-1]:
   await Game.timeout(0.08)

 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_frozen():
 var frozen_tiles = get_tiles({include_effects = [TileStatus.FROZEN]})

 if frozen_tiles.is_empty():
  return

 for tile in frozen_tiles:
  AudioManager.play_sound(Sounds.TILE.FROZEN)
  tile.add_poofcloud(Globals.COLORS.ICE, null, false)
  tile.remove_status(TileStatus.FROZEN)

  if tile != frozen_tiles[-1]:
   await Game.timeout(0.08)

 await Game.timeout(TURN_END_STEP_DELAY)


func trigger_screw():
 var screw_tiles = get_tiles({include_effects = [TileStatus.SCREW]})
 var tiles_needing_screwing: Array[Tile] = []
 for tile: Tile in screw_tiles:
  var status: ScrewStatus = tile.get_status(TileStatus.SCREW)
  if status.turns > 0:
   tiles_needing_screwing.append(tile)

 if tiles_needing_screwing.is_empty():
  return

 for tile in tiles_needing_screwing:
  var status: ScrewStatus = tile.get_status(TileStatus.SCREW)
  status.set_turns(status.turns - 1)
  if status.turns == 0:
   AudioManager.play_sound(Sounds.SPELLS.SCREW_HIGH_PITCH)

  if tile != tiles_needing_screwing[-1]:
   await Game.timeout(0.08)

 await Game.timeout(TURN_END_STEP_DELAY)


func is_idle():
 if is_removing or is_restocking or is_settling or is_removing_acid:
  return false

 return true


func wait_for_idle():
 while not is_idle():
  await state_updated


func wait_for_idle_tiles():
 for tile in get_tiles({sorted = true}):
  while tile != null and is_instance_valid(tile) and not tile.is_idle():
   await tile.state_updated


func lock_restock(turns = 1, instant: bool = false):
 restock_just_locked = true
 lock_amount = turns
 fade_previews(instant)

 for child in %Chains.get_children():
  if child is Sprite2D:
   if preview_rows == 0:
    child.texture = small_chain_texture
   else:
    child.texture = big_chain_texture

 chain_anim_player.play_advance("chain_board", instant)


func unlock_restock(instant_preview: = false):
 lock_amount = 0
 fade_previews_in(instant_preview)
 chain_anim_player.play("RESET")


func update_state():
 idle = is_idle()
 state_updated.emit()
 main.game_state_updated.emit()


func update_tiles():
 for tile in get_tiles({sorted = true}):
  tile.update()


func reset_tiles(do_preview = false):
 await remove_tiles(get_tiles({sorted = true}), {
  restock = false, 
  ignore_status = true, 
 })

 if do_preview:
  queue.clear()


func reset():
 await reset_tiles()
 clear_coord_statuses()


func add_flag(flag: String) -> void :
 if not flag in flags:
  flags.append(flag)


func has_flag(flag: String) -> bool:
 return flag in flags


func remove_flag(flag: String) -> void :
 if flag in flags:
  flags.erase(flag)


func get_tiles_save_data():
 var save_tiles = {}
 for coord in tile_map:
  var tile = tile_map[coord]
  save_tiles[coord] = tile.get_save_data()

 return save_tiles


func load_tiles_save_data(save_tiles, parent_to_mask = false):
 for coord in save_tiles:
  var tile = create_tile()
  if parent_to_mask:
   tile_mask.add_child(tile)
  else:
   main.tile_container.add_child(tile)

  var tile_data = save_tiles[coord]
  set_tile_coords(tile, coord)
  tile.load_save_data(tile_data)

 for tile in get_tiles():
  tile.global_position = tile.get_coords_position()


func get_size_save_data(include_restock_depth: = false):
 var save = {
  columns = num_columns, 
  rows = num_rows, 
  preview_rows = preview_rows
 }

 if include_restock_depth:
  save.restock_depth = restock_depth

 return save


func load_size_save_data(save):
 set_size(save.columns, save.rows, save.preview_rows, save.get("restock_depth", null), true)


func get_tile_state_save_data(include_restock_depth: = false):
 return {
  size = get_size_save_data(include_restock_depth), 
  queue = queue.get_save_data(), 
  tiles = get_tiles_save_data(), 
 }


func load_tile_state_save_data(save, parent_to_mask: = false, needs_reset: = true):
 if needs_reset:
  await reset_tiles()

 load_size_save_data(save.size)

 queue.load_save_data(save.queue)
 update_previews()

 load_tiles_save_data(save.tiles, parent_to_mask)


func get_save_data():
 var save = {
  size = get_size_save_data(true), 
  queue = queue.get_save_data(), 
  tiles = get_tiles_save_data(), 
  flags = flags, 
  coord_statuses = {}, 
  defense_bag = defense_bag, 
  lock_amount = lock_amount, 
  crit_chance = crit_chance, 
  prevent_filling = prevent_filling, 
  stay_off_screen = stay_off_screen, 
  rng = RNG.get_rng_group_save(rng), 
 }

 for coords in coord_statuses:
  var status = coord_statuses[coords]
  save.coord_statuses[coords] = status.scene_file_path

 return save


func load_save_data(save):
 RNG.load_rng_group_save(rng, save.rng)

 crit_chance = save.crit_chance
 defense_bag = save.defense_bag
 lock_amount = save.lock_amount
 prevent_filling = save.get("prevent_filling", false)
 stay_off_screen = save.get("stay_off_screen", false)
 flags = save.flags

 anim_player.play_advance("RESET")

 reset()
 load_tile_state_save_data(save, false, false)

 if restock_locked:
  lock_restock(lock_amount, true)

 for coords in save.coord_statuses:
  var status = load(save.coord_statuses[coords]).instantiate()
  set_coord_status(coords, status)


func tween_acid_tile(tile: Tile, fall_by: Vector2, counter: Counter) -> void :
 tile.reparent(tile_mask)
 tile.set_state(Tile.State.REMOVING)
 tile.z_index += 50

 var target_pos = tile.global_position + fall_by
 var grid_distance = (target_pos.y - tile.global_position.y) / GRID_SIZE
 var duration = 0.08 + grid_distance * 0.16
 await tile.tween_position(target_pos, duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, Tile.State.REMOVING, false)
 AchievementManager.acid_fell()
 tile.queue_free()
 counter.decrement()


func trigger_bottom_acid_tiles(no_restock: = false):
 if not is_idle():
  return

 var falling_acid_tiles: Array[Tile] = []
 var tiles_by_column: Dictionary[int, Array] = {}
 var highest_in_column: Dictionary[int, int] = {}
 var check_columns = range(num_columns) as Array[int]
 for check_row in num_rows:
  var row_acid_tiles = get_tiles({include_effects = [TileStatus.ACID], rows = [check_row], columns = check_columns})
  if row_acid_tiles.is_empty():
   break

  var next_columns: Array[int] = []
  for tile: Tile in row_acid_tiles:
   if not tile.can_fall():
    continue

   falling_acid_tiles.append(tile)
   var column: int = tile.get_coord().x
   if column not in tiles_by_column:
    tiles_by_column[column] = []

   tiles_by_column[column].append(tile)
   highest_in_column[column] = check_row
   next_columns.append(column)

  check_columns = next_columns

 if falling_acid_tiles.is_empty():
  return

 is_removing_acid = true
 update_state()

 remove_tiles(falling_acid_tiles, {restock = false, delete_tiles = false, settle = false})

 var acid_damage: int = 0
 var counter: = Counter.new(falling_acid_tiles.size())
 for column in tiles_by_column:
  var fall_distance: float = (highest_in_column[column] + 1) * GRID_SIZE
  var fall_by: = Vector2(0.0, fall_distance + 2.0)
  var tiles: Array = tiles_by_column[column]
  for tile: Tile in tiles:
   acid_damage += tile.get_status(TileStatus.ACID).get_status_value()
   tween_acid_tile(tile, fall_by, counter)

 await settle_board()
 await counter.pend_finished()

 Game.player.hurt(acid_damage, Globals.DamageType.PIERCING)

 if is_removing_acid:
  if no_restock:
   word_builder.remove_intent(Globals.Intent.ACID)
   await Game.timeout(TURN_END_STEP_DELAY)
   is_removing_acid = false
   update_state()
  else:
   is_removing_acid = false
   update_state()
   await fill_board()


func create_preview_tile(from_tile = null) -> Tile:
 var tile = create_tile()
 tile.is_preview = true


 main.add_child(tile)

 if from_tile:
  tile.copy_tile(from_tile)

 return tile




func letter_exists(letter):
 return letter in get_letter_census()


func get_absent_suits(suit_rng: RNG, count: int = 1):
 var suits = Letters.WILDCARD_GROUPS.keys()
 var board_suits = get_tiles({
  sorted = true, 
  include_effects = [TileEffect.SUIT]
 })

 var available_suits = suits.duplicate()
 for tile: Tile in board_suits:
  for i in range(available_suits.size() - 1, -1, -1):
   var suit = available_suits[i]
   if tile.has_any_letter(suit):
    available_suits.remove_at(i)

 var needed_suits = count - available_suits.size()
 if needed_suits > 0:
  var add_suits = suits.duplicate()
  for suit in available_suits:
   add_suits.erase(suit)

  suit_rng.shuffle(add_suits)
  available_suits.append_array(add_suits.slice(0, needed_suits))

 suit_rng.shuffle(available_suits)
 return available_suits


func settle_board_if_state_changed() -> void :
 if board_state_recently_changed:
  await Game.word_builder.remove_tiles()
  await wait_for_idle_tiles()
  await settle_board()
  await fill_board()


func _on_tiles_changed():
 tiles_updated.emit()


func _on_tile_updated():
 tiles_updated.emit()


func _on_tile_board_state_changed() -> void :
 board_state_recently_changed = true


func _on_panel_generate_tooltip(tooltip) -> void :
 tooltip.add_subtooltip(
  StringManager.get_string("misc/restock_lock/title"), 
  StringManager.get_string("misc/restock_lock/description")
 )


func _on_tooltip_collision_check_generate_tooltip(tooltip_collision: Variant) -> void :
 tooltip_collision.enabled = restock_locked
