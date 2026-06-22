class_name FocusHolder extends Control


func _init() -> void :
 focus_mode = Control.FOCUS_ALL
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 size = Vector2.ZERO
 Util.disable_focus_for_controls([self])
