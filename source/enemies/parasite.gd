extends "res://source/enemies/vampire.gd"


var updating_intent: = false


func _init():
 super._init()
 id = Enemies.PARASITE
 inherited_id = Enemies.VAMPIRE

 fish_chance = 0.25

 moves.spill = {
  eternal = {
   0: 4, 
   2: 5, 
   3: 6, 
  }, 
  next = "bite", 
 }
 moves.bite.damage = {
  0: 4, 
  1: 5, 
  3: 6, 
 }
 moves.bite.next = "taunt"
 moves.bite.bleed_curse = false


func _ready():
 super._ready()

 if launching_from_enemy_scene:
  return

 tile_board.tiles_updated.connect(_tiles_updated)


func display_intent():
 if next_move == "spill":
  var eternal_tiles = get_tiles({include_effects = [TileStatus.ETERNAL], sorted = true})
  add_intent(Intent.APPLY_ETERNAL, {count = maxi(get_eternal_count() - eternal_tiles.size(), 0)})

 elif next_move == "bite":
  add_intent(Intent.BITE, {damage = moves.bite.damage})


func get_eternal_count() -> int:
 return moves.spill.eternal + times_performed_move.spill


func apply_spill_status():
 var eternal_count = get_eternal_count()
 var eternal_tiles = get_tiles({include_effects = [TileStatus.ETERNAL]})

 var remaining_tiles = eternal_count - eternal_tiles.size()
 if remaining_tiles > 0:
  var target_tiles = get_tiles({
   amount = remaining_tiles, 
   type_priority = TileType.DAMAGE, 
   effect_priority = DEFAULT_EFFECT_PRIORITY, 
  })
  eternal_tiles.append_array(target_tiles)

 for tile: Tile in eternal_tiles:
  tile.add_status(TileStatus.ETERNAL)
  tile.remove_face_statuses()
  tile.randomize_face(["q"], rng.move)
  tile.set_type(TileType.DAMAGE)
  tile.add_poofcloud(tile.get_color())

  await Game.timeout(randf_range(0.04, 0.08))


func _tiles_updated() -> void :
 if not updating_intent and battle_started and main.is_player_turn and next_move == "spill":
  updating_intent = true
  update_eternal_intent.call_deferred()


func update_eternal_intent() -> void :
 update_intents()
 updating_intent = false
