class_name CutscenePlayer extends Control


signal finished

@export var hide_on_finish: bool = true
@export var track_cutscene_viewed: bool = false

var cutscene: Cutscene = null
var cutscene_id: String = ""
var queued_cutscenes: Array[String] = []

@onready var zigzag: Sprite2D = %Zigzag
@onready var screen_wipe: ScreenWipe = %ScreenWipe
@onready var anim_player: AnimPlayer = %AnimPlayer
@onready var cutscene_visibility: Control = %CutsceneVisibility


func _ready() -> void :
 Util.disable_focus_for_controls([self])
 set_process(false)
 visible = false
 cutscene_visibility.visible = false


func _process(delta: float) -> void :
 zigzag.region_rect.position.x += 10 * delta


func _gui_input(event: InputEvent) -> void :
 if cutscene and _is_advance_event(event):
  cutscene.try_advance()

 if not (event.is_action("toggle_console") or event.is_action("toggle_fullscreen") or event.is_action("toggle_mute")):
  accept_event()


func _is_advance_event(event: InputEvent) -> bool:
 if event.is_action_pressed("advance_cutscene") and Input.is_action_just_pressed("advance_cutscene"):
  return true

 return Util.is_mobile_tap(event)


func _cutscene_finished() -> void :
 cutscene.queue_free()
 cutscene = null

 if track_cutscene_viewed:
  SaveManager.get_save().track_viewed_cutscene(cutscene_id)

 cutscene_id = ""

 if has_queued_cutscene():
  play_queued_cutscene()
  return

 release_focus()
 set_process(false)
 finished.emit()
 if hide_on_finish:
  visible = false
  cutscene_visibility.visible = false


func focus() -> void :
 visible = true
 grab_focus(true)


func play_cutscene(id: String) -> void :
 focus()

 cutscene_id = id

 var string_group: = StringManager.get_string_group("cutscenes/%s" % cutscene_id)

 if string_group.has_string("queue"):
  queued_cutscenes.append(string_group.get_string("queue"))

 var cutscene_flags: = PackedStringArray()
 if string_group.has_string("flags"):
  cutscene_flags = string_group.get_string("flags").split(" ")

 if "credits" in cutscene_flags:
  cutscene = load("res://source/ui/credits/credits.tscn").instantiate()
 elif "vanity" in cutscene_flags:
  cutscene = load("res://source/ui/cutscenes/vanity.tscn").instantiate()
 else:
  cutscene = load("res://source/ui/cutscenes/story_cutscene.tscn").instantiate()

 screen_wipe.uncover()
 cutscene.player = self
 cutscene.string_group = string_group
 cutscene.flags = cutscene_flags
 cutscene.finished.connect(_cutscene_finished)
 cutscene_visibility.visible = true

 add_child(cutscene)

 set_process(true)

 cutscene.play()


func play_queued_cutscene() -> void :
 play_cutscene(queued_cutscenes.pop_front())


func queue_cutscene(id: String) -> void :
 queued_cutscenes.append(id)


func has_queued_cutscene() -> bool:
 return not queued_cutscenes.is_empty()


func is_cutscene_queued(id: String) -> bool:
 return id in queued_cutscenes
