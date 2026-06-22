class_name WordList extends RefCounted

const RESPECT_SHIMMERING_VALUE = true

enum PermutationWordResult{
 OK, 
 NO_MATCH, 
 WILDCARD_INVALID
}

var tiles: Dictionary[Tile, FaceSet] = {}
var tiles_list: Array[Tile]:
 get():
  return tiles.keys()
var all_face_sets: Array[FaceSet] = []
var all_faces: Array[Face] = []
var all_wildcards: Array[Wildcard] = []
var permutations: Array[Permutation] = []
var wildcard_permutations: Array[Permutation] = []
var all_valid: bool = false
var wildcard_conflicts: bool = false
var invalid_word: String = ""
var words: = PackedStringArray()
var wildcard_words: = PackedStringArray()
var max_wildcard_identity_value: int = -1
var wildcard_identities: Dictionary[Wildcard, String] = {}
var sub_lists: Array[WordList] = []
var minimum_length: int = -1
var maximum_length: int = -1
var last_displayed_permutation: int = -1
var identity_hashes: Dictionary[int, bool] = {}
var permutation_hashes: Dictionary[int, bool] = {}

var priority_words: = PackedStringArray()
var depriority_words: = PackedStringArray()
var priority_flag: WordDictionary.WordFlags = WordDictionary.WordFlags.NONE


func add_tile(tile: Tile) -> void :
 tile.reset_wildcard_faces()

 var face_set = WordList.FaceSet.new()
 for face_string in tile.faces:
  var face: = WordList.Face.new(face_string, tile.tile_face.slashed_faces)
  face_set.faces.append(face)

 tiles[tile] = face_set
 add_face_set(face_set)


func set_priority(_priority_words: PackedStringArray, _depriority_words: PackedStringArray, _priority_flag: WordDictionary.WordFlags) -> void :
 priority_words = _priority_words
 depriority_words = _depriority_words
 priority_flag = _priority_flag


func set_tile_wildcard_faces() -> void :
 for tile in tiles:
  var wildcard_faces: Dictionary[int, String] = {}
  var face_set: = tiles[tile]
  for i in face_set.faces.size():
   var face: = face_set.faces[i]
   if face.has_wildcard:
    wildcard_faces[i] = face.text

  tile.set_wildcard_faces(wildcard_faces)


func add_face_set(face_set: FaceSet) -> void :
 all_face_sets.append(face_set)
 all_faces.append_array(face_set.faces)
 for face in face_set.faces:
  for wildcard in face.wildcards:
   all_wildcards.append(wildcard)


func add_permutation(permutation: Permutation) -> void :
 permutations.append(permutation)
 if minimum_length == -1:
  minimum_length = permutation.length
 else:
  minimum_length = min(minimum_length, permutation.length)

 if maximum_length == -1:
  maximum_length = permutation.length
 else:
  maximum_length = max(maximum_length, permutation.length)


func generate_permutations(permutation_faces: Array[Face] = [], face_set_index: int = 0) -> void :
 var face_set: FaceSet = all_face_sets[face_set_index]
 var is_last_face: bool = face_set_index == all_face_sets.size() - 1
 for face: Face in face_set.faces:
  var next_faces: Array[Face] = permutation_faces.duplicate()
  next_faces.append(face)
  if is_last_face:
   var permutation: = Permutation.new(next_faces)
   add_permutation(permutation)
  else:
   generate_permutations(next_faces, face_set_index + 1)


