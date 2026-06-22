@tool
extends CharacterSprite


var play_stop_stop_stop: = false
var stop_stop_stop_sound: AudioManagerSingleton.SoundPlayback


func play_sound(sound_data: Variant, pitch_scale: float = -1.0, volume: = 1.0, bus: = "Sound") -> AudioManagerSingleton.SoundPlayback:
 if sound_data == Sounds.ADDICT.FLINCH:
  if play_stop_stop_stop:
   AudioManager.stop_sound(Sounds.ADDICT.FLINCH)
   play_stop_stop_stop = false
   stop_stop_stop_sound = super.play_sound(Sounds.ADDICT.STOP, pitch_scale, volume, bus)
   return stop_stop_stop_sound
  elif stop_stop_stop_sound != null and is_instance_valid(stop_stop_stop_sound) and stop_stop_stop_sound.is_valid:
   return null

 return super.play_sound(sound_data, pitch_scale, volume, bus)
