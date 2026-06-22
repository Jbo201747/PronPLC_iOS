extends Spell


func _spell_init():
 secret_id = id


func _use():
 reroll()
 _post_use()
