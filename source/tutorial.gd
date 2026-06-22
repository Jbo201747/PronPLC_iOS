class_name Tutorial extends RefCounted


var active: bool = false

var prevent_saving: = false
var prevent_game_action: = false
var allow_spell_use: = false
var hide_enemy_intent: = false
var exclude_letters: Array = ["q", "u", "i"]
var letter_opener_removed: String = ""
var target_letter: String = ""
var speech_bubble: SpeechBubble = null
var last_defense_gained: int = -1

var current_line_flags: PackedStringArray = []

var sequence: Array[PackedStringArray] = []


func start_tutorial() -> void :
 active = true
 prevent_saving = true
 prevent_game_action = true
 allow_spell_use = false
 hide_enemy_intent = true
 last_defense_gained = -1

 if not Game.word_builder.submitted_word.is_connected(_on_submitted_word):
  Game.word_builder.submitted_word.connect(_on_submitted_word)


func play_tutorial_sequence(id: String) -> void :
 var group: = StringManager.get_string_group(id)
 sequence = group.get_ordered_children_paths(true)

 await speech_bubble.appear()

 play_tutorial_line()


func play_tutorial_line() -> void :
 speech_bubble.visible = true

 var path: PackedStringArray = sequence[0]
 if StringManager.has_string_group_at_path(path):
  var group: = StringManager.get_string_group_at_path(path)

  if group.has_string("flags"):
   current_line_flags = group.get_string("flags").split(" ", false)

  if "hide_intent" in current_line_flags:
   hide_enemy_intent = true
  elif "show_intent" in current_line_flags:
   speech_bubble.anim_player.play("move_up")
   await speech_bubble.anim_event
   hide_enemy_intent = false
   Game.enemy.update_intents()

  if "add_spell" in current_line_flags:
   Game.main.add_starting_spells(true)

  if "enable_game_action" in current_line_flags:
   prevent_game_action = false
  elif "disable_game_action" in current_line_flags:
   prevent_game_action = true

  if "enable_spells" in current_line_flags:
   allow_spell_use = true
  elif "disable_spells" in current_line_flags:
   allow_spell_use = false

  if "set_viewed_tutorial" in current_line_flags:
   SaveManager.get_save().set_viewed_tutorial(true)
   SaveManager.get_save().store_file()
   prevent_saving = false

  var context: Dictionary = {}
  if "letter_opener" in current_line_flags:
   var tiles = Game.tile_board.get_tiles({rng = Game.random})
   var letter_counts: Dictionary[String, int] = {}
   for tile in tiles:
    if tile.has_face():
     if tile.face not in letter_counts:
      letter_counts[tile.face] = 0

     letter_counts[tile.face] += 1

   if "q" in letter_counts:
    target_letter = "q"
   else:
    var minimum_count_letter: String = ""
    var minimum_letter_count: int = 999
    for letter in letter_counts:
     if letter_counts[letter] < minimum_letter_count:
      minimum_letter_count = letter_counts[letter]
      minimum_count_letter = letter

    target_letter = minimum_count_letter

   context.letter = target_letter

  var use_alt: bool = false

  var alt_flag_index: int = 0
  for flag in current_line_flags:
   if "alt" in flag:
    if flag == "alt_no_hit_defense_wasted" and Game.enemy.health >= Game.enemy.max_health and last_defense_gained >= 3:
     use_alt = true
     break
    elif flag == "alt_no_hit" and Game.enemy.health >= Game.enemy.max_health:
     use_alt = true
     break
    elif flag == "alt_over_defended" and last_defense_gained > 1:
     use_alt = true
     break
    elif flag == "alt_no_defense" and last_defense_gained <= 0:
     use_alt = true
     break
    elif flag == "alt_wrong_remove" and letter_opener_removed != target_letter:
     use_alt = true
     break
    elif flag == "alt_almost_killed" and Game.enemy.health == 1:
     use_alt = true
     break

    alt_flag_index += 1

  if use_alt and group.has_string_group("alt"):
   var paths: = group.get_string_group("alt").get_ordered_children_paths(true)
   alt_flag_index = mini(alt_flag_index, paths.size() - 1)
   if alt_flag_index >= 0:
    speech_bubble.type_text(StringManager.get_string_at_path(paths[alt_flag_index], context))
   else:
    assert (false, "Something went wrong, couldn't find text to play!")
  elif use_alt and group.has_string("alt"):
   speech_bubble.type_text(group.get_string("alt", context))
  else:
   speech_bubble.type_text(group.get_string("line", context))
 else:
  var string: = StringManager.get_string_at_path(path)
  speech_bubble.type_text(string)


func start_first_turn() -> void :
 await play_tutorial_sequence("tutorial/first_turn")


func start_second_turn() -> void :
 await play_tutorial_sequence("tutorial/second_turn")


func advance() -> void :
 var end_tutorial: bool = "end_tutorial" in current_line_flags
 current_line_flags.clear()
 sequence.pop_front()
 if not sequence.is_empty():
  play_tutorial_line()
 else:
  await speech_bubble.disappear()

  if end_tutorial:
   finish_tutorial()

 Game.main.game_state_updated.emit()


func finish_tutorial() -> void :
 if speech_bubble != null and is_instance_valid(speech_bubble):
  speech_bubble.queue_free()

 active = false
 if Game.word_builder.submitted_word.is_connected(_on_submitted_word):
  Game.word_builder.submitted_word.disconnect(_on_submitted_word)

 Game.main.game_state_updated.emit()


func can_advance() -> bool:
 if sequence.is_empty():
  return false

 if speech_bubble.is_typing_text():
  return true

 if "hover_intent" in current_line_flags or "letter_opener" in current_line_flags:
  return false

 return true


func try_advance() -> void :
 if sequence.is_empty():
  return

 if speech_bubble.is_typing_text():
  speech_bubble.cancel_typing_text()
  return

 var path: PackedStringArray = sequence[0]
 if not StringManager.has_string_group_at_path(path):
  advance()
  return

 if "hover_intent" in current_line_flags or "letter_opener" in current_line_flags:
  return

 advance()


func _on_submitted_word(_words: WordList, _damage: int, _ending_turn: bool) -> void :
 last_defense_gained = Game.word_builder.defense
