@tool
extends EditorPlugin


var export_plugin: EditorExportPlugin


func _enter_tree() -> void :
 export_plugin = BuildIncludePlugin.new()
 add_export_plugin(export_plugin)


func _exit_tree() -> void :
 remove_export_plugin(export_plugin)
 export_plugin = null


class BuildIncludePlugin extends EditorExportPlugin:
 func _get_name() -> String:
  return "BuildIncludePlugin"


 func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void :
  Util.copy_files_recursive("res://.build_include", path.get_base_dir())
