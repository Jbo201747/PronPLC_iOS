extends "res://source/enemies/dew_jubilist.gd"


func _init():
 super._init()
 dew_projectile_scene = preload("res://source/effects/dew_projectile_baja.tscn")
 id = Enemies.DEW_JUBAJALIST
 inherited_id = Enemies.DEW_JUBILIST
 next_move = "baja_blast"

 moves = {
  baja_blast = {
   acid = {
    0: 3, 
    1: 4, 
   }, 
   damage = {
    0: 2, 
   }, 
   next = "wicked_elixir", 
  }, 
  wicked_elixir = {
   custom_call = "baja_blast", 
   acid = {
    0: 3, 
    3: 4, 
   }, 
   damage = {
    0: 2, 
    2: 3, 
   }, 
   next = "baja_blast", 
  }, 
 }


func display_intent():
 add_acid_intent()
 add_intent(Intent.ATTACK, {damage = moves[next_move].damage})


func baja_blast():
 anim_player.play("pranxis")

 num_projectiles = 2
 for i in range(2):
  await sprite.hit

  if i == 1:
   throw_player_dew(moves[next_move].damage, true)
  else:
   throw_acid_dew()

 if num_projectiles > 0:
  await all_projectiles_impacted
