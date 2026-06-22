class_name AchievementIcon extends Control

@onready var icon: Sprite2D = %Icon
@onready var character_icon: Sprite2D = %CharacterIcon
@onready var spell_sprite: SpellSprite = %SpellSprite


func set_achievement(achievement_id: String):
 character_icon.visible = false
 icon.visible = false
 spell_sprite.visible = false

 var locking_achievements = Globals.CHARACTER_LOCKING_ACHIEVEMENTS.values()
 var difficulty_achievements = Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS.values()
 if (
  achievement_id in locking_achievements
  or achievement_id in difficulty_achievements
  or achievement_id == Globals.ACHIEVEMENTS.FIRST_RUN
 ):
  var character = ""
  var use_trans: bool = false
  if achievement_id == Globals.ACHIEVEMENTS.FIRST_RUN:
   character = Globals.CHARACTERS.LEXICOGRAPHER
  elif achievement_id in locking_achievements:
   character = Globals.CHARACTER_LOCKING_ACHIEVEMENTS.find_key(achievement_id)
  else:
   use_trans = true
   character = Globals.CHARACTER_DIFFICULTY_ACHIEVEMENTS.find_key(achievement_id)

  character_icon.set_character(character, use_trans)
  character_icon.visible = true
 elif achievement_id in Globals.SPELL_ACHIEVEMENTS:
  var spell: = Spell._instantiate_spell(achievement_id)
  spell_sprite.link_spell(spell)
  spell_sprite.visible = true
 else:
  icon.visible = true
  var texture_path: String = "res://arte/ui/achievements/%s.png" % achievement_id
  if ResourceLoader.exists(texture_path):
   icon.texture = load(texture_path)
  else:
   icon.texture = preload("res://arte/ui/achievements/missing.png")
