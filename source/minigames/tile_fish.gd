class_name Fish extends Node2D

const CENTER = 64
const UPPER_BOUNDS = -32
const LOWER_BOUNDS = 224

const TileType = Globals.TileType
const TileStatus = Globals.TileStatus
const TileEffect = Globals.TileEffect
const LinkColor = Globals.LinkColor


const SCARED_SPEED = 120.0
const SCARED_DECEL = 120.0

const CHARGE_SPEED = 150.0
const CHARGE_DECEL = 120.0

const PULSE_DECEL = 60.0

var damage_crit_chance = 1.0 / 15.0
var defense_crit_chance = 0.1

var horizontal_speed = 0
var speed_boost = 0
var vertical_speed = 0

var max_pulse_speed = 0
var pulse_speed = 0

var max_pulse_cooldown = 0
var pulse_cooldown = 0

var is_removing = false
var is_caught = false
var is_projectile = false
var is_shooting_target = false
var is_mouse_entered = false
var was_spooked = false
var no_variation: = false

var type:
 get:
  return tile.type
 set(value):
  tile.set_type(value)

var is_controlled = false
var linked_fish = null
var is_evil: = false

var hook = null
var bubble_cooldown = 30

var rng = RNG.new()
var variation_rng = RNG.new()
var minigame = null

@onready var hitbox = %Hitbox
@onready var mouth_marker = %MouthMarker
@onready var tail_marker = %TailMarker
@onready var anim_player = %AnimPlayer
@onready var sway_handler = %SwayHandler
@onready var tile: Tile = %Tile


func _ready():
 tile.z_as_relative = true
 tile.sway_handler.disabled = true
 tile.disable_shadow()
 tile.tile_sprite.is_fish = true
 tile.tile_face.SHIMMERING_FACE_TIME_MS = 500


func _physics_process(delta):
 if is_projectile or is_caught:
  return

 if minigame.should_despawn_fish(self):
  minigame.remove_fish(self)
  return

 var can_dash: bool = hook != null and not was_spooked
 if tile.has_status(TileStatus.CRIT) and can_dash:
  var hook_distance = global_position.distance_to(hook.global_position)

  if (hook_distance < 30
    and hook.global_position.y < global_position.y
    and not (hook.global_position.x < global_position.x - 5 and horizontal_speed < 0)
    and not (hook.global_position.x > global_position.x + 5 and horizontal_speed > 0)
  ):
   AudioManager.play_sound(Sounds.FISHER.FISH_DASH, 1.0, 1.0, "SoundLowpass")
   was_spooked = true

   speed_boost = SCARED_SPEED * sign(horizontal_speed)

   if linked_fish:
    linked_fish.was_spooked = true
    linked_fish.speed_boost = speed_boost

   spawn_bubbles(randi_range(4, 6), tail_marker)

 if is_evil and can_dash:
  if (
    abs(hook.global_position.y - global_position.y) < 20.0
    and sign(hook.global_position.x - global_position.x) == sign(horizontal_speed)
  ):
   AudioManager.play_sound(Sounds.FISHER.FISH_DASH, 1.0, 1.0, "SoundLowpass")
   AudioManager.play_sound(Sounds.FISHER.FISH_EVIL, 1.0, 1.0, "SoundLowpass")
   was_spooked = true

   tile.animation.play("cursed_fish_chomp")
   tile.tile_sprite.is_charging = true

   speed_boost = CHARGE_SPEED * sign(horizontal_speed)

   if linked_fish:
    linked_fish.was_spooked = true
    linked_fish.speed_boost = speed_boost

   spawn_bubbles(randi_range(4, 6), tail_marker)

 if not is_controlled:
  if not is_zero_approx(speed_boost):
   if is_evil:
    speed_boost = move_toward(speed_boost, 0.0, CHARGE_DECEL * delta)
    if is_zero_approx(speed_boost):
     tile.tile_sprite.is_charging = false
   else:
    speed_boost = move_toward(speed_boost, 0.0, SCARED_DECEL * delta)

  if not is_zero_approx(pulse_speed):
   pulse_speed = move_toward(pulse_speed, 0.0, PULSE_DECEL * delta)

  if pulse_cooldown <= 0:
   pulse_speed = max_pulse_speed
   pulse_cooldown = max_pulse_cooldown
  else:
   pulse_cooldown -= delta

 if linked_fish and not is_controlled:
  linked_fish.speed_boost = speed_boost
  linked_fish.pulse_speed = pulse_speed

 position.x += (horizontal_speed + speed_boost + pulse_speed) * delta
 position.y += vertical_speed * delta

 roll_bubbles(delta)


func reseed(parent_rng):
 rng.reseed(parent_rng)
 variation_rng.reseed(parent_rng)


