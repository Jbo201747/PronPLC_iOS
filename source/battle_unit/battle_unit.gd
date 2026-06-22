class_name BattleUnit extends Node2D

signal turn_started
signal turn_ended
signal pre_turn_ended

signal health_changed
signal defense_changed
signal bruise_changed
signal action_finished
signal stopped_flinching
signal started_dying

const Intent = Globals.Intent
const TileType = Globals.TileType
const TileStatus = Globals.TileStatus
const TileEffect = Globals.TileEffect
const DamageType = Globals.DamageType

const VIBRATION_THRESHOLDS_ENEMY: Dictionary[int, Vector3] = {

 1: Vector3(0.2, 0.0, 0.2), 
 4: Vector3(0.3, 0.0, 0.2), 
 10: Vector3(0.5, 0.0, 0.2), 
 20: Vector3(1.0, 0.0, 0.2), 
}

const VIBRATION_THRESHOLDS_PLAYER: Dictionary[int, Vector3] = {
 1: Vector3(0.4, 0.05, 0.1), 
 3: Vector3(0.6, 0.1, 0.2), 
 6: Vector3(1.0, 0.2, 0.2), 
 10: Vector3(1.0, 1.0, 0.2), 
}

enum Gender{
 UNKNOWN, 
 MALE, 
 FEMALE, 
 NONBINARY, 
}

var DamageStar = preload("res://source/ui/damage_star.tscn")
var HealHeart = preload("res://source/ui/heal_heart.tscn")
var Poofcloud = preload("res://source/effects/poofcloud_small.tscn")
var BigPoofcloud = preload("res://source/effects/poofcloud.tscn")

var id = null
var max_health = 26
var health = max_health:
 set(value):
  var prev_health = health
  health = clamp(value, 0, max_health)

  if health != prev_health:
   health_changed.emit()

var damage_received = 0
var damage_taken = 0

var defense: int = 0:
 set(value):
  var prev_defense: = defense
  defense = clampi(value, -99, 99)

  if defense != prev_defense:
   defense_changed.emit()

var is_dead:
 get:
  return health == 0 and not is_immortal

var is_defeated: bool = false:
 get:
  return is_dead or is_defeated

var is_flinching = false:
 set(value):
  is_flinching = value

  if not is_flinching:
   stopped_flinching.emit()

var is_dying: = false

var is_immortal = false
var can_take_lethal_damage: bool = true
var lethal_damage_misses: bool = false
var hide_sprite_on_death: bool = true
var bruise = 0:
 set(value):
  if value != bruise:
   bruise = value
   bruise_changed.emit()

var flags = []
var rng = {}

var health_bar: BattleUnitBar = null
var anim_player: AnimPlayer:
 get():
  return sprite.anim_player
var hit_marker: Marker2D:
 get():
  return sprite.hit_marker

var intent_container = null

var flinch_animation: String = "flinch"

@export var gender: Gender = Gender.UNKNOWN
@export var idle_after_flinching = true

@onready var main = Game.main

@onready var sprite: BattleUnitSprite = $Sprite


func _ready():
 sprite.set_unit_id(id)
 sprite.event_emitted.connect(_on_sprite_event)
 _init_rng()
 sprite.active_sprite_changed.connect(update_intent_container)


func _init_rng():
 pass


func reseed(game_rng):
 RNG.reseed_rng_group(rng, game_rng)


func set_intent_container(_intent_container):
 intent_container = _intent_container
 update_intent_container()


func update_intent_container() -> void :
 intent_container.intents_realign_above_word = sprite.intents_realign_above_word
 intent_container.set_position_parent(sprite.intent_marker)


func act():
 pass


func deal_damage(target: BattleUnit, amount, type = DamageType.DIRECT, can_kill = true, no_flinch = false):
 if amount < 0:
  target.heal(abs(amount))
 else:
  await target.hurt(amount, type, can_kill, no_flinch)


