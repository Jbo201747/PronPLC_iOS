extends Enemy

const ADDICT_SPEED_SCALE = 2.0

var bit_addict: = false
var fish_chance: = 0.5


func _init():
 id = Enemies.VAMPIRE
 next_move = "spill"

 lethal_damage_misses = true

 moves = {
  spill = {
   bleed = {
    0: 8, 
    1: 9, 
    2: 10, 
   }, 
   next = "bite", 
  }, 
  bite = {
   damage = 2, 
   bleed_curse = true, 
   next = {
    0: "taunt", 
    3: "spill", 
   }, 
  }, 
  taunt = {
   next = "spill", 
  }, 
 }


func display_intent():
 if next_move == "spill":
  add_intent(Intent.APPLY_STATUS, {status = TileStatus.BLEED, target = "top", near = true, count = moves.spill.bleed})

 elif next_move == "bite":
  add_intent(Intent.BITE, {damage = moves.bite.damage})
  add_intent(Intent.BLEED_CURSE)


func spill():
 await wrap_up_idle()

 anim_player.play("spill")
 anim_player.queue("idle")
 await sprite.hit

 await apply_spill_status()

 await anim_player.pend_animation_stopped("spill")


func apply_spill_status():
 var target_tiles = get_tiles({
  amount = moves.spill.bleed, 
  row_priority = tile_board.get_row_coords(true), 
  include_effects = [TileStatus.DEFAULT], 
  no_final_shuffle = true, 
 })

 var tile_delay = 0.07
 for tile in target_tiles:
  tile.add_status(TileStatus.BLEED)
  tile.add_poofcloud(tile.get_color())

  await Game.timeout(tile_delay)
  tile_delay += 0.025


func bite():
 await wrap_up_idle()

 anim_player.play("bite_start")

 var player_health = player.health

 await sprite.hit
 hit_player(moves.bite.damage)

 var player_health_loss = player_health - player.health

 var queue_bite_end: = true
 if player_health_loss > 0:
  heal(player_health_loss)

  if player.id == Globals.CHARACTERS.ADDICT:
   queue_bite_end = false
   bit_addict = true
   anim_player.queue("bite_end_addict")
   if moves.bite.next != "spill":
    anim_player.queue("idle")

 if queue_bite_end:
  anim_player.queue("bite_end")
  if moves.bite.next != "spill":
   anim_player.queue("idle")

 if moves.bite.bleed_curse:
  var target_tiles = get_tiles({
   include_effects = [TileStatus.BLEED]
  })

  for tile in target_tiles:
   tile.add_status(TileStatus.CURSED)
   tile.add_poofcloud(tile.get_color())

   await Game.timeout(0.08)

 await anim_player.pend_animation_stopped("bite")

 if bit_addict:
  anim_player.speed_scale = ADDICT_SPEED_SCALE

 if moves.bite.next == "spill":
  anim_player.play("drank")
  anim_player.queue("idle")
  await anim_player.pend_animation_stopped("drank")


func taunt():
 await wrap_up_idle()

 anim_player.play("drank")
 anim_player.queue("idle")
 await anim_player.pend_animation_stopped("drank")


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= fish_chance:
  tile.add_status(TileStatus.BLEED)


func animate_flinch_lethal():
 await anim_player.play_until_finished("die")


func get_save_data():
 var save = super.get_save_data()
 save.bit_addict = bit_addict
 return save


func load_save_data(save):
 super.load_save_data(save)
 bit_addict = save.get("bit_addict", false)
 if bit_addict:
  anim_player.speed_scale = ADDICT_SPEED_SCALE
