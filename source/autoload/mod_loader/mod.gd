@abstract
class_name Mod extends Node


var mod_data: ModData


func _post_mods_loaded() -> void :
 pass


func get_save_data() -> Dictionary:
 return {}


func get_run_save_data() -> Dictionary:
 return {}


func load_save_data(_data: Dictionary) -> void :
 pass


func load_run_save_data(_data: Dictionary) -> void :
 pass