func get_adjusted_damage_amount(amount: int, type: = DamageType.DIRECT) -> int:
 if type == DamageType.DIRECT:
  amount -= defense
  if amount > 0 or defense <= 0:
   amount += bruise

 return maxi(0, amount)


func play_damage_vibration(amount: int, thresholds: Dictionary[int, Vector3]) -> void :
 var vibration: Vector3 = Vector3.INF
 for threshold in thresholds:
  if amount >= threshold:
   vibration = thresholds[threshold]

 if vibration != Vector3.INF:
  InputManager.vibrate(vibration.x, vibration.y, vibration.z)


func hurt(amount, type = DamageType.DIRECT, can_kill = true, no_flinch = false):
 damage_received += amount

 amount = get_adjusted_damage_amount(amount, type)

 damage_taken += amount

 if is_player():
  AchievementManager.player_hurt(amount)

 var is_lethal: bool = amount >= health and can_kill and can_take_lethal_damage

 if is_player():
  play_damage_vibration(amount, VIBRATION_THRESHOLDS_PLAYER)
 else:
  play_damage_vibration(amount, VIBRATION_THRESHOLDS_ENEMY)

 if amount > 0:
  var screenshake_amount = clamp(amount / 20.0 * 8, 2, 16)
  Game.screenshake(screenshake_amount, 0.32)


 if not is_dead:
  if is_lethal and lethal_damage_misses:
   is_defeated = true
  else:
   take_damage(amount, can_kill)

  if is_defeated:
   take_lethal_damage()

 if is_defeated:
  if is_player():
   flinch(amount)
  else:
   flinch_lethal(amount)
 elif not no_flinch:
  flinch(amount)

 if not is_lethal or not lethal_damage_misses:
  spawn_damage_star(amount)

 if is_flinching:
  await stopped_flinching


func spawn_damage_star(amount: int) -> void :
 var existing_popup = null
 var existing_amount = 0

 if is_player():
  existing_popup = get_tree().get_first_node_in_group("player_popup")
 else:
  existing_popup = get_tree().get_first_node_in_group("enemy_popup")

 if existing_popup != null:
  existing_amount = existing_popup.value

  main.remove_child(existing_popup)
  existing_popup.queue_free()

 var damage_star = DamageStar.instantiate()

 main.add_child(damage_star)
 damage_star.global_position = hit_marker.global_position
 damage_star.appear(amount + existing_amount, is_player())


func take_damage(amount: int, can_kill: bool) -> void :
 if can_kill and can_take_lethal_damage:
  health -= amount
 else:
  health = max(1, health - amount)


func will_damage_kill(damage: int, type: = DamageType.DIRECT, can_kill: = true) -> bool:
 if not can_kill:
  return false

 damage = get_adjusted_damage_amount(damage, type)
 return damage >= health


func flinch(_damage):
 is_flinching = true

 await animate_flinch(_damage)

 if idle_after_flinching:
  _play_idle()

 is_flinching = false


func animate_flinch(_damage):
 if anim_player.is_playing() and anim_player.current_animation == flinch_animation:
  anim_player.seek(0)
 else:
  anim_player.play(flinch_animation)

 await anim_player.animation_finished


func flinch_lethal(_amount: int):
 is_flinching = true
 is_dying = true

 started_dying.emit()
 clear_intent()
 await animate_flinch_lethal()

 if hide_sprite_on_death:
  sprite.hide()

 await health_bar.disappear()

 is_flinching = false


func _play_idle():
 if anim_player.has_animation("idle"):
  anim_player.play("idle")
 elif anim_player.has_animation("RESET"):
  push_warning("Unit ", id, " has no idle, using reset!")
  anim_player.play("RESET")
 else:
  push_warning("Unit ", id, " has no idle or reset!")


func _start_wrapping_up_idle(top_speed: float, acceleration_time: float) -> Tween:
 var tween: = create_tween()
 tween.set_ease(Tween.EASE_OUT)
 tween.tween_property(sprite.anim_player, "speed_scale", top_speed, acceleration_time)
 return tween


