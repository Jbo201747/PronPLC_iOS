@tool
class_name SortedWords extends Resource

@export var words: = PackedStringArray()
@export var length_indices: = PackedInt32Array()

var last_added_length: = -1

func add_word(word: String) -> void :
 words.append(word)

 var length: = len(word)
 if length > last_added_length:
  var last_word_index: = words.size() - 1
  if last_added_length != -1:
   length_indices.append(last_word_index - 1)
  else:
   last_added_length = 0

  var length_difference: = length - last_added_length
  if length_difference > 1:
   for i in length_difference - 1:
    length_indices.append_array([-1, -1])

  length_indices.append(last_word_index)
  last_added_length = length


func finish_adding_words() -> void :
 var last_word_index: = words.size() - 1
 length_indices.append(last_word_index)


func has_word(word: String) -> bool:
 return word in words


func has_words_with_length(length: int) -> bool:
 var end_index = ((length - 1) * 2) + 1
 return length_indices.size() > end_index and length_indices[end_index] != -1


func get_words_by_length(min_length: int, max_length: int = -1) -> PackedStringArray:
 if max_length == -1:
  max_length = min_length

 var start_index: = length_indices[(min_length - 1) * 2]
 if start_index == -1:
  return PackedStringArray()

 var end_index: = length_indices[(max_length - 1) * 2 + 1]
 if end_index == -1:
  while end_index == -1:
   max_length -= 1
   end_index = length_indices[(max_length - 1) * 2 + 1]

 return words.slice(start_index, end_index + 1)


func get_index_range(length: int = -1) -> Vector2i:
 if length == -1:
  return Vector2i(0, words.size() - 1)
 else:
  var start_index: = length_indices[(length - 1) * 2]
  assert (start_index != -1, "Attempted to get index range for length that has no words")
  var end_index: = length_indices[(length - 1) * 2 + 1]
  return Vector2i(start_index, end_index)


func pick_random(length: int = -1, rng: RNG = Game.random) -> String:
 var index_range: = get_index_range(length)
 return words[rng.randi_range(index_range.x, index_range.y)]
