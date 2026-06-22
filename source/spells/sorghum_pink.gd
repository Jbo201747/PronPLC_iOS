extends Spell


var abbreviations = [
 "ilu", "ily", "luv", "qtp", "otp", 
 "fwb", "gfs", "bfs", "xox", "pda", 
 "asl", "t4t", "lu2", "hot", "qtp", 
]


func set_status_tooltips():
 status_tooltips = [TileStatus.CANDY]


func sort_tiles_tl_to_br(tile_a, tile_b):
 var coord_a = tile_a.get_coord()
 var coord_b = tile_b.get_coord()

 if coord_a.x != coord_b.x:
  return coord_a.x < coord_b.x
 else:
  return coord_a.y > coord_b.y


func _use():
 var row_priority = []
 for row in tile_board.get_row_coords():
  var tiles = get_tiles({
   rows = [row], 
   sorted = true, 
   effect_priority = FACE_EFFECT_PRIORITY, 
  })

  if tiles.size() >= 3:
   row_priority.append(row)

 if row_priority.size() > 0:
  rng.spell.shuffle(row_priority)

 var apply_to = get_tiles({
  amount = 3, 
  row_priority = row_priority, 
  effect_priority = FACE_EFFECT_PRIORITY, 
 })

 if apply_to.is_empty():
  _end_use()
  return

 apply_to.sort_custom(sort_tiles_tl_to_br)

 var abbreviation = rng.spell.pick_random(abbreviations)
 var index = 0

 for tile in apply_to:
  var letter = abbreviation[index]
  tile.remove_face_statuses()
  tile.add_status(TileStatus.CANDY)
  tile.set_face(letter)
  tile.add_poofcloud(tile.get_color())
  index += 1

 _post_use()
