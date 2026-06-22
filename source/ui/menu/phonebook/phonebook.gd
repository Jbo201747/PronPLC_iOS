extends MenuPanel


@onready var selector: PhonebookSelector = %PhonebookSelector
@onready var portrait: PhonebookPortrait = %PhonebookPortrait
@onready var scroll_bar: VScrollBar = %VScrollBar


func _ready() -> void :
 super._ready()
 selector.scroll_container.get_v_scroll_bar().share(scroll_bar)


func check_unlock_phonebook_finished() -> void :
 AchievementManager.try_unlock_phonebook_finished()


func _on_icon_selected(icon: PhonebookIcon) -> void :
 portrait.set_icon(icon)


func _on_start_appearing() -> void :
 portrait.shadow_button.button.disabled = false
 Bridge.set_rich_presence_display("#InPhonebook")
 portrait.set_icon(selector.get_selected_icon())
 AudioManager.effects.phonebook.set_enabled(true)


func _on_start_disappearing() -> void :
 portrait.shadow_button.button.disabled = true
 if portrait.active_portrait_sprite != null:
  AudioManager.stop_node_sounds(portrait.active_portrait_sprite)
  portrait.active_portrait_sprite.process_mode = Node.PROCESS_MODE_DISABLED

 check_unlock_phonebook_finished()
 Bridge.clear_rich_presence()
 AudioManager.effects.phonebook.set_enabled(false)


func finish_disappear() -> void :
 portrait.clear_sprite_container(false)
 portrait.active_entry = null
 super.finish_disappear()


func get_focus_controls() -> Array[Control]:
 return selector.get_focus_controls()


func setup_focus_connections(_focus_controls: Array[Control]) -> void :
 last_focus_target_control = selector.get_selected_icon().button
 selector.setup_focus_connections()
