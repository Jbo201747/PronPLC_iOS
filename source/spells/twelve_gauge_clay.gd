extends Spell


func _use():
 var condition = func(spell): return not spell.spell_data.character_specific and spell.is_owned()
 var chosen_spell = await player.get_selection(player.Selection.SPELL, condition)

 if chosen_spell == null or not condition.call(chosen_spell):
  _end_use()
  return

 var transform_to_id: String = chosen_spell.id
 if chosen_spell.id in Globals.SPECIAL_COPY_SPELLS:
  transform_to_id = Globals.SPECIAL_COPY_SPELLS[chosen_spell.id]


 if secret_id != "":
  transform_spell(transform_to_id, true, true, false, false, false, set_spell_clay)

 else:
  transform_spell(transform_to_id, chosen_spell.secret_id, true, false, false, false, set_spell_clay)

 _post_use(false, true)


func set_spell_clay(spell: Spell) -> void :
 spell.is_clay = true
