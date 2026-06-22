@tool
class_name BGPattern extends Resource

signal id_changed

var group_hint = "":
 set(value):
  group_hint = value
  update_hints()

var pattern_hint = "":
 set(value):
  pattern_hint = value
  update_hints()


@export_placeholder("Pattern Name") var id: String = "":
 set(value):
  id = value
  id_changed.emit()

@export_placeholder("Pattern Name") var next: String = ""
@export var steps: Array[BGPatternStep] = []:
 set(value):
  steps = value
  update_hints()

@export var force_generate_chunks: int = 0


func update_hints():
 for step in steps:
  if step != null:
   step.group_hint = group_hint
   step.pattern_hint = pattern_hint
