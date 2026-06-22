extends Status


var mystery_seed: int = 0


func get_tooltip_context():
 var face = tile.face
 var face_length = len(face)
 if face_length < 1 or face_length > 2:
  return {}

 var letter = face[0]
 if letter not in Letters.LETTER_VALUES:
  return {}

 var letter_value = Letters.LETTER_VALUES[letter]

 var possible_faces = []
 if face_length == 2:
  possible_faces = Letters.DOUBLE_LETTERS
 else:
  possible_faces = Letters.LETTER_VALUES

 var matching_faces = []
 var has_matchable_face: = false
 for possible_face in possible_faces:
  if face == possible_face:
   has_matchable_face = true
  elif Letters.LETTER_VALUES[possible_face[0]] == letter_value and possible_face != "q":
   matching_faces.append(possible_face)

 if not has_matchable_face:
  return {}

 var rng: = RNG.new()
 rng.set_seed(mystery_seed)
 rng.shuffle(matching_faces)

 matching_faces.push_front(face)

 if matching_faces.size() > Game.balance.mystery_options:
  matching_faces = matching_faces.slice(0, Game.balance.mystery_options)

 matching_faces.sort()

 return {faces = matching_faces, double = face_length == 2}


func apply(data):
 if data != null:
  mystery_seed = data
 else:
  mystery_seed = Game.random.randi()


func get_save_data():
 return mystery_seed


func load_save_data(_mystery_seed):
 if _mystery_seed != null:
  mystery_seed = _mystery_seed
