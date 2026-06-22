@tool
class_name BGGroup extends Resource

signal id_changed

var group_hint = "":
 set(value):
  group_hint = value
  update_hints()

var pattern_hint = "":
 set(value):
  pattern_hint = value
  update_hints()

var folder_chunk_entries: Array[BGPatternEntry] = []

@export_placeholder("Group Name") var id: String = "":
 set(value):
  id = value
  id_changed.emit()
@export var entries: Array[BGPatternEntry] = []:
 set(value):
  entries = value
  update_hints()
@export_dir var chunk_scene_folder: String = "":
 set(value):
  chunk_scene_folder = value
  refresh_folder()

@export var default_repeat_delay: int = 0
@export_tool_button("Refresh Folder") var refresh_folder_button: Callable = refresh_folder


func refresh_folder() -> void :
 folder_chunk_entries.clear()
 if chunk_scene_folder != "":
  var existing_chunks: Dictionary[String, bool]
  for entry in entries:
   if entry is BGChunkEntry:
    existing_chunks[entry.chunk.resource_path] = true

  for file in ResourceLoader.list_directory(chunk_scene_folder):
   if file in existing_chunks or not file.ends_with(".tscn"):
    continue

   var chunk: PackedScene = load(chunk_scene_folder + "/" + file)
   var entry: = BGChunkEntry.new()
   entry.chunk = chunk
   folder_chunk_entries.append(entry)


func update_hints():
 for entry in entries:
  if entry is BGGroupEntry:
   entry.group_hint = group_hint
  elif entry is BGSubpatternEntry:
   entry.pattern_hint = pattern_hint


func get_entries(layer: BGLayer) -> Array[BGPatternEntry]:
 var all_entries: Array[BGPatternEntry] = entries + folder_chunk_entries
 var out_entries: Array[BGPatternEntry] = []
 for entry in all_entries:
  if entry is BGGroupEntry and entry.flatten:
   var group: = layer.get_group(entry.id)
   out_entries.append_array(group.get_entries(layer))
  else:
   out_entries.append(entry)

 return out_entries


func get_num_entries() -> int:
 return entries.size() + folder_chunk_entries.size()


func get_sum_weight(layer: BGLayer) -> float:
 var sum_weight: float = 0.0
 for entry in get_entries(layer):
  sum_weight += entry.get_weight(layer)

 return sum_weight
