class_name PhonebookEntry extends RefCounted


var id: String
var sprite_scene: PackedScene

var locked_override_active: = false
var locked_override: = false


func _init(_id: String) -> void :
 id = _id
 sprite_scene = load("res://source/enemies/sprites/" + id + "_sprite.tscn")


func is_locked() -> bool:
 if not SaveManager.has_valid_selected_save():
  return true

 if locked_override_active:
  return locked_override

 return SaveManager.get_save().get_enemy_stats(id, -1, false).kills == 0


func get_enemy_name() -> String:
 var enemy_name: = StringManager.get_string("enemy/" + id + "/name")
 if is_locked():
  var whitespace_regex = Util.regex("\\S")
  return whitespace_regex.sub(enemy_name, "?", true)
 else:
  return enemy_name


func get_description() -> String:
 return StringManager.get_string("enemy/" + id + "/phonebook")


func instantiate_sprite() -> BattleUnitSprite:
 var sprite: BattleUnitSprite = sprite_scene.instantiate()
 sprite.set_unit_id(id)
 return sprite
