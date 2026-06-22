class_name DragHandler extends Control


signal drag_started(start_pos: Vector2, current_pos: Vector2)
signal dragged(start_pos: Vector2, current_pos: Vector2)
signal drag_released(start_pos: Vector2, end_pos: Vector2, was_received: bool)
signal received(other_handler: DragHandler, current_pos: Vector2)
signal hovering(other_handler: DragHandler, current_pos: Vector2)
signal unhovered(other_handler: DragHandler, current_pos: Vector2)


const DRAG_DISTANCE_THRESHOLD: float = 12

var start_position: Vector2 = Vector2(0, 0)
var current_position: Vector2 = Vector2(0, 0)
var pressed: = false
var dragging: = false
var previously_hovered: DragHandler = null
var can_receive_func: Callable = Callable()
var can_drag_func: Callable = Callable()

@export_placeholder("Drop Group") var drop_group = ""
@export var can_drag: bool = true


func _ready() -> void :
 InputManager.mouse_position_changed.connect(_on_mouse_position_changed)


func _unhandled_input(event: InputEvent) -> void :
 if event is not InputEventMouseMotion and not event.is_action("primary_button"):
  return

 if not check_can_grab():
  return

 if event.is_action("primary_button"):
  var mouse_pos: Vector2 = InputManager.get_mouse_position()
  if event.is_pressed():
   if get_global_rect().has_point(mouse_pos):
    start_position = mouse_pos
    pressed = true
  elif event.is_released():
   var was_received = false
   var receiving_handler = null
   if dragging:
    if previously_hovered != null and is_handler_hovered(previously_hovered, mouse_pos):
     was_received = true
     receiving_handler = previously_hovered
    current_position = mouse_pos
   cancel_drag(was_received)
   if was_received:
    receiving_handler.receive(self, mouse_pos)

 set_process(pressed or dragging)


func _on_mouse_position_changed() -> void :
 if InputManager.has_non_mouse_focus():
  return

 if pressed or dragging:
  current_position = InputManager.get_mouse_position()
  update_drag()


func _process(_delta: float) -> void :
 check_can_grab()
 if not (pressed or dragging):
  set_process(false)


func is_dragging():
 return dragging


func check_can_grab() -> bool:
 if not can_drag:
  return false

 if can_drag_func.is_valid() and not can_drag_func.call():
  if (pressed or dragging):
   cancel_drag()
  return false

 return true


func update_drag() -> void :
 if pressed and not dragging:
  if start_position.distance_to(current_position) >= DRAG_DISTANCE_THRESHOLD:
   start_drag()

 if dragging:
  dragged.emit(start_position, current_position)

  var handler = get_hovered_handler(current_position)
  if handler != previously_hovered:
   if previously_hovered != null:
    previously_hovered.unhover(self, current_position)

   previously_hovered = handler

  if handler != null:
   handler.hover(self, current_position)


func start_drag() -> void :
 pressed = true
 dragging = true
 drag_started.emit(start_position, current_position)


func cancel_drag(was_received: bool = false):
 pressed = false
 if dragging:
  if not was_received and previously_hovered != null:
   previously_hovered.unhover(self, current_position)

  previously_hovered = null
  drag_released.emit(start_position, current_position, was_received)
  dragging = false


func is_handler_hovered(handler: DragHandler, event_pos: Vector2):
 if not handler.get_global_rect().has_point(event_pos):
  return false

 if not handler.can_receive(self, event_pos):
  return false

 return true


func get_hovered_handler(event_pos: Vector2):
 if drop_group != "":
  var drop_handlers = get_tree().get_nodes_in_group(drop_group)
  for drop_handler in drop_handlers:
   if drop_handler is DragHandler:
    if is_handler_hovered(drop_handler, event_pos):
     return drop_handler

 return null


func can_receive(other_handler: DragHandler, current_pos: Vector2):
 if can_receive_func.is_valid():
  return can_receive_func.call(other_handler, current_pos)
 else:
  return true


func hover(other_handler: DragHandler, current_pos: Vector2):
 hovering.emit(other_handler, current_pos)


func unhover(other_handler: DragHandler, current_pos: Vector2):
 unhovered.emit(other_handler, current_pos)


func receive(other_handler: DragHandler, current_pos: Vector2):
 received.emit(other_handler, current_pos)
