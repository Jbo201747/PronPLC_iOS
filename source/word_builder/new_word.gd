extends CenterContainer


@onready var label: Label = %Label
@onready var anim_player: AnimPlayer = %AnimPlayer


func set_text(slur: bool) -> void :
 if slur:
  label.text = StringManager.get_string("misc/new_word_slur")
 else:
  label.text = StringManager.get_string("misc/new_word")


func new_word() -> void :
 await appear()
 await Game.timeout(0.5)
 await disappear()


func appear() -> void :
 await anim_player.play_until_finished("appear")


func disappear() -> void :
 await anim_player.play_until_finished("disappear")
