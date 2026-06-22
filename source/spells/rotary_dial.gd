extends "res://source/spells/letter_stamp.gd"


func set_status_tooltips():
 selectable_regions = [Selection.CENTER, Selection.LEFT_RIGHT]


func randomize_face():
 face = rng.spell.pick_random(Letters.NUMPAD_CHARACTERS.keys())


func get_excluded_charges() -> PackedStringArray:
 return []


func get_tooltip_context():
 if not Game.is_in_run() or ( not is_owned() and not Game.main.is_player_turn):
  return {}
 elif not Game.main.is_battle:
  return {face = "?"}
 else:
  return {face = face, letters = Letters.NUMPAD_CHARACTERS[face]}


func player_turn_started(is_battle_start: bool) -> void :
 super.player_turn_started(is_battle_start)
 if is_owned():
  randomize_face()
  description_updated.emit()


func battle_ended():
 super.battle_ended()
 if is_owned():
  description_updated.emit()
