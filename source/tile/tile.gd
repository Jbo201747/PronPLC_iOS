@static_unload
class_name Tile extends Node2D


signal updated
signal anim_flag
signal state_updated
signal impacted

signal board_state_changed


enum State{
 IDLE, 
 QUEUED, 
 MOVING, 
 SETTLING, 
 REMOVING, 
 DRAGGING, 
}

const SIDE_TO_VECTOR: Dictionary[Side, Vector2i] = {
 SIDE_TOP: Vector2i.DOWN, 
 SIDE_BOTTOM: Vector2i.UP, 
 SIDE_LEFT: Vector2i.LEFT, 
 SIDE_RIGHT: Vector2i.RIGHT, 
}

const TILE_DIM_COLOR = Color(0.85, 0.85, 0.85, 1.0)

const TileType = Globals.TileType
const TileStatus = Globals.TileStatus
const TileEffect = Globals.TileEffect

static var highlight_condition: = Callable()

@export var is_preview: = false

var face: String:
 get:
  return tile_face.face
var faces: Array[String]:
 get:
  return tile_face.faces
var wildcard_faces: Dictionary[int, String]:
 get:
  return tile_face.wildcard_faces

var type = TileType.DAMAGE
var state = State.IDLE
var statuses: Dictionary[String, Status] = {}
var processing_statuses: Array[Status] = []
var highlight_data = {}
var is_projectile = false
var shadow_enabled = true
var word_holder_hovered: = false:
 set(value):
  word_holder_hovered = value
  tile_collision.update_hover_handler_enabled()
  hover_handler.hover_for_state()
var tile_board: TileBoard = Game.tile_board

var arcing_projectile_scene = preload("res://source/effects/arcing_projectile.tscn")
var Poofcloud = preload("res://source/effects/poofcloud_small.tscn")
var BigPoofcloud = preload("res://source/effects/poofcloud.tscn")

@onready var tile_sprite: TileSprite = %TileSprite
@onready var tile_overlay_anim_player = %TileSprite.tile_overlay_anim_player
@onready var bomb_overlay = %TileSprite.bomb_overlay
@onready var tile_face: TileFace = %TileSprite.tile_face
@onready var tooltip_collision: TooltipCollision = %TooltipCollision
@onready var tile_collision: TileCollision = %TileCollision
@onready var animation = $Animation
@onready var sprite_anim_player = %TileSprite.base_sprite_anim_player
@onready var line_edit = $LineEdit
@onready var hover_container: Node2D = %HoverContainer
@onready var icicles = %TileSprite.icicles
@onready var main = Game.main
@onready var player = Game.player
@onready var word_builder = Game.word_builder
@onready var sway_handler: SwayHandler = %SwayHandler
@onready var hover_handler: HoverHandler = %HoverHandler
@onready var drag_handler: DragHandler = %DragHandler


static func is_tile_valid(tile):
 return (tile != null
  and is_instance_valid(tile)
  and not tile.is_queued_for_deletion()
  and not tile.is_removing())


static func get_focused_tile() -> Tile:
 var focus_owner: = InputManager.get_viewport().gui_get_focus_owner()
 if focus_owner is TileCollision:
  return focus_owner.tile

 return null


static func any_tile_dragging() -> bool:
 var focused_tile: = get_focused_tile()
 if focused_tile == null:
  return false

 return focused_tile.state == State.DRAGGING


static func any_other_tile_selected(tile: Tile) -> bool:
 var focused_tile: = get_focused_tile()
 return focused_tile != null and focused_tile != tile


static func tile_has_forced_focus() -> bool:
 var focused_tile: = get_focused_tile()
 if focused_tile == null:
  return false

 return not focused_tile.tile_collision.can_release_focus()

func _ready():
 tile_collision.tile = self
 tile_collision.focus_entered.connect(update_z_index)
 tile_collision.focus_exited.connect(update_z_index)

 if not is_preview:
  player.started_using_spell.connect(_on_started_using_spell)
  player.stopped_using_spell.connect(_on_stopped_using_spell)
 else:
  tooltip_collision.queue_free()

 initialize_drag()
 tile_sprite.shadow_cloner.clone_offset = hover_container
 set_shadow_visibility()


func _enter_tree() -> void :
 if is_node_ready():
  set_shadow_visibility()


func _process(delta: float) -> void :
 for status in processing_statuses:
  status._process(delta)


func set_shadow_visibility():
 if tile_board == null:
  return

 if get_parent() == tile_board.tile_mask or not shadow_enabled:
  tile_sprite.set_shadow_enabled(false)
 else:
  tile_sprite.set_shadow_enabled(true)


func disable_shadow():
 shadow_enabled = false
 set_shadow_visibility()


func enable_shadow():
 shadow_enabled = true
 set_shadow_visibility()


func make_local() -> void :
 z_as_relative = true
 tile_sprite.shadow_cloner.solid_shadow_color = Color(3298927103)
 tile_sprite.shadow_cloner.use_solid_shadow = true
 tile_sprite.shadow_cloner.local_shadow = true


