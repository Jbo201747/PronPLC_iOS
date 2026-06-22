class_name SaveSlotButton extends Control

signal save_modified(ensure_visible_save: String)
signal action_changed
signal duplicate_requested
signal button_focus_entered

enum Action{
 NONE, 
 RENAME, 
 TRASHING, 
}

const TRASH_TIME = 1.5
const EDIT_ACTIONS = [Action.RENAME]

static var focused_slot: SaveSlotButton = null

var save: SaveFile = null
var action: Action = Action.NONE
var trash_timer: float = 0.0
var mouse_over: = false

@onready var line_edit: LineEdit = %LineEdit

@onready var percent_label: Label = %PercentLabel
@onready var time_label: Label = %TimeLabel

@onready var stats_container: Control = %Stats
@onready var sub_button_container: Control = %SubButtons
@onready var save_edit_button_container: Control = %SaveEditButtons

@onready var button: Button = %Button
@onready var sub_buttons: Array[SaveEditButton] = [ %RenameButton, %DuplicateButton, %TrashButton]


func _ready() -> void :
 set_process(false)

 button.focus_entered.connect(check_focused)
 button.focus_entered.connect(button_focus_entered.emit)
 button.focus_exited.connect(check_focused.call_deferred)
 for sub_button in sub_buttons:
  sub_button.button.focus_entered.connect(check_focused)
  sub_button.button.focus_exited.connect(check_focused.call_deferred)

 Bridge.gamepad_text_cancelled.connect(_gamepad_text_cancelled)
 Bridge.gamepad_text_received.connect(_gamepad_text_received)


func _process(delta: float) -> void :
 if action == Action.TRASHING:
  trash_timer = clampf(trash_timer + delta, 0.0, TRASH_TIME)
  %TrashButton.modulate = Color.WHITE.lerp(Color.RED, trash_timer / TRASH_TIME)
 else:
  set_process(false)


func set_save(_save: SaveFile):
 save = _save
 line_edit.text = save.name

 if save.corrupt:
  var failed_to_load: Array[String] = []
  if not save.data_loaded:
   failed_to_load.append(SaveFile.SAVE_FILENAME)

  if not save.word_stats_loaded:
   failed_to_load.append(SaveFile.WORD_STATS_FILENAME)

  if not save.stats_loaded:
   failed_to_load.append(SaveFile.STATS_FILENAME)

  if not save.mod_data_loaded:
   failed_to_load.append(SaveFile.MOD_DATA_FILENAME)

  percent_label.text = StringManager.get_string("menu/save_select/corrupt_save", {
   fully_corrupt = not save.data_loaded, 
  })
  time_label.text = StringManager.get_string("menu/save_select/corrupt_list", {
   failed_to_load = failed_to_load
  })
  Util.shrink_label_to_bounds(time_label, 88, 9)
 else:
  var percent: = save.get_percent(true)
  percent_label.text = "%d%%" % [percent]

  if "time_spent" in save.metadata:
   time_label.text = StringManager.format_time(save.metadata.time_spent)
   Util.shrink_label_to_bounds(time_label, 88, 9)
  else:
   time_label.text = ""

  if save.is_selected():
   set_meta(&"custom_panel", "MenuPaperLight")
  else:
   if has_meta(&"custom_panel"):
    remove_meta(&"custom_panel")

 check_focused()


func any_button_focused() -> bool:
 if button.has_focus():
  return true

 for sub_button in sub_buttons:
  if sub_button.button.has_focus():
   return true

 return false


func can_release_focus() -> bool:
 return action == Action.NONE


func check_focused() -> void :
 var focus_owner: = get_viewport().gui_get_focus_owner()
 if action != Action.NONE:
  focused_slot = self
 elif any_button_focused() or (mouse_over and (focus_owner == null or not focus_owner.has_focus(true))):
  if focused_slot == null or focused_slot.can_release_focus():
   focused_slot = self
 elif focused_slot == self:
  focused_slot = null

 stats_container.visible = focused_slot != self
 sub_button_container.visible = focused_slot == self
 update_focus_sequence()


