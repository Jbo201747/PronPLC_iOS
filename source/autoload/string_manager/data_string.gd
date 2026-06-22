@tool
class_name DataString extends RefCounted



static var command_regex: RegEx = Util.regex("{[^{}]+}")

static var command_argument_regex: RegEx = Util.regex("(?:[^{}\"\\s]+|\"[^{}\"]*\")+")

var segments: Array[Variant] = []


static func create(string: String) -> Variant:
 var command_matches: = command_regex.search_all(string)
 if command_matches.size() == 0:
  return string

 return DataString.new(string, command_matches)


func _init(string: String, command_matches: Array[RegExMatch]) -> void :
 if OS.is_debug_build():
  set_meta("original_string", string)

 var string_segment_start: = 0
 for command_match in command_matches:
  var string_segment_length: = command_match.get_start() - string_segment_start
  if string_segment_length > 0:
   var string_segment: = string.substr(string_segment_start, string_segment_length)
   segments.append(string_segment)

  string_segment_start = command_match.get_end()

  var command = DataStringCommand.create(command_match.get_string())
  segments.append(command)

 var final_segment_length: = len(string) - string_segment_start
 if final_segment_length > 0:
  var string_segment: = string.substr(string_segment_start, final_segment_length)
  segments.append(string_segment)


func resolve(context: Dictionary, path: PackedStringArray) -> String:
 var out_string: = ""
 for segment: Variant in segments:
  if segment is String:
   out_string += segment
  elif segment is DataStringCommand:
   out_string += segment.resolve(context, path)

 return out_string.strip_edges()
