@tool
class_name StringManager

enum TimeFlags{
 NONE = 0, 
 HOURS = 1 << 0, 
 MINUTES = 1 << 1, 
 SECONDS = 1 << 2, 
 THIRDS = 1 << 3, 
}
const HHMMSS: int = TimeFlags.HOURS | TimeFlags.MINUTES | TimeFlags.SECONDS
const MMSS: int = TimeFlags.MINUTES | TimeFlags.SECONDS
const MMSSTT: int = TimeFlags.MINUTES | TimeFlags.SECONDS | TimeFlags.THIRDS

const LETTERS_USING_AN: Array[String] = [
 "a", "e", "f", "h", "i", "l", 
 "m", "n", "o", "r", "s", "x", 
]

static var STRINGS: StringGroup = StringGroup.new()
static var data_sources: Dictionary[String, Dictionary] = {}
static var file_modified_timestamps: Dictionary[String, int] = {}
static var _loaded: bool = false

const STRING_TXT_FILES: PackedStringArray = [
 "res://strings/achievements.txt",
 "res://strings/character.txt",
 "res://strings/controls.txt",
 "res://strings/credits.txt",
 "res://strings/curse.txt",
 "res://strings/cutscenes.txt",
 "res://strings/difficulty.txt",
 "res://strings/enemy.txt",
 "res://strings/intent.txt",
 "res://strings/menu.txt",
 "res://strings/misc.txt",
 "res://strings/nobody.txt",
 "res://strings/spell.txt",
 "res://strings/status.txt",
 "res://strings/summary.txt",
 "res://strings/tutorial.txt",
]


static func ensure_loaded() -> void :
 if _loaded:
  return

 load_strings()


static func load_strings() -> void :
 STRINGS = StringGroup.new()
 var string_file_paths: = get_string_file_paths()
 for file_path in string_file_paths:
  if file_path.get_extension() != "txt":
   continue

  if Engine.is_editor_hint() or OS.is_debug_build():
   file_modified_timestamps[file_path] = FileAccess.get_modified_time(file_path)

  var file_identifier: = file_path.get_basename().replace("res://strings/", "")
  var file: = FileAccess.open(file_path, FileAccess.READ)
  if file == null:
   push_warning("Failed to open string file: ", file_path)
   continue

  var string_path: PackedStringArray = file_identifier.split("/", false)
  var empty_identifier_indices: = PackedInt32Array()
  empty_identifier_indices.resize(string_path.size() - 1)
  var base_string_path_size: = string_path.size()
  var current_string: = ""
  while not file.eof_reached():
   var line: = file.get_line()
   var tabs_stripped: = line.lstrip("\t")
   if tabs_stripped.begins_with("#"):
    continue
   elif tabs_stripped.begins_with(":") and tabs_stripped.ends_with(":"):
    if current_string != "":
     add_string(current_string, string_path)

    var num_tabs: = len(line) - len(tabs_stripped)
    var path_size: = string_path.size()
    if (num_tabs + base_string_path_size) < path_size:
     string_path.resize(num_tabs + base_string_path_size)
     empty_identifier_indices.resize(string_path.size())
    else:
     empty_identifier_indices.append(0)

    var identifier: String
    if tabs_stripped == "::":
     identifier = str(empty_identifier_indices[-1])
     empty_identifier_indices[-1] += 1
    else:
     identifier = tabs_stripped.substr(1, tabs_stripped.length() - 2)

    string_path.append_array(split_identifier(identifier))

    current_string = ""
    continue

   current_string = current_string + tabs_stripped + "\n"

  if current_string != "":
   add_string(current_string, string_path)

 _loaded = true


static func check_reload_strings() -> void :
 ensure_loaded()
 if not Engine.is_editor_hint():
  if not OS.is_debug_build() or OS.has_feature("web"):
   return

  var tree: SceneTree = Engine.get_main_loop()
  if tree.current_scene == null or not tree.current_scene.is_node_ready():
   return

 var string_file_paths: = get_string_file_paths()
 for file_path in string_file_paths:
  if file_path not in file_modified_timestamps:
   load_strings()
   return
  elif file_modified_timestamps[file_path] != FileAccess.get_modified_time(file_path):
   load_strings()
   return


static func get_string_file_paths() -> PackedStringArray:
 if Util.is_mobile() or OS.has_feature("web"):
  return STRING_TXT_FILES.duplicate()

 var string_file_paths: = Util.get_file_paths_recursive("res://strings", ".txt")
 if string_file_paths.is_empty():
  return STRING_TXT_FILES.duplicate()

 return string_file_paths


