@tool
class_name WordMapDictionary extends WordDictionary


@export var word_map: Dictionary[String, bool] = {}


func add_word(word: String) -> void :
 super.add_word(word)
 word_map[word] = true


func is_word(word: String) -> bool:
 return word in word_map