func add_face(new_face: String, clear_faceless: = true, clear_mystery: = true):
 set_face(faces + [new_face], clear_faceless, clear_mystery)


func set_face(new_face: Variant, clear_faceless: = true, clear_mystery: = true):
 tile_face.set_face(new_face)

 if clear_faceless:
  clear_faceless_effects()

 if clear_mystery:
  remove_status(TileStatus.MYSTERY)

 update()


func set_slashed(slashed_faces: PackedStringArray) -> void :
 tile_face.set_slashed_faces(slashed_faces)
 tile_face.set_face("/", true)
 update()


func set_current_face(new_face, clear_faceless = true, clear_mystery: = true):
 set_face_at(tile_face.face_index, new_face, clear_faceless, clear_mystery)


func set_face_at(index, new_face, clear_faceless = true, clear_mystery: = true):
 var changed_faces = faces.duplicate()
 changed_faces[index] = new_face
 set_face(changed_faces, clear_faceless, clear_mystery)


func copy_face(other_tile: Tile) -> void :
 if other_tile.face == "/":
  clear_faceless_effects()
  set_slashed(other_tile.tile_face.slashed_faces.duplicate())
 else:
  set_face(other_tile.faces, true)


func swap_face(other_tile: Tile) -> void :
 var was_slashed: bool = false
 var slashed_faces: PackedStringArray
 var old_faces: Array
 if face == "/":
  was_slashed = true
  slashed_faces = tile_face.slashed_faces.duplicate()
 else:
  old_faces = faces.duplicate()

 copy_face(other_tile)
 swap_statuses(other_tile, get_face_statuses() + other_tile.get_face_statuses())
 if was_slashed:
  other_tile.set_slashed(slashed_faces)
 else:
  other_tile.set_face(old_faces, true)


func copy_statuses(other_tile: Tile, statuses_to_copy: Array) -> void :
 for id in statuses_to_copy:
  if other_tile.has_status(id):
   add_status(id)
  else:
   remove_status(id)


func swap_statuses(other_tile: Tile, statuses_to_swap: Array) -> void :
 var a_statuses: Array[String] = []
 var b_statuses: Array[String] = []
 for id: String in statuses_to_swap:
  if has_status(id) and id not in a_statuses:
   a_statuses.append(id)

  if other_tile.has_status(id) and id not in b_statuses:
   b_statuses.append(id)

 for id: String in statuses_to_swap:
  if id in a_statuses:
   other_tile.add_status(id)
  else:
   other_tile.remove_status(id)

  if id in b_statuses:
   add_status(id)
  else:
   remove_status(id)


func clear_faceless_effects():
 for status in get_statuses():
  if status.is_faceless():
   remove_status(status.id)


func is_single_letter(allow_all_wildcards = true, allow_only_numbers = false):
 if not has_face() or faces.size() > 1 or len(face) > 1 or has_effect(TileEffect.SLASHED):
  return false

 if allow_all_wildcards:
  return true
 elif allow_only_numbers and face in Letters.NUMPAD_CHARACTERS:
  return true
 elif face not in Letters.ALPHABET:
  return false

 return true


func is_shimmering():
 if faces.size() > 1:
  return true

 return false


func only_face_is(check_face):
 if not has_face():
  return false

 if faces.size() > 1:
  return false

 if check_face is Array:
  return faces[0] in check_face
 else:
  return faces[0] == check_face


func has_face():
 return not has_faceless_status()


func get_random_safe_letter(rng = Game.random, exclude_letters = []):
 if has_status(TileStatus.CAPITAL):
  return Letters.get_random_capital_letter(rng, exclude_letters)
 elif has_status(TileStatus.PERIOD):
  return Letters.get_random_period_letter(rng, exclude_letters)
 else:
  return Letters.get_random_letter(tile_board.get_letter_census(), rng, exclude_letters)


func randomize_face(exclude_letters = [], rng = Game.random, clear_mystery: = true):
 set_face(get_random_safe_letter(rng, exclude_letters), true, clear_mystery)


func count_wildcards() -> int:
 var num_wildcards: = 0
 for letter in face:
  if letter == "*" or letter in Letters.WILDCARD_GROUPS:
   num_wildcards += 1

 return num_wildcards


func randomize_similar_face(rng = Game.random):
 if has_status(TileStatus.MYSTERY) or face.count("*") == len(face):
  return

 if is_shimmering():
  apply_shimmering(null, "".join(PackedStringArray(faces)), rng)
 elif has_effect(TileEffect.SLASHED):
  apply_slashed(rng)

 elif face in Letters.NUMPAD_CHARACTERS:
  set_face(Letters.get_random_number(rng, face))

 elif face in Letters.ALPHABET:
  randomize_face([face], rng)

 elif face in Letters.SUITS:
  var suits: = Letters.SUITS.duplicate()
  suits.erase(face)
  set_face(rng.pick_random(suits))

 elif len(face) > 1:
  var new_face = ""

  if len(face) == 2:
   if has_status(TileStatus.PERIOD):
    new_face = Letters.get_random_ending_bigram(rng, face)
   else:
    new_face = Letters.get_random_bigram(null, rng, face)
  elif len(face) == 3:
   new_face = Letters.get_random_trigram(rng, face)

  var num_wildcards: = count_wildcards()
  if num_wildcards > 0:
   var wildcard_indices = range(len(face))
   rng.shuffle(wildcard_indices)

   var wildcards: Array[String] = []
   for letter in face:
    if letter in Letters.SUITS:
     var suits: = Letters.SUITS.duplicate()
     suits.erase(letter)
     wildcards.append(rng.pick_random(suits))
    elif letter in Letters.FULL_WILDCARDS:
     wildcards.append(letter)

   for _i in range(num_wildcards):
    var wildcard_index = wildcard_indices.pop_front()
    var wildcard_character = wildcards.pop_front()
    new_face[wildcard_index] = wildcard_character

  set_face(new_face)

 else:
  printerr("Tile with faces: ", faces, " cannot be randomized.")


