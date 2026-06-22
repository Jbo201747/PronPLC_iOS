extends "res://source/enemies/cat.gd"


var new_name: String = ""
var should_update_name: bool = false


func _init():
 super._init()
 id = Enemies.DECLAWED
 inherited_id = Enemies.CAT
 moves.swipe.damage = 0
 moves.pounce.damage = {
  0: 4, 
  1: 5, 
  2: 6, 
  3: 7, 
 }


func _on_word_submitted(words: WordList, _damage: int, _ending_turn: bool) -> void :
 if "declawed_name" not in Game.main.persistent_data:
  var name_words: = PackedStringArray()
  for sub_list in words.sub_lists:
   name_words.append(sub_list.words[0].capitalize())

  new_name = " ".join(name_words)
  should_update_name = true


func animate_flinch(damage):
 update_name()
 await super.animate_flinch(damage)


func animate_flinch_lethal():
 update_name()
 await super.animate_flinch_lethal()


func update_name() -> void :
 if "declawed_name" in Game.main.persistent_data or new_name == "":
  should_update_name = false
  new_name = ""

 if not should_update_name:
  return

 Game.main.persistent_data.declawed_name = new_name
 should_update_name = false
 health_bar.update_name()
 health_bar.name_label.set_forced(true, true)
 Game.main.set_battle_rich_presence()
 await Game.timeout(2.0)
 if not is_queued_for_deletion():
  health_bar.name_label.set_forced(false, false)
