extends Node2D

const FREQUENCY: float = 5.0


const AMPLITUDE: float = 2.0


const RAMP_DELAY_PER_TILE: float = 0.1


const TILE_RAMP_TIME: float = 0.5

@export var skip_animation: bool = false

var waving: bool = false
var wave_time: float = 0.0
var wave_offset: float = 0.0

var per_tile_ramp: Dictionary[Sprite2D, float] = {}
var wave_ramp_up: float = 0.0:
 set(value):
  wave_ramp_up = clamp(value, 0, RAMP_DELAY_PER_TILE * per_tile_ramp.size())

@onready var pronoun: Node2D = %Pronoun
@onready var anim_player: AnimPlayer = %AnimPlayer


func _ready() -> void :
 for node in pronoun.get_children():
  var tile: Sprite2D = node.get_children()[0]
  if skip_animation:
   per_tile_ramp[tile] = 1.0
  else:
   per_tile_ramp[tile] = 0.0

 if skip_animation:
  waving = true
  wave_ramp_up = INF
  anim_player.play_advance("new_animation", true)


func _process(delta: float) -> void :
 update_tile_wave(delta)


func _on_anim_player_event_emitted(event_name: String) -> void :
 if event_name == "pronoun_finished":
  waving = true


func update_tile_wave(delta: float):
 wave_time += delta

 if waving:
  wave_ramp_up += delta
 else:
  wave_ramp_up -= delta

 var index = -1
 var buffer = -0.13

 for node in pronoun.get_children():
  index += 1
  var tile: Sprite2D = node.get_children()[0]

  if waving and wave_ramp_up >= index * RAMP_DELAY_PER_TILE:
   per_tile_ramp[tile] = clampf(per_tile_ramp[tile] + TILE_RAMP_TIME * delta, 0.0, 1.0)
  else:
   per_tile_ramp[tile] = clampf(per_tile_ramp[tile] - TILE_RAMP_TIME * delta, 0.0, 1.0)

  var wave = cos((wave_time + index * buffer + wave_offset * PI) * FREQUENCY)
  var movement = wave * AMPLITUDE

  movement = movement * ease(per_tile_ramp[tile], 0.4)
  tile.position.y = movement
