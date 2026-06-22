@tool
extends BattleUnitSprite


@onready var wall_sprite: BattleUnitSprite = %WallSprite
@onready var heart_sprite: BattleUnitSprite = %HeartSprite
@onready var wind_anim_player = %WallSprite / Wind / AnimPlayer


func _ready() -> void :
 super._ready()
 sub_sprites = [wall_sprite, heart_sprite]
 if Engine.is_editor_hint():
  return

 set_active_sub_sprite(wall_sprite)


func stop_wind():
 await wall_sprite.pend_event("wind_looped")
 wind_anim_player.play("RESET")


func prep_phonebook_portrait() -> void :
 wall_sprite.prep_phonebook_portrait()
 %WallSprite / Sidewalk.hide()
 %WallSprite / Base.texture = load("res://arte/enemies/brutalist_base_phonebook.png")


func prep_credits() -> void :
 heart_sprite.prep_credits()
 set_active_sub_sprite(heart_sprite)
