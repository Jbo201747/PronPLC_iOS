@tool
class_name AlternatingPageBox extends DecorationBox


@export var first_panel_extra_size: int = 0
@export var last_panel_extra_size: int = 0
@export var last_panel_must_be_base: bool = false
@export_tool_button("Refresh") var refresh: = update_panels


func _ready() -> void :
 if Engine.is_editor_hint():
  update_panels.call_deferred()


func update_panels() -> void :
 var last_panel: Panel
 var last_panel_was_base: = false
 var first_panel: bool = true

 var panels: = get_children()

 var source_separation: int = get_separation()

 var box_children: = get_box_children()

 for box_child: Control in box_children:
  var panel: Panel = null
  if panels.size() > 0:
   panel = panels.pop_front()
  else:
   panel = Panel.new()
   add_child(panel)

  panel.size_flags_vertical = Control.SIZE_FILL
  last_panel = panel

  panel.custom_minimum_size = Vector2(0.0, box_child.size.y + source_separation)
  panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

  if first_panel:
   panel.custom_minimum_size.y += first_panel_extra_size
   first_panel = false

  if box_child.has_meta(&"custom_panel"):
   panel.theme_type_variation = box_child.get_meta(&"custom_panel")
   last_panel_was_base = false
  elif not last_panel_was_base or box_child.is_in_group("always_base_panel"):
   panel.theme_type_variation = "MenuPaper"
   last_panel_was_base = true
  else:
   panel.theme_type_variation = "MenuPaperAlt"
   last_panel_was_base = false

 if last_panel_must_be_base and last_panel != null and not last_panel_was_base:
  var panel: Panel = null
  if panels.size() > 0:
   panel = panels.pop_front()
  else:
   panel = Panel.new()
   add_child(panel)

  last_panel = panel
  last_panel.custom_minimum_size = Vector2.ZERO
  panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

  panel.theme_type_variation = "MenuPaper"
  last_panel_was_base = true

 if last_panel != null:
  last_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
  last_panel.custom_minimum_size.y += last_panel_extra_size

 for panel in panels:
  remove_child(panel)
  panel.queue_free()
