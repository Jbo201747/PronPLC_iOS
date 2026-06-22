class_name SimpleByteArray extends RefCounted

var byte_array: PackedByteArray
var pointer = 0
var invalid = false


func _init(init_byte_array: = PackedByteArray()):
 byte_array = init_byte_array


func store_byte_array(bytes: PackedByteArray):
 store_u8(bytes.size())
 byte_array.append_array(bytes)
 pointer = pointer + bytes.size()


func get_byte_array(max_size = 32) -> PackedByteArray:
 if invalid:
  return "error".to_utf8_buffer()

 var size = get_u8()
 if size > max_size:
  invalid = true
  return "error".to_utf8_buffer()

 var slice = byte_array.slice(pointer, pointer + size)
 pointer = pointer + size
 return slice


func store_string(string: String):
 store_byte_array(string.to_utf8_buffer())


func get_string(max_size = 50) -> String:
 return get_byte_array(max_size).get_string_from_utf8()


func store_string_array(array: Array[String]):
 var size = array.size()
 store_u8(size)
 if size != 0:
  for i in size:
   store_string(array[i])


func get_string_array(max_size = 4) -> Array[String]:
 if invalid:
  return []

 var size = get_u8()
 if size == 0:
  return []
 elif size > max_size:
  invalid = true
  return []
 else:
  var array: Array[String] = []
  for i in size:
   array.append(get_string())

  return array


func store_u8(u8: int):
 byte_array.resize(pointer + 1)
 byte_array.encode_u8(pointer, u8)
 pointer += 1


func get_u8() -> int:
 if invalid:
  return 0

 pointer += 1
 return byte_array.decode_u8(pointer - 1)


func store_u32(u32: int):
 byte_array.resize(pointer + 4)
 byte_array.encode_u32(pointer, u32)
 pointer += 4


func get_u32() -> int:
 if invalid:
  return 0

 pointer += 4
 return byte_array.decode_u32(pointer - 4)


func get_packed_int32_array():
 var size = byte_array.size()
 @warning_ignore("integer_division")
 var nearest_multiple = ((size + 3) / 4) * 4
 byte_array.resize(nearest_multiple)
 return byte_array.to_int32_array()