func apply_shimmering(use_face = null, exclude_letter = null, rng = Game.random):
 if use_face != null:
  use_face = face

 var letter_swap = Letters.get_random_swap(use_face, exclude_letter, rng)
 set_face([letter_swap[0], letter_swap[1]])


func apply_slashed(rng: RNG = Game.random):
 if has_effect(TileEffect.SLASHED):
  var first_face = get_random_safe_letter(rng, tile_face.slashed_faces)
  var second_face = get_random_safe_letter(rng, tile_face.slashed_faces + PackedStringArray([first_face]))
  set_slashed([first_face, second_face])
 else:
  var first_face = face
  var second_face = get_random_safe_letter(rng, [first_face])
  set_slashed([first_face, second_face])


func set_type(num):
 type = num
 update()


func apply_hole(use_mouse_pos: = true) -> void :
 var hole_offset: Vector2
 if use_mouse_pos:
  var clamped_central: Vector2 = tile_collision.get_selected_position().clamp(Vector2(-6, - 6), Vector2(6, 6)) / 3.0
  hole_offset = clamped_central.round()
 else:
  hole_offset = Vector2(randi_range(-2, 2), randi_range(-2, 2))

 add_status(TileStatus.HOLE, hole_offset)


func can_rotate_face(degrees):
 if face.length() > 1:
  return false

 var is_caps = has_status(TileStatus.CAPITAL)

 if (( not is_caps and face not in Letters.ROTATED_LETTERS)
 or (is_caps and face not in Letters.ROTATED_CAPITAL_LETTERS)):
  return false

 if (( not is_caps and degrees in Letters.ROTATED_LETTERS[face])
 or (is_caps and degrees in Letters.ROTATED_CAPITAL_LETTERS[face])):
  return true

 return false


func reset_wildcard_faces():
 tile_face.set_wildcard_faces({})
 update()


func set_wildcard_faces(new_faces: Dictionary[int, String]):
 tile_face.set_wildcard_faces(new_faces)
 update()


func copy_tile(tile):
 load_save_data(tile.get_save_data())


func update_face():
 tile_face.set_statuses(statuses)
 tile_face.set_value(get_value(true))
 tile_face.set_type(type)
 tile_face.is_faceless = has_faceless_status()
 tile_face.update_visual()


func _on_check_generate_tooltip(collision) -> void :
 var using_spell = player.get_using_spell()
 if is_moving() or not main.is_player_turn or Tile.any_other_tile_selected(self):
  collision.enabled = false
 elif using_spell != null:
  if using_spell.has_special_tile_tooltip():
   if highlight_condition.is_valid():
    collision.enabled = highlight_condition.call(self) and using_spell.is_tile_selectable(self)
   else:
    collision.enabled = using_spell.is_tile_selectable(self)
  else:
   collision.enabled = false
 else:
  if SaveManager.get_hide_default_tile_tooltips_enabled():
   collision.enabled = not has_only_effects(Globals.EFFECTS_WITHOUT_TOOLTIPS)
  else:
   collision.enabled = true


