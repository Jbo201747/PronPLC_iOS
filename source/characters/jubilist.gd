extends Player


func _init():
 id = CHARACTERS.JUBILIST
 starting_spells = [SPELLS.GIFT_ENHANCING]


func get_gender():
 if is_trans():
  return Gender.NONBINARY
 else:
  return Gender.FEMALE
