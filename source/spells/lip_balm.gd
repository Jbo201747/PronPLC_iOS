extends Spell


enum {
 LIP_BALM, 
 ICBM, 
}

var state = LIP_BALM
var switch_cooldown = 0


func _ready() -> void :
 _update_state()


func _process(delta):
 update_switch_cooldown(delta)


func _process_select(delta):
 update_switch_cooldown(delta)


func update_switch_cooldown(delta) -> void :
 if switch_cooldown > 0:
  switch_cooldown = max(0, switch_cooldown - 60 * delta)


func _use():
 if state == LIP_BALM:
  _use_lip_balm()

 elif state == ICBM:
  _use_icbm()


func get_tooltip_context():
 return {icbm = state == ICBM}


func get_hv_frames() -> Vector2i:
 return Vector2i(1, 2)


func get_frame() -> int:
 if state == LIP_BALM:
  return 0
 else:
  return 1


func _update_state():
 if state == LIP_BALM:
  status_tooltips = [TileStatus.FROZEN]
 elif state == ICBM:
  status_tooltips = [{status = TileStatus.BOMB, wooden = true, bomb_turns = "2-3"}]

 frame_updated.emit()
 description_updated.emit()


func _use_lip_balm():
 var selected_tile = await get_selection()

 if selected_tile == null:
  _end_use()
  return

 var coord = selected_tile.get_coord()
 var target_tiles = get_tiles({
  rows = [coord.y], 
  has_face = true, 
  by_distance_from = coord, 
  group_by_priority = true, 
  sorted = true, 
  exclude_effects = [TileStatus.FROZEN], 
 })

 if target_tiles.is_empty():
  selected_tile.animation.play("shake")
  _end_use()
  return

 AudioManager.play_sound(Sounds.SPELLS.LIP_BALM)

 for group in target_tiles:
  for tile in group:
   tile.add_status(TileStatus.FROZEN)
   tile.bounce()
   tile.add_poofcloud(tile.get_color())
  await Game.timeout(0.16)

 _post_use()


func _use_icbm():
 var target_tiles = get_tiles({
  amount = 2, 
  effect_priority = FACE_EFFECT_PRIORITY, 
 })

 if target_tiles.is_empty():
  _end_use()
  return

 var fuse = 3

 for tile in target_tiles:
  AudioManager.play_sound(Sounds.SPELLS.BOMB_SPAWN)
  tile.add_status(TileStatus.BOMB, fuse)
  tile.set_type(TileType.DAMAGE)
  tile.remove_face_statuses()
  tile.add_poofcloud(tile.get_color())

  var letter_pair = Letters.get_random_bigram(null, rng.spell)
  tile.set_face(letter_pair)

  fuse -= 1

  await Game.timeout(0.16)

 _post_use()


func on_hover():
 if player.is_using_spell() or switch_cooldown > 0:
  return

 switch_state()


func on_unhover():
 switch_cooldown = max(10, switch_cooldown)


func switch_state():
 switch_cooldown = 20

 if state == LIP_BALM:
  state = ICBM

 elif state == ICBM:
  state = LIP_BALM

 shake.emit()
 _update_state()
