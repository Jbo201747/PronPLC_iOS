class_name PrintUtil


static func variant_str(variant: Variant) -> String:
 if variant is Color:
  return hex_color_str(variant)
 elif variant is float:
  return "%.3f" % variant
 elif variant is Array:
  var array_entries: = PackedStringArray()
  for value in variant:
   array_entries.append(variant_str(value))

  return "[" + ", ".join(array_entries) + "]"
 else:
  return var_to_str(variant)


static func hex_color_str(color: Color) -> String:
 return "Color(0x%X)" % color.to_rgba32()


static func convert_dictionary_key(key: String, back_enums: Array[BackEnum] = []) -> String:
 for back_enum in back_enums:
  var converted: = back_enum.convert_key(key)
  if converted != key:
   return converted

 return "\"%s\"" % key


static func print_dictionary(dictionary: Dictionary, columns: int = 1, back_enums: Array[BackEnum] = []) -> void :
 var dictionary_entries: = PackedStringArray()
 var column_entries: = PackedStringArray()
 var longest_column_entry: int = -1
 for key: String in dictionary:
  var converted_key: = convert_dictionary_key(key, back_enums)

  var dictionary_entry: = "%s: %s" % [converted_key, variant_str(dictionary[key])]
  column_entries.append(dictionary_entry)
  longest_column_entry = maxi(len(dictionary_entry), longest_column_entry)

  if column_entries.size() == columns:
   for i in columns:
    column_entries[i] = column_entries[i].lpad(longest_column_entry)

   var column_entry: = ", ".join(column_entries)
   dictionary_entries.append(column_entry)
   column_entries.clear()

 if not column_entries.is_empty():
  dictionary_entries.append(", ".join(column_entries))

 print("{\n" + ",\n".join(dictionary_entries).indent("\t") + ",\n}")


class BackEnum extends RefCounted:
 var source: Dictionary
 var name: String
 func _init(_source: Dictionary, _name: String) -> void :
  source = _source
  name = _name

 func convert_key(string: String) -> String:
  if source.find_key(string):
   return name + "." + source.find_key(string)
  else:
   return string
