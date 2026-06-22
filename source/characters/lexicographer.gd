extends Player


func _init():
 id = CHARACTERS.LEXICOGRAPHER
 starting_spells = [SPELLS.LETTER_OPENER]


func get_gender():
 if is_trans():
  return Gender.FEMALE
 else:
  return Gender.MALE
