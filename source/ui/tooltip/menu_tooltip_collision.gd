class_name MenuTooltipCollision extends "res://source/ui/tooltip/tooltip_collision.gd"


@export var red: bool = false:
 set(value):
  red = value
  update_tooltip()
@export var string_identifier: String:
 set(value):
  string_identifier = value
  update_tooltip()
@export var context: Dictionary = {}:
 set(value):
  context = value
  update_tooltip()


func populate_tooltip() -> void :
 if tooltip is MenuTooltip:
  tooltip.set_alignment(horizontal_alignment, vertical_alignment)
  update_tooltip()

 generate_tooltip.emit(tooltip)


func update_tooltip() -> void :
 if tooltip == null:
  return

 tooltip.text = StringManager.get_string(string_identifier, context)
 tooltip.red = red
