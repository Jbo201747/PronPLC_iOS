class_name FishingMinigame extends Minigame


const LinkColor = Globals.LinkColor
const UMAMI_LINK_POOL = [LinkColor.COBALT, LinkColor.OXIDIZED, LinkColor.GOLD]
const BRUTALIST_LINK_POOL = [LinkColor.GRAY, LinkColor.SILVER, LinkColor.RUSTY]

const FISHING_PROPERTIES = {
 MIN_SINK_SPEED = 55.0, 
 MAX_SINK_SPEED = 120.0, 
 MAX_SINK_ACCELERATION = 5.0, 
 SINK_ACCELERATION_RAMP = 0.5, 

 FISH_INTERVAL = {
  START = Vector2(62, 72), 
  FINAL = Vector2(35, 45), 
 }, 
 INTERVAL_MULTIPLIER = 1.0, 

 FISH_X_OFFSET = {
  START = 35, 
  FINAL = 35, 
  CAP_AT = 120.0, 
 }, 

 FISH_MINIMUM_SPEED = {
  START = 25.0, 
  FINAL = 35.0, 
  CAP_AT = 120.0, 
 }, 
 FISH_MAXIMUM_SPEED = {
  START = 60.0, 
  FINAL = 65.0, 
  CAP_AT = 120.0, 
 }, 

 WHIRLPOOLS_ENABLED = false, 
 WHIRLPOOL_INTERVAL = {
  START = Vector2(50, 200), 
  FINAL = Vector2(150, 400), 
 }, 
}

const FISHING_PROPERTIES_NOBODY = {
 MAX_SINK_SPEED = 160.0, 
 MAX_SINK_ACCELERATION = 6.0, 
 SINK_ACCELERATION_RAMP = 0.6, 
 WHIRLPOOLS_ENABLED = true, 
 FISH_INTERVAL = {
  START = Vector2(60, 90), 
  FINAL = Vector2(20, 30), 
 }, 
}

const FISHING_PROPERTIES_BRUTALIST = {
 FISH_X_OFFSET = {
  START = 75, 
  FINAL = 55, 
  CAP_AT = 120.0, 
 }, 
 FISH_MAXIMUM_SPEED = {
  START = 40.0, 
  FINAL = 50.0, 
  CAP_AT = 120.0, 
 }, 
 INTERVAL_MULTIPLIER = 1.25, 
}

const LINKED_FISH_OFFSET = Vector2(24, 16)

var fish_scene = preload("res://source/minigames/tile_fish.tscn")
var Whirlpool = preload("res://source/minigames/whirlpool.tscn")

var letter_pool = "qjxzwkvfybhmpgudcllooottnnrraaaiiissseeeee"
var letter_bag = []
var link_pool = []

var swimming_fish = []
var caught_fish = []
var whirlpools = []

var fishing_properties = {}

var scroll_ease_progress = 0.0

var fish_interval = 0.0

var sink_speed = 0.0
var sink_accel = 0.0

var whirlpools_enabled = false
var whirlpool_interval = 0.0

var rng = RNG.new()

@onready var mask = $Background / Mask
@onready var hook = $Background / Mask / Hook
@onready var fish_despawn_point = %FishDespawnPoint
@onready var fish_spawn_point = %FishSpawnPoint
@onready var anim_player = $AnimPlayer
@onready var main = Game.main
@onready var Bubble = preload("res://source/effects/bubble.tscn")


func _init() -> void :
 hide_mouse_out_of_mouse_mode = true


func _ready():
 reset_fishing_properties()

 link_pool = []

 hook.fishing_minigame = self

 AudioManager.play_sound(Sounds.FISHER.REEL_OUT)

 anim_player.play("start")
 await anim_player.animation_finished

 hook.is_active = true


