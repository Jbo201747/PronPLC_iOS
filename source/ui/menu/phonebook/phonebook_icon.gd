class_name PhonebookIcon extends Control


signal selected(icon: PhonebookIcon)

var entries: Array[PhonebookEntry]
var active_entry: PhonebookEntry

@onready var notification_icon: Sprite2D = %Notification
@onready var sprite: Sprite2D = %Sprite2D
@onready var button: Button = %Button


func _ready():
 SaveManager.save_changed.connect(refresh_entries)
 button.focus_entered.connect(_on_focus_entered)


func refresh_entries() -> void :
 set_entries(entries)


func set_entries(_entries: Array[PhonebookEntry]) -> void :
 entries = _entries

 var selected_entry_index: = -1

 if SaveManager.has_valid_selected_save():
  var save: = SaveManager.get_save()
  var first_entry: = entries[0]
  if first_entry.id in save.data.selected_phonebook_entries:
   selected_entry_index = save.data.selected_phonebook_entries[first_entry.id]
   if selected_entry_index >= entries.size() or entries[selected_entry_index].is_locked():
    selected_entry_index = -1

 if selected_entry_index == -1:
  selected_entry_index = 0
  for i in entries.size():
   if not entries[i].is_locked():
    selected_entry_index = i
    break

 set_entry(entries[selected_entry_index])


func set_entry(entry: PhonebookEntry) -> void :
 var entry_index: = entries.find(entry)
 if entry_index != -1 and SaveManager.has_valid_selected_save():
  var save: = SaveManager.get_save()
  save.data.selected_phonebook_entries[entries[0].id] = entry_index

 active_entry = entry

 sprite.frame_coords = Enemies.get_icon_frame_coord(entry.id)
 if Enemies.is_shadow(entry.id):
  sprite.texture = preload("res://arte/ui/enemy_shadow_icons.png")
 else:
  sprite.texture = preload("res://arte/ui/enemy_icons.png")

 if entry.is_locked():
  sprite.modulate = Color.BLACK
 else:
  sprite.modulate = Color.WHITE

 notification_icon.visible = false
 if SaveManager.has_valid_selected_save():
  for other_entry in entries:
   if not other_entry.is_locked() and not SaveManager.get_save().has_enemy_been_read(other_entry.id):
    notification_icon.visible = true
    break


func _on_button_pressed() -> void :
 AudioManager.play_sound(Sounds.UI.TEXT_TYPING)
 Game.menu_shake(true)
 selected.emit(self)


func _gui_input(event: InputEvent) -> void :
 if event.is_action_pressed("unlock_cheat") and Bridge.is_debug_build():
  toggle_unlock_state()
  accept_event()


func toggle_unlock_state():
 var entries_changed: = false
 for entry in entries:
  if entry.is_locked():
   entry.locked_override_active = true
   entry.locked_override = false
   entries_changed = true
   break

 if not entries_changed:
  for entry in entries:
   entry.locked_override_active = true
   entry.locked_override = true

 refresh_entries()


func _on_focus_entered() -> void :
 if button.has_focus(true):
  _on_button_pressed()
