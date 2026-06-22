@tool
class_name TileFace extends Node2D


const TileType = Globals.TileType
const TileStatus = Globals.TileStatus

const FONT = preload("res://fonts/Suwannaphum-Bold.ttf")

const BASE_FACE_OFFSET = Vector2(0, -1)
const FACE_WITH_VALUE_OFFSET = Vector2(-1, 0)
const FACE_OFFSET_KEYPAD = Vector2(0, -3)
const KEYPAD_TEXT_OFFSET = Vector2(0, 0)
const VALUE_TEXT_BR = Vector2(10, 10)
const DEBOSS_HIGHLIGHT_OFFSET = Vector2(0.0, 0.5)
const UNDERLINE_POSITION = Vector2(0, 6)

const KEYPAD_FACE_FONT_SIZE = 10
const KEYPAD_HINT_FONT_SIZE = 6
const BASE_FONT_SIZE = 12
const TWO_CHARACTER_FONT_SIZE = 10
const THREE_CHARACTER_FONT_SIZE = 8
const VALUE_FONT_SIZE = 5
const MAX_WIDTH = 24
const MAX_HEIGHT = 24

var face: String = "b"
var frozen = false
var type = TileType.DEFENSE
var displaying_permutation_face_index = -1
var faces: Array[String] = ["b"]
var slashed_faces: = PackedStringArray()
var wildcard_faces: Dictionary[int, String] = {}
var face_index = 0
var drawn_color = Color.BLACK
var value_color = Color.BLACK
@export var deboss_highlight_color: Color = Color(247.0 / 255.0, 220.0 / 255.0, 165.0 / 255.0):
 set(value):
  deboss_highlight_color = value
  queue_redraw()

var statuses = []
var value = 2

@export var SHIMMERING_FACE_TIME_MS = 1000

var force_no_value: = false
var is_faceless: = false

var face_text = "b"
var value_text = "2"
var keypad_text = ""
var draw_underline: = false
var face_text_line = TightTextLine.new()
var value_text_line = TightTextLine.new()
var keypad_text_line = TightTextLine.new()
var underline_text_line = TightTextLine.new()


func _ready():
 if Engine.is_editor_hint():
  update_visual(false)


func _process(_delta):
 if Engine.is_editor_hint():
  return

 if faces.size() > 1 and displaying_permutation_face_index == -1 and not frozen:
  update_face(true)


func set_face(new_faces: Variant, no_clear_slashed: = false):
 if not no_clear_slashed:
  slashed_faces.clear()

 if new_faces is String:
  faces = [new_faces]
 elif new_faces is Array or new_faces is PackedStringArray:
  faces.assign(new_faces)
 else:
  assert (false, "Invalid faces " + str(new_faces))
  return

 if faces.size() > 1:
  var deduplicated: Array[String] = []
  for new_face in faces:
   if new_face not in deduplicated:
    deduplicated.append(new_face)

  faces = deduplicated

 update_face()


func set_slashed_faces(new_faces: PackedStringArray):
 slashed_faces = new_faces


func freeze():
 frozen = true


func unfreeze():
 frozen = false
 update_face()


func set_displaying_permutation_face_index(index):
 displaying_permutation_face_index = index
 update_visual()


func set_wildcard_faces(new_faces: Dictionary[int, String]) -> void :
 wildcard_faces = new_faces


func get_resolved_faces():
 var resolved_faces = []
 for i in faces.size():
  var resolved_face = faces[i]
  if i in wildcard_faces:
   resolved_face = wildcard_faces[i]

  resolved_faces.append(resolved_face)

 return resolved_faces


func set_color(color):
 drawn_color = color


func set_deboss_color(highlight):
 deboss_highlight_color = highlight


func set_type(_type):
 type = _type


func set_statuses(new_statuses):
 if new_statuses is Dictionary:
  new_statuses = new_statuses.keys()

 statuses = new_statuses


func set_value(new_value):
 value = new_value


func has_any_letter(check_letters) -> bool:
 if not (check_letters is Array or check_letters is PackedStringArray):
  check_letters = [check_letters]

 for letter in check_letters:
  for string in faces:
   if letter in string:
    return true

 return false


func contains_wildcard():
 return has_any_letter(Letters.WILDCARD_CHARACTERS)


func update_face(call_visual = false):
 var previous_face = face
 if displaying_permutation_face_index != -1:
  face_index = displaying_permutation_face_index
 elif faces.size() > 1:

  var game_time = Time.get_ticks_msec()
  var num_faces = faces.size()


  var divided_time = (game_time % (num_faces * SHIMMERING_FACE_TIME_MS))
  face_index = floor(divided_time / SHIMMERING_FACE_TIME_MS)
 elif faces.size() > 0:
  face_index = 0

 face = faces[face_index]

 if face != previous_face and call_visual:
  update_visual(false)


func alter_face_text(text: String) -> String:
 if TileStatus.MONEY in statuses:
  text = text.replace("*", "$")

 var text_length = len(text)
 if TileStatus.MYSTERY in statuses and text_length > 0:
  text = "?".repeat(text_length)

 if TileStatus.CAPITAL in statuses:
  text = text.capitalize()
 elif TileStatus.PERIOD in statuses and text_length > 0:
  text += "."

 return text


