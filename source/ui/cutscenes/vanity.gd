extends Cutscene


@onready var present_label: Label = %PresentLabel

var pre_presents_timeout: CancelableTimeout
var text_playback: Util.TypeTextPlayback


func advance() -> void :
 can_advance = false

 cancel_auto_progress()
 if pre_presents_timeout and pre_presents_timeout.valid:
  pre_presents_timeout.cancel()

 if text_playback and text_playback.valid:
  text_playback.cancel()

 await player.screen_wipe.wipe_in()
 finished.emit()


func play() -> void :
 present_label.visible_characters = 0

 player.screen_wipe.cover()
 await Game.timeout(0.33)
 await player.screen_wipe.wipe_out()
 can_advance = true

 pre_presents_timeout = Game.cancelable_timeout(1.0)
 await pre_presents_timeout.cancel_or_timeout
 if not pre_presents_timeout.is_canceled:
  text_playback = Util.type_text_cancelable(present_label)
  await text_playback.finished
  text_playback = null

 set_auto_progress(3.0)