func _finish_wrapping_up_idle(tween: Tween, prior_speed_scale: float) -> void :
 tween.kill()
 sprite.anim_player.speed_scale = prior_speed_scale


func wrap_up_idle(top_speed: float = 3.0, acceleration_time: float = 1.0):
 var prior_speed: = sprite.anim_player.speed_scale
 var tween: = _start_wrapping_up_idle(top_speed, acceleration_time)
 await sprite.pend_event("idle_break")
 _finish_wrapping_up_idle(tween, prior_speed)


func wrap_up_idle_flag(top_speed: float = 3.0, acceleration_time: float = 1.0):
 var prior_speed: = sprite.anim_player.speed_scale
 var tween: = _start_wrapping_up_idle(top_speed, acceleration_time)
 await sprite.pend_flag("idle_break", true)
 _finish_wrapping_up_idle(tween, prior_speed)


func animate_flinch_lethal():
 if id in Sounds.ENEMY_DEATH_SOUNDS:
  AudioManager.play_sound(Sounds.ENEMY_DEATH_SOUNDS[id])

 if anim_player.has_animation("dying"):
  anim_player.play("dying")
 else:
  push_warning("Unit ", id, " has no dying animation!")

 await animate_death()


func animate_death() -> void :
 await Game.timeout(2)

 if anim_player.has_animation("die"):
  anim_player.play("die")
  await anim_player.animation_finished
  sprite.blood_explode()
  sprite.hide()
 else:
  push_warning("Unit ", id, " has no die animation!")

 await Game.timeout(0.5)


func heal(amount, is_candy: = false):
 var prev_health = health
 amount = max(0, amount)

 var heal_heart = HealHeart.instantiate()
 main.add_child(heal_heart)
 heal_heart.global_position = hit_marker.global_position
 heal_heart.appear(amount, false)

 if self is Enemy:
  AudioManager.play_sound(Sounds.AGE_REGRESSOR.HEAL)
 else:
  AudioManager.play_sound(Sounds.GENERIC.HEAL)

 health += amount

 if is_player():
  AchievementManager.player_healed(health - prev_health, is_candy)

 await heal_heart.tree_exiting


func add_intent(intent, context = null, tiles = []):
 intent_container.update_intent(intent, context, tiles, true)


func clear_intent():
 if intent_container != null:
  await intent_container.clear_intents()


func update_intents():
 intent_container.reset_intents()
 display_intent()
 intent_container.update_intents()


func display_intent():
 pass


func end_turn():
 turn_ended.emit()

 damage_received = 0
 damage_taken = 0



func take_lethal_damage():
 pass


func revive(amount = max_health):
 health = amount


func show_health(instant: = false):
 await health_bar.appear(instant)


func get_save_data() -> Dictionary:
 var save = {
  max_health = max_health, 
  health = health, 
  defense = defense, 
  damage_taken = damage_taken, 
  damage_received = damage_received, 
  rng = RNG.get_rng_group_save(rng), 
 }

 return save


func load_save_data(save):
 RNG.load_rng_group_save(rng, save.rng)
 max_health = save.max_health
 health = save.health
 defense = save.defense
 damage_taken = save.get("damage_taken", 0)
 damage_received = save.get("damage_received", 0)


func start_appearing() -> void :
 pass


func appear() -> void :
 if id in Enemies.AMBUSH and anim_player.has_animation("appear"):
  anim_player.play_advance("appear")
  await anim_player.animation_stopped


func pend_animation_stopped(anim_name: StringName) -> void :
 await sprite.pend_animation_stopped(anim_name)


func pend_animation_played(anim_name: StringName):
 await sprite.pend_animation_played(anim_name)


func pend_any_animation_played(anim_names: Array[StringName]) -> void :
 await sprite.pend_any_animation_played(anim_names)


func get_gender():
 return gender


func is_player():
 pass



func get_unit_name() -> String:
 return ""


func _on_sprite_event(event: String) -> void :
 if event == "hide_health":
  health_bar.disappear()
