extends Spell


var spell_charge_decay: = SpellChargeDecay.new(self, 20)
var is_enhancing_word: = false


func set_status_tooltips():
 status_tooltips = [TileStatus.ENHANCED]


func _ready() -> void :
 if main.is_player_turn and is_owned() and not spell_charge_decay.timer.is_running():
  spell_charge_decay.timer.start()

 word_builder.post_tile_stats.connect(_on_word_builder_post_tile_stats)


func _process(delta: float) -> void :
 spell_charge_decay._process(delta)


func _use():
 if not word_builder.can_submit():
  _end_use()
  return

 Game.stop_turn_timers.emit()

 Game.screenshake(2, 0.16)

 is_enhancing_word = true
 word_builder.update()

 AudioManager.play_sound(Sounds.SPELLS.SWITCH)

 await Game.timeout(0.5)
 main.force_end_player_turn(true)
 is_enhancing_word = false

 _post_use()


func _on_word_builder_post_tile_stats(_words):
 if is_enhancing_word:
  word_builder.damage_multiplier += 0.5
  word_builder.defense_multiplier += 0.5
