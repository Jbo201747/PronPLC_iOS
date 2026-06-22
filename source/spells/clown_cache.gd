extends Spell


func _spell_init():
 secret_id = SPELLS.CLOWN_CACHE


func _use():
 reroll()
 _post_use()
