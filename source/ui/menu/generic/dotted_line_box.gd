class_name DottedLineBox extends DecorationBox


@export var line_width: float = 204.0


func _ready() -> void :
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 alignment = BoxContainer.ALIGNMENT_BEGIN
 add_theme_constant_override("separation", -2)


func update_panels() -> void :
 var children: = get_children()
 children.reverse()

 var source_separation: = get_separation()

 var box_children: = get_box_children()

 for i in box_children.size():
  var box_child: Control = box_children[i]
  if box_child == box_children[-1] and not box_child.is_in_group("force_dotted_line"):
   continue

  var spacer: Control
  var dotted_line: Panel
  if children.size() > 1:
   spacer = children.pop_back()
   dotted_line = children.pop_back()
  else:
   spacer = add_spacer(false)
   spacer.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
   spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
   dotted_line = Panel.new()
   dotted_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
   dotted_line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
   dotted_line.custom_minimum_size = Vector2(line_width, 4.0)
   add_child(dotted_line)

  var line_type = "MenuDottedLine"
  if box_child.has_meta(&"custom_dotted_line"):
   line_type = box_child.get_meta(&"custom_dotted_line")
  elif i < box_children.size() - 1 and box_children[i + 1].has_meta(&"custom_dotted_line"):
   line_type = box_children[i + 1].get_meta(&"custom_dotted_line")

  dotted_line.theme_type_variation = line_type

  spacer.custom_minimum_size = Vector2(box_child.size.x, box_child.size.y + source_separation)

 for child in children:
  remove_child(child)
  child.queue_free()