static func add_string(string: String, string_path: PackedStringArray) -> void :
 var stripped: = string.strip_edges()
 var string_data: Variant = DataString.create(stripped)
 STRINGS.add_string_data(string_path, string_data)


static func split_identifier(identifier: String) -> PackedStringArray:
 return identifier.split("/", false)


static func has_string_at_path(path: PackedStringArray) -> bool:
 check_reload_strings()
 return STRINGS.has_string_at_path(path)


static func has_string(identifier: String) -> bool:
 check_reload_strings()
 return STRINGS.has_string(identifier)


static func has_string_group_at_path(path: PackedStringArray) -> bool:
 check_reload_strings()
 return STRINGS.has_string_group_at_path(path)


static func has_string_group(identifier: String) -> bool:
 check_reload_strings()
 return STRINGS.has_string_group(identifier)


static func get_string_at_path(path: PackedStringArray, context: Dictionary = {}) -> String:
 check_reload_strings()
 return STRINGS.get_string_at_path(path, context)


static func get_string(identifier: String, context: Dictionary = {}) -> String:
 check_reload_strings()
 return STRINGS.get_string(identifier, context)


static func get_string_group_at_path(path: PackedStringArray) -> StringGroup:
 check_reload_strings()
 return STRINGS.get_string_group_at_path(path)


static func get_string_group(identifier: String) -> StringGroup:
 check_reload_strings()
 return STRINGS.get_string_group(identifier)


static func set_data_source(id: String, dictionary: Dictionary) -> void :
 data_sources[id] = dictionary


static func erase_data_source(id: String) -> void :
 data_sources.erase(id)


static func get_data_from_source(id: String, path: PackedStringArray, default: Variant = null) -> Variant:
 if id not in data_sources:
  return default

 var source: Dictionary = data_sources[id]
 var result: Variant = null
 for key in path:
  if result is Dictionary:
   if key in result:
    result = result[key]
   else:
    return default
  else:
   if key in source:
    result = source[key]
   else:
    return default

 if result is Callable:
  result = result.call()

 return result


static func get_list_string(list: Array[Variant], delimiter: String = "", pre_last_element: String = "", no_oxford_delimiter: String = "") -> String:
 var list_string: = ""
 var list_size: = list.size()
 if list_size == 1:
  return str(list[0])

 for i in list_size:
  var element: = str(list[i])
  var last_element: = i == list_size - 1
  if last_element:
   list_string += pre_last_element

  list_string += element

  if not last_element:
   if list_size == 2 and no_oxford_delimiter != "":
    list_string += no_oxford_delimiter
   else:
    list_string += delimiter

 return list_string


static func format_time(milliseconds: int, time_flags: int = MMSS) -> String:
 var thirds: = int(milliseconds / (1000.0 / 60.0))
 var seconds: = int(milliseconds / 1000.0)
 var minutes: = int(seconds / 60.0)
 var hours: = int(minutes / 60.0)

 var time_strings: = PackedStringArray()
 if hours > 0 or time_flags & TimeFlags.HOURS != 0:
  time_strings.append("%02d" % hours)

 if time_flags & TimeFlags.MINUTES != 0:
  time_strings.append("%02d" % (minutes % 60))

 if time_flags & TimeFlags.SECONDS != 0:
  time_strings.append("%02d" % (seconds % 60))

 if time_flags & TimeFlags.THIRDS != 0:
  time_strings.append("%02d" % (thirds % 60))

 return ":".join(time_strings)


static func format_time_string(milliseconds: int, time_string: String = "mm:ss") -> String:
 var thirds: = int(milliseconds / (1000.0 / 60.0))
 var seconds: = int(milliseconds / 1000.0)
 var minutes: = int(seconds / 60.0)
 var hours: = int(minutes / 60.0)

 minutes = minutes % 60
 seconds = seconds % 60
 thirds = thirds % 60

 var time_strings: = PackedStringArray()
 var chunks: = time_string.split(":")
 for chunk in chunks:
  if chunk[0] == "h":
   time_strings.append(str(hours).pad_zeros(len(chunk)))
  elif chunk[0] == "m":
   time_strings.append(str(minutes).pad_zeros(len(chunk)))
  elif chunk[0] == "s":
   time_strings.append(str(seconds).pad_zeros(len(chunk)))
  elif chunk[0] == "t":
   time_strings.append(str(thirds).pad_zeros(len(chunk)))

 return ":".join(time_strings)


static func indicate_sign(value: Variant) -> String:
 var compare_value: Variant = value
 if value is String:
  if value.is_valid_float():
   compare_value = value.to_float()
  else:
   compare_value = 1

 if compare_value < 0:
  return str(value)
 else:
  return "+" + str(value)