func _on_generate_tooltip(tooltip) -> void :
 if in_word():
  tooltip_collision.vertical_alignment = tooltip_collision.TooltipVerticalAlignment.BOTTOM
  tooltip_collision.position_offset = Vector2(0, 5)
  tooltip_collision.allow_fallback = false
 else:
  tooltip_collision.vertical_alignment = tooltip_collision.TooltipVerticalAlignment.TOP
  tooltip_collision.position_offset = Vector2(0, -3)

  var coord: Variant = get_coord()
  if coord != null:
   tooltip_collision.allow_fallback = true
   if coord.x < ceili(float(tile_board.num_columns) / 2.0):
    tooltip_collision.fallback_halign = TooltipCollision.TooltipHorizontalAlignment.LEFT
    tooltip_collision.fallback_position_offset = Vector2(-6, 0)
   else:
    tooltip_collision.fallback_halign = TooltipCollision.TooltipHorizontalAlignment.RIGHT
    tooltip_collision.fallback_position_offset = Vector2(6, 0)
  else:
   tooltip_collision.allow_fallback = false

 var tooltip_context = {
  plastic = type == TileType.DEFENSE, 
  wooden = type == TileType.DAMAGE, 
  tile = true, 
  value = get_value_string(), 
 }

 var using_spell = player.get_using_spell()
 if using_spell != null:
  if using_spell.has_special_tile_tooltip():
   using_spell.generate_tile_tooltip(self, tooltip)
   return

 var has_default_title_override: = false
 var has_added_default_title_override_tooltip: = false
 if has_faceless_status():
  tooltip_context.value = 0

 if is_space():
  tooltip_context.space = true

 var status_instances: = get_statuses()
 for status in status_instances:
  if status.override_default_title:
   has_default_title_override = true
   break

 if not has_default_title_override and not SaveManager.get_hide_default_tile_tooltips_enabled():
  tooltip.add_subtooltip(
   StringManager.get_string("status/default/tile_name", tooltip_context), 
   StringManager.get_string("status/default/description", tooltip_context)
  )

 var status_tooltips: Array[Status] = []
 for status in status_instances:
  if status.id == TileStatus.DEFAULT:
   continue
  elif not status.is_relevant():
   continue

  status_tooltips.append(status)

 status_tooltips.sort_custom( func(a: Status, b: Status): return a.get_priority() > b.get_priority())

 for status in status_tooltips:
  var status_context = tooltip_context.duplicate()
  status_context.merge(status.get_tooltip_context())
  var use_name = "name"
  if not has_added_default_title_override_tooltip and StringManager.has_string("status/" + status.id + "/tile_name"):
   use_name = "tile_name"
   has_added_default_title_override_tooltip = true

  tooltip.add_subtooltip(
   StringManager.get_string("status/" + status.id + "/" + use_name, status_context), 
   StringManager.get_string("status/" + status.id + "/description", status_context)
  )

 if faces.size() > 1:
  tooltip.add_subtooltip(
   StringManager.get_string("status/shimmering/name"), 
   StringManager.get_string("status/shimmering/description")
  )

 if has_status(TileStatus.MYSTERY) or has_faceless_status():
  return

 if has_number():
  var numbers = get_numbers()
  numbers.sort()
  var description = ""
  for number in numbers:
   var number_description = StringManager.get_string("status/number/specific_description", {number = number, letters = Letters.NUMPAD_CHARACTERS[number]})
   description += number_description + "\n"

  tooltip.add_subtooltip(
   StringManager.get_string("status/number/name"), 
   description.strip_edges()
  )

 if has_any_letter("*"):
  var wildcard_context = {wildcard_letter = "*", show_wildcard_chance = player.has_natural_wildcards()}
  if has_status(TileStatus.MONEY):
   wildcard_context.wildcard_letter = "$"

  tooltip.add_subtooltip(
   StringManager.get_string("status/wildcard/name"), 
   StringManager.get_string("status/wildcard/description", wildcard_context)
  )

 if has_effect(TileEffect.SLASHED):
  tooltip.add_subtooltip(
   StringManager.get_string("status/slashed/name"), 
   StringManager.get_string("status/slashed/description", {faces = tile_face.slashed_faces})
  )

 if has_effect(TileEffect.SUIT):
  tooltip.add_subtooltip(
   StringManager.get_string("status/suit/name"), 
   StringManager.get_string("status/suit/description")
  )


func update():
 update_face()
 update_modulate()
 updated.emit()
 update_tile_sprite()


func update_tile_sprite():
 tile_sprite.set_type(type)
 tile_sprite.set_highlight(get_highlight())
 tile_sprite.set_deboss_color(get_deboss_color())


static func set_highlight_condition(condition: Callable) -> void :
 highlight_condition = condition
 Game.tile_board.update_tiles()


static func clear_highlight_condition() -> void :
 highlight_condition = Callable()
 Game.tile_board.update_tiles()


func update_modulate():
 if (
  not highlight_condition.is_valid()
  or not Game.player
  or is_preview
  or is_projectile
  or highlight_condition.call(self)
 ):
  modulate = Color.WHITE
 else:
  modulate = TILE_DIM_COLOR


func get_value(for_face = false) -> int:
 if not for_face and contains_wildcard() and wildcard_faces.is_empty():
  return 0

 var tile_value = Letters.get_face_value(faces, wildcard_faces)

 if (has_status(TileStatus.POOP) or has_status(TileStatus.MONEY) or has_faceless_status()) and not for_face:
  tile_value = 0
 elif has_status(TileStatus.ENHANCED):
  tile_value += 1

 if word_builder != null:
  tile_value *= word_builder.get_tile_multiplier(self)

 return tile_value


func has_value():
 return get_value() != 0


func contains_wildcard():
 return tile_face.contains_wildcard()


func get_value_string():
 if contains_wildcard() and wildcard_faces.is_empty():
  return "X"
 else:
  return str(get_value(true))


func has_any_letter(check_letters) -> bool:
 if not has_face():
  return false

 return tile_face.has_any_letter(check_letters)


func has_number() -> bool:
 return has_any_letter(Letters.NUMPAD_CHARACTERS.keys())


func get_numbers():
 var numbers = []
 for _face in faces:
  for letter in _face:
   if letter in Letters.NUMPAD_CHARACTERS and not letter in numbers:
    numbers.append(letter)

 return numbers


