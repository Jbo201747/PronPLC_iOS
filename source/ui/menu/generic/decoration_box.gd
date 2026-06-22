class_name DecorationBox extends VBoxContainer


@export var source_boxes: Array[VBoxContainer] = []


func get_separation() -> int:
 if source_boxes.is_empty():
  return 0
 else:
  return source_boxes[0].get_theme_constant("separation")


func get_box_children() -> Array[Control]:
 if source_boxes.is_empty():
  return []

 var boxes: Array[VBoxContainer] = source_boxes.duplicate()
 var box_children: Array[Control] = []

 while not boxes.is_empty():
  var box: VBoxContainer = boxes.pop_front()
  add_box_children(box, boxes, box_children)

 return box_children


func add_box_children(box: VBoxContainer, boxes_queue: Array[VBoxContainer], box_children: Array[Control]) -> void :
 for box_child: Control in box.get_children():
  var processed_from_queue: = false
  for queued_box in boxes_queue.duplicate():
   if queued_box not in boxes_queue:
    continue

   if box_child == queued_box or box_child.is_ancestor_of(queued_box):
    processed_from_queue = true
    boxes_queue.erase(queued_box)

    if box.visible and box_child.visible and queued_box.visible and not queued_box.is_queued_for_deletion() and not queued_box.is_in_group("no_bg_panel"):
     add_box_children(queued_box, boxes_queue, box_children)

  if processed_from_queue:
   continue

  if box.visible and box_child.visible and not box_child.is_queued_for_deletion() and not box_child.is_in_group("no_bg_panel"):
   box_children.append(box_child)
