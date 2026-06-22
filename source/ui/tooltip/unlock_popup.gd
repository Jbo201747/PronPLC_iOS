extends Control


signal appeared
signal dismissed

var can_dismiss = false

@onready var title = %Title
@onready var icon = %Icon
@onready var description = %Description
@onready var anim_player = %AnimPlayer
@onready var achievement_container: VBoxContainer = %AchievementContainer

@onready var pronouns_title: Label = %PronounsTitle
@onready var pronouns: Label = %Pronouns
@onready var pronouns_container: MarginContainer = %PronounsContainer


func set_achievement(achievement_id):
 icon.visible = true
 achievement_container.visible = true
 pronouns_container.visible = false
 icon.set_achievement(achievement_id)
 title.text = AchievementManager.get_achievement_title(achievement_id, true)
 Util.shrink_label_to_bounds(title, 104.0, 8)
 description.text = AchievementManager.get_achievement_description(achievement_id)


func set_pronouns(achievement_id: String, character_id: String) -> void :
 icon.visible = false
 achievement_container.visible = false
 pronouns_container.visible = true
 pronouns_title.text = StringManager.get_string("achievements/%s/title" % achievement_id)
 pronouns.text = StringManager.get_string("achievements/%s/pronouns" % achievement_id, {
  pronouns = StringManager.get_string("character/%s/pronouns" % character_id)
 })


func _input(event):
 if can_dismiss and event.is_action("click_tile"):
  can_dismiss = false

  anim_player.play("disappear")
  await anim_player.animation_finished

  dismissed.emit()
  queue_free()


func _on_appeared():
 can_dismiss = true