func get_face_text(do_wildcard: = true, do_alteration: = true, get_face_index: int = face_index):
 if get_face_index in wildcard_faces and do_wildcard:
  if do_alteration:
   return alter_face_text(wildcard_faces[get_face_index])
  else:
   return wildcard_faces[get_face_index]

 var get_face_string: = faces[get_face_index]
 if get_face_string == "/":
  var slashed_text: = PackedStringArray()
  if do_alteration:
   for slashed_face in slashed_faces:
    slashed_text.append(alter_face_text(slashed_face))
  else:
   slashed_text = slashed_faces

  return "/".join(slashed_text)
 else:
  if do_alteration:
   return alter_face_text(get_face_string)
  else:
   return get_face_string


func update_visual(call_face = true):
 if not frozen and call_face:
  update_face()

 face_text = get_face_text()

 var type_color_index: int = 0 if type == TileType.DAMAGE else 1
 var changed_face_color: = false
 var changed_value_color: = false
 for status in statuses:
  if status in Globals.TILE_FACE_COLOR:
   set_color(Globals.TILE_FACE_COLOR[status][type_color_index])
   changed_face_color = true

  if status in Globals.TILE_VALUE_COLOR:
   value_color = Globals.TILE_VALUE_COLOR[status][type_color_index]
   changed_value_color = true

 if not changed_face_color:
  set_color(Color.BLACK)

 if not changed_value_color:
  value_color = drawn_color

 if force_no_value or is_faceless:
  value_text = ""
 else:
  value_text = str(value)


 var face_length = len(face_text)
 if TileStatus.CAPITAL in statuses and face_length > 0:
  var is_wildcard = face_text[0] in Letters.WILDCARD_CHARACTERS + ["$"]
  var is_number = face_text[0] in Letters.NUMPAD_CHARACTERS
  if is_wildcard and ( not is_number or len(face) > 1):
   draw_underline = true
  elif TileStatus.MYSTERY in statuses:
   draw_underline = true
  else:
   draw_underline = false
 else:
  draw_underline = false

 queue_redraw()

 if face_text in Letters.NUMPAD_CHARACTERS:
  value_text = ""
  keypad_text = "".join(Letters.NUMPAD_CHARACTERS[face_text])
  if TileStatus.CAPITAL in statuses:
   keypad_text = keypad_text.to_upper()
 else:
  keypad_text = ""
  if (contains_wildcard() and wildcard_faces.is_empty()) or value == 0:
   value_text = ""


func get_face_line(line: TightTextLine, text: String) -> Dictionary:
 var font_size = BASE_FONT_SIZE
 var no_period = text.rstrip(".")
 var length_without_period = len(no_period)
 if length_without_period >= 3:
  font_size = THREE_CHARACTER_FONT_SIZE
 elif length_without_period >= 2:
  font_size = TWO_CHARACTER_FONT_SIZE

 if keypad_text != "":
  font_size = KEYPAD_FACE_FONT_SIZE

 var face_tight_rect = line.fit_space(text, FONT, font_size, MAX_WIDTH, MAX_HEIGHT)
 var face_draw_pos = - face_tight_rect.position - face_tight_rect.size / 2
 if value_text != "":
  face_draw_pos += FACE_WITH_VALUE_OFFSET

 if keypad_text != "":
  face_draw_pos += FACE_OFFSET_KEYPAD
 else:
  face_draw_pos += BASE_FACE_OFFSET

 return {line = line, position = face_draw_pos}


func _draw():
 var drawing_lines = []
 if face_text != "":
  drawing_lines.append(get_face_line(face_text_line, face_text))

 if keypad_text != "":
  keypad_text_line.clear()
  keypad_text_line.add_string(keypad_text, FONT, KEYPAD_HINT_FONT_SIZE)
  var keypad_tight_rect = keypad_text_line.get_tight_rect()
  var keypad_hint_draw_pos = KEYPAD_TEXT_OFFSET - keypad_tight_rect.position - Vector2(keypad_tight_rect.size.x / 2, 0.0)
  drawing_lines.append({line = keypad_text_line, position = keypad_hint_draw_pos})

 if value_text != "":
  value_text_line.clear()
  value_text_line.add_string(value_text, FONT, VALUE_FONT_SIZE)
  var value_tight_rect = value_text_line.get_tight_rect()
  var value_draw_pos = (VALUE_TEXT_BR - value_tight_rect.size - value_tight_rect.position)
  drawing_lines.append({line = value_text_line, position = value_draw_pos, color = value_color})

 if draw_underline:
  underline_text_line.clear()
  underline_text_line.add_string("_", FONT, BASE_FONT_SIZE)
  var underline_tight_rect = underline_text_line.get_tight_rect()
  var underline_draw_pos = UNDERLINE_POSITION - underline_tight_rect.position - underline_tight_rect.size / 2
  drawing_lines.append({line = underline_text_line, position = underline_draw_pos})

 for line: Dictionary in drawing_lines:
  line.line.draw(get_canvas_item(), line.position + DEBOSS_HIGHLIGHT_OFFSET, line.get("deboss_color", deboss_highlight_color))
  line.line.draw(get_canvas_item(), line.position, line.get("color", drawn_color))