func _physics_process(delta):
 fish_interval -= 60 * delta
 whirlpool_interval -= 60 * delta

 if fish_interval <= 0:
  spawn_fish()
  var interval = scale_with_sink_speed(fishing_properties.FISH_INTERVAL)
  fish_interval += rng.randf_range(interval.x, interval.y)
  fish_interval *= fishing_properties.INTERVAL_MULTIPLIER

 if fishing_properties.WHIRLPOOLS_ENABLED:
  if whirlpool_interval <= 0:
   spawn_whirlpool()
   var interval = scale_with_sink_speed(fishing_properties.WHIRLPOOL_INTERVAL)
   whirlpool_interval += rng.randf_range(interval.x, interval.y)

 sink_accel = min(fishing_properties.MAX_SINK_ACCELERATION, sink_accel + fishing_properties.SINK_ACCELERATION_RAMP * delta)
 sink_speed = min(fishing_properties.MAX_SINK_SPEED, sink_speed + sink_accel * delta)

 for fish in swimming_fish:
  fish.vertical_speed = - sink_speed

 for whirlpool in whirlpools:
  whirlpool.vertical_speed = - sink_speed

 if not hook.is_active:
  return

 if scroll_ease_progress < 1:
  scroll_ease_progress += min(delta, 1)

 var scroll_ease = ease(scroll_ease_progress, 2)
 var scroll_speed = sink_speed * scroll_ease * 0.6 * delta

 $Background / Mask / WoodGrain.region_rect.position.y += scroll_speed


func reset_fishing_properties():
 fishing_properties = FISHING_PROPERTIES.duplicate()
 if Game.enemy.id == Enemies.NOBODY:
  fishing_properties.merge(FISHING_PROPERTIES_NOBODY, true)
 elif Game.enemy.id == Enemies.BRUTALIST and Game.tile_board.restock_locked:
  fishing_properties.merge(FISHING_PROPERTIES_BRUTALIST, true)

 sink_accel = 0.0
 sink_speed = fishing_properties.MIN_SINK_SPEED
 fish_interval = fishing_properties.FISH_INTERVAL.START.y
 whirlpool_interval = fishing_properties.WHIRLPOOL_INTERVAL.START.y


func start() -> void :
 super.start()
 AudioManager.effects.fishing.set_enabled(true)


func end() -> void :
 AudioManager.effects.fishing.set_enabled(false)
 super.end()


func scale_with_sink_speed(property: Dictionary):
 var cap = property.get("CAP_AT", fishing_properties.MAX_SINK_SPEED)
 var progress = remap(min(sink_speed, cap), fishing_properties.MIN_SINK_SPEED, cap, 0.0, 1.0)
 return lerp(property.START, property.FINAL, progress)


func reseed(parent_rng):
 rng.reseed(parent_rng)


func fill_linked_pool():
 if Game.enemy.id == Enemies.BRUTALIST:
  link_pool = BRUTALIST_LINK_POOL.duplicate()
 else:
  link_pool = UMAMI_LINK_POOL.duplicate()

 rng.shuffle(link_pool)


func pick_linked_color():
 if link_pool.is_empty():
  fill_linked_pool()

 var choice = link_pool.pop_front()
 if link_pool.is_empty():
  fill_linked_pool()
  while link_pool[0] == choice:
   rng.shuffle(link_pool)

 return choice


func instantiate_fish():
 var fish = fish_scene.instantiate()
 mask.add_child(fish)
 fish.reseed(rng)
 swimming_fish.append(fish)
 fish.hook = hook
 fish.minigame = self

 return fish


