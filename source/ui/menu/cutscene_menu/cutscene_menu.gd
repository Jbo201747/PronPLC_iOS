extends MenuPanel


var cutscene_entry_scene: PackedScene = preload("res://source/ui/menu/cutscene_menu/cutscene_entry.tscn")

var cutscene_entries: Dictionary[String, CutsceneEntry] = {}

@onready var sectioned_panel: SectionedPanel = %SectionedPanel


func _ready() -> void :
 super._ready()

 var cutscene_file: = StringManager.get_string_group("cutscenes")
 for cutscene_root in cutscene_file.groups:
  for cutscene in cutscene_file.groups[cutscene_root].groups:
   var cutscene_path: String = "%s/%s" % [cutscene_root, cutscene]
   var cutscene_group: = cutscene_file.groups[cutscene_root].groups[cutscene]
   if cutscene_group.has_string("name"):
    var cutscene_entry: CutsceneEntry = cutscene_entry_scene.instantiate()
    sectioned_panel.contents_box.add_child(cutscene_entry)
    cutscene_entries[cutscene_path] = cutscene_entry
    cutscene_entry.button.pressed.connect(play_cutscene.bind(cutscene_path))
    cutscene_entry.button.focus_entered.connect(_cutscene_focus_entered.bind(cutscene_entry))

    if cutscene_group.has_string("flags"):
     var flags: = cutscene_group.get_string("flags").split(" ")
     if "hide_until_viewed" in flags:
      cutscene_entry.hide_unless_viewed = true

 update_cutscenes()
 SaveManager.save_changed.connect(update_cutscenes)


func update_cutscenes() -> void :
 for cutscene in cutscene_entries:
  var entry: = cutscene_entries[cutscene]
  if not SaveManager.has_valid_selected_save() or not SaveManager.get_save().has_viewed_cutscene(cutscene):
   entry.sprite.modulate = Color.BLACK
   entry.visible = not entry.hide_unless_viewed
   entry.title.text = StringManager.get_string("achievements/locked")
  else:
   entry.title.text = StringManager.get_string("cutscenes/%s/name" % cutscene)
   entry.sprite.modulate = Color.WHITE
   entry.visible = true

 sectioned_panel.update_panels()


func play_cutscene(cutscene_path: String) -> void :
 Game.menu_shake()
 AudioManager.play_sound(Sounds.UI.MENU_BUTTON)

 var save: = SaveManager.get_save()
 if not save.has_viewed_cutscene(cutscene_path):
  return

 Game.main_menu.cutscene.focus()
 AudioManager.fade_music()
 await Game.main_menu.screen_wipe.wipe_in()
 Game.main_menu.cutscene.play_cutscene(cutscene_path)
 await Game.main_menu.cutscene.finished
 await Game.main_menu.screen_wipe.wipe_out()
 AudioManager.play_music(Globals.MUSIC.AUTHOR)


func get_focus_controls() -> Array[Control]:
 var controls: Array[Control] = []
 for cutscene in cutscene_entries:
  controls.append(cutscene_entries[cutscene].button)

 return controls


func setup_focus_connections(focus_controls: Array[Control]) -> void :
 Util.set_control_focus_sequence(focus_controls, true)


func _cutscene_focus_entered(entry: CutsceneEntry) -> void :
 if entry.button.has_focus(true):
  sectioned_panel.scroll.ensure_control_visible(entry)
