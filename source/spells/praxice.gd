extends Spell


func _use():
 var condition = func(spell): return spell != self and not spell.spell_data.character_specific and spell.is_owned()
 var chosen_spell = await player.get_selection(player.Selection.SPELL, condition)

 if chosen_spell == null or not condition.call(chosen_spell):
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.DICE_ROLL_3)
 chosen_spell.reroll([], chosen_spell.secret_id != SPELLS.CLOWN_CACHE, true, false, false, true)

 _post_use()
