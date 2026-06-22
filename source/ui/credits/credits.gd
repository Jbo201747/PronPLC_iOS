class_name Credits extends Cutscene


var skip_timer: float = 0.0

var is_shadow: bool = false:
 set(value):
  is_shadow = value
  if is_node_ready() and Engine.is_editor_hint():
   voice_credits.is_shadow = is_shadow

@onready var voice_credits: VoiceCredits = %VoiceCredits
@onready var skipping_label: Label = %SkippingLabel
@onready var credits_container: VBoxContainer = %CreditsContainer
@onready var anim_player: AnimPlayer = %AnimPlayer
@onready var chatter_player: AudioStreamPlayer = %ChatterPlayer


func _ready() -> void :
 if Engine.is_editor_hint():
  voice_credits.is_shadow = is_shadow

 set_physics_process(false)


func _physics_process(delta: float) -> void :
 if Input.is_action_pressed("advance_cutscene"):
  skip_timer = minf(skip_timer + delta, 1.0)
 else:
  skip_timer = maxf(skip_timer - delta * 2, 0.0)

 skipping_label.modulate.a = skip_timer / 1.0

 var skipping = StringManager.get_string("credits/skipping")
 skipping_label.text = skipping + ".".repeat(floori((minf(skip_timer, 0.8) / 0.8) * 3))

 if skip_timer >= 1.0:
  finish(true)


func play() -> void :
 skipping_label.modulate.a = 0.0
 player.anim_player.play_advance("start_cutscene", true)
 voice_credits.is_shadow = "shadow" in flags

 player.screen_wipe.cover()
 await Game.timeout(0.33)
 await player.screen_wipe.wipe_out()

 set_physics_process(true)

 AudioManager.play_music(Globals.MUSIC.DEATH_OF_THE)
 anim_player.play_advance("credits_start")
 anim_player.queue("roll_credits")
 anim_player.queue("credits_end")


func finish(is_skipping: bool = false) -> void :
 set_physics_process(false)

 AudioManager.fade_music()

 var chatter_fade_tween: = fade_chatter_player(0.0, 1.0)

 if is_skipping:
  await player.screen_wipe.wipe_in()
 else:
  await player.anim_player.play_until_finished("finish_cutscene")

 if chatter_fade_tween.is_valid() and chatter_fade_tween.is_running():
  await chatter_fade_tween.finished

 finished.emit()


func fade_chatter_player(volume: float, duration: float) -> Tween:
 var tween: = create_tween()
 tween.tween_property(chatter_player, "volume_linear", volume, duration)
 return tween


func _on_anim_player_event_emitted(event_name: String) -> void :
 if event_name == "credits_finished":
  finish()
 elif event_name == "chatter":
  chatter_player.volume_linear = 0.0
  chatter_player.play()
  fade_chatter_player(1.0, 3.0)
