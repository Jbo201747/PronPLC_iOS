extends Control


@onready var label = %TimeLabel
@onready var anim_player: AnimPlayer = %AnimPlayer


func _ready():
 SaveManager.updated_settings.connect(load_enabled_setting)
 load_enabled_setting()


func load_enabled_setting() -> void :
 visible = SaveManager.get_battle_timer_enabled()
 set_process(visible)


func _process(_delta: float) -> void :
 var time_spent = Game.main.run_stats.get_current_encounter_time()
 if time_spent == -1 or not Game.main.is_battle or not Game.main.enemy.battle_started:
  anim_player.play_reversible_appear_disappear(false)
 else:
  label.text = StringManager.format_time(time_spent)
  anim_player.play_reversible_appear_disappear(true)
