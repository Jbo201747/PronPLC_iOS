class_name AchievementEntry extends Control

signal edited

var achievement_id = null
var floppy_texture = preload("res://arte/ui/floppy_disks.png")

@onready var achievement_icon = %AchievementIcon
@onready var title = %Title
@onready var description = %Description


func set_achievement(achievement):
 achievement_id = achievement
 reload()


func reload():
 var character = Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS.find_key(achievement_id)
 if character:
  if character in Globals.CHARACTER_LOCKING_ACHIEVEMENTS:
   visible = AchievementManager.has_achievement(Globals.CHARACTER_LOCKING_ACHIEVEMENTS[character])
   if not visible:
    return

 if not AchievementManager.has_achievement(achievement_id):
  if achievement_id in Globals.SUPER_SECRET_ACHIEVEMENTS:
   visible = false
   return

  achievement_icon.modulate = Color(0, 0, 0, 1)
 else:
  achievement_icon.modulate = Color(1, 1, 1, 1)

 achievement_icon.set_achievement(achievement_id)

 title.text = AchievementManager.get_achievement_title(achievement_id)
 description.text = AchievementManager.get_achievement_description(achievement_id)


func _gui_input(event: InputEvent):
 if event.is_action_pressed("unlock_cheat") and Bridge.is_debug_build():
  var save_data = SaveManager.get_save_data()
  if achievement_id not in save_data.achievements:
   save_data.achievements[achievement_id] = 1
  else:
   var current_count: int = save_data.achievements[achievement_id]
   var max_count: = 1
   if achievement_id in Globals.ACHIEVEMENT_COUNTS:
    max_count = Globals.ACHIEVEMENT_COUNTS[achievement_id]

   var next_count: = (current_count + 1) % (max_count + 1)
   if next_count == 0:
    save_data.achievements.erase(achievement_id)
   else:
    save_data.achievements[achievement_id] = next_count

  edited.emit()
  accept_event()