func validate_permutation_word(permutation: Permutation, word: String, add_to_hashes: bool, is_only_permutation: bool) -> PermutationWordResult:
 if not word.match (permutation.glob):
  return PermutationWordResult.NO_MATCH

 var adding_global_hashes: Dictionary[int, bool] = {}
 var adding_permutation_hashes: Dictionary[int, bool] = {}
 var adding_valid_identities: Dictionary[Wildcard, String] = {}

 var global_identities: Dictionary[Wildcard, String] = {}
 var permutation_identities: Dictionary[Variant, String] = {}
 if not is_only_permutation:
  permutation_identities[permutation] = ""

 var group_identities: Dictionary[int, String] = {}
 for wildcard in permutation.wildcards:
  var word_char: = wildcard.get_word_slice(word, permutation.wildcards[wildcard])
  if not wildcard.can_become(word_char):
   return PermutationWordResult.NO_MATCH

  if wildcard.group != -1 and wildcard.group in group_identities:
   if group_identities[wildcard.group] != word_char:
    return PermutationWordResult.WILDCARD_INVALID

  global_identities[wildcard] = word_char
  if not is_only_permutation:
   var identity_hash: = global_identities.hash()
   if add_to_hashes:
    adding_global_hashes[identity_hash] = true
   elif identity_hash not in identity_hashes:
    return PermutationWordResult.WILDCARD_INVALID

   permutation_identities[wildcard] = word_char
   adding_permutation_hashes[permutation_identities.hash()] = true

   if word_char not in wildcard.next_valid_identities:
    adding_valid_identities[wildcard] = word_char

  if wildcard.group != -1:
   group_identities[wildcard.group] = word_char

 if not is_only_permutation:
  identity_hashes.merge(adding_global_hashes)
  permutation_hashes.merge(adding_permutation_hashes)

  for wildcard in adding_valid_identities:
   wildcard.next_valid_identities.append(adding_valid_identities[wildcard])
 else:
  wildcard_identities = global_identities

 return PermutationWordResult.OK


func validate_permutation_words(out: Dictionary, check_words: PackedStringArray, ignore_words: PackedStringArray, check_length: bool, permutation: Permutation, any_wildcard_not_restricting: bool, is_only_permutation: bool) -> void :
 var has_ignore_words: = not ignore_words.is_empty()
 for word in check_words:
  if check_length and len(word) != permutation.length:
   continue

  if has_ignore_words and word in ignore_words:
   continue

  var word_result: PermutationWordResult = validate_permutation_word(permutation, word, any_wildcard_not_restricting, is_only_permutation)
  if word_result == PermutationWordResult.OK:
   if not out.any_word_valid:
    out.any_word_valid = true
    if is_only_permutation:
     break
  elif word_result == PermutationWordResult.WILDCARD_INVALID:
   out.any_word_matched = true


func validate_permutation(permutation: Permutation, is_only_permutation: bool) -> void :
 if not WordUtility.dictionary.has_length(permutation.length):
  permutation.invalid = true
  return

 var any_wildcard_not_restricting: = false
 for wildcard in permutation.wildcards:
  if not wildcard.restricting_identities:
   any_wildcard_not_restricting = true
   break

 var match_data: Dictionary = {
  any_word_matched = false, 
  any_word_valid = false
 }

 var deprioritized_words: = depriority_words.duplicate()
 if not priority_words.is_empty():
  validate_permutation_words(match_data, priority_words, deprioritized_words, true, permutation, any_wildcard_not_restricting, is_only_permutation)
  deprioritized_words.append_array(priority_words)

 if not match_data.any_word_valid and priority_flag != WordDictionary.WordFlags.NONE:
  if WordUtility.dictionary.has_flag_words_with_length(priority_flag, permutation.length):
   var flag_words_by_length: = WordUtility.dictionary.get_flag_words_by_length(priority_flag, permutation.length)
   validate_permutation_words(match_data, flag_words_by_length, deprioritized_words, false, permutation, any_wildcard_not_restricting, is_only_permutation)
   deprioritized_words.append_array(flag_words_by_length)

 if not match_data.any_word_valid:
  var words_of_length: = WordUtility.dictionary.get_words_by_length(permutation.length)
  validate_permutation_words(match_data, words_of_length, deprioritized_words, false, permutation, any_wildcard_not_restricting, is_only_permutation)

 if not match_data.any_word_valid:
  validate_permutation_words(match_data, depriority_words, PackedStringArray(), true, permutation, any_wildcard_not_restricting, is_only_permutation)

 if not match_data.any_word_valid:
  permutation.invalid = true
  permutation.invalid_by_wildcards = match_data.any_word_matched
  return

 for wildcard in permutation.wildcards:
  wildcard.restricting_identities = true
  wildcard.valid_identities = wildcard.next_valid_identities
  wildcard.next_valid_identities = PackedStringArray()


