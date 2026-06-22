@tool
extends MarginContainer


const PRIMARY_CREDIT_SCENE = preload("res://source/ui/credits/primary_credit.tscn")


@export var credit_path: String:
 set(value):
  credit_path = value
  if is_node_ready():
   update()

@onready var credits_container: VBoxContainer = %CreditsContainer


func _ready() -> void :
 update()


func update() -> void :
 if not StringManager.has_string_group(credit_path):
  return

 var existing_credits: = credits_container.get_children()

 var group: = StringManager.get_string_group(credit_path)
 var credits: = group.get_ordered_children()
 for credit_group: StringManager.StringGroup in credits:
  var credit: PrimaryCredit = existing_credits.pop_front()
  if credit == null:
   credit = PRIMARY_CREDIT_SCENE.instantiate()
   credits_container.add_child(credit)

  credit.credit_path = credit_group.get_path_key()

 for credit in existing_credits:
  credit.queue_free()
