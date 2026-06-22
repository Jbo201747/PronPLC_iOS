class_name CharacterIcon extends Sprite2D

@export var show_locked_character: bool = false


func _ready() -> void :
 if ( not Engine.is_editor_hint() and Game.is_steam_inactive()):
  texture = load("res://arte/ui/character_piracy_icons.png")


func set_character(id: String, trans: bool = false) -> void :
 frame = Globals.CHARACTER_ICONS.get(id, 0)
 if trans:
  frame += 5

 if not show_locked_character and not Globals.is_character_unlocked(id):
  modulate = Color.BLACK
 else:
  modulate = Color.WHITE
