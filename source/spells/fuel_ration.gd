extends Spell


func _use():
 var condition = func(spell): return spell.is_owned() and spell.can_gain_max_charge()
 var chosen_spell = await player.get_selection(player.Selection.SPELL, condition)

 if chosen_spell == null:
  _end_use()
  return

 elif not condition.call(chosen_spell):
  _end_use()
  return

 chosen_spell.add_max_charge(1)
 chosen_spell.add_charge(1, true)

 _post_use()
