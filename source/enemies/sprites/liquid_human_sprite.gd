@tool
extends BattleUnitSprite


func prep_phonebook_portrait() -> void :
 $Cracks.texture = load("res://arte/enemies/liquid_human_cracks_phonebook.png")
 super.prep_phonebook_portrait()


func prep_credits() -> void :
 $Cracks.texture = load("res://arte/enemies/liquid_human_cracks_credits.png")
 super.prep_credits()
