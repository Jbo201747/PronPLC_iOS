extends Status


const MAX_PARTICLE_DELAY = 1
const MIN_PARTICLE_DELAY = 0.08
var particle_delay = MAX_PARTICLE_DELAY

var crit_sparkle_resource = preload("res://source/effects/crit_sparkle.tscn")


func _process(delta):
 if not tile.is_visible_in_tree():
  return

 particle_delay -= delta

 if particle_delay <= 0:
  var crit_sparkle = crit_sparkle_resource.instantiate()
  particle_delay = randf_range(MIN_PARTICLE_DELAY, MAX_PARTICLE_DELAY)

  if Game.is_in_run():
   var crit_count = Game.tile_board.get_tiles({sorted = true, status = TileStatus.CRIT}).size()
   if crit_count > 1:
    particle_delay *= crit_count - 1

  Game.get_particle_target(tile).add_child(crit_sparkle)
  crit_sparkle.global_position = tile.global_position + Vector2(
    randi_range(4, 10) * [1, -1].pick_random(), 
    randi_range(4, 10) * [1, -1].pick_random())

  if tile.type == TileType.DEFENSE:
   crit_sparkle.sprite.frame_coords.y += 1


func get_tooltip_context():
 if Game.player:
  return {show_crit_chance = Game.player.has_natural_crits()}
 else:
  return {}
