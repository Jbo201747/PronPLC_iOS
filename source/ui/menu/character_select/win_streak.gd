extends MenuPanel


@onready var label: Label = %WinStreak


func _ready() -> void :
 %Label.text = StringManager.get_string("menu/character_select/win_streak")
 super._ready()
