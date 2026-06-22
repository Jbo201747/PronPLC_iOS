@tool
@abstract class_name DataStringCommand extends RefCounted


static var argument_regex: RegEx = Util.regex("(?:[^{}\"\\s]+|\"[^{}\"]*\")+")


@abstract func resolve(context: Dictionary, path: PackedStringArray) -> String


static func create(string: String) -> DataStringCommand:
 var argument_matches: = argument_regex.search_all(string)
 assert (argument_matches.size() > 0, "Empty DataStringCommand")
 if argument_matches.size() == 1:
  var argument: = DataStringArgument.create(argument_matches[0].get_string())
  return Insert.new(argument)

 var command: = argument_matches[1].get_string()
 argument_matches.remove_at(1)

 var arguments: PackedStringArray = PackedStringArray()
 for argument_match in argument_matches:
  arguments.append(argument_match.get_string())

 if command == "if" or command == "not":
  return If.new(arguments, command == "if")
 elif command == "plural" or command == "single":
  return Plural.new(arguments, command == "plural")
 elif command == "aoran":
  return AorAn.new(arguments)
 elif command in List.COMMANDS:
  return List.new(arguments, command)
 elif command == "with":
  return With.new(arguments)
 elif command == "time":
  return ParseTime.new(arguments)
 elif command in ChangeCase.COMMANDS:
  return ChangeCase.new(arguments, command)

 assert (false, "Invalid command")
 return Literal.new(string)





class Insert extends DataStringCommand:
 var argument: DataStringArgument

 func _init(init_argument: DataStringArgument) -> void :
  argument = init_argument


 func resolve(context: Dictionary, path: PackedStringArray) -> String:
  return argument.get_string(context, path)






class If extends DataStringCommand:
 var string_argument: DataStringArgument
 var condition_argument: DataStringArgument
 var compare_argument: DataStringArgument = null
 var triggered_when_true: bool = true


 func _init(arguments: PackedStringArray, trigger_when_true: bool) -> void :
  var num_arguments: = arguments.size()
  assert (num_arguments == 2 or num_arguments == 3, "Bad if command")

  string_argument = DataStringArgument.create(arguments[0])
  condition_argument = DataStringArgument.create(arguments[1])

  if num_arguments > 2:
   compare_argument = DataStringArgument.create(arguments[2])

  triggered_when_true = trigger_when_true


 func resolve(context: Dictionary, path: PackedStringArray) -> String:
  var condition_is_true: = false
  if compare_argument != null:
   var condition_value: Variant = condition_argument.get_value(context, path)
   var compare_value: Variant = compare_argument.get_value(context, path)
   if condition_value is String or compare_value is String:
    condition_is_true = str(condition_value) == str(compare_value)
   else:
    condition_is_true = condition_value == compare_value
  else:
   condition_is_true = condition_argument.is_true(context, path)

  if condition_is_true == triggered_when_true:
   return string_argument.get_string(context, path)
  else:
   return ""





class Plural extends DataStringCommand:
 var value_argument: DataStringArgument
 var string_argument: DataStringArgument
 var triggered_when_plural: bool = true


 func _init(arguments: PackedStringArray, trigger_when_plural: bool) -> void :
  assert (arguments.size() == 2, "Bad plural command")
  value_argument = DataStringArgument.create(arguments[0])
  string_argument = DataStringArgument.create(arguments[1])
  triggered_when_plural = trigger_when_plural


 func resolve(context: Dictionary, path: PackedStringArray) -> String:
  var value: Variant = value_argument.get_value(context, path)
  if value == null:
   return ""

  var is_plural: = true
  if value is String:
   if value.is_valid_float():
    is_plural = value.to_float() != 1
  else:
   is_plural = value != 1

  if is_plural == triggered_when_plural:
   return string_argument.get_string(context, path)
  else:
   return ""





class AorAn extends DataStringCommand:
 var argument: DataStringArgument


 func _init(arguments: PackedStringArray) -> void :
  assert (arguments.size() == 1, "Bad aoran command")
  argument = DataStringArgument.create(arguments[0])


 func resolve(context: Dictionary, path: PackedStringArray) -> String:
  var value: Variant = argument.get_value(context, path)
  if value == null:
   return ""

  var insert: = "a"
  if value is Array and value.size() > 0:
   value = value[0]

  if value is String and len(value) > 0:
   if value.to_lower()[0] in StringManager.LETTERS_USING_AN:
    insert = "an"

  return insert







