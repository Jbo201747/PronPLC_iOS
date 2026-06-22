extends Enemy


signal finished_eating

var uneaten_tiles = 0
var ate_bomb: = false
var ate_harmful_value: int = 0

var suck_start_anim: String = "start_sucking"

@onready var tile_marker = $Sprite / TileMarker


func _init():
 id = Enemies.BOTTOM_FEEDER
 next_move = "sneeze"

 moves = {
  sneeze = {
   damage = {
    0: 1, 
    3: 3
   }, 
   next = "bash", 
   custom_call = "attack", 
  }, 
  bash = {
   damage = {
    0: 2, 
    1: 3, 
    2: 4, 
   }, 
   next = "sneeze", 
   custom_call = "attack", 
  }, 
 }


func display_intent():
 if moves[next_move].damage > 0:
  add_intent(Intent.ATTACK, {damage = moves[next_move].damage})

 add_intent(Intent.FEED)


func attack():
 var vacuum_tiles = get_vacuum_tiles()
 await suck_tiles(vacuum_tiles)

 if ate_bomb:
  await eat_bomb()
  return

 if ate_harmful_value > 0:
  await hurt(ate_harmful_value)
  await tile_board.wait_for_idle()
  if is_defeated:
   return

 if moves[next_move].damage == 0:
  return

 anim_player.play(next_move)

 await sprite.hit
 hit_player(moves[next_move].damage)

 if next_move == "sneeze":
  Game.screenshake(3, 0.24)

 await pend_animation_stopped(next_move)
 anim_player.play("idle")


func eat_bomb():
 sprite.bleed_override = Globals.COLORS.SMOKE
 sprite.bleed_blend = Globals.COLORS.DARK_SMOKE
 sprite.bleed_blend_duration = 1.0

 sprite.get_node("./Sprite").texture = load("res://arte/enemies/reflux_feeder.png")

 await hurt(999)
 await tile_board.wait_for_idle()


func animate_flinch_lethal():
 if id in Sounds.ENEMY_DEATH_SOUNDS:
  AudioManager.play_sound(Sounds.ENEMY_DEATH_SOUNDS[id])

 if ate_bomb:
  anim_player.play("explode")
  anim_player.queue("dying_explode")
 else:
  anim_player.play("dying")

 await animate_death()


func get_vacuum_tiles():
 var bottom_row = tile_board.get_row(0)
 bottom_row.reverse()

 return bottom_row


func suck_tiles(tiles):
 ate_harmful_value = 0
 uneaten_tiles = tiles.size()

 anim_player.play(suck_start_anim)
 anim_player.queue("suck")

 await Game.timeout(0.24)

 for tile in tiles:
  tile.animation.play("jitter")
  tile.z_index += 1

  await Game.timeout(0.08)

 await Game.timeout(0.24)

 for tile in tiles:
  suck_tile(tile)
  await Game.timeout(0.32)

 await finished_eating

 tile_board.remove_tiles(tiles, {
  ignore_status = true, 
 })

 anim_player.play_advance("stop_sucking")
 await anim_player.animation_finished


func suck_tile(tile: Tile):
 tile.disable_shadow()
 await tile.tween_position(tile_marker.global_position, 0.35)

 if tile.has_status(TileStatus.COAL) or tile.has_status(TileStatus.ASH):
  heal(1)

 if tile.has_status(TileStatus.CANDY):
  heal(maxi(tile.get_value(), 1))

 if tile.has_any_status([TileStatus.POISON, TileStatus.ACID]):
  ate_harmful_value += tile.get_value()

 if tile.has_status(TileStatus.BOMB):
  ate_bomb = true

 uneaten_tiles -= 1
 tile.hide()

 if uneaten_tiles == 0:
  anim_player.play("swallow_final")
 elif anim_player.current_animation == "swallow":
  anim_player.seek(0)
 else:
  anim_player.play("swallow")

 await anim_player.animation_finished

 if uneaten_tiles == 0:
  finished_eating.emit()
 else:
  anim_player.play("suck")
