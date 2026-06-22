extends Player


func _init():
 id = CHARACTERS.CHILD
 max_health = 6
 health = 6
 starting_spells = [SPELLS.HOLE_PUNCH]


func get_gender():
 if is_trans():
  return Gender.MALE
 else:
  return Gender.FEMALE
