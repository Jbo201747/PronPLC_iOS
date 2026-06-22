extends Enemy


var yuri_front = true
var last_row = null
var next_rows = []
var anim_prefix: String:
 get():
  return "yuri" if yuri_front else "yaoi"


func _init():
 id = Enemies.PADDLERS
 next_move = "handoff"

 moves = {
  wobble = {
   damage = {
    0: 3, 
    1: 4, 
    2: 5, 
    3: 6, 
   }, 
   count = 3, 
   next = "handoff", 
  }, 
  handoff = {
   custom_call = "wobble", 
   damage = {
    0: 1, 
    2: 2, 
    3: 3, 
   }, 
   count = 3, 
   next = "wobble", 
  }, 
 }


func display_intent():
 add_intent(Intent.ATTACK, {damage = moves[next_move].damage, count = moves[next_move].count})
 if next_move == "wobble":
  add_intent(Intent.PADDLE, {count = 12, yuri_rows = 2, yaoi_rows = 1})
 else:
  add_intent(Intent.PADDLE, {count = 12, yuri_rows = 1, yaoi_rows = 2})


func _play_idle():
 anim_player.play(anim_prefix + "_idle")


func animate_flinch(_damage):
 anim_player.play(anim_prefix + "_flinch")
 await anim_player.animation_finished


func animate_flinch_lethal():
 anim_player.play(anim_prefix + "_dying_start")
 anim_player.queue(anim_prefix + "_dying")
 flinch_lethal_bleed()

 var tween = create_tween()
 tween.set_ease(Tween.EASE_IN)
 tween.tween_property(sprite.anim_player, "speed_scale", 3.0, 4.0)

 await tween.finished

 sprite.blood_explode()
 sprite.hide()


func flinch_lethal_bleed():
 var delay = 0.3

 while sprite.anim_player.speed_scale < 3.0:
  sprite.bleed()
  await Game.timeout(delay)
  delay = max(delay - 0.01, 0.16)


func wobble():
 var rows = tile_board.get_row_coords(false, false)
 rng.move.shuffle(rows)

 for i in moves[next_move].count:
  var tile_type = TileType.DEFENSE if yuri_front else TileType.DAMAGE
  var anim_suffix = "_start" if i == 0 else "_cycle" if i == 1 else "_stop"

  if yuri_front:
   anim_player.play("yaoi" + anim_suffix)
   yuri_front = false
  else:
   anim_player.play("yuri" + anim_suffix)
   yuri_front = true

  await sprite.hit
  hit_player(moves[next_move].damage, i == moves[next_move].count - 1)

  if not rows.is_empty():
   apply_gay(tile_type, tile_board.get_column_coords(), [rows.pop_front()])

  await anim_player.animation_finished

 _play_idle()


func handoff():
 var rows = tile_board.get_row_coords(false, false)
 rng.move.shuffle(rows)

 var move_order = [TileType.DAMAGE, TileType.DEFENSE]

 if not yuri_front:
  move_order.reverse()
  yuri_front = true

 for tile_type in move_order:
  if tile_type == TileType.DAMAGE:
   anim_player.play("yuri")
  else:
   anim_player.play("yaoi")

  await sprite.hit

  if tile_type == TileType.DAMAGE:
   hit_player(moves.handoff.damage)

  if not rows.is_empty():
   apply_gay(tile_type, tile_board.get_column_coords(), [rows.pop_front()])

  await anim_player.animation_finished

 _play_idle()


func apply_gay(tile_type, column, row):
 var target_tiles = get_tiles({
  columns = column, 
  rows = row, 
  include_effects = [TileStatus.DEFAULT], 
  has_face = true, 
 })

 rng.move.shuffle(target_tiles)

 for tile in target_tiles:
  tile.set_type(tile_type)
  tile.add_status(TileStatus.GAY)
  tile.add_poofcloud(tile.get_color())

  var interval = randf_range(0.04, 0.08)
  await Game.timeout(interval)


func get_save_data():
 var save = super.get_save_data()

 save["yuri_front"] = yuri_front

 return save


func load_save_data(save):
 super.load_save_data(save)

 yuri_front = save.yuri_front
 _play_idle()


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randf() <= 0.5:
  tile.add_status(TileStatus.GAY)
  if fish.rng.randi_range(1, 2) == 1:
   tile.set_type(TileType.DAMAGE)
  else:
   tile.set_type(TileType.DEFENSE)
