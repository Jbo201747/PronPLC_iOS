class_name InputGuideContainer extends VBoxContainer

const INPUT_GUIDE_SCENE = preload("res://source/ui/menu/settings/input_guide.tscn")

@export var string_key: String:
 set(value):
  string_key = value
  if is_node_ready():
   update()


func _ready() -> void :
 update()


func update() -> void :
 var children: = get_children()

 if StringManager.has_string_group(string_key):
  var group: = StringManager.get_string_group(string_key)
  for sub_group_key in group.groups:
   var sub_group: = group.groups[sub_group_key]

   var guide: InputGuide = children.pop_front()
   if guide == null:
    guide = INPUT_GUIDE_SCENE.instantiate()
    add_child(guide)

   guide.string_key = sub_group.get_path_key()

 for child in children:
  remove_child(child)
  child.queue_free()
