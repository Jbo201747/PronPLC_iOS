class_name SpeechBubble extends Node2D


signal anim_event

var text_playback: Util.TypeTextPlayback
var cancelable: = true

@onready var label: RichTextLabel = %RichTextLabel
@onready var anim_player: AnimPlayer = %AnimPlayer


func is_typing_text() -> bool:
 return text_playback != null and text_playback.valid


func cancel_typing_text() -> void :
 if cancelable:
  text_playback.cancel()


func type_text(text: String, control_text: String = "", is_cancelable: = true) -> void :
 if is_typing_text():
  cancel_typing_text()

 cancelable = is_cancelable
 label.visible_characters = 0
 label.text = text
 text_playback = Game.type_text_with_audio_cancelable(label, 0.02, 1, -1, true, control_text)


func appear(animation: StringName = &"appear", frame: int = -1) -> void :
 label.text = ""
 label.visible_characters = 0
 anim_player.play_advance("RESET")

 if frame != -1:
  %Bubble.frame = frame
  %Tail.frame = frame

 anim_player.play_advance(animation)
 visible = true
 await anim_event


func disappear() -> void :
 anim_player.play("disappear")
 await anim_player.animation_finished
 visible = false