class List extends DataStringCommand:
 const COMMANDS: PackedStringArray = ["list_or", "list_and", "list_merge", "list_line", "list_delim"]

 enum Mode{
  LIST_OR, 
  LIST_AND, 
  LIST_MERGE, 
  LIST_LINE, 
  LIST_DELIM
 }

 var mode: Mode
 var case_mode: ChangeCase.Mode = ChangeCase.Mode.NONE
 var list_argument: DataStringArgument
 var delimiter: DataStringArgument


 func _init(arguments: PackedStringArray, list_type: String) -> void :
  var num_arguments: = arguments.size()
  assert (num_arguments > 0)

  list_argument = DataStringArgument.create(arguments[0])
  mode = COMMANDS.find(list_type) as Mode

  var case_argument_index: = 1
  if mode == Mode.LIST_DELIM:
   assert (num_arguments > 1 and num_arguments < 4)
   delimiter = DataStringArgument.create(arguments[1])
   case_argument_index = 2
  else:
   assert (num_arguments < 3)

  if num_arguments > case_argument_index:
   case_mode = ChangeCase.COMMANDS.find(arguments[case_argument_index]) as ChangeCase.Mode


 func resolve(context: Dictionary, path: PackedStringArray) -> String:
  var array: Variant = list_argument.get_value(context, path) as Array
  if array == null:
   return ""

  var using_array: Array[Variant] = array
  if case_mode != ChangeCase.Mode.NONE:
   using_array = ChangeCase.change_array_case(using_array, case_mode)

  var delimiter_string: String = ""
  var no_oxford_string: String = ""
  if mode == Mode.LIST_OR or mode == Mode.LIST_AND:
   delimiter_string = ", "
   no_oxford_string = " "
  elif mode == Mode.LIST_DELIM:
   delimiter_string = delimiter.get_string(context, path)
  elif mode == Mode.LIST_LINE:
   delimiter_string = "\n"

  var pre_last_element_string: String = ""
  if mode == Mode.LIST_OR:
   pre_last_element_string = "or "
  elif mode == Mode.LIST_AND:
   pre_last_element_string = "and "

  return StringManager.get_list_string(using_array, delimiter_string, pre_last_element_string, no_oxford_string)







class With extends DataStringCommand:
 var string_argument: DataStringArgument
 var context_keys: Dictionary[String, DataStringArgument] = {}

 func _init(arguments: PackedStringArray) -> void :
  assert (arguments.size() > 2 and arguments.size() % 2 == 1, "Bad with command")
  string_argument = DataStringArgument.create(arguments[0])

  for i in (arguments.size() - 1) / 2:
   var key: = arguments[(i * 2) + 1]
   var value_argument: = DataStringArgument.create(arguments[(i * 2) + 2])
   context_keys[key] = value_argument


 func resolve(context: Dictionary, path: PackedStringArray) -> String:
  var new_context: = context.duplicate()
  for key in context_keys:
   new_context[key] = context_keys[key].get_value(context, path)
  return string_argument.get_string(new_context, path)



class Literal extends DataStringCommand:
 var string: String


 func _init(init_string: String) -> void :
  string = init_string


 func resolve(_context: Dictionary, _path: PackedStringArray) -> String:
  return string




class ChangeCase extends DataStringCommand:
 const COMMANDS = ["capital", "upper", "lower", "sentence"]

 enum Mode{
  CAPITALIZE, 
  UPPERCASE, 
  LOWERCASE, 
  SENTENCE, 
  NONE, 
 }

 var mode: Mode
 var string_argument: DataStringArgument
 func _init(arguments: PackedStringArray, mode_string: String):
  assert (arguments.size() == 1, "Invalid case command")

  mode = COMMANDS.find(mode_string) as Mode
  string_argument = DataStringArgument.create(arguments[0])


 func resolve(context: Dictionary, path: PackedStringArray) -> String:
  var string: = string_argument.get_string(context, path)
  return change_case(string, mode)


 static func change_case(string: String, case_mode: Mode) -> String:
  if case_mode == Mode.CAPITALIZE:
   return string.capitalize()
  elif case_mode == Mode.UPPERCASE:
   return string.to_upper()
  else:
   return string.to_lower()


 static func change_array_case(strings: PackedStringArray, case_mode: Mode) -> PackedStringArray:
  var out_array: = PackedStringArray()
  var num_strings: = strings.size()
  out_array.resize(num_strings)
  for i in strings.size():
   if case_mode == Mode.SENTENCE:
    if i == 0:
     out_array[i] = strings[i].capitalize()
    else:
     out_array[i] = strings[i].to_lower()
   else:
    out_array[i] = change_case(strings[i], case_mode)

  return out_array




class ParseTime extends DataStringCommand:
 var value_argument: DataStringArgument
 var string_argument: DataStringArgument

 func _init(arguments: PackedStringArray) -> void :
  assert (arguments.size() == 2, "Invalid time command")

  value_argument = DataStringArgument.create(arguments[0])
  string_argument = DataStringArgument.create(arguments[1])


 func resolve(context: Dictionary, path: PackedStringArray) -> String:
  var value: Variant = value_argument.get_value(context, path)
  var milliseconds: int = -1
  if value is String:
   if value.is_valid_int():
    milliseconds = value.to_int()
  elif value is int:
   milliseconds = value
  elif value is float:
   milliseconds = int(value)

  if milliseconds == -1:
   return ""
  else:
   return StringManager.format_time_string(milliseconds, string_argument.get_string(context, path))
