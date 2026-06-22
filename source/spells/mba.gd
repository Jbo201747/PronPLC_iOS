extends Spell


func _use():
 if not can_submit():
  _end_use()
  return

 Game.screenshake(2, 0.16)
 AudioManager.play_sound(Sounds.SPELLS.BOX_SHUFFLE)

 await word_builder.submit_without_ending_turn(false)

 _post_use()


func can_submit():
 var words: WordList = word_builder.get_words()
 return word_builder.can_submit() and words.maximum_length < 4 and words.sub_lists.size() == 1


func is_usable():
 return super.is_usable() and not word_builder.is_submitting and can_submit()
