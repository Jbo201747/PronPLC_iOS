class_name FiringMinigame extends Minigame


const CATCH_LIMIT = 4
const MAX_WAVE_SIZE = 6
const BRUTAL_MAX_WAVE_SIZE = 12
const BRUTAL_WAVE_LIMIT = 15

const TileType = Globals.TileType
const TileStatus = Globals.TileStatus

var fish_scene = preload("res://source/minigames/tile_fish.tscn")
var FishProjectile = preload("res://source/effects/fish_projectile.tscn")

var is_tutorial = true
var wave_cooldown_sec = 0
var wave_size = 3
var num_waves = 0
var has_mouse: = false

var source_tiles = []
var caught_fish = []

var rng = RNG.new()

@onready var sub_viewport: SubViewport = %SubViewport
@onready var background: ColorRect = $Background
@onready var mask = $Background / Mask
@onready var lower_bound = $LowerBoundMarker
@onready var main = Game.main


func _init() -> void :
 hide_mouse_out_of_mouse_mode = true


func _ready():
 await Game.timeout(1)
 launch_fish()

 await Game.timeout(2)
 is_tutorial = false


func _physics_process(delta):
 if is_tutorial:
  return

 if wave_cooldown_sec > 0:
  wave_cooldown_sec -= delta
  return

 spawn_wave()

 wave_cooldown_sec = rng.randf_range(1.5, 2.5)
 num_waves += 1

 if wave_size < MAX_WAVE_SIZE and num_waves % 3 == 0:
  wave_size += 1

 elif wave_size < BRUTAL_MAX_WAVE_SIZE and num_waves >= BRUTAL_WAVE_LIMIT:
  wave_size += 1


func reseed(parent_rng):
 rng.reseed(parent_rng)


func spawn_wave():
 if source_tiles.size() <= 0:
  finished.emit()
  return

 for _i in range(min(wave_size, source_tiles.size())):
  launch_fish()
  var interval = rng.randf_range(0.08, 0.24)
  await Game.timeout(interval)


func launch_fish():
 var tile: Tile = source_tiles.pop_back()
 var projectile = FishProjectile.instantiate()
 var fish = fish_scene.instantiate()
 fish.minigame = self

 var minigame_x_radius = background.size.x / 2
 var lower_y_bound = lower_bound.position.y
 var direction = rng.pick_random([1, -1])

 var starting_x_radius = rng.randf_range(4, minigame_x_radius)
 var starting_x = starting_x_radius * - direction
 var starting_position = Vector2(starting_x, lower_y_bound)

 var target_x_radius = rng.randf_range(12, 32 + starting_x_radius)
 var target_x = target_x_radius * direction
 var target_position = Vector2(target_x, lower_y_bound - 4)

 var arc_height = rng.randf_range(96, 224)

 mask.add_child(projectile)
 projectile.add_child(fish)

 fish.reseed(rng)

 projectile.gravity = rng.randf_range(350, 500)

 projectile.launch(global_position + starting_position, global_position + target_position, arc_height)
 projectile.impacted.connect(_on_projectile_impacted.bind(fish))

 fish.spawn_flying(tile)
 tile.clear(false)

 fish.is_projectile = true
 fish.is_shooting_target = true

 fish.rotation_degrees = rng.randf_range(0, 360)


func catch_fish(fish):
 caught_fish.append(fish)

 fish.hitbox.monitoring = false
 fish.hitbox.monitorable = false
 fish.reparent(main)
 fish.hide()


func _on_projectile_impacted(fish):
 catch_fish(fish)


func _on_background_mouse_entered():
 has_mouse = true
 update_standard_mouse_mode()


func _on_background_mouse_exited():
 has_mouse = false
 update_standard_mouse_mode()


func update_standard_mouse_mode() -> void :
 if not InputManager.is_mouse_mode():
  return

 if has_mouse:
  Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
 else:
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func switch_to_mouse_mode() -> void :
 update_standard_mouse_mode()
