class_name PhonebookShadowButton extends Control


@onready var sprite: Sprite2D = %Sprite2D
@onready var notification_icon: Sprite2D = %Notification
@onready var button: Button = %Button


func set_icon(icon: PhonebookIcon):
 var unlocked_entry_count: int = 0
 for entry in icon.entries:
  if not entry.is_locked():
   unlocked_entry_count += 1

 visible = unlocked_entry_count > 1
 if not visible:
  return

 notification_icon.visible = false
 for entry in icon.entries:
  if entry != icon.active_entry and not SaveManager.get_save().has_enemy_been_read(entry.id):
   notification_icon.visible = true
   break

 button.set_pressed_no_signal(icon.active_entry == icon.entries[1])
 if button.button_pressed:
  sprite.frame = 1
 else:
  sprite.frame = 0
