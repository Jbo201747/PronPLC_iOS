class_name ModData extends RefCounted


var folder: String = ""
var id: String = ""
var packs: Array[Pack] = []
var assets_only: bool = false

var json: JSON
var loaded: = false


func load_json(file_path: String) -> void :
 folder = file_path.get_base_dir()

 var file_data: = FileAccess.get_file_as_string(file_path)

 json = JSON.new()
 var error = json.parse(file_data, false)
 if error != OK:
  push_error("JSON Error: ", json.get_error_message(), " in ", file_path, " at line ", json.get_error_line())
  return

 if json.data is not Dictionary:
  push_error("Failed to load mod ", file_path, ": Mod JSON must be JSON Object.")
  return

 if "id" not in json.data:
  push_error("Mod ", file_path, " must have 'id' field.")
  return

 id = json.data.id

 if "assets_only" in json.data:
  if json.data.assets_only is not bool:
   push_error("Mod ", id, ": 'assets_only' must be bool.")
   return
  else:
   assets_only = json.data.assets_only

 if "packs" in json.data:
  if json.data.packs is not Array:
   push_error("Mod ", id, ": 'packs' must be array of JSON Object.")
   return

  for pack_data in json.data.packs:
   if pack_data is not Dictionary:
    push_error("Mod ", id, ": 'packs' must be array of JSON Object.")
    return

   var pack: = Pack.new(self, pack_data)
   if not pack.valid:
    return

   packs.append(pack)

 loaded = true


class Pack extends RefCounted:
 var id: String
 var path: String
 var phase: String

 var override: bool = false
 var priority: int = 0

 var valid: = false

 var mod_ref: WeakRef = null
 var mod: ModData:
  get():
   return mod_ref.get_ref()
  set(value):
   mod_ref = weakref(value)

 func _init(mod_data: ModData, json_data: Dictionary) -> void :
  if "path" not in json_data or not json_data.path.ends_with(".pck") or not FileAccess.file_exists(mod_data.folder.path_join(json_data.path)):
   push_error("Mod ", id, ": Pack must have 'path' to valid .pck file relative to mod folder.")
   return

  valid = true
  mod = mod_data
  path = mod.folder.path_join(json_data.path)
  phase = json_data.get("phase", "main")

  if "override" in json_data:
   if json_data.override is not bool:
    push_error("Mod ", id, ": Pack ", path, " invalid. 'override' must be bool.")
    valid = false
    return

   override = json_data.override

  if "priority" in json_data:
   if json_data.priority is int or json_data.priority is float:
    priority = int(json_data.priority)


 func load_pck() -> void :
  ProjectSettings.load_resource_pack(path, override)
