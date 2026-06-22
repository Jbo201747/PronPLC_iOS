extends Node


const REPORTED_MISSING_FILE = "user://reported_missing.txt"
const REPORTED_FAKE_FILE = "user://reported_fake.txt"

var dictionary: WordDictionary = preload("res://words/compiled.res")

var reported_missing_words = {}
var reported_fake_words = {}


func _ready():
 load_report_file(REPORTED_MISSING_FILE, reported_missing_words)
 load_report_file(REPORTED_FAKE_FILE, reported_fake_words)


func report_tiles(tiles, valid):
 var reporting_string = ""
 for tile: Tile in tiles:
  if tile.is_space():
   reporting_string += " "
  elif tile.faces.size() == 1:
   reporting_string += tile.face
  else:
   var sorted_faces = tile.faces.duplicate()
   sorted_faces.sort()
   reporting_string += str(sorted_faces)

 if valid:
  if reporting_string not in reported_fake_words:
   reported_fake_words[reporting_string] = true
   add_to_report_file(reporting_string, REPORTED_FAKE_FILE)
 else:
  if reporting_string not in reported_missing_words:
   reported_missing_words[reporting_string] = true
   add_to_report_file(reporting_string, REPORTED_MISSING_FILE)


func add_to_report_file(string, filename):
 var file
 if FileAccess.file_exists(filename):
  file = FileAccess.open(filename, FileAccess.READ_WRITE)
 else:
  file = FileAccess.open(filename, FileAccess.WRITE)

 if not file:
  return

 file.seek_end()
 file.store_string(string + "\n")


func word_list_has_flag(word_list: WordList, flag: Variant) -> bool:
 return any_word_has_flag(word_list.words, flag)


func any_word_has_flag(words, flag) -> bool:
 for word in words:
  if flag is Array:
   if dictionary.word_has_any_flag(word, flag):
    return true
  elif dictionary.word_has_flag(word, flag):
   return true

 return false


func load_report_file(filename, dict):
 var file = FileAccess.open(filename, FileAccess.READ)
 if not file:
  return

 while not file.eof_reached():
  var line = file.get_line().to_lower()
  if line != "":
   dict[line] = true


func is_wildcard_character(character):
 return character in Letters.WILDCARD_CHARACTERS


func get_wildcard_glob(word):
 for wildcard_character in Letters.WILDCARD_CHARACTERS:
  word = word.replace(wildcard_character, "?")

 return word




func resolve_tile_words(tiles, priority_words: = PackedStringArray(), depriority_words: = PackedStringArray(), priority_flag: WordDictionary.WordFlags = WordDictionary.WordFlags.NONE) -> WordList:
 var full_word_list = WordList.new()
 full_word_list.all_valid = true

 var tile_sets = [[]]

 for tile: Tile in tiles:
  if tile.is_space():
   tile_sets.append([])
   continue

  var current_set = tile_sets[-1]
  current_set.append(tile)

 for tile_set in tile_sets:
  var word_list = WordList.new()
  word_list.set_priority(priority_words, depriority_words, priority_flag)

  for tile: Tile in tile_set:
   word_list.add_tile(tile)

  if not tile_set.is_empty():
   word_list.generate_permutations()
   word_list.resolve()

   if word_list.all_valid:
    word_list.set_tile_wildcard_faces()

  full_word_list.extend_from_word_list(word_list)

 return full_word_list


func can_submit_word_list(word_list):
 var settings = {valid = true, minimum_length = 3}

 return (word_list.all_valid and word_list.words.size() > 0
 and word_list.minimum_length >= settings.minimum_length and settings.valid)


func get_lotd_words(letter):
 const MIN_LENGTH = 6
 const MAX_LENGTH = 6

 var lotd_words = []
 var letter_cap = Letters.LETTER_CAPS[letter].soft
 var words = dictionary.words.words

 while lotd_words.size() < 10 and letter_cap > 0:
  for word in words:
   if word.length() >= MIN_LENGTH and word.length() <= MAX_LENGTH:
    if word.countn(letter) >= letter_cap and word not in lotd_words:
     lotd_words.append(word)

  letter_cap -= 1

 return lotd_words
