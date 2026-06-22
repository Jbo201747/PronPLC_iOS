extends "res://source/enemies/npcs.gd"


var last_damage_taken: int = 0


func _init():
 id = Enemies.TRAFFIC
 inherited_id = Enemies.NPCS
 next_move = "obstruct"

 moves = {
  obstruct = {
   next = "pathfind"
  }, 
  pathfind = {
   damage = {
    0: 4, 
    1: 6, 
    2: 8, 
   }, 
   npc_health = {
    0: 4, 
    3: 5, 
   }, 
   next = "obstruct", 
  }, 
 }


func get_intent():
 if next_move == "obstruct":
  return Intent.TRAFFIC
 else:
  return super.get_intent()


func obstruct() -> void :
 if get_attack_damage() == 0:
  next_move_override = "obstruct"

 await sprite.get_moving()


func post_ready():
 if main.is_battle:
  sprite.update_intent_position()
 else:
  sprite.update_intent_position(moves.pathfind.damage)

 await super.post_ready()


func prepare_next_turn():
 if next_move == "obstruct":
  sprite.update_intent_position(moves.pathfind.damage)
 else:
  sprite.update_intent_position()

 await super.prepare_next_turn()


func end_turn():
 if next_move == "pathfind":
  last_damage_taken = damage_taken
 else:
  last_damage_taken = 0

 super.end_turn()


func respawn() -> void :
 if next_move == "obstruct":
  await super.respawn()
  await sprite.stand_still()


func animate_flinch(_damage):
 await super.animate_flinch(_damage)

 if next_move == "obstruct" and main.is_player_turn:
  await sprite.stand_still()


func get_damage_taken():
 return super.get_damage_taken() + last_damage_taken


func get_save_data():
 var save = super.get_save_data()
 save.last_damage_taken = last_damage_taken
 return save


func load_save_data(save):
 last_damage_taken = save.last_damage_taken
 sprite.start_still = save.next_move == "obstruct"
 super.load_save_data(save)
 sprite.start_still = true
