@tool
class_name WordDictionary extends Resource

enum WordFlags{
 NONE, 

 VERY_COMMON, 
 COMMON, 
 SWEAR, 
 SLUR, 

 ANIMALS, 
 BODY_PARTS, 
 COLORS, 
 FRUITS_AND_VEGETABLES, 
 METALS, 
}

const COMMON_FLAGS: Array[WordFlags] = [WordFlags.VERY_COMMON, WordFlags.COMMON]
const SWEAR_FLAGS: Array[WordFlags] = [WordFlags.SWEAR, WordFlags.SLUR]

@export var words: = SortedWords.new()
@export var word_flags: Dictionary[WordFlags, SortedWords] = {}


func add_word(word: String) -> void :
 words.add_word(word)


func finish_adding_words() -> void :
 words.finish_adding_words()
 for flag in word_flags:
  word_flags[flag].finish_adding_words()


func flag_word(word: String, flag: WordFlags) -> void :
 if flag not in word_flags:
  word_flags[flag] = SortedWords.new()

 word_flags[flag].add_word(word)


func is_word(word: String) -> bool:
 return words.has_word(word)


func word_has_flag(word: String, flag: WordFlags) -> bool:
 return word_flags[flag].has_word(word)


func word_has_any_flag(word: String, flags: Array[WordFlags]) -> bool:
 for flag in flags:
  if word_has_flag(word, flag):
   return true

 return false


func pick_random_flag_word(flag: WordFlags, length: int = -1, rng: RandomNumberGenerator = Game.random) -> String:
 return word_flags[flag].pick_random(length, rng)


func pick_random_flags_word(flags: Array[WordFlags], length: int = -1, rng: RandomNumberGenerator = Game.random) -> String:
 var index_ranges: Array[Vector2i] = []
 var range_starts: Array[int] = []
 var total_range: = 0
 for flag in flags:
  var indices: = word_flags[flag].get_index_range(length)
  range_starts.append(total_range)
  total_range += (indices.y - indices.x) + 1
  index_ranges.append(indices)

 var roll = rng.randi_range(0, total_range - 1)
 for i in range(range_starts.size() - 1, -1, -1):
  var range_start = range_starts[i]
  if roll >= range_start:
   var index_range: = index_ranges[i]
   return word_flags[flags[i]].words[roll - range_start + index_range.x]

 assert (false, "Failed to find any word of length within flags")
 return ""


func pick_random_word(length: int = -1, rng = Game.random) -> String:
 return words.pick_random(length, rng)


func has_length(length: int) -> bool:
 return words.has_words_with_length(length)


func get_words_by_length(min_length: int, max_length: int = -1) -> PackedStringArray:
 return words.get_words_by_length(min_length, max_length)


func has_flag_words_with_length(flag: WordFlags, length: int) -> bool:
 return word_flags[flag].has_words_with_length(length)


func get_flag_words_by_length(flag: WordFlags, min_length: int, max_length: int = -1) -> PackedStringArray:
 return word_flags[flag].get_words_by_length(min_length, max_length)


func get_flags_words_by_length(flags: Array[WordFlags], min_length: int, max_length: int = -1) -> PackedStringArray:
 var array: = PackedStringArray()
 for flag in flags:
  array.append_array(get_flag_words_by_length(flag, min_length, max_length))

 return array
