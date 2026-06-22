class_name PhonebookSelector extends Control

signal icon_selected(icon: PhonebookIcon)

var phonebook_icon_scene = preload("res://source/ui/menu/phonebook/phonebook_icon.tscn")
var icons: Array[PhonebookIcon]

@onready var phonebook_label: Label = %PhonebookLabel
@onready var vertical_container: VBoxContainer = %VBoxContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer


func _ready() -> void :
 phonebook_label.text = StringManager.get_string("menu/main/phonebook")
 for act in Enemies.POOLS.size():
  var label = Label.new()
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.text = StringManager.get_string("misc/act_" + str(act) + "/subtitle")
  label.theme_type_variation = &"MainMenuLabel"
  label.add_theme_font_size_override("font_size", 10)
  vertical_container.add_child(label)
  var act_pool = Enemies.POOLS[act]
  for enemy_set in act_pool:
   for enemy in enemy_set:
    if StringManager.has_string("enemy/" + enemy + "/phonebook"):
     add_icon(enemy)


func get_selected_icon() -> PhonebookIcon:
 var first_unlocked_icon: PhonebookIcon = null
 for icon in icons:
  if first_unlocked_icon == null and not icon.active_entry.is_locked():
   first_unlocked_icon = icon

  if icon.entries[0].id == SaveManager.get_save().data.selected_phonebook_entry:
   return icon

 return first_unlocked_icon


func add_hbox() -> HBoxContainer:
 var hbox = HBoxContainer.new()
 hbox.alignment = BoxContainer.ALIGNMENT_CENTER
 hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 vertical_container.add_child(hbox)
 return hbox


func add_icon(id) -> PhonebookIcon:
 var add_to_box: HBoxContainer
 if vertical_container.get_child_count() != 0:
  var last_child = vertical_container.get_child(-1)
  if last_child is HBoxContainer:
   add_to_box = vertical_container.get_child(-1)

 if add_to_box == null or add_to_box.get_child_count() >= 3:
  add_to_box = add_hbox()

 var entries: Array[PhonebookEntry] = [PhonebookEntry.new(id)]
 if id in Enemies.SHADOWS:
  entries.append(PhonebookEntry.new(Enemies.SHADOWS[id]))

 var icon: PhonebookIcon = phonebook_icon_scene.instantiate()
 add_to_box.add_child(icon)
 icon.set_entries(entries)
 icon.selected.connect(_on_card_selected)
 icons.append(icon)
 return icon


func _on_card_selected(icon: PhonebookIcon):
 if icon.get_parent().get_index() <= 1:
  scroll_container.ensure_control_visible(phonebook_label)
 else:
  scroll_container.ensure_control_visible(icon)

 icon_selected.emit(icon)


func get_focus_controls() -> Array[Control]:
 var controls: Array[Control] = []
 for icon in icons:
  controls.append(icon.button)

 return controls


func setup_focus_connections() -> void :
 var controls: Array[Array] = []
 for child in vertical_container.get_children():
  if child is HBoxContainer:
   var layer_controls: Array[Control] = []
   for icon: PhonebookIcon in child.get_children():
    layer_controls.append(icon.button)

   controls.append(layer_controls)

 Util.set_control_grid_focus(controls)
