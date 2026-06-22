@tool
extends Control

@export var id: String = "":
 set(value):
  id = value
  update()
@export var is_enemy: bool = true:
 set(value):
  is_enemy = value
  update()
@export var shadow: bool = false:
 set(value):
  shadow = value
  update()

var sprite: BattleUnitSprite

@onready var name_label: RichTextLabel = %NameLabel
@onready var credit_label: Label = %CreditLabel


func _ready() -> void :
 update()


func update() -> void :
 if not is_node_ready():
  return

 if sprite != null and is_instance_valid(sprite) and not sprite.is_queued_for_deletion():
  if sprite.unit_id == id and sprite.unit_is_enemy == is_enemy:
   return

  sprite.queue_free()

 sprite = null

 name_label.text = ""
 credit_label.text = ""

 if is_enemy:
  if id not in Enemies.list():
   return
 elif id not in Globals.CHARACTERS.values():
  return

 var use_id: String = id
 if id in Enemies.SHADOWS:
  if shadow or ( not Engine.is_editor_hint() and SaveManager.get_save().has_viewed_cutscene("extra/credits_red") and randi_range(1, 3) == 1):
   use_id = Enemies.SHADOWS[id]

 var sprite_path: String
 if is_enemy:
  sprite_path = "res://source/enemies/sprites/%s_sprite.tscn" % use_id
 else:
  sprite_path = "res://source/characters/sprites/%s_sprite.tscn" % use_id

 if ResourceLoader.exists(sprite_path):
  var scene: PackedScene = load(sprite_path)
  sprite = scene.instantiate()
  sprite.set_unit_id(id)
  sprite.position = Vector2(0, -40)
  sprite.sound_disabled = true
  add_child(sprite)
  move_child(sprite, 0)

  if sprite is CharacterSprite:
   sprite.is_trans = true

  sprite.prep_credits()

 var name_root: String = "enemy" if is_enemy else "character"
 var name_key: String = "%s/%s/name" % [name_root, use_id]
 if StringManager.has_string(name_key):
  var context: Dictionary = {}
  if not is_enemy:
   context.trans = true
  name_label.text = StringManager.get_string(name_key, context)

 var credit_priority_key: String = "%s/%s/credit" % [name_root, use_id]
 var credit_key: String = "%s/%s/credit" % [name_root, id]
 if StringManager.has_string(credit_priority_key):
  credit_label.text = StringManager.get_string(credit_priority_key)
 elif StringManager.has_string(credit_key):
  credit_label.text = StringManager.get_string(credit_key)