func update_focus_sequence() -> void :
 var controls: = get_focus_controls()
 Util.disable_focus_for_controls(controls, true)
 Util.set_control_focus_sequence(controls)


func get_focus_controls() -> Array[Control]:
 var controls: Array[Control] = [line_edit, button]
 for sub_button in sub_buttons:
  controls.append(sub_button.button)

 return controls


func can_action() -> bool:
 return action == Action.NONE and focused_slot == self


func set_action(_action: Action = Action.NONE) -> void :
 if action != _action:
  action = _action
  action_changed.emit()

  if action in EDIT_ACTIONS:
   edit()
  elif action == Action.TRASHING:
   set_process(true)


func cancel_action() -> void :
 if is_queued_for_deletion():
  return

 if action in EDIT_ACTIONS:
  finish_edit(true)
 elif action == Action.TRASHING:
  %TrashButton.modulate = Color.WHITE
  trash_timer = 0.0
  set_process(false)

 set_action(Action.NONE)


func edit():
 line_edit.mouse_filter = MOUSE_FILTER_PASS
 line_edit.focus_mode = Control.FOCUS_ALL
 line_edit.editable = true
 line_edit.selecting_enabled = true
 line_edit.grab_focus()
 line_edit.set_caret_column(len(save.name))
 line_edit.select_all()
 save_edit_button_container.visible = false
 update_focus_sequence()

 if InputManager.get_input_mode() == InputManager.InputMode.CONTROLLER:
  Bridge.popup_keyboard(StringManager.get_string("menu/save_select/rename_save"), 64, line_edit.text)


func finish_edit(cancel: = false) -> void :
 if not line_edit.editable:
  return

 line_edit.editable = false
 line_edit.selecting_enabled = false
 line_edit.mouse_filter = MOUSE_FILTER_IGNORE
 line_edit.focus_mode = Control.FOCUS_NONE
 if line_edit.has_focus():
  line_edit.release_focus()

 save_edit_button_container.visible = true
 update_focus_sequence()

 var finishing_action: = action
 set_action(Action.NONE)

 if finishing_action == Action.RENAME:
  if cancel:
   line_edit.text = save.name
  else:
   if save.rename(line_edit.text):
    save_modified.emit(line_edit.text)


func _on_line_edit_text_submitted(_text):
 finish_edit()


func _on_line_edit_focus_exited() -> void :
 finish_edit()


func _on_line_edit_editing_toggled(toggled_on: bool) -> void :
 if not toggled_on:
  finish_edit(Input.is_action_just_pressed("ui_cancel"))


func _on_button_pressed():
 if can_action() and not save.is_selected():
  AudioManager.play_sound(Sounds.UI.MENU_BUTTON)
  Game.menu_shake()
  SaveManager.select_save(save.name)
  save_modified.emit("")


func _on_rename_button_pressed() -> void :
 if can_action():
  set_action(Action.RENAME)


func _on_mouse_entered() -> void :
 mouse_over = true
 if focused_slot == null or focused_slot.can_release_focus():
  button.grab_focus(true)


func _on_mouse_exited() -> void :
 mouse_over = false
 if button.has_focus() and not button.has_focus(true):
  button.release_focus()
 else:
  check_focused()


func _on_duplicate_button_pressed() -> void :
 duplicate_requested.emit()


func _exit_tree() -> void :
 if focused_slot == self:
  focused_slot = null


func _on_trash_button_down() -> void :
 if can_action():
  set_action(Action.TRASHING)


func _on_trash_button_up() -> void :
 if action == Action.TRASHING:
  if trash_timer >= TRASH_TIME:
   AudioManager.play_sound(Sounds.SPELLS.GUNSHOT)
   Game.screenshake(16.0, 0.32)
   save.delete()
   save_modified.emit("")
  else:
   cancel_action()


func _on_trash_button_mouse_exited() -> void :
 if action == Action.TRASHING:
  cancel_action()


func _on_focus_entered() -> void :
 if has_focus(true):
  button.grab_focus()


func _gamepad_text_received() -> void :
 if action in EDIT_ACTIONS:
  finish_edit()


func _gamepad_text_cancelled() -> void :
 if action in EDIT_ACTIONS:
  finish_edit(true)