func get_status(status_id) -> Status:
 return statuses.get(status_id)


func get_statuses() -> Array[Status]:
 return statuses.values()


func get_sorted_statuses() -> Array[Status]:
 var sort_statuses: = get_statuses()
 sort_statuses.sort_custom( func(a: Status, b: Status): return a.get_priority() > b.get_priority())
 return sort_statuses


func is_type(type_id):
 return type == type_id


func has_status(status_id) -> bool:
 return statuses.has(status_id)


func has_any_status(status_ids) -> bool:
 if not status_ids is Array:
  return has_status(status_ids)

 for status in status_ids:
  if has_status(status):
   return true

 return false


func has_all_statuses(status_ids) -> bool:
 if status_ids is Array:
  for status in status_ids:
   if not has_all_statuses(status):
    return false

  return true
 else:
  return has_status(status_ids)


func has_only_statuses(status_ids) -> bool:
 if not status_ids is Array:
  status_ids = [status_ids]

 for status_id in statuses.keys():
  if status_id not in status_ids:
   return false

 return true


func get_status_count() -> int:
 return get_statuses().size()


func has_exclusive_status() -> bool:
 for status in get_statuses():
  if status.is_exclusive:
   return true

 return false


func add_status(status_id, data = null, from_save = false) -> void :
 if has_status(status_id):
  return

 var could_fall: = can_fall()

 var status: = Status.create(status_id)
 if status.is_exclusive or not status.exclusive_with.is_empty():
  for existing_status in get_statuses():
   if status.is_exclusive and existing_status.is_exclusive:
    remove_status(existing_status.id, false)
   elif existing_status.id != status_id and existing_status.id in status.exclusive_with:
    remove_status(existing_status.id, false)

 statuses[status.id] = status
 if status.has_process:
  processing_statuses.append(status)

 status.connect_tile(self, data, from_save)
 update()

 if can_fall() != could_fall:
  board_state_changed.emit()


func remove_status(status_id, replace = true):
 if not has_status(status_id):
  return

 var could_fall: = can_fall()

 var status = get_status(status_id)

 statuses.erase(status.id)
 processing_statuses.erase(status)
 status.clear()

 if status.is_exclusive and replace:
  add_status(TileStatus.DEFAULT)

 update()

 if can_fall() != could_fall:
  board_state_changed.emit()


func remove_statuses(status_ids = statuses.keys()):
 for status_id in status_ids:
  remove_status(status_id)


func has_harmful_status() -> bool:
 for status in get_statuses():
  if status.is_harmful:
   return true

 return false


func is_indestructible() -> bool:
 for status in get_statuses():
  if status.indestructible:
   return true

 return false


func has_faceless_status() -> bool:
 for status in get_statuses():
  if status.is_faceless():
   return true

 return false


func destroyed_by_spray() -> bool:
 for status in get_statuses():
  if status.destroyed_by_spray():
   return true

 return false


func is_space() -> bool:
 for status in get_statuses():
  if status.is_space():
   return true

 return false


func is_playable() -> bool:
 for status in get_statuses():
  if status.is_always_playable():
   return true

 return not has_faceless_status()


func status_preventing_dragging() -> bool:
 for status in get_statuses():
  if status.preventing_dragging():
   return true

 return false


func get_face_statuses() -> PackedStringArray:
 var face_statuses: = PackedStringArray()
 for status in get_statuses():
  if status.face_status:
   face_statuses.append(status.id)

 return face_statuses


func remove_face_statuses() -> void :
 remove_statuses(get_face_statuses())


func get_effects() -> PackedStringArray:
 var effects: = PackedStringArray()
 for effect in Globals.TRACKED_EFFECTS:
  if has_effect(effect):
   effects.append(effect)

 return effects


func has_effect(effect: String) -> bool:
 match effect:
  TileEffect.SHIMMERING:
   return faces.size() > 1
  TileEffect.SPACE:
   return is_space()
  TileEffect.FACELESS:
   return has_faceless_status()
  TileEffect.WILDCARD:
   return has_any_letter("*")
  TileEffect.SLASHED:
   return has_any_letter("/")
  TileEffect.NUMBER:
   return has_any_letter(Letters.NUMPAD_CHARACTERS.keys())
  TileEffect.SUIT:
   return has_any_letter(Letters.WILDCARD_GROUPS.keys())
  TileEffect.BIGRAM, TileEffect.TRIGRAM:
   var match_length: int = 2 if effect == TileEffect.BIGRAM else 3

   for string in faces:
    if len(face) == match_length:
     return true

   return false

 return has_status(effect)


func has_any_effect(effects: PackedStringArray) -> bool:
 for effect in effects:
  if has_effect(effect):
   return true

 return false


func has_all_effects(effects: PackedStringArray) -> bool:
 for effect in effects:
  if not has_effect(effect):
   return false

 return true


func has_only_effects(effects: PackedStringArray) -> bool:
 for effect in get_effects() + PackedStringArray(statuses.keys()):
  if effect not in effects:
   return false

 return true