func validate_permutations() -> bool:
 var single_permutation = permutations.size() == 1
 for permutation in permutations:
  if permutation.has_wildcard:
   validate_permutation(permutation, single_permutation)
   if permutation.invalid and not permutation.invalid_by_wildcards:
    invalid_word = permutation.get_combined_string()
    return false

   wildcard_permutations.append(permutation)
  elif WordUtility.dictionary.is_word(permutation.glob):
   words.append(permutation.glob)
  else:
   invalid_word = permutation.glob
   return false

 return true


func resolve_wildcard_identities(identities: Dictionary[Wildcard, String] = {}, permutation_identities: Dictionary[Permutation, Dictionary] = {}, group_identities: Dictionary[int, String] = {}, wildcard_index: int = 0) -> bool:
 var wildcard: = all_wildcards[wildcard_index]
 var is_last_wildcard: bool = wildcard == all_wildcards[-1]
 var any_resolved: = false
 for identity in wildcard.valid_identities:
  var next_identities: Dictionary[Wildcard, String] = identities.duplicate()
  next_identities[wildcard] = identity

  var invalid: = false
  var next_permutation_identities: Dictionary[Permutation, Dictionary] = permutation_identities.duplicate()
  for permutation_ref in wildcard.permutations:
   var permutation: Permutation = permutation_ref.get_ref()
   if permutation not in permutation_identities:
    next_permutation_identities[permutation] = {}
    next_permutation_identities[permutation][permutation] = ""
   else:
    next_permutation_identities[permutation] = permutation_identities[permutation].duplicate()

   var permutation_identity: = next_permutation_identities[permutation]
   permutation_identity[wildcard] = identity

   if permutation_identity.hash() not in permutation_hashes:
    invalid = true
    break

  if invalid:
   continue

  var next_group_identities: Dictionary[int, String] = group_identities.duplicate()
  if wildcard.group != -1:
   if wildcard.group in next_group_identities:
    if next_group_identities[wildcard.group] != identity:
     continue
   else:
    next_group_identities[wildcard.group] = identity

  if is_last_wildcard:
   var value: int = 0
   if RESPECT_SHIMMERING_VALUE:
    value = calculate_identity_value(next_identities)
    if value <= max_wildcard_identity_value:
     continue

   wildcard_identities = next_identities

   if RESPECT_SHIMMERING_VALUE:
    max_wildcard_identity_value = value
    any_resolved = true
   else:
    return true
  else:
   var resolved: = resolve_wildcard_identities(next_identities, next_permutation_identities, next_group_identities, wildcard_index + 1)
   if resolved:
    if not RESPECT_SHIMMERING_VALUE:
     return true
    else:
     any_resolved = true

 return any_resolved


func resolve() -> void :
 all_valid = validate_permutations()
 if not all_valid:
  return

 if not wildcard_permutations.is_empty():
  if wildcard_identities.is_empty():
   var resolved: = resolve_wildcard_identities()
   if not resolved:
    all_valid = false
    wildcard_conflicts = true
    return

  for permutation in wildcard_permutations:
   var resolved_word: = permutation.resolve(wildcard_identities)
   words.append(resolved_word)

  for wildcard in wildcard_identities:
   var face: Face = wildcard.face
   face.text[wildcard.index] = wildcard_identities[wildcard]


