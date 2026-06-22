extends "res://source/effects/particle_spawner.gd"


func spawn_particle(position_override: = Vector2.INF, speed_scale_override: float = - INF) -> Node2D:
 var particle: = super.spawn_particle()
 particle.clone(get_parent())

 if position_override != Vector2.INF:
  particle.global_position = position_override

 if speed_scale_override != - INF:
  particle.find_child("AnimPlayer").speed_scale = speed_scale_override

 return particle
