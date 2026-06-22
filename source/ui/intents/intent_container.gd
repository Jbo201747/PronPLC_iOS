extends Marker2D



@export var sort_intents: bool
@export var fade_with_minigame: bool = false
@export var realign_with_word_length: bool = false
@export var intents_realign_above_word: bool = false

var intent_instances = []
var updated_intents = []
var new_intents = []
var position_parent: TransformMarker = null

var faded: = false
var fade_tween: Tween
var realigned: = false
var realign_tween: Tween

var Intent: PackedScene = preload("res://source/ui/intents/intent.tscn")

@onready var intent_offset: Node2D = %IntentOffset


func _ready() -> void :
 if Game.is_in_run() and (realign_with_word_length or fade_with_minigame):
  Game.main.game_state_updated.connect(_on_game_state_updated)


func align_intents():
 for intent in intent_instances:
  var tween = intent.create_tween()
  tween.set_trans(tween.TRANS_QUAD)
  tween.tween_property(intent, "position", get_intent_position(intent), 0.35)


func get_intent_position(intent_instance):
 var intents_size = intent_instances.size() * 24.0
 var left_intent_x = - (intents_size / 2.0) + 12
 var intent_index = intent_instances.find(intent_instance)
 return Vector2(left_intent_x + 24 * intent_index, 0)


func intent_sort(intent_a, intent_b):
 var priority_a = intent_a.get_priority()
 var priority_b = intent_b.get_priority()
 if priority_a == priority_b:
  return intent_a.get_key() < intent_b.get_key()
 else:
  return priority_a < priority_b


func get_intent_instance(intent, context):
 for instance in intent_instances:
  if instance.matches(intent, context):
   return instance

 return null


func update_intent(intent, context = null, tiles = null, create_if_not_found = false):
 if context == null:
  context = {}

 if tiles == null:
  tiles = []
 elif not tiles is Array:
  tiles = [tiles]

 var intent_instance = get_intent_instance(intent, context)
 if intent_instance != null:
  intent_instance.set_context(context, tiles)
  updated_intents.append(intent_instance)
 elif create_if_not_found:
  var new_intent = Intent.instantiate()
  intent_offset.add_child(new_intent)
  new_intent.set_intent(intent, context.duplicate(), tiles)
  intent_instances.append(new_intent)
  new_intents.append(new_intent)
  updated_intents.append(new_intent)


func reset_intents():
 new_intents = []
 updated_intents = []


func keep_intents(intents: Array) -> void :
 reset_intents()
 for instance in intent_instances:
  if instance.intent in intents:
   updated_intents.append(instance)

 update_intents()


func remove_intents(intents: Array) -> void :
 reset_intents()
 for instance in intent_instances:
  if instance.intent not in intents:
   updated_intents.append(instance)

 update_intents()


func update_intents(instant: bool = false, simultaneous_appear: bool = false) -> void :
 for intent in intent_instances:
  if intent not in updated_intents:
   intent.disappear()

 intent_instances = updated_intents

 if sort_intents:
  intent_instances.sort_custom(intent_sort)

 for intent in new_intents:
  intent.position = get_intent_position(intent)

 if simultaneous_appear:
  for intent in new_intents:
   intent.appear()
 else:
  for intent in new_intents:
   if intent == new_intents[-1]:
    await intent.appear(instant)
   else:
    intent.appear(instant)
    await Game.conditional_timeout(0.12, instant)

 var intent_z_index = 0
 for intent in intent_instances:
  intent.update_label()
  intent.z_index = intent_z_index
  intent_z_index += 1

 align_intents()


func clear_intents(instant: = false):
 new_intents = []
 intent_instances = []
 updated_intents = []

 var intents = intent_offset.get_children()

 if intents.is_empty():
  return

 var all_intents_disappearing: = true
 for intent in intents:
  if not intent.disappearing:
   all_intents_disappearing = false
   break

 if all_intents_disappearing:
  return

 if sort_intents:
  intents.sort_custom(intent_sort)

 for intent in intents:
  if intent == intents[-1]:
   await intent.disappear(instant)
  else:
   intent.disappear(instant)
   await Game.conditional_timeout(0.12, instant)


func set_position_parent(marker: TransformMarker) -> void :
 if position_parent != null and is_instance_valid(position_parent):
  position_parent.transform_changed.disconnect(_position_parent_transform_changed)

 position_parent = marker
 position_parent.transform_changed.connect(_position_parent_transform_changed)
 _position_parent_transform_changed()


func _position_parent_transform_changed() -> void :
 global_transform = position_parent.get_global_transform()


func _on_game_state_updated() -> void :
 var should_be_faded: bool = false
 var should_be_realigned: bool = false

 if realign_with_word_length:
  if Game.word_builder.tiles.size() >= 10 and absf(global_position.y - Game.word_builder.global_position.y) < 24.0:
   should_be_realigned = true

 if fade_with_minigame and Game.main.get_active_minigame() != null:
  should_be_faded = true

 if should_be_realigned != realigned:
  realigned = should_be_realigned

  if realign_tween != null and realign_tween.is_running():
   realign_tween.kill()

  realign_tween = create_tween()

  if realigned:
   var align_to: Vector2 = Game.word_builder.intent_container.global_position
   if intents_realign_above_word:
    align_to = Game.word_builder.intent_high_position.global_position

   realign_tween.tween_property(intent_offset, "position:y", align_to.y - global_position.y, 0.2)
  else:
   realign_tween.tween_property(intent_offset, "position:y", 0, 0.2)

 if should_be_faded != faded:
  faded = should_be_faded

  if fade_tween != null and fade_tween.is_running():
   fade_tween.kill()

  fade_tween = create_tween()

  if faded:
   fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
  else:
   fade_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
