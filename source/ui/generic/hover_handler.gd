class_name HoverHandler extends Node2D

signal hover_state_changed

@export var hovering: CanvasItem
@export var source: Control
@export var expand_control: Control

@export var default_position: Vector2
@export var hovered_position: Vector2
@export var pressed_position: Vector2 = Vector2.INF

@export var use_focus: = true
@export var only_count_full_mouse_exit: = false

var disabled: = false
var button_down: = false
var has_pressed_state: = false
var mouse_over: = false
var hover_tween: Tween
var last_hover_position: Vector2 = Vector2.INF

var expand_control_base_size: Vector2
var expand_control_base_pos: Vector2

var hover_condition: Callable
var pressed_condition: Callable


func _ready() -> void :
 has_pressed_state = pressed_position != Vector2.INF
 source.mouse_entered.connect(_on_mouse_entered)
 source.mouse_exited.connect(_on_mouse_exited)
 source.focus_entered.connect(_on_focus_entered)
 source.focus_exited.connect(_on_focus_exited)

 if source is Button and has_pressed_state:
  source.button_down.connect(_on_button_down)
  source.button_up.connect(_on_button_up)

 if expand_control != null:
  expand_control_base_size = expand_control.size
  expand_control_base_pos = expand_control.position

 set_physics_process(false)


func _physics_process(_delta: float) -> void :
 if not only_count_full_mouse_exit or not source.has_focus() or source.has_focus(true):
  set_physics_process(false)
  return

 if not source.get_global_rect().has_point(InputManager.get_mouse_position(true)):
  source.release_focus()
  set_physics_process(false)


func is_hovering() -> bool:
 return last_hover_position != Vector2.INF and last_hover_position != default_position


func can_grab_focus() -> bool:
 return source.get_focus_mode_with_override() != Control.FOCUS_NONE


func tween(new_position: Vector2):
 if hover_tween:
  hover_tween.kill()

 hover_tween = create_tween()
 hover_tween.set_ease(Tween.EASE_OUT)
 hover_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
 hover_tween.tween_property(hovering, "position", new_position, 0.1)


func get_target_hover_position() -> Vector2:
 if has_pressed_state and (
   button_down
   or (pressed_condition.is_valid() and pressed_condition.call())
 ):
  return pressed_position


 if (
   (use_focus and source.has_focus())
   or ( not use_focus and mouse_over)
   or (hover_condition.is_valid() and hover_condition.call())
 ):
  return hovered_position

 return default_position


func set_hover_position(hover_position: Vector2, instant: = false) -> void :
 last_hover_position = hover_position

 if expand_control != null:
  expand_control.position = expand_control_base_pos + hover_position
  expand_control.size = expand_control_base_size - hover_position

 if instant:
  if hover_tween:
   hover_tween.kill()


  if hovering is Node2D:
   hovering.position = hover_position
  elif hovering is Control:
   hovering.position = hover_position
 else:
  tween(hover_position)

 hover_state_changed.emit()


func hover_for_state() -> void :
 if disabled:
  return

 var target: = get_target_hover_position()
 if target != last_hover_position:
  set_hover_position(target)


func _on_mouse_entered() -> void :
 if use_focus:
  if not can_grab_focus() or not InputManager.can_take_focus():
   return

  if not source.has_focus():
   source.grab_focus(true)
 else:
  mouse_over = true
  hover_for_state()


func _on_mouse_exited() -> void :
 if use_focus:
  if not can_grab_focus():
   return

  if source.has_focus():
   if only_count_full_mouse_exit:
    if source.get_global_rect().has_point(InputManager.get_mouse_position(true)):
     set_physics_process(true)
     return

   if source is TileCollision:
    if not source.can_release_focus():
     return

   source.release_focus()
 else:
  mouse_over = false
  hover_for_state()


func _on_button_down() -> void :
 button_down = true
 hover_for_state()


func _on_button_up() -> void :
 button_down = false
 hover_for_state()


func _on_focus_entered() -> void :
 hover_for_state()


func _on_focus_exited() -> void :
 hover_for_state()


func set_disabled(value: bool, instant: = false) -> void :
 disabled = value
 if disabled:
  set_hover_position(default_position, instant)
 else:
  hover_for_state()


func stop(instant: = false) -> void :
 set_disabled(true, instant)


func resume() -> void :
 set_disabled(false)