func extend_from_word_list(word_list: WordList) -> void :
 words.append_array(word_list.words)

 if invalid_word == "" and word_list.invalid_word != "":
  invalid_word = word_list.invalid_word

 all_valid = all_valid != false and word_list.all_valid
 if minimum_length == -1:
  minimum_length = word_list.minimum_length
 else:
  minimum_length = min(word_list.minimum_length, minimum_length)

 if maximum_length == -1:
  maximum_length = word_list.maximum_length
 else:
  maximum_length = max(word_list.maximum_length, maximum_length)

 sub_lists.append(word_list)


func get_first_word():
 return words[0]


func calculate_identity_value(identity: Dictionary[Wildcard, String]) -> int:
 var value: int = 0
 for wildcard in identity:
  if wildcard is Wildcard:
   value += Letters.LETTER_VALUES[identity[wildcard]]

 return value



class FaceSet extends RefCounted:
 var faces: Array[Face] = []



class Face extends RefCounted:

 var text: String = ""

 var glob: String = ""

 var index: int = 0

 var wildcards: Array[Wildcard] = []

 var has_wildcard: = false

 func _init(face: String, slashed_faces: PackedStringArray) -> void :
  text = face
  glob = face
  for i in len(face):
   var character = face[i]
   if WordUtility.is_wildcard_character(character):
    has_wildcard = true
    var wildcard: = Wildcard.new(self, character, i, slashed_faces)
    wildcards.append(wildcard)
    glob[i] = "?"



class Wildcard extends RefCounted:

 var face_ref: WeakRef
 var face: Face:
  get():
   return face_ref.get_ref()
  set(value):
   face_ref = weakref(value)

 var character: String = ""

 var index: int = 0

 var group: int = -1

 var valid_identities: = PackedStringArray()


 var next_valid_identities: = PackedStringArray()


 var restricting_identities: = false

 var slashed_faces: = PackedStringArray()

 var permutations: Array[WeakRef] = []

 func _init(_face: Face, _character: String, _index: int, _slashed_faces: PackedStringArray) -> void :
  face = _face
  character = _character
  index = _index
  slashed_faces = _slashed_faces

  if character in Letters.WILDCARD_GROUPS:
   group = Letters.WILDCARD_GROUPS[character]


 func get_word_slice(word: String, face_word_index: int) -> String:
  return word[face_word_index + index]


 func sub(word: String, face_word_index: int, with_character: String) -> String:
  word[face_word_index + index] = with_character
  return word


 func can_become(word_char: String) -> bool:
  if restricting_identities:
   return word_char in valid_identities

  if character == "/":
   if "*" in slashed_faces:
    return true

   if word_char in slashed_faces:
    return true

   for slashed_face in slashed_faces:
    if slashed_face in Letters.NUMPAD_CHARACTERS:
     if word_char in Letters.NUMPAD_CHARACTERS[slashed_face]:
      return true

   return false
  elif character in Letters.NUMPAD_CHARACTERS:
   return word_char in Letters.NUMPAD_CHARACTERS[character]
  else:
   return true



class Permutation extends RefCounted:

 var glob: String = ""

 var length: int = 0

 var faces: Array[Face]

 var wildcards: Dictionary[Wildcard, int] = {}

 var has_wildcard: bool = false

 var invalid: bool = false

 var invalid_by_wildcards: bool = false


 func _init(_faces: Array[Face]) -> void :
  faces = _faces

  for face in faces:
   if face.has_wildcard:
    for wildcard in face.wildcards:
     wildcards[wildcard] = length
     wildcard.permutations.append(weakref(self))
    has_wildcard = true

   length += len(face.glob)
   glob += face.glob


 func get_combined_string() -> String:
  var combined_string: String = ""
  for face in faces:
   combined_string += face.text

  return combined_string


 func resolve(identities: Dictionary[Wildcard, String]) -> String:
  var resolved_word: = glob
  for wildcard in wildcards:
   resolved_word = wildcard.sub(resolved_word, wildcards[wildcard], identities[wildcard])

  return resolved_word
