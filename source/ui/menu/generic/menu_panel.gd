class_name MenuPanel extends Control

signal start_appearing
signal start_disappearing
signal finish_animating
signal active_changed
signal request_back
signal request_close

@export var anim: AnimationPlayer
@export var panel: Control

@export var full_screen_menu: = false
@export var no_back_button: = false
@export var can_close: = true

var appearing: = false
var disappearing: = false
var active: = false:
 set(value):
  if active != value:
   active = value
   active_changed.emit()
var has_reset_position: = false
var animating: = false
var forced_hidden: = false


var last_focus_target_control: Control = null

var menu_controller: MenuController = null:
 set = set_menu_controller


func _ready() -> void :
 if not Engine.is_editor_hint():
  if full_screen_menu:
   position = Vector2.ZERO

  position.y += 1000.0

 focus_entered.connect(_focus_entered)

 if get_tree().current_scene == self:
  appear()


static func sequenced_appear(panels: Array[MenuPanel], instant: bool = false, delay: float = 0.02, multipanel: = false):
 for menu_panel in panels:
  if not menu_panel.active:
   menu_panel.start_appear()
   menu_panel.hide()

 for menu_panel in panels:
  if not menu_panel.active:
   var reset_pos: = not multipanel or menu_panel.is_in_group("multipanel_position_exclude")
   if menu_panel == panels[-1]:
    await menu_panel.appear(instant, reset_pos)
   else:
    menu_panel.appear(instant, reset_pos)
    await Game.conditional_timeout(delay, instant)

 for menu_panel in panels:
  if menu_panel.animating:
   await menu_panel.finish_animating

 for menu_panel in panels:
  menu_panel.finish_appear()


static func sequenced_disappear(panels: Array[MenuPanel], instant: bool = false, delay: float = 0.02):
 var active_panels: Array[MenuPanel] = []
 for menu_panel in panels:
  if menu_panel.active:
   active_panels.append(menu_panel)

  menu_panel.start_disappear()

 for menu_panel in active_panels:
  if menu_panel == active_panels[-1]:
   await menu_panel.disappear(instant)
  else:
   menu_panel.disappear(instant)
   await Game.conditional_timeout(delay, instant)

 for menu_panel in panels:
  menu_panel.finish_disappear()


func play_animation(animation: String, instant: bool = false) -> void :
 anim.speed_scale = 1.1
 anim.play(animation)
 if instant:
  anim.advance(anim.current_animation_length)
 else:
  anim.advance(0)
  await anim.animation_finished


func animate_appear(instant: bool = false) -> void :
 await play_animation("appear", instant)


func animate_disappear(instant: bool = false) -> void :
 await play_animation("disappear", instant)


func appear(instant: bool = false, reset_position: bool = true) -> void :
 if not has_reset_position:
  has_reset_position = true
  if reset_position:
   position.y -= 1000.0

 show()

 animating = true
 await animate_appear(instant)
 finish_animating.emit()
 animating = false


func disappear(instant: bool = false) -> void :
 animating = true
 await animate_disappear(instant)
 finish_animating.emit()
 animating = false

 hide()


func start_appear() -> void :
 appearing = true
 start_appearing.emit()


func finish_appear() -> void :
 setup_internal_focus()
 active = true
 appearing = false


func start_disappear() -> void :
 disappearing = true
 active = false
 clear_internal_focus()
 start_disappearing.emit()


func finish_disappear() -> void :
 disappearing = false


func appear_complete(instant: = false) -> void :
 start_appear()
 await appear(instant)
 finish_appear()


func disappear_complete(instant: = false) -> void :
 start_disappear()
 await disappear(instant)
 finish_disappear()


func is_active_or_opening() -> bool:
 return active or appearing


func is_doing_anything() -> bool:
 return active or appearing or disappearing


func get_menu_panel_children() -> Array[MenuPanel]:
 var children: Array[MenuPanel] = []
 for child in get_children():
  if child is MenuPanel:
   children.append(child)

 return children


func get_panel_size() -> Vector2:
 if panel != null:
  return panel.size
 else:
  return Vector2.ZERO


func get_center() -> Vector2:
 if panel != null:
  return panel.global_position + panel.size / 2
 else:
  return Vector2.ZERO


func set_menu_controller(value: MenuController) -> void :
 menu_controller = value
 for sub_menu_panel in get_menu_panel_children():
  sub_menu_panel.set_menu_controller(menu_controller)



func get_focus_controls() -> Array[Control]:
 return []


func get_focus_target_control() -> Control:
 if last_focus_target_control != null:
  if Util.can_grab_focus(last_focus_target_control):
   return last_focus_target_control
  else:
   last_focus_target_control = null

 var controls: = get_focus_controls()
 for control in controls:
  if Util.can_grab_focus(control):
   return control

 return null


func can_grab_focus() -> bool:
 return active and get_focus_target_control() != null


func setup_internal_focus() -> void :
 var focus_controls: = get_focus_controls()
 for control in focus_controls:
  if not control.focus_entered.is_connected(_sub_control_focused):
   control.focus_entered.connect(_sub_control_focused.bind(control))

 Util.disable_focus_for_controls(focus_controls, true)
 setup_focus_connections(focus_controls)


func setup_focus_connections(focus_controls: Array[Control]) -> void :
 Util.set_control_focus_sequence(focus_controls)


func clear_internal_focus() -> void :
 for control in get_focus_controls():
  if control.focus_entered.is_connected(_sub_control_focused):
   control.focus_entered.disconnect(_sub_control_focused)

  control.release_focus()


func _sub_control_focused(control: Control) -> void :
 last_focus_target_control = control


func _focus_entered() -> void :
 if not can_grab_focus() or not has_focus(true):
  return

 var focus_target: = get_focus_target_control()
 if focus_target == null:
  release_focus()
 else:
  focus_target.grab_focus()
