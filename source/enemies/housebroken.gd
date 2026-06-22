extends "res://source/enemies/strawman.gd"


var passcode: = ""
var warning_played: = false


func _init():
 super._init()
 id = Enemies.HOUSEBROKEN
 inherited_id = Enemies.STRAWMAN
 next_move = "countdown_3"
 flinch_animation = "flinch_housebroken"
 suwucide_anim = "trololo"

 moves.word = {
  length = {
   0: 6, 
   1: 7, 
   2: 8, 
  }
 }
 moves.kill_myself = {
  next = "none"
 }


func prepare_first_turn():
 passcode = WordUtility.dictionary.pick_random_flag_word(WordDictionary.WordFlags.COMMON, moves.word.length, rng.move)


func start_player_action() -> void :
 word_builder.word_hint.set_passcode(passcode)
 word_builder.word_hint.appear()


func end_player_action() -> void :
 if word_builder.is_submitting:
  var words: WordList = word_builder.get_words()
  if passcode not in words.words:
   await word_builder.word_hint.animate_invalid()
   word_builder.word_hint.reset_passcode()
   return

 await word_builder.word_hint.disappear()
 word_builder.word_hint.reset_passcode()


func display_intent():
 add_intent(Intent.PASSCODE, {word = passcode})
 super.display_intent()


func play_intent_sound() -> void :
 if next_move == "countdown_3" and not warning_played and not been_touched:
  warning_played = true
  AudioManager.play_sound(Sounds.STRAWMAN.WARNING)
 else:
  AudioManager.stop_sound(Sounds.STRAWMAN.WARNING)
  AudioManager.play_sound(Sounds.STRAWMAN.INPUT_PASSWORD)


func kill_myself():
 hurt(999)
 if is_flinching:
  await stopped_flinching


func animate_flinch(_damage):
 AudioManager.reset_sound(Sounds.STRAWMAN.WARNING)
 super.animate_flinch(_damage)
 if next_move == "kill_myself":
  AudioManager.play_sound(Sounds.STRAWMAN.WELCOME_USER)
 else:
  AudioManager.play_sound(Sounds.STRAWMAN.INVALID_PASSWORD)


func _on_word_submitted(words: WordList, _damage: int, _ending_turn: bool) -> void :
 if passcode in words.words:
  next_move = "kill_myself"


func _on_touch() -> void :
 if not been_touched:
  been_touched = true
  AudioManager.stop_sound(Sounds.STRAWMAN.WARNING)


func get_save_data():
 var save = super.get_save_data()
 save.passcode = passcode
 save.warning_played = warning_played
 save.times_tapped = sprite.times_tapped
 save.taps_needed = sprite.taps_needed
 return save


func load_save_data(save):
 super.load_save_data(save)
 passcode = save.get("passcode", "null")
 warning_played = save.get("warning_played", false)
 sprite.times_tapped = save.get("times_tapped", 0)
 sprite.taps_needed = save.get("taps_needed", 100)