func get_effect_priority(priority_list: Array) -> int:
 for priority in range(priority_list.size() - 1, -1, -1):
  var effect = priority_list[priority]
  if effect is Array:
   if has_any_effect(PackedStringArray(effect)):
    return priority
  elif has_effect(effect):
   return priority

 return 999


func will_be_melted_on_turn_end():
 if has_status(TileStatus.ACID):
  return false

 var coord = get_coord()
 var above_tiles = tile_board.get_tiles({
  columns = [coord.x], 
  rows = tile_board.get_row_coords(false, true, coord.y), 
  sorted = true, 
  custom_tile_check = func(tile, _params): return tile.will_exist_on_turn_end(), 
 })

 return above_tiles.size() != 0 and above_tiles[0].has_status(TileStatus.ACID) and above_tiles[0].can_fall()


func will_exist_on_turn_end():
 if in_word():
  return false

 for status in get_statuses():
  if status.will_destroy_on_turn_end():
   return false

 return true


func can_fall() -> bool:
 for status in get_statuses():
  if status.preventing_falling():
   return false

 return true


func tween_position(dest, duration = 0.35, tween_trans = Tween.TRANS_QUAD, tween_ease = Tween.EASE_IN_OUT, move_state = State.MOVING, change_state: = true):
 if change_state:
  set_state(move_state)

 var tween = create_tween()
 tween.set_trans(tween_trans)
 tween.set_ease(tween_ease)
 tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)

 tween.tween_property(self, "global_position", dest, duration)

 await tween.finished
 if change_state:
  set_state(State.IDLE)


func get_coord() -> Variant:
 return tile_board.get_tile_coords(self)


func is_edge_tile() -> bool:
 var coord: Variant = get_coord()
 if coord == null:
  return false

 var coord_v: Vector2i = coord as Vector2i
 return coord_v.x == 0 or coord_v.y == 0 or coord_v.x == tile_board.num_columns - 1 or coord_v.y == tile_board.num_rows - 1


func set_state(tile_state, update_board = true):
 state = tile_state

 if not is_removing():
  hover_handler.hover_for_state()
  update_z_index()

 if is_moving():
  if tooltip_collision.is_displaying:
   tooltip_collision.clear_tooltip()

 if update_board:
  tile_board.update_state()

 state_updated.emit()


func is_removing():
 return state == State.REMOVING


func is_idle():
 return state == State.IDLE


func is_moving(ignore_settling = false):
 return state == State.MOVING or state == State.DRAGGING or ( not ignore_settling and state == State.SETTLING)


func in_word():
 var index = find_in_word()

 if index == -1:
  return false
 return true


func find_in_word():
 return word_builder.tiles.find(self)


func clear(update_state = null):
 if self in word_builder.tiles and not word_builder.is_submitting:
  word_builder.remove_tile(self)

 set_state(State.REMOVING, update_state)
 get_parent().remove_child(self)
 queue_free()


func get_settle_duration(base_duration: float, duration_per_grid: float) -> float:
 var distance = get_distance_from_coords()
 var grid_distance = distance / float(tile_board.GRID_SIZE)
 return base_duration + (duration_per_grid * grid_distance)



func settle(base_duration: = 0.08, duration_per_grid: = 0.16) -> void :
 var duration: = get_settle_duration(base_duration, duration_per_grid)
 set_state(State.SETTLING, true)
 await tween_to_board(duration, State.SETTLING, false)



 if get_parent() == tile_board.tile_mask and not tile_board.is_slid_out:
  reparent(main.tile_container)

 set_state(State.IDLE, true)


func get_coords_position():
 return tile_board.get_coord_position(get_coord())


func get_distance_from_coords():
 var dest = get_coords_position()
 return global_position.distance_to(dest)


func tween_to_board(duration = 0.35, move_state = State.MOVING, change_state = true):
 var dest = tile_board.get_coord_position(get_coord())

 if duration == 0:
  global_position = dest
  return

 await tween_position(dest, duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT, move_state, change_state)


func add_poofcloud(color = Color(0, 0, 0), fade_color = null, play_sound: = true, fade_duration = 0.5, big = false):
 var poofcloud = null




 if play_sound:
  AudioManager.play_sound(Sounds.GENERIC.APPLY_STATUS)

 if big:
  poofcloud = BigPoofcloud.instantiate()
 else:
  poofcloud = Poofcloud.instantiate()

 main.add_child(poofcloud)

 poofcloud.global_position = global_position
 poofcloud.modulate = color

 if fade_color != null:
  poofcloud.color_fade(fade_color, fade_duration)


func poof_smoke() -> void :
 add_poofcloud(Globals.COLORS.SMOKE, Globals.COLORS.BLEND_SMOKE)


func poof_tile_smoke() -> void :
 add_poofcloud(get_poof_color(), Globals.COLORS.BLEND_SMOKE)


func poof_ink() -> void :
 add_poofcloud(Globals.COLORS.INK_BLACK)


func get_highlight():
 var highest_priority = -1
 var priority_highlight = null

 for highlight_source in highlight_data.keys():
  var highlight = highlight_data[highlight_source]
  if highlight.priority > highest_priority:
   highest_priority = highlight.priority
   priority_highlight = highlight

 return priority_highlight


