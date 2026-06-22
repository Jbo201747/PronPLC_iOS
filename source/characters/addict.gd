extends Player


func _init():
 id = CHARACTERS.ADDICT
 starting_spells = [SPELLS.SALT]


func get_gender():
 if is_trans():
  return Gender.MALE
 else:
  return Gender.FEMALE
