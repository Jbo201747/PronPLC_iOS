@tool
class_name BGLayer extends Resource

@export var z_index: int = 0
@export var motion_scale: float = 1.0
@export var motion_scale_y: float = -1.0

@export var x_velocity: float = 0.0
@export var y_offset: float = 0.0
@export var start_x_offset: float = 0.0
@export var randomize_start: = true
@export var start_hidden: = false
@export var is_static: = false
@export var extra_deadzone: int = 0
@export var groups: Array[BGGroup] = []:
 set(value):
  groups = value
  update_hints()

@export var patterns: Array[BGPattern] = []:
 set(value):
  patterns = value
  update_hints()


func update_hints():
 var group_hint = ""
 for group in groups:
  if group != null:
   group_hint += group.id + ","
   if not group.id_changed.is_connected(update_hints):
    group.id_changed.connect(update_hints)

 var pattern_hint = ""
 for pattern in patterns:
  if pattern != null:
   pattern_hint += pattern.id + ","
   if not pattern.id_changed.is_connected(update_hints):
    pattern.id_changed.connect(update_hints)

 group_hint = group_hint.rstrip(",")
 pattern_hint = pattern_hint.rstrip(",")
 for entry in groups + patterns:
  if entry != null:
   entry.group_hint = group_hint
   entry.pattern_hint = pattern_hint


func get_pattern(id) -> BGPattern:
 for pattern in patterns:
  if pattern.id == id:
   return pattern

 return null

func get_group(id) -> BGGroup:
 for group in groups:
  if group.id == id:
   return group

 return null
