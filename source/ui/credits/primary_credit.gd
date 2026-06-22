@tool
class_name PrimaryCredit extends MarginContainer

const CREDIT_LABEL_SCENE = preload("res://source/ui/credits/credit_minor_label.tscn")

@export var credit_path: String = "":
 set(value):
  credit_path = value
  if is_node_ready():
   update()

@onready var name_label: Label = %NameLabel
@onready var credits_container: VBoxContainer = %CreditsContainer


func _ready() -> void :
 update()


func update() -> void :
 if StringManager.has_string(credit_path):
  name_label.text = StringManager.get_string(credit_path)

 var existing_labels: = credits_container.get_children()
 if StringManager.has_string_group(credit_path):
  var group: = StringManager.get_string_group(credit_path)
  if group.has_string("0"):
   var credits: = group.get_string("0").split("\n")

   for credit in credits:
    var label: RichTextLabel = existing_labels.pop_front()
    if label == null:
     label = CREDIT_LABEL_SCENE.instantiate()
     label.add_theme_font_size_override("font_size", 10)
     credits_container.add_child(label)

    label.text = credit

 for label in existing_labels:
  label.queue_free()