func init_stats():
 if rng.randf() < Game.balance.defense_fish_chance:
  tile.set_type(TileType.DEFENSE)
 else:
  tile.set_type(TileType.DAMAGE)

 var crit_roll: = rng.randf()
 var crit_chance: = 0.0

 var board_damage_crits: = 0
 var board_defense_crits: = 0
 var board_crits = Game.tile_board.get_tiles({sorted = true, include_effects = [TileStatus.CRIT]})
 for crit in board_crits:
  if crit.type == TileType.DAMAGE:
   board_damage_crits += 1
  else:
   board_defense_crits += 1

 var caught_damage_crits: = 0
 var caught_defense_crits: = 0
 for fish in minigame.caught_fish:
  if fish.tile.has_status(TileStatus.CRIT):
   if fish.type == TileType.DAMAGE:
    caught_damage_crits += 1
   elif fish.type == TileType.DEFENSE:
    caught_defense_crits += 1

 var total_damage_crits: = board_damage_crits + caught_damage_crits
 var total_defense_crits: = board_defense_crits + caught_defense_crits
 if type == TileType.DAMAGE:
  crit_chance = damage_crit_chance
  if caught_damage_crits > 1 or total_damage_crits > 2:
   crit_chance = 0.0
  elif caught_damage_crits > 0 or total_damage_crits > 1:
   crit_chance *= 0.5
 elif type == TileType.DEFENSE:
  crit_chance = defense_crit_chance
  if caught_defense_crits > 1 or total_defense_crits > 2:
   crit_chance = 0.0
  elif caught_defense_crits > 0 or total_defense_crits > 1:
   crit_chance *= 0.5

 if crit_roll <= crit_chance:
  tile.add_status(TileStatus.CRIT)

 var evil_roll: = rng.randf()
 if not tile.has_status(TileStatus.CRIT):
  if evil_roll < Game.balance.evil_fish_chance and not tile.has_status(TileStatus.LINKED):
   tile.add_status(TileStatus.CURSED)
   horizontal_speed *= 0.8
   is_evil = true
   tile.tile_sprite.is_evil = true
  else:
   Game.enemy.apply_fish(tile, self)

 Game.enemy.apply_any_fish(tile, self)

 if (
  not no_variation
  and tile.faces.size() == 1
  and tile.faces[0] in Letters.ALPHABET
  and not tile.has_status(TileStatus.LINKED)
 ):
  if variation_rng.randf() < Game.balance.capital_period_chance_fishing:
   if variation_rng.randi_range(0, 1) == 0:
    tile.set_face(Letters.get_random_capital_letter(variation_rng))
    tile.add_status(TileStatus.CAPITAL)
   else:
    tile.set_face(Letters.get_random_period_letter(variation_rng))
    tile.add_status(TileStatus.PERIOD)
  elif variation_rng.randf() < Game.balance.bigram_chance_fishing:
   if variation_rng.randf() < Game.balance.bigram_become_trigram_chance:
    tile.set_face(Letters.get_random_trigram(variation_rng))
   else:
    tile.set_face(Letters.get_random_bigram(null, variation_rng))


func spawn(letter):
 tile.set_face(letter)

 if horizontal_speed > 0:
  tile.tile_sprite.is_flipped = true
  hitbox.scale.x *= -1

 init_stats()


func set_pulse_speed(speed, base_cooldown = 0.0):
 horizontal_speed *= 0.075
 max_pulse_speed = speed
 max_pulse_cooldown = abs(speed) / 100.0
 if base_cooldown == 0.0:
  pulse_cooldown = max_pulse_cooldown * rng.randf_range(0.0, 0.5)
 else:
  pulse_cooldown = base_cooldown + max_pulse_cooldown * rng.randf_range(0.1, 0.5)


func set_linked_fish(fish):
 linked_fish = fish
 fish.linked_fish = self
 fish.is_controlled = true

 fish.horizontal_speed = horizontal_speed
 fish.vertical_speed = vertical_speed

 var linked_status = tile.get_status(TileStatus.LINKED)
 linked_fish.tile.add_status(TileStatus.LINKED, {color = linked_status.link_id, turns = linked_status.turns})


func spawn_flying(copy_tile: Tile):
 if rng.randi_range(0, 1) == 0:
  tile.tile_sprite.is_flipped = true
  hitbox.scale.x *= -1

 tile.copy_tile(copy_tile)


func catch(degree_offset = 0):
 is_caught = true
 sway_handler.disabled = false
 sway_handler.direct_from_position_multiplier *= randf_range(0.5, 3.0)

 AudioManager.play_sound(Sounds.BRUTALIST.HEART_BEAT, 1.0, 1.0, "SoundLowpass")
 tile.play_status_sound(1.0, "SoundLowpass")

 if horizontal_speed > 0:
  anim_player.play("catch_right")
 else:
  anim_player.play("catch_left")

 position = Vector2(0, 6)
 rotation_degrees = degree_offset

 hitbox.set_deferred("monitoring", false)
 hitbox.set_deferred("monitorable", false)
 vertical_speed = 0
 horizontal_speed = 0
 speed_boost = 0
 tile.tile_sprite.is_charging = false


func apply_to_tile(to_tile):
 to_tile.copy_tile(tile)


func roll_bubbles(delta):
 if bubble_cooldown > 0:
  bubble_cooldown -= 60 * delta
  return

 if randf() <= 0.005:
  spawn_bubbles(randi_range(1, 3))
  bubble_cooldown = 120


func spawn_bubbles(amount, marker = mouth_marker):
 if is_caught or is_projectile or is_removing or not is_inside_tree():
  return

 for _i in range(amount):
  if is_caught or is_projectile or is_removing:
   return

  var abs_h_speed = randf_range(0, 50) + abs(horizontal_speed)
  var h_speed = abs_h_speed * - sign(horizontal_speed)

  if marker == tail_marker:
   h_speed = abs_h_speed * sign(horizontal_speed)

  minigame.spawn_bubble(h_speed, marker.global_position)

  if marker == tail_marker:
   await Game.timeout(randf_range(0.04, 0.12))
  else:
   await Game.timeout(randf_range(0.16, 0.24))


func shoot():
 get_parent().kill()
