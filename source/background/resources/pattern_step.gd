@tool
class_name BGPatternStep extends Resource


var group_hint = "":
 set(value):
  group_hint = value
  update_hints()

var pattern_hint = "":
 set(value):
  pattern_hint = value
  update_hints()

@export var entries: Array[BGPatternEntry] = []:
 set(value):
  entries = value
  update_hints()


@export_range(0, 1, 0.05) var repeat_count: Dictionary[int, float] = {1: 1.0}


@export var can_terminate_pattern: bool = true


func _validate_property(property: Dictionary) -> void :
 if property.name == "repeat_count":
  property.hint_string = "%d/%d:%s;%d/%d:%s" % [
   TYPE_INT, PROPERTY_HINT_RANGE, "0,10,1,or_greater", 
   TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,1,0.05,or_greater"
  ]


func update_hints():
 for entry in entries:
  if entry is BGGroupEntry:
   entry.group_hint = group_hint
  elif entry is BGSubpatternEntry:
   entry.pattern_hint = pattern_hint


func pick_entry(rng: RNG, layer: BGLayer, delay_table: Dictionary[String, int], from_entries: Array[BGPatternEntry] = entries, default_repeat_delay: int = 0) -> BGPlaceableEntry:
 var weighted_entries: Dictionary[BGPatternEntry, float] = {}
 for entry in from_entries:
  var delay_id: = entry.get_delay_id()
  if delay_id in delay_table:
   delay_table[delay_id] -= 1
   if delay_table[delay_id] == 0:
    delay_table.erase(delay_id)

   continue

  weighted_entries[entry] = entry.get_weight(layer)

 var entry: BGPatternEntry = rng.weighted_random(weighted_entries)
 var repeat_delay: = default_repeat_delay
 if entry.repeat_delay != -1:
  repeat_delay = entry.repeat_delay

 if repeat_delay > 0:
  delay_table[entry.get_delay_id()] = repeat_delay

 if entry is BGPlaceableEntry:
  return entry
 elif entry is BGGroupEntry:
  var group: = layer.get_group(entry.id)
  if group == null:
   push_error("Group ", entry.id, " does not exist in ", layer.resource_path, " at ", entry.resource_path)
   return null

  return pick_entry(rng, layer, delay_table, group.get_entries(layer), group.default_repeat_delay)

 return null
