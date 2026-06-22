@tool
extends BattleUnitSprite


@onready var cigarette_marker: Marker2D = %CigaretteMarker
@onready var cigarette_target: Area2D = %CigaretteTarget
@onready var breath_smoke_marker: Marker2D = %BreathSmokeMarker
@onready var particle_spawners: Array[NobodyParticleSpawner] = [ %NobodyParticleSpawner, %NobodyParticleSpawner2, %NobodyParticleSpawner3]


func particle_fastforward(delta: float) -> void :
 for particle_spawner in particle_spawners:
  particle_spawner._physics_process(delta)


func particle_reset_velocity() -> void :
 for particle_spawner in particle_spawners:
  particle_spawner.last_relative_position = Vector2.INF
