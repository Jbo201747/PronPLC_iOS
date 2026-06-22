extends Node

const LOAD_PHASES = ["early", "main", "late"]

var mod_scenes: Array[Mod] = []
var mods: Array[ModData] = []


func _init() -> void :
 if OS.has_feature("web"):
  return

 if OS.has_feature("editor") or OS.has_feature("modding"):
  if OS.has_feature("editor"):
   load_mod_data_at_directory("res://mod_packs")

  var mods_folder: = OS.get_executable_path().get_base_dir().path_join("mods")
  load_mod_data_at_directory(mods_folder)

  load_mod_packs()
  load_mod_scenes()


func load_mod_data_at_directory(directory: String) -> void :
 if not DirAccess.dir_exists_absolute(directory):
  return

 var dir: = DirAccess.open(directory)
 dir.list_dir_begin()
 var file_name: = dir.get_next()
 while file_name != "":
  if dir.current_is_dir():
   var mod_json_path: = "%s/%s/mod.json" % [directory, file_name]
   if FileAccess.file_exists(mod_json_path):
    var mod: = ModData.new()
    mod.load_json(mod_json_path)
    if mod.loaded:
     print("Successfully loaded mod ", mod.id)
     mods.append(mod)

  file_name = dir.get_next()


func load_mod_packs() -> void :
 var packs: Dictionary[String, Array] = {}
 for mod in mods:
  for pack in mod.packs:
   if pack.phase not in packs:
    packs[pack.phase] = []

   packs[pack.phase].append(pack)

 for phase in LOAD_PHASES:
  if phase not in packs:
   continue

  packs[phase].sort_custom( func(a: ModData.Pack, b: ModData.Pack): return a.priority > b.priority)

  for pack: ModData.Pack in packs[phase]:
   pack.load_pck()


func load_mod_scenes() -> void :
 for mod in mods:
  var path: = "res://mods/%s/mod.tscn" % mod.id
  if ResourceLoader.exists(path, "PackedScene"):
   var scene: PackedScene = load(path)
   var node: = scene.instantiate()
   if node is Mod:
    node.mod_data = mod
    mod_scenes.append(node)
    add_child(node)
   else:
    node.free()
    push_error("Mod ", mod.id, ": Mod Node must inherit 'Mod'")
    continue

 for mod in mod_scenes:
  mod._post_mods_loaded()


func get_active_mod_ids(ignore_assets_only: bool = false) -> PackedStringArray:
 var ids: = PackedStringArray()
 for mod in mods:
  if not ignore_assets_only or not mod.assets_only:
   ids.append(mod.id)

 ids.sort()

 return ids


func get_active_mods() -> Array[Mod]:
 return mod_scenes
