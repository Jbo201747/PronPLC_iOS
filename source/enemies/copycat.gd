extends "res://source/enemies/paradigm.gd"


func _init():
 super._init()
 id = Enemies.COPYCAT
 inherited_id = Enemies.PARADIGM

 launch_direction = 1.5


func get_bomb_faces():
 var patterns: Array[String] = ["XOX", "OXX", "XXO"]
 for i in patterns.size():
  var red_suit = rng.move.pick_random(["♥", "♦"])
  var black_suit = rng.move.pick_random(["♠", "♣"])
  patterns[i] = patterns[i].replace("X", red_suit)
  patterns[i] = patterns[i].replace("O", black_suit)
 rng.move.shuffle(patterns)

 return patterns


func get_bomb_intent_statuses():
 return [TileEffect.TRIGRAM, TileEffect.SUIT, TileStatus.BOMB]


func animate_flinch_lethal():
 anim_player.play("abscond")
 await sprite.hit

 blow_away_bombs()

 for i in range(10):
  var spawn_position = Vector2(-30 + 15 * i, 0)
  var speed_scale = max(0.2, 2 - 0.1 * i)

  afterimage_spawner.spawn_particle(global_position + spawn_position, speed_scale)

 sprite.hide()
 await anim_player.animation_finished


func apply_fish(tile: Tile, fish: Fish) -> void :
 super.apply_fish(tile, fish)
 if tile.has_status(TileStatus.BOMB):
  tile.set_face(fish.rng.pick_random(Letters.WILDCARD_GROUPS.keys()))
