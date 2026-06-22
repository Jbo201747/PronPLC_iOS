extends MenuPanel

var achievement_entry_scene = preload("res://source/ui/menu/achievements/achievement_entry.tscn")

@onready var sectioned_panel: SectionedPanel = %SectionedPanel


func _ready():
 position = Vector2.ZERO
 super._ready()
 load_achievements()
 SaveManager.save_changed.connect(reload_achievements)
 AchievementManager.unlocked_achievement.connect(_on_achievement_unlocked)


func load_achievements():
 var all_achievements = [Globals.ACHIEVEMENTS.FIRST_RUN]
 all_achievements.append_array(Globals.CHARACTER_LOCKING_ACHIEVEMENTS.values())
 all_achievements.append_array(Globals.SPELL_ACHIEVEMENTS)
 all_achievements.append_array(Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS.values())
 all_achievements.append_array(Globals.CHALLENGE_ACHIEVEMENTS)
 all_achievements.append_array(Globals.PROGRESS_ACHIEVEMENTS)
 for achievement in all_achievements:
  if not Globals.is_valid_achievement(achievement):
   continue

  var entry = achievement_entry_scene.instantiate()
  sectioned_panel.contents_box.add_child(entry)
  entry.set_achievement(achievement)
  entry.edited.connect(achievement_edited)

 sectioned_panel.update_panels()


func reload_achievements():
 for achievement in sectioned_panel.contents_box.get_children():
  if achievement is AchievementEntry:
   achievement.reload()

 sectioned_panel.update_panels()


func achievement_edited():
 reload_achievements()


func _on_achievement_unlocked(_achievement: String, _count: int, store: bool):
 if store:
  reload_achievements()


func get_focus_controls() -> Array[Control]:
 return [sectioned_panel.scroll]
