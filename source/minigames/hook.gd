extends Node2D


const UPPER_BOUNDS = -12

const RISE_SPEED = 0.02
const SINKER_RISE_SPEED = 0.02

const CATCH_SPEED_BOOST = 2.5
const SINKER_CATCH_SPEED_BOOST = 1.5

const REEL_RISE_SPEED = 1.0
const REEL_SPEED_BOOST = 4.0

const CONTROLLER_TARGET_OFFSET = 40.0

var default_rise_speed = RISE_SPEED
var catch_speed_boost = CATCH_SPEED_BOOST

var rise_speed = default_rise_speed
var top_speed = default_rise_speed

var target = null
var is_active = false
var ending_minigame: = false
var sway_followed_through = false
var prev_global_position = null
var has_sinker = false
var whirlpool_boosted = false
var fishing_minigame = null
var velocity = 0.0
var reeling: bool = false

var bonus_bubble_odds_taper: float = 0.5
var bonus_bubble_odds: float = 0.0

@onready var bubble_marker = %BubbleMarker
@onready var fish_marker = %FishMarker
@onready var sinker = %Sinker


func _process(_delta):
 if not is_active or ending_minigame:
  return

 if position.y <= UPPER_BOUNDS:
  ending_minigame = true
  rise_speed = REEL_SPEED_BOOST
  AudioManager.play_sound(Sounds.FISHER.REEL_IN)
  await Game.timeout(0.5)

  if not fishing_minigame.caught_fish.is_empty():
   AudioManager.play_sound(Sounds.FISHER.SPLASH)

  fishing_minigame.finished.emit()


func _physics_process(delta):
 if not is_active:
  return

 if InputManager.is_mouse_mode():
  target = InputManager.get_mouse_position()
 else:
  target = global_position + InputManager.get_any_movement_vector() * CONTROLLER_TARGET_OFFSET

 var x_distance = clamp(target.x, 240 - 64, 240 + 64) - global_position.x

 var acceleration = x_distance / 20.0
 var target_velocity = 80 * acceleration

 if not InputManager.is_mouse_mode():
  velocity = lerp(velocity, target_velocity, 0.25)
 else:
  velocity = target_velocity

 position.x += velocity * delta
 position.x = clamp(position.x, 16, 112)

 rise_speed = rise_speed + ((top_speed - rise_speed) / 16.0) * 60 * delta
 if whirlpool_boosted and rise_speed > -0.25:
  whirlpool_boosted = false

 position.y -= rise_speed * 60 * delta

 if prev_global_position == null:
  prev_global_position = global_position
  return

 roll_bubbles(global_position - prev_global_position)

 bonus_bubble_odds = clampf(bonus_bubble_odds - bonus_bubble_odds_taper * delta, 0, 1.0)

 prev_global_position = global_position


func _input(event):
 if not is_active or ending_minigame:
  return

 if event.is_action("primary_button"):
  if event.is_pressed():
   if not reeling:
    reeling = true
    AudioManager.play_sound(Sounds.FISHER.REEL)
   rise_speed = REEL_SPEED_BOOST
   top_speed = REEL_RISE_SPEED
  elif not event.is_pressed():
   reeling = false
   top_speed = default_rise_speed


func add_sinker():
 has_sinker = true

 sinker.show()

 default_rise_speed = SINKER_RISE_SPEED
 catch_speed_boost = SINKER_CATCH_SPEED_BOOST

 rise_speed = default_rise_speed
 top_speed = default_rise_speed


func roll_bubbles(position_change):
 var change_ratio = (clamp(abs(position_change.x), 0, 8) ** 1.5) / (8.0 ** 1.5)
 var odds = change_ratio * 0.25

 odds += bonus_bubble_odds

 var direction = 1

 if position_change.x < 0:
  direction = -1

 if randf() <= odds:
  var h_speed = randf_range(0, 100 * direction * (abs(position_change.x) / 8.0))
  fishing_minigame.spawn_bubble(h_speed, bubble_marker.global_position)


func catch_fish(fish):
 if not whirlpool_boosted:
  rise_speed = min(rise_speed + catch_speed_boost, catch_speed_boost)

  if fish.linked_fish:
   rise_speed *= 2

 fishing_minigame.catch_fish(fish)


func hit_whirlpool(whirlpool):
 whirlpool_boosted = true
 rise_speed = -2.0 * whirlpool.get_boost_multiplier()
 bonus_bubble_odds = 0.33 * whirlpool.get_boost_multiplier()


func _on_hitbox_area_entered(area):
 if ending_minigame:
  return

 if area.is_in_group("fish"):
  var fish = area.owner

  if not fish.is_caught:
   catch_fish(fish)

 elif area.is_in_group("whirlpool"):
  var whirlpool = area.owner
  hit_whirlpool(whirlpool)
  whirlpool.disappear()