class StringGroup extends RefCounted:
 var groups: Dictionary[String, StringGroup] = {}
 var strings: Dictionary[String, Variant] = {}
 var path_from_origin: = PackedStringArray()


 func _traverse(path: PackedStringArray, look_for_string: bool) -> Variant:
  var group: StringGroup = self

  var path_size = path.size()
  for i in path_size:
   var key = path[i]
   if i == path_size - 1:
    if look_for_string:
     if key in group.strings:
      return group.strings[key]
     else:
      return null
    elif key in group.groups:
     return group.groups[key]
    else:
     return null
   elif key in group.groups:
    group = group.groups[key]
   else:
    return null

  return null


 func get_string_group_at_path(path: PackedStringArray) -> StringGroup:
  var group: StringGroup = _traverse(path, false)
  return group


 func get_string_group(identifier: String) -> StringGroup:
  return get_string_group_at_path(StringManager.split_identifier(identifier))


 func has_string_group_at_path(path: PackedStringArray) -> bool:
  return get_string_group_at_path(path) != null


 func has_string_group(identifier: String) -> bool:
  return get_string_group(identifier) != null


 func get_string_data(path: PackedStringArray) -> Variant:
  return _traverse(path, true)


 func has_string_at_path(path: PackedStringArray) -> bool:
  return get_string_data(path) != null


 func get_string_data_or_group(path: PackedStringArray) -> Variant:
  if has_string_group_at_path(path):
   return get_string_group_at_path(path)
  else:
   return get_string_data(path)


 func has_string_data_or_group(path: PackedStringArray) -> bool:
  if has_string_group_at_path(path):
   return true
  else:
   return get_string_data(path) != null


 func get_ordered_children() -> Array[Variant]:
  var array: Array[Variant] = []
  while true:
   var child: Variant = get_string_data_or_group([str(array.size())])
   if child == null:
    break

   array.append(child)

  return array


 func get_ordered_children_paths(from_origin: bool = false) -> Array[PackedStringArray]:
  var paths: Array[PackedStringArray] = []
  while true:
   var path: PackedStringArray = [str(paths.size())]
   var child: Variant = get_string_data_or_group(path)
   if child == null:
    break

   if from_origin:
    paths.append(path_from_origin + path)
   else:
    paths.append(path)

  return paths


 func has_string(identifier: String) -> bool:
  return has_string_at_path(StringManager.split_identifier(identifier))


 func get_string_at_path(path: PackedStringArray, context: Dictionary = {}, get_original: = false) -> String:
  var data_string: Variant = get_string_data(path)
  if data_string == null:
   push_error("Attempted to get string not present :" + "/".join(path) + ":")
   return ""

  if data_string is String:
   return data_string
  elif data_string is DataString:
   if get_original:
    return data_string.get_meta("original_string")
   else:
    return data_string.resolve(context, path_from_origin + path)
  else:
   assert (false, "Invalid string type")
   return ""


 func get_string(identifier: String, context: Dictionary = {}) -> String:
  return get_string_at_path(StringManager.split_identifier(identifier), context)


 func add_string_data(path: PackedStringArray, string: Variant, path_index: int = 0) -> void :
  var location: String = path[path_index]
  if path_index == path.size() - 1:
   strings[location] = string
   return

  if location not in groups:
   groups[location] = StringGroup.new()
   groups[location].path_from_origin = path.slice(0, path_index + 1)

  groups[location].add_string_data(path, string, path_index + 1)


 func get_file_formatted_strings() -> String:
  var out_string: String = ""
  var keys: = strings.keys()
  for key: String in keys:
   var string_data: Variant = strings[key]
   var string: String = ""
   if string_data is DataString:
    string = string_data.get_meta("original_string")
   else:
    string = string_data

   out_string += ":" + key + ":\n" + string.indent("\t")

   if key != keys[-1]:
    out_string += "\n\n"

  return out_string


 func get_file_formatted_groups() -> String:
  var out_string: String = ""
  var keys: = groups.keys()
  for key: String in keys:
   var group: = groups[key]
   out_string += ":" + key + ":\n"
   var group_string = group.get_file_formatted_string()
   out_string += group_string.indent("\t")

   if key != keys[-1]:
    out_string += "\n\n"

  return out_string


 func get_file_formatted_string() -> String:
  var strings_text: = get_file_formatted_strings()
  var groups_text: = get_file_formatted_groups()
  var out_string: String = ""
  if strings_text != "":
   out_string += strings_text
   if groups_text != "":
    out_string += "\n\n"

  out_string += groups_text

  return out_string


 func get_path_key() -> String:
  return "/".join(path_from_origin)
