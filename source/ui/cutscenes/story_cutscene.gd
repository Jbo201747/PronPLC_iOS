extends Cutscene


var section_index: int = 0
var control_text: String = ""
var line_counts: Array[int] = []

var text_playback: Util.TypeTextPlayback

@onready var art: Sprite2D = %Art
@onready var art_overlay: Sprite2D = %ArtOverlay
@onready var label: RichTextLabel = %Label
@onready var anim_player: AnimPlayer = %AnimPlayer


func advance() -> void :
 if text_playback != null and not text_playback.is_finished:
  text_playback.cancel()
  return

 if line_counts.is_empty():
  section_index += 1
  if string_group.has_string_data_or_group([str(section_index)]):
   set_lines_for_section(section_index)
   advance()
  else:
   finish()

  return

 var count: int = line_counts.pop_front()
 text_playback = Game.type_text_with_audio_cancelable(label, 0.02, 1, count, true, control_text)


func play() -> void :
 if string_group.has_string("image"):
  var texture_path: String = string_group.get_string("image")
  art.texture = load("res://arte/cutscenes/" + texture_path + "_trans.png")
  art_overlay.texture = load("res://arte/cutscenes/" + texture_path + ".png")

 section_index = -1
 label.visible_characters = 0

 player.anim_player.play_advance("start_cutscene")
 await anim_player.play_until_finished("start_cutscene")

 can_advance = true
 advance()


func finish() -> void :
 can_advance = false
 player.anim_player.play_advance("finish_cutscene")
 await anim_player.play_until_finished("finish_cutscene")
 finished.emit()


func set_lines_for_section(section_number: int) -> void :
 label.visible_characters = 0
 label.text = ""
 control_text = ""

 line_counts.clear()

 var section_path: = PackedStringArray([str(section_number)])
 if string_group.has_string_group_at_path(section_path):
  var section: = string_group.get_string_group_at_path(section_path)
  var line_number: int = 0
  var line_paths: Array[PackedStringArray] = []
  while true:
   var line_path: = PackedStringArray([str(line_number)])
   if section.has_string_at_path(line_path):
    line_paths.append(line_path)
    line_number += 1
   else:
    break

  for i in line_paths.size():
   add_line(section, line_paths[i], i == line_paths.size() - 1)
 else:
  add_line(string_group, section_path, true)


func add_line(root: StringManager.StringGroup, line_path: PackedStringArray, is_last_line: bool) -> void :
 var optional_newline: = "\n" if not is_last_line else ""
 var line: = root.get_string_at_path(line_path) + optional_newline
 var control_line: = root.get_string_at_path(line_path, {control = true}) + optional_newline
 var prev_character_count: = label.get_total_character_count()
 label.text += line
 var added_length: = label.get_total_character_count() - prev_character_count
 control_text += control_line
 line_counts.append(added_length)


func _on_anim_player_event_emitted(event_name: String) -> void :
 if event_name == "fade_in" and "evil_laugh" in flags:
  AudioManager.play_sound(Sounds.UI.EVIL_DEVELOPER_LAUGHTER)
