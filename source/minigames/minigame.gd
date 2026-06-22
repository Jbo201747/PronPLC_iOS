@abstract
class_name Minigame extends Node2D

signal finished

var hide_mouse_out_of_mouse_mode: = false
var mouse_mode: = true


func start() -> void :
 Game.main.minigame_container.add_child(self)
 if hide_mouse_out_of_mouse_mode:
  InputManager.input_mode_changed.connect(_input_mode_changed)
  update_mouse_mode()

 Game.main.game_state_updated.emit()


func end() -> void :
 hide_mouse_out_of_mouse_mode = false
 update_mouse_mode()
 queue_free()
 Game.main.game_state_updated.emit()


func cancel() -> void :
 pass


func confirm() -> void :
 pass


func handles_right_stick() -> bool:
 return true


func has_left_stick_targeting() -> bool:
 return false


func get_left_stick_center() -> Vector2:
 return Game.tile_board.global_position


func get_left_stick_focus_holder() -> Control:
 return null


func get_left_stick_targets() -> Dictionary[Control, Vector2]:
 return {}


func spell_picking_enabled() -> bool:
 return false


func get_default_focus() -> Control:
 return null


func switch_from_mouse_mode() -> void :
 Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN


func switch_to_mouse_mode() -> void :
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func update_mouse_mode() -> void :
 if hide_mouse_out_of_mouse_mode and not InputManager.is_mouse_mode():
  if mouse_mode:
   mouse_mode = false
   switch_from_mouse_mode()
 else:
  if not mouse_mode:
   mouse_mode = true
   switch_to_mouse_mode()


func _input_mode_changed() -> void :
 update_mouse_mode()