func add_highlight(source, color = Color(1, 1, 1, 1), priority = 0):
 highlight_data[source] = {
  color = color, 
  priority = priority
 }
 update_z_index()
 update_tile_sprite()


func clear_highlight(source):
 highlight_data.erase(source)
 update_z_index()
 update_tile_sprite()


func get_board_next_in_direction(vector: Vector2i, wrap_coords: = false, exclude_in_word: = false) -> Tile:
 var coord: Variant = get_coord()
 if coord == null:
  return null

 var coord_vector: Vector2i = coord
 var next_coord: = coord_vector
 var next_tile: Tile = null
 while next_tile == null:
  next_coord += vector
  if wrap_coords:
   next_coord = tile_board.wrap_coords(next_coord)

  if next_coord == coord_vector or not tile_board.are_coords_valid(next_coord):
   return null

  next_tile = tile_board.get_tile_at(next_coord)
  if next_tile != null and exclude_in_word and next_tile.in_word():
   next_tile = null

 return next_tile


func get_board_neighbor(vector: Vector2i) -> Tile:
 return tile_board.get_tile_at(get_coord() + vector)


func get_board_neighbors() -> Array[Tile]:
 var tiles: Array[Tile] = []

 var neighbor_coords: Array[Vector2i] = [
  Vector2i.RIGHT, 
  Vector2i.DOWN, 
  Vector2i.LEFT, 
  Vector2i.UP, 
 ]

 for tile_coord in neighbor_coords:
  var neighbor: = get_board_neighbor(tile_coord)

  if neighbor != null:
   tiles.append(neighbor)

 return tiles



func get_color(blend_color = null):
 var color = get_poof_color()
 if blend_color != null:
  return color.blend(blend_color)

 return color


func get_poof_color():
 const TILE_POOF_COLOR = Globals.TILE_POOF_COLOR

 for status in get_statuses():
  if status.id != TileStatus.DEFAULT and status.id in TILE_POOF_COLOR:
   return TILE_POOF_COLOR[status.id][type]

 return TILE_POOF_COLOR[TileStatus.DEFAULT][type]


func get_deboss_color():
 const TILE_DEBOSS_COLOR = Globals.TILE_DEBOSS_COLOR

 for status in get_statuses():
  if status.id != TileStatus.DEFAULT and status.id in TILE_DEBOSS_COLOR:
   return TILE_DEBOSS_COLOR[status.id][type]

 return TILE_DEBOSS_COLOR[TileStatus.DEFAULT][type]


func launch(starting_position: Vector2, target_position: Vector2, arc_height: float, target_coord: Vector2i = Vector2i.MIN, gravity: float = 800, free_on_impact: = false, no_shadow: = false, do_tile_poof: = true, poof_method: = Callable()) -> ArcingProjectile:
 var projectile: ArcingProjectile = arcing_projectile_scene.instantiate()

 if no_shadow:
  disable_shadow()

 main.projectile_container.add_child(projectile)
 reparent(projectile)

 is_projectile = true
 update_z_index()
 position = Vector2(0, 0)
 rotation = deg_to_rad(-90)

 projectile.gravity = gravity
 projectile.free_on_impact = free_on_impact
 projectile.look_at_direction = true
 projectile.do_poof = false

 projectile.launch(starting_position, target_position, arc_height)

 projectile.impacted.connect(_impact.bind(projectile, target_coord, no_shadow, do_tile_poof, poof_method))
 return projectile


func _impact(projectile: ArcingProjectile, target_coord: = Vector2i.MIN, reenable_shadow: bool = false, do_tile_poof: = true, poof_method: = Callable()) -> void :
 impacted.emit()

 if not projectile.free_on_impact:
  projectile.queue_free()

 is_projectile = false

 var poof_tile: Tile = self
 if target_coord != Vector2i.MIN:
  if reenable_shadow:
   enable_shadow()

  tile_sprite.is_fish = false




  poof_tile = tile_board.insert_tile(self, target_coord)

 if do_tile_poof:
  poof_tile.add_poofcloud(poof_tile.get_color())

 if poof_method.is_valid():
  poof_method.call(poof_tile)


func is_hoverable() -> bool:
 if is_preview or is_projectile or Tile.any_tile_dragging():
  return false

 return is_idle() and (main.is_game_actionable() or player.is_selecting(player.Selection.TILE))


func is_selectable() -> bool:
 return true


func is_clickable() -> bool:
 if is_preview or is_projectile or Tile.any_tile_dragging():
  return false

 return is_idle() and (main.is_game_actionable() or (player.is_selecting(player.Selection.TILE) and is_selectable()))


func bounce() -> void :
 animation.play("bounce")


func play_status_sound(base_pitch: float = 1.0, bus: String = "Sound") -> void :
 for status in get_statuses():
  status.play_tile_sound(base_pitch, bus)


func play_tile_sound(base_pitch: float = 1.0) -> void :
 play_status_sound(base_pitch)

 if type == TileType.DAMAGE:
  AudioManager.play_sound(Sounds.TILE.WOOD, base_pitch)
 else:
  AudioManager.play_sound(Sounds.TILE.PLASTIC, base_pitch)


