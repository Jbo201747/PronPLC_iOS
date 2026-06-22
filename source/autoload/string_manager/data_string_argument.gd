@tool
@abstract class_name DataStringArgument extends RefCounted


@abstract func get_value(_context: Dictionary, _path: PackedStringArray) -> Variant


static func create(string: String) -> DataStringArgument:
 var length: = len(string)
 if length >= 2:

  if string == "\"\"":
   return Literal.new("")

  elif string[0] == "\"" and string[-1] == "\"":
   return Literal.new(string.substr(1, length - 2))

 if "&" in string:
  var argument: = And.new()
  argument.sub_arguments = split_subarguments(string, "&")
  return argument

 if "|" in string:
  var argument: = FirstAvailable.new()
  argument.sub_arguments = split_subarguments(string, "|")
  return argument

 if "." in string:
  var split: = string.split(".")
  if split.size() > 1:
   var argument: = FromSource.new()
   if split[0].begins_with("+"):
    argument.indicate_sign = true
    argument.source_id = split[0].substr(1)
   else:
    argument.source_id = split[0]
   argument.path = split.slice(1)
   return argument

 if length >= 2:

  if string[0] == ":" and string[-1] == ":":
   var argument: = Insert.new()
   argument.insert_path = string.substr(1, length - 2).split("/")
   return argument

 if string.is_valid_int():
  return Number.new(string)

 return Context.new(string)


static func split_subarguments(source: String, split_by: String) -> Array[DataStringArgument]:
 var sub_arguments: Array[DataStringArgument] = []
 for sub_argument in source.split(split_by):
  sub_arguments.append(create(sub_argument))

 return sub_arguments


func has_value(_context: Dictionary, _path: PackedStringArray) -> bool:
 return true


func is_true(context: Dictionary, path: PackedStringArray) -> bool:
 var value: Variant = get_value(context, path)
 return value != null and (value is not bool or value != false)


func get_string(context: Dictionary, path: PackedStringArray) -> String:
 return str(get_value(context, path))


class Literal extends DataStringArgument:
 var string: String

 func _init(init_string: String) -> void :
  string = init_string


 func get_value(_context: Dictionary, _path: PackedStringArray) -> Variant:
  return string


class Number extends DataStringArgument:
 var number: int

 func _init(init_string: String) -> void :
  number = init_string.to_int()


 func get_value(_context: Dictionary, _path: PackedStringArray) -> int:
  return number


class Insert extends DataStringArgument:
 var insert_path: PackedStringArray

 func get_value(context: Dictionary, path: PackedStringArray) -> Variant:
  for i: int in range(path.size(), -1, -1):
   var from_path: = path.slice(0, i)
   from_path.append_array(insert_path)
   if StringManager.has_string_at_path(from_path):
    return StringManager.get_string_at_path(from_path, context)

  return null


class Context extends DataStringArgument:
 var key: String
 var indicate_sign: bool = false

 func _init(init_key: String) -> void :
  if init_key.begins_with("+"):
   indicate_sign = true
   init_key = init_key.substr(1)
  key = init_key


 func has_value(context: Dictionary, _path: PackedStringArray) -> bool:
  return key in context


 func get_value(context: Dictionary, _path: PackedStringArray) -> Variant:
  if key in context:
   return context[key]
  else:
   return null


 func get_string(context: Dictionary, _path: PackedStringArray) -> String:
  if key in context:
   var value: Variant = context[key]
   return StringManager.indicate_sign(value) if indicate_sign else str(value)
  else:
   return key


class FromSource extends DataStringArgument:
 var source_id: String
 var path: PackedStringArray
 var indicate_sign: bool = false

 func get_value(_context: Dictionary, _path: PackedStringArray) -> Variant:
  return StringManager.get_data_from_source(source_id, path, null)


 func has_value(_context: Dictionary, _path: PackedStringArray) -> bool:
  return get_value(_context, _path) != null


 func get_string(_context: Dictionary, _path: PackedStringArray) -> String:
  var value: Variant = get_value(_context, _path)
  return StringManager.indicate_sign(value) if indicate_sign else str(value)


class FirstAvailable extends DataStringArgument:
 var sub_arguments: Array[DataStringArgument] = []

 func is_true(context: Dictionary, path: PackedStringArray) -> bool:
  for argument in sub_arguments:
   if argument.is_true(context, path):
    return true

  return false


 func has_value(context: Dictionary, path: PackedStringArray) -> bool:
  for argument in sub_arguments:
   if argument.has_value(context, path):
    return true

  return false


 func get_value(context: Dictionary, path: PackedStringArray) -> Variant:
  for argument in sub_arguments:
   if argument.has_value(context, path):
    return argument.get_value(context, path)

  return null


 func get_string(context: Dictionary, path: PackedStringArray) -> String:
  for argument in sub_arguments:
   if argument.has_value(context, path):
    return argument.get_string(context, path)

  return sub_arguments[-1].get_string(context, path)


class And extends DataStringArgument:
 var sub_arguments: Array[DataStringArgument] = []

 func is_true(context: Dictionary, path: PackedStringArray) -> bool:
  for argument in sub_arguments:
   if not argument.is_true(context, path):
    return false

  return true


 func has_value(_context: Dictionary, _path: PackedStringArray) -> bool:
  return false


 func get_value(_context: Dictionary, _path: PackedStringArray) -> Variant:
  return null
