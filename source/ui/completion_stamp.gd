@tool
class_name CompletionStamp extends Node2D

@export_range(0, 105, 1, "prefer_slider") var completion_percent: int = 100:
 set = set_percent

@onready var label: DebossLabel = %CompletionLabel
@onready var percent_label: DebossLabel = %PercentLabel
@onready var sprite: Sprite2D = %Sprite
@onready var overlay: Sprite2D = %Overlay


func update_completion(save: SaveFile) -> void :
 if save == null:
  visible = false
  return

 if not save.metadata.any_difficulty_won:
  visible = false
  return

 visible = true

 set_percent(save.get_percent(true))


func set_percent(percent: int) -> void :
 if not is_node_ready():
  return

 completion_percent = percent
 label.text = str(percent)

 var can_be_golden: = true
 if not Engine.is_editor_hint() and percent >= 105:
  var save: = SaveManager.get_save()
  for character in Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS:
   var achievement: String = Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS[character]
   if save.get_achievement_level(achievement) < Globals.ACHIEVEMENT_COUNTS[achievement]:
    can_be_golden = false
    break

 var deboss_color: = Color(0.525, 0.525, 0.937)
 if percent > 99:
  if percent >= 105 and can_be_golden:
   deboss_color = Color(0.929, 0.816, 0.678)
   sprite.frame = 2
  else:
   sprite.frame = 1

  overlay.visible = false
 else:
  sprite.frame = 0
  overlay.frame = 1
  overlay.modulate.a = percent / 100.0
  deboss_color = Color(0.792, 0.776, 0.82).blend(Color(0.525, 0.525, 0.937, overlay.modulate.a))
  overlay.visible = true

 label.deboss_color = deboss_color
 percent_label.deboss_color = deboss_color

 if percent > 99:
  label.custom_minimum_size.x = 19
 elif percent > 9:
  label.custom_minimum_size.x = 15.5
 else:
  label.custom_minimum_size.x = 13

 if percent >= 100:
  %HBoxContainer.add_theme_constant_override("separation", -5)
 else:
  %HBoxContainer.add_theme_constant_override("separation", -6)