func click_tile() -> bool:
 if player.is_selecting(player.Selection.TILE):
  player.emit_signal("selected", self)
 elif self in word_builder.tiles:
  word_builder.remove_tile(self)
  return true
 else:
  var click_handled: = false
  for status in get_sorted_statuses():
   if status.handles_click():
    if status.handle_click():
     click_handled = true
     break

  if click_handled:
   return true

  var had_focus: = tile_collision.has_focus(true)
  var can_add_tile: bool = word_builder.can_add_tile(self)
  if had_focus and can_add_tile:
   var blank: = Game.tile_board.get_blank_space_at(get_coord())
   blank.grab_focus()

  word_builder.try_add_tile(self)

 return false


func update_z_index():
 z_index = 20
 if state == State.DRAGGING or is_projectile:
  z_index = 1200
 elif in_word():
  z_index = 1001 + word_builder.tiles.find(self)
 elif is_moving(true):
  z_index = 1000
 elif not is_preview and not is_projectile and get_coord() != null:
  var coord = get_coord()
  var row_z_index = (tile_board.num_rows - coord.y) * tile_board.num_columns
  z_index += row_z_index + coord.x

 if highlight_data.size() > 0:
  z_index += 300

 if tile_collision.has_focus():
  z_index += 500


func initialize_drag():
 drag_handler.can_drag_func = can_drag
 if Util.is_mobile():
  drag_handler.can_drag = false


func can_drag():
 if Util.is_mobile():
  return false

 return (
  not is_preview
  and (state == State.IDLE or state == State.DRAGGING)
  and get_coord() != null
  and main.is_game_actionable()
  and not status_preventing_dragging()
 )


func is_dragging():
 return drag_handler.is_dragging()


func _on_drag_handler_drag_started(_start_pos: Vector2, _current_pos: Vector2) -> void :
 set_state(State.DRAGGING)
 tile_sprite.hide_multiplier()


func _on_drag_handler_dragged(_start_pos: Vector2, current_pos: Vector2) -> void :
 global_position = current_pos


func _on_drag_handler_drag_released(_start_pos: Vector2, _end_pos: Vector2, was_received: bool) -> void :
 set_state(State.IDLE)

 if not was_received:
  if in_word():
   Game.word_builder.remove_tile(self, true, false)
  else:
   play_tile_sound()
   tween_to_board()
 else:
  play_tile_sound()


func get_save_data():
 var save = {
  type = type
 }

 if face == "/":
  save.slashed_faces = tile_face.slashed_faces.duplicate()
 else:
  save.faces = faces.duplicate()

 for status in get_statuses():
  if status.id != TileStatus.DEFAULT:
   if "statuses" not in save:
    save.statuses = []

   save.statuses.append(status.id)
   var save_data = status.get_save_data()
   if save_data != null:
    if "status_data" not in save:
     save.status_data = {}

    save.status_data[status.id] = save_data

 return save


func load_save_data(save, as_save = true):
 remove_statuses()

 if "slashed_faces" in save:
  set_slashed(save.slashed_faces)
 else:
  set_face(save.faces, false)

 set_type(save.type)
 add_status(TileStatus.DEFAULT)

 if "statuses" in save:
  var status_data = save.get("status_data", {})
  for status in save.statuses:
   add_status(status, status_data.get(status, null), as_save or ("as_save" in save))

 if "hole_punched" in save and save.hole_punched:
  add_status(TileStatus.HOLE, save.get("hole_offset", null))

 update()


func _on_started_using_spell():
 tooltip_collision.max_delay = 20
 tooltip_collision.tooltip_delay = tooltip_collision.max_delay


func _on_stopped_using_spell():
 tooltip_collision.max_delay = tooltip_collision.default_delay
 tooltip_collision.tooltip_delay = tooltip_collision.max_delay
 if tooltip_collision.is_displaying:
  tooltip_collision.clear_tooltip()



func _debug_edit_face(shimmering: = false) -> void :
 set_meta("debug_editing_face", tile_face.face_index)
 set_meta("debug_editing_shimmering", shimmering)
 if shimmering:
  line_edit.text = ""
 else:
  line_edit.text = face
 line_edit.visible = true
 tile_face.visible = false
 line_edit.grab_focus()
 line_edit.set_caret_column(len(face))
 line_edit.edit()


func _debug_face_from_string(new_text: String):
 if new_text.ends_with("."):
  new_text = new_text.rstrip(".")
  add_status(TileStatus.PERIOD)

 if new_text != new_text.to_lower():
  new_text = new_text.to_lower()
  add_status(TileStatus.CAPITAL)

 if "/" in new_text:
  set_slashed(new_text.split("/"))
 elif get_meta("debug_editing_shimmering", false):
  add_face(new_text)
 else:
  set_face_at(get_meta("debug_editing_face", 0), new_text)


func _on_line_edit_text_submitted(_text):
 line_edit.release_focus()


func _on_line_edit_focus_exited():
 _debug_face_from_string(line_edit.text)
 line_edit.visible = false
 tile_face.visible = true
 update()
