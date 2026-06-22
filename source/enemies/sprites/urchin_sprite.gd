@tool
class_name UrchinSprite extends BattleUnitSprite

@onready var urchin = $Offset / Sprite
@onready var outline = $Offset / Sprite / Outline
@onready var psychic_wave = $Offset / Sprite / Outline / PsychicWave

var shield_loop_playback: AudioManager.SoundPlayback


func _physics_process(_delta):
 psychic_wave.region_rect.position.x += 0.25


func _process(_delta):
 CopyUtil.copy_transform(urchin, outline)
 CopyUtil.copy_sprite_frame(urchin, outline)


func play_shield_loop() -> void :
 shield_loop_playback = play_sound(Sounds.URCHIN.SHIELD_LOOP)


func stop_shield_loop() -> void :
 if shield_loop_playback != null and shield_loop_playback.is_valid:
  shield_loop_playback.stop()
