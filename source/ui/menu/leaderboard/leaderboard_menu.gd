extends MenuPanel


func _on_start_appearing() -> void :
 if not Game.is_in_run():
  Bridge.set_rich_presence_display("#InLeaderboard")

 %Leaderboard.active = true
 %Leaderboard.generate_leaderboard()


func _on_start_disappearing() -> void :
 %Leaderboard.active = false
 if not Game.is_in_run():
  Bridge.clear_rich_presence()


func get_focus_controls() -> Array[Control]:
 return [ %Leaderboard.sectioned_panel.scroll]
