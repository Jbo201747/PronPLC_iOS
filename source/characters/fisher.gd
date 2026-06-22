extends Player


func _init():
 id = CHARACTERS.FISHER
 starting_spells = [SPELLS.FISHING_ROD]


func get_gender():
 if is_trans():
  return Gender.FEMALE
 else:
  return Gender.MALE
