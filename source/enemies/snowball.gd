extends Enemy

var exclude_effects = [TileStatus.CRIT]


func _init():
 id = Enemies.SNOWBALL
 next_move = "ashes_to"

 moves = {
  ashes_to = {
   damage = {
    0: 1, 
    1: 2, 
    2: 3, 
    3: 3, 
   }, 
   next = "ashes_to", 
  }, 
 }


func _ready() -> void :
 super._ready()
 sprite.is_critical = is_critical


func appear() -> void :
 AudioManager.play_sound(Sounds.SNOWBALL.CACKLE)


func display_intent():
 var total_damage = moves.ashes_to.damage + times_performed_move.ashes_to

 if next_move == "ashes_to":
  if total_damage > 0:
   add_intent(Intent.ATTACK, {damage = total_damage})

  display_other_intent()


func animate_flinch_lethal():
 anim_player.play("die")
 await anim_player.animation_finished
 sprite.hide()


func display_other_intent():
 add_intent(Intent.APPLY_STATUS, {status = TileStatus.ASH, target = "all"})


func ashes_to():
 var total_damage = moves.ashes_to.damage + times_performed_move.ashes_to

 anim_player.play("drag")
 await anim_player.animation_finished

 show_above_board()
 anim_player.play("blow")
 await sprite.hit

 if total_damage > 0:
  hit_player(total_damage)

 await apply_ash()
 await pend_animation_stopped("blow")

 return_below_board()
 anim_player.play("appear")
 await pend_animation_stopped("idle")


func apply_ash():
 var rows = tile_board.get_row_coords()
 rng.move.shuffle(rows)

 for row in rows:
  ashen_row(row)
  await Game.timeout(0.16)


func ashen_row(row):
 var apply_to = get_tiles({
  rows = [row], 
  exclude_effects = exclude_effects, 
  sorted = true, 
  is_playable = true, 
 })

 apply_to.sort_custom( func(a, b): return a.get_coord() > b.get_coord())

 for tile in apply_to:
  tile.bounce()
  ashen_tile(tile)
  await Game.timeout(0.08)


func ashen_tile(tile):
 tile.add_status(TileStatus.ASH)
 tile.add_poofcloud(Globals.COLORS.ASH)


func is_critical():
 return float(health) / float(max_health) <= 0.4


func apply_fish(tile: Tile, _fish: Fish) -> void :
 tile.add_status(TileStatus.ASH)
