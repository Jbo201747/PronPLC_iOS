@tool
extends MarginContainer

const credits_label_scene: PackedScene = preload("res://source/ui/credits/credits_grid_label.tscn")

@export var string_key: String = "":
 set(value):
  string_key = value
  update()

@onready var grid_container: GridContainer = %GridContainer


func _ready() -> void :
 update()


func update() -> void :
 if not is_node_ready():
  return

 var existing_labels: = grid_container.get_children()

 var credits_string: String = ""
 if StringManager.has_string(string_key):
  credits_string = StringManager.get_string(string_key)

  var credits: Array[String] = []
  credits.append_array(credits_string.split("\n"))
  credits.sort_custom( func(a: String, b: String):
   var stripped_a: = a.replace("_", "")
   var stripped_b: = b.replace("_", "")
   return stripped_a.naturalnocasecmp_to(stripped_b) > 0
  )

  var num_credits: = credits.size()
  var columns: Array[Array] = [[], [], []]
  var credits_per_column: = num_credits / 3
  var total_extra_credits: = num_credits % 3
  var extra_credits: = total_extra_credits

  for c in columns.size():
   var column: Array = columns[c]
   for i in credits_per_column:
    column.append(credits.pop_back())

   if extra_credits > 0 and (total_extra_credits != 1 or c == 1):
    extra_credits -= 1
    column.append(credits.pop_back())

   column.reverse()

  var column_index: = 0
  var placed_credits: = 0
  while placed_credits < num_credits:
   var credit: String = ""
   if not columns[column_index].is_empty():
    credit = columns[column_index].pop_back()
    placed_credits += 1

   var label: Label = existing_labels.pop_front()
   if label == null:
    label = credits_label_scene.instantiate()
    grid_container.add_child(label)

   label.text = credit
   column_index = (column_index + 1) % 3

 for label in existing_labels:
  label.queue_free()
