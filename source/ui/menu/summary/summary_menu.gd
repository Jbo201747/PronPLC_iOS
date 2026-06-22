class_name SummaryMenu extends MenuPanel

signal finished

var showing_summary_panel: = false

@onready var leaderboard_panel = %LeaderboardPanel
@onready var summary_panel = %SummaryPanel
@onready var continue_button = %ContinueButton


func animate_appear(instant: bool = false):
 if not Game.tile_board.is_slid_out:
  await Game.tile_board.slide_out(instant)

 if showing_summary_panel:
  await sequenced_appear([summary_panel, continue_button], instant)
 else:
  await sequenced_appear([continue_button], instant)


func animate_disappear(instant: bool = false):
 if showing_summary_panel:
  await sequenced_disappear([continue_button, summary_panel, leaderboard_panel], instant)
 else:
  await sequenced_disappear([continue_button], instant)

 if Game.main.board_should_come_back():
  await Game.tile_board.slide_in(instant)


func get_summary():
 return summary_panel.summary


func show_continue() -> void :
 showing_summary_panel = false
 await continue_button.pressed
 finished.emit()
 request_close.emit()


func show_summary(act = -1, show_run = false, victory = true) -> void :
 showing_summary_panel = true

 var summary: Summary = summary_panel.summary
 summary.run_stats = Game.main.run_stats

 if act != -1:
  summary.generate_summary(act)
  await continue_button.pressed

 if show_run:
  summary.generate_summary(-1, victory)
  await continue_button.pressed

 if Game.active_daily and show_run and Bridge.version_has_leaderboards():
  await show_leaderboard()
  await continue_button.pressed

 finished.emit()
 request_close.emit()


func show_leaderboard() -> void :
 var had_focus: = Util.has_focus(self, true)
 if summary_panel.active:
  await summary_panel.disappear_complete()

 await leaderboard_panel.appear_complete()

 setup_internal_focus()

 if had_focus:
  grab_focus()


func get_focus_controls() -> Array[Control]:
 if leaderboard_panel.active:
  return [leaderboard_panel]
 else:
  return [summary_panel]
