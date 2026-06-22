class_name NewRunButton extends MainMenuButton


@onready var stamp: CompletionStamp = %Stamp
@onready var title: Label = %Title


func _ready() -> void :
 super._ready()
 start_appearing.connect(_on_start_appearing)
 title.text = StringManager.get_string("menu/main/new_run")


func _on_start_appearing() -> void :
 stamp.update_completion(SaveManager.get_save())
