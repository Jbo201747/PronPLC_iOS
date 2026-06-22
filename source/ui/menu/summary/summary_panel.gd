class_name SummaryPanel extends MenuPanel


@onready var summary: Summary = %Summary


func get_focus_controls() -> Array[Control]:
 return [summary.scroll]
