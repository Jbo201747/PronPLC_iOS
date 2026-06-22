extends MenuPanel


var save_slot_button_scene = preload("res://source/ui/menu/save_select/save_slot_button.tscn")

@onready var sectioned_panel: SectionedPanel = %SectionedPanel
@onready var new_save_button: Control = %NewSaveButton

var reloading_slots: = false


func _unhandled_input(event: InputEvent) -> void :
 if not active:
  return

 if event.is_action_released("load_achievements_from_steam"):
  Bridge.request_recover_achievements.emit()


func _ready() -> void :
 super._ready()
 new_save_button.button.focus_entered.connect(_on_new_save_button_focus_entered)


func get_save_slots() -> Array[SaveSlotButton]:
 var save_slots: Array[SaveSlotButton] = []
 for child in sectioned_panel.contents_box.get_children():
  if child is SaveSlotButton:
   save_slots.append(child)

 return save_slots


func reload_save_buttons() -> void :
 reloading_slots = true

 SaveSlotButton.focused_slot = null

 var save_slots: = get_save_slots()
 for save in SaveManager.get_available_saves():
  var slot: SaveSlotButton = null
  if save_slots.is_empty():
   slot = instantiate_slot()
   sectioned_panel.contents_box.add_child(slot)
  else:
   slot = save_slots.pop_front()

  slot.cancel_action()
  slot.check_focused()

  slot.set_save(save)

 for slot in save_slots:
  sectioned_panel.contents_box.remove_child(slot)
  slot.queue_free()

 sectioned_panel.contents_box.move_child(new_save_button, -1)

 reloading_slots = false

 sectioned_panel.update_panels()

 setup_internal_focus()


func instantiate_slot() -> SaveSlotButton:
 var slot: SaveSlotButton = save_slot_button_scene.instantiate()
 slot.save_modified.connect(_on_save_modified)
 slot.action_changed.connect(_on_save_slot_action_changed)
 slot.duplicate_requested.connect(_on_save_slot_duplicate_requested.bind(slot))
 slot.button_focus_entered.connect(_on_slot_focus_entered.bind(slot))
 return slot


func _on_save_modified(ensure_visible_save: String) -> void :
 var had_focus: = Util.has_focus(self, true)

 reload_save_buttons()

 var regrabbed_focus: = false
 if ensure_visible_save != "":
  await get_tree().process_frame
  for slot in get_save_slots():
   if slot.save.name == ensure_visible_save:
    sectioned_panel.scroll.ensure_control_visible(slot)
    if had_focus:
     slot.grab_focus()
     regrabbed_focus = true

    break

 if had_focus and not regrabbed_focus:
  grab_focus()


func _on_save_slot_action_changed() -> void :
 if reloading_slots:
  return

 var save_slots: = get_save_slots()
 for slot: SaveSlotButton in save_slots:
  slot.check_focused()


func _on_save_slot_duplicate_requested(slot: SaveSlotButton) -> void :
 if not slot.save.data_loaded:
  slot.save.load_file()
  if not slot.save.data_loaded:
   return

 var new_slot: = instantiate_slot()
 slot.add_sibling(new_slot)

 var placeholder_name: = SaveManager.get_first_available_save_name(slot.save.name, true, true)
 var new_save: = SaveFile.create_copy(placeholder_name, slot.save)
 new_save.store_file()

 SaveManager.select_save(new_save.name)

 new_slot.set_save(new_save)

 _on_save_modified(new_save.name)


func _on_new_save_button_pressed() -> void :
 var new_slot: = instantiate_slot()
 sectioned_panel.contents_box.add_child(new_slot)
 sectioned_panel.contents_box.move_child(new_slot, -2)

 var placeholder_name = SaveManager.get_first_available_save_name()
 var new_save: = SaveFile.create_new(placeholder_name)
 new_save.store_file()

 SaveManager.select_save(new_save.name)

 new_slot.set_save(new_save)

 _on_save_modified(new_save.name)


func _on_start_appearing() -> void :
 reload_save_buttons()


func _on_start_disappearing() -> void :
 for slot in get_save_slots():
  slot.cancel_action()


func _on_slot_focus_entered(slot: SaveSlotButton) -> void :
 if slot.button.has_focus(true):
  sectioned_panel.scroll.ensure_control_visible(slot)


func _on_new_save_button_focus_entered() -> void :
 if new_save_button.button.has_focus(true):
  sectioned_panel.scroll.ensure_control_visible(new_save_button)


func get_focus_controls() -> Array[Control]:
 var controls: Array[Control] = []
 controls.assign(get_save_slots())
 controls.append(new_save_button.button)

 return controls


func setup_focus_connections(focus_controls: Array[Control]) -> void :
 Util.set_control_focus_sequence(focus_controls, true, true)
