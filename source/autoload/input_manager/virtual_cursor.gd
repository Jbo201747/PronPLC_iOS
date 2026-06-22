class_name VirtualCursor extends Sprite2D

signal position_changed

var snapped_control: Control


func _ready() -> void :
 set_process(false)


func _process(_delta: float) -> void :
 if snapped_control == null:
  visible = false
  set_process(false)
  return

 var focus_owner: = get_viewport().gui_get_focus_owner()
 visible = focus_owner == snapped_control and focus_owner.has_focus(true)
 snap_to_control(snapped_control)


func set_snapped_control(node: Control) -> void :
 if snapped_control == node:
  return
 elif snapped_control != null:
  unsnap_to_control(snapped_control)

 snapped_control = node
 set_process(true)
 snap_to_control(node)


func unsnap_to_control(node: Control) -> void :
 if snapped_control != node:
  return

 snapped_control = null


func snap_to_control(node: Node) -> void :
 var target_position: Vector2 = node.global_position
 if node.has_meta("cursor_marker"):
  var marker: NodePath = node.get_meta("cursor_marker")
  var marker_node: = node.get_node_or_null(marker)
  if marker_node == null:
   push_warning("Could not resolve cursor_marker node path ", node)
  else:
   snap_to_control(marker_node)
  return
 elif node is HSlider:
  target_position += Vector2(((node.size.x - 6) * node.ratio) + 4, node.size.y / 2.0)
 elif node is VSlider:
  target_position += Vector2(node.size.x / 2.0, node.size.y * node.ratio)
 elif node is HScrollBar:
  var grabber_length: float = (node.size.x * node.page) / (node.max_value - node.min_value)
  target_position += Vector2(node.size.x * node.ratio + grabber_length / 2.0, node.size.y / 2.0)
 elif node is VScrollBar:
  var grabber_length: float = (node.size.y * node.page) / (node.max_value - node.min_value)
  target_position += Vector2(node.size.x / 2.0, node.size.y * node.ratio + grabber_length / 2.0)
 elif node is LabelSwitcher:
  snap_to_control(node.right_button)
  return
 elif node is ControllableScrollContainer:
  if node.active_scroll_bar.visible:
   snap_to_control(node.active_scroll_bar)
   return
  else:
   target_position += Vector2(node.size.x, 0) + Vector2(-3, 7)
 elif node is IconSelector:
  snap_to_control(node.get_selected_icon())
  return
 elif node is SpecialFocusButton:
  snap_to_control(node.focus_position_source)
  return
 elif node is Node2D:
  pass
 else:
  target_position += node.size / 2.0

 var final_target: = target_position - Vector2(3, 2)
 if global_position != final_target:
  global_position = final_target
  position_changed.emit()


func get_position_without_offset() -> Vector2:
 return global_position + Vector2(3, 2)
