class_name BattleUnitBar extends Node2D

const SHIELD_BASE_TEXTURE = preload("res://arte/ui/shield.png")
const SHIELD_EVIL_TEXTURE = preload("res://arte/ui/shield_evil.png")

var battle_unit: BattleUnit = null

@onready var health_label = %HealthLabel
@onready var heart = %Heart
@onready var shield: Sprite2D = %Shield
@onready var shield_label: DebossLabel = %ShieldLabel
@onready var anim_player = %AnimPlayer
@onready var name_label: HoverLabel = %NameLabel


func set_battle_unit(_battle_unit) -> void :
 battle_unit = _battle_unit
 battle_unit.health_bar = self
 battle_unit.health_changed.connect(_update_health)
 battle_unit.defense_changed.connect(_update_defense)
 battle_unit.started_dying.connect(_on_start_dying)
 name_label.hover_source = battle_unit.sprite
 battle_unit.sprite.update_hovering()
 update_name()
 name_label.set_disabled( not visible, true)
 heart.frame = battle_unit.sprite.get_heart()
 _update_health()
 _update_defense()


func update_name() -> void :
 name_label.text = battle_unit.get_unit_name()


func appear(instant: = false) -> void :
 if visible:
  return

 _update_defense()
 anim_player.play_advance("RESET")
 anim_player.play_advance("appear", instant)
 if not instant:
  await anim_player.animation_finished
 name_label.set_disabled(false)


func disappear(instant: = false):
 if not visible:
  return

 name_label.set_disabled(true)
 anim_player.play_advance("disappear", instant)
 if not instant:
  await anim_player.animation_finished


func _update_health():
 var health = battle_unit.health
 var max_health = battle_unit.max_health
 health_label.text = str(health) + "/" + str(max_health)
 health_label.reset_size()


func _update_defense():
 var defense = battle_unit.defense


 if defense == 0:
  anim_player.play("unshield")
 else:
  if defense < 0:
   shield.texture = SHIELD_EVIL_TEXTURE
   shield_label.deboss_color = Color(3268078335)
  else:
   shield.texture = SHIELD_BASE_TEXTURE
   shield_label.deboss_color = Color(3203066111)

  anim_player.play("shield")

 var defense_text: = str(defense)
 if len(defense_text) > 1:
  shield_label.font_size = 8
 else:
  shield_label.font_size = 10

 shield_label.text = defense_text


func _on_start_dying():
 name_label.set_disabled(true)