func spawn_fish():
 var direction = rng.pick_random([1, -1])

 var minimum_speed = scale_with_sink_speed(fishing_properties.FISH_MINIMUM_SPEED)
 var maximum_speed = scale_with_sink_speed(fishing_properties.FISH_MAXIMUM_SPEED)
 var swim_speed = rng.randf_range(minimum_speed, maximum_speed) * direction

 var base_x_offset = scale_with_sink_speed(fishing_properties.FISH_X_OFFSET)
 var x_offset = rng.randf_range(base_x_offset, base_x_offset + 20.0) * - direction
 var y_offset = rng.uniform_around(0.0, 16.0)

 var fish = instantiate_fish()
 fish.global_position = fish_spawn_point.global_position + Vector2(x_offset, y_offset)
 fish.horizontal_speed = swim_speed

 fish.spawn(get_fish_face())

 var should_pulse = rng.randf() <= 0.2
 var base_pulse_speed = 0.0
 if should_pulse:
  base_pulse_speed = rng.randf_range(55.0, 95.0) * direction
  fish.set_pulse_speed(base_pulse_speed)

 if check_spawn_linked_fish(fish, direction):
  return

 if rng.randf() <= 0.66:
  var follower_swim_speed = swim_speed + rng.randf_range(-3.0, 0.0)

  var follower_distance = rng.randf_range(50.0, 90.0) + rng.randfn(0.0, 2.0)
  var follower_x_offset = x_offset + follower_distance * - direction
  var follower_y_offset = y_offset + rng.randf_range(0.0, 32.0) + rng.randfn(0.0, 2.0)
  var follower_offset = Vector2(follower_x_offset, follower_y_offset)

  var follower = instantiate_fish()
  follower.horizontal_speed = follower_swim_speed
  follower.global_position = fish_spawn_point.global_position + follower_offset

  follower.spawn(get_fish_face())

  if should_pulse:
   var follower_pulse_speed = rng.randfn(base_pulse_speed, 4.0)
   follower.set_pulse_speed(follower_pulse_speed, fish.pulse_cooldown)

  check_spawn_linked_fish(follower, direction)


func check_spawn_linked_fish(fish, direction):
 if fish.tile.has_status(Globals.TileStatus.LINKED):
  var linked_fish = instantiate_fish()
  fish.set_linked_fish(linked_fish)
  var linked_offset = LINKED_FISH_OFFSET * Vector2(direction, 1.0)
  linked_fish.global_position = fish.global_position + linked_offset
  linked_fish.spawn(get_fish_face())

  return true


func get_fish_face():
 if letter_bag.is_empty():
  letter_bag = Array(letter_pool.split())
  rng.shuffle(letter_bag)

 var face = letter_bag.pop_front()
 return face


func catch_fish(fish, ignore_pair = false):
 caught_fish.append(fish)

 var degree_offset: float = 0.0
 var num_fish: = caught_fish.size()
 var push_right: = num_fish % 2 == 0
 for i in num_fish:
  if i == (num_fish - 1):
   continue

  var old_fish: Node2D = caught_fish[i]
  if push_right and old_fish.rotation_degrees >= 0:
   old_fish.rotation_degrees += 12.0
  elif not push_right and old_fish.rotation_degrees <= 0:
   old_fish.rotation_degrees -= 12.0

 fish.catch(degree_offset)
 remove_fish(fish, false)

 hook.fish_marker.call_deferred("add_child", fish)

 Game.screenshake(2, 0.16)

 if fish.linked_fish and not ignore_pair:
  catch_fish(fish.linked_fish, true)


func should_despawn_fish(fish):
 return fish.global_position.y <= fish_despawn_point.global_position.y


func remove_fish(fish, free = true):
 var fish_index = swimming_fish.find(fish)

 swimming_fish.remove_at(fish_index)
 mask.remove_child(fish)

 if free:
  fish.queue_free()


func instantiate_whirlpool():
 var whirlpool = Whirlpool.instantiate()
 mask.add_child(whirlpool)
 whirlpools.append(whirlpool)

 return whirlpool


func spawn_whirlpool():
 var whirlpool = instantiate_whirlpool()
 var x_offset = randf_range(-48, 48)

 whirlpool.spawn(x_offset)
 whirlpool.tree_exiting.connect(_on_whirlpool_tree_exiting.bind(whirlpool))


func _on_whirlpool_tree_exiting(whirlpool: Node) -> void :
 whirlpools.erase(whirlpool)


func spawn_bubble(h_speed, spawn_position):
 var bubble = Bubble.instantiate()
 mask.add_child(bubble)

 bubble.global_position = spawn_position
 bubble.fishing_minigame = self
 bubble.spawn(h_speed)


func switch_to_mouse_mode() -> void :
 super.switch_to_mouse_mode()
 InputManager.warp_mouse(hook.global_position)
