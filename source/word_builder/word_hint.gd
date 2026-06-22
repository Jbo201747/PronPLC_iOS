class_name WordHint extends CenterContainer


var passcode: String = ""
var temp_warning: String = ""
var temp_warning_context: Dictionary = {}
var warning_key: String = ""
var warning_context: Dictionary = {}

var cancelable_timer: CancelableTimeout
var text_playback: Util.TypeTextPlayback

@onready var label: RichTextLabel = %Label


func set_passcode(value: String) -> void :
 passcode = value
 label.text = StringManager.get_string("misc/passcode", {passcode = passcode})
 update_label()


func reset_passcode() -> void :
 passcode = ""
 update_label()


func set_warning(value: String, context: Dictionary) -> void :
 warning_key = value
 warning_context = context
 update_label()
 appear(true)


func reset_warning() -> void :
 warning_key = ""
 warning_context = {}
 update_label()


func update_label() -> void :
 if warning_key != "":
  label.text = StringManager.get_string("misc/word_warnings/text", {
   warning = StringManager.get_string(warning_key, warning_context)
  })
 elif passcode != "":
  label.text = StringManager.get_string("misc/passcode", {passcode = passcode})
 else:
  label.text = ""
  disappear(true)


func cancel_animation() -> void :
 if cancelable_timer != null and cancelable_timer.valid:
  cancelable_timer.cancel()
  cancelable_timer = null

 if text_playback != null and text_playback.valid:
  text_playback.cancel()
  text_playback = null


func flash_out() -> void :
 for i in 9:
  cancelable_timer = Game.cancelable_timeout(0.1)
  await cancelable_timer.cancel_or_timeout
  if cancelable_timer.is_canceled:
   visible = false
   return

  visible = not visible


func animate_invalid() -> void :
 cancel_animation()
 label.text = StringManager.get_string("misc/passcode_invalid")
 flash_out()


func temporary_warning(warning: String, context: Dictionary) -> void :
 cancel_animation()
 label.text = StringManager.get_string("misc/word_warnings/text", {
  warning = StringManager.get_string(warning, context)
 })
 visible = true
 label.visible_characters = -1
 cancelable_timer = Game.cancelable_timeout(2.0)
 await cancelable_timer.cancel_or_timeout
 update_label()


func appear(instant: bool = false) -> void :
 cancel_animation()
 if instant:
  label.visible_characters = -1
  visible = true
  return

 label.visible_characters = 0
 visible = true
 cancelable_timer = Game.cancelable_timeout(0.02)
 await cancelable_timer.cancel_or_timeout
 if cancelable_timer.is_canceled:
  return

 text_playback = Game.type_text_with_audio_cancelable(label, 0.02)
 await text_playback.finished


func disappear(instant: bool = false) -> void :
 cancel_animation()
 if instant:
  visible = false
  return

 text_playback = Game.type_text_with_audio_cancelable(label, 0.02, -1)
 await text_playback.finished
 visible = false
