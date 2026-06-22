extends Status


const CRIT_MULTIPLIER = 0.5
const SmallExplosion: Resource = preload("res://source/effects/small_explosion.tscn")

var is_exploded = false

var turns = 3:
 set(value):
  turns = value
  update_sprite_animation()


func apply(data):
 if data != null:
  turns = data


func play_tile_sound(base_pitch: float = 1.0, bus: String = "Sound") -> void :
 if turns == 1:
  AudioManager.play_sound(Sounds.TILE.BOMB_CRIT, base_pitch, 1.0, bus)


func get_sprite_animation():
 if turns > 2:
  return "bomb_idle"
 elif turns == 2:
  return "bomb_ticking"
 elif turns == 1:
  return "bomb_ticking_fast"


func get_tooltip_context():
 return {bomb_turns = turns, status_value = get_status_value()}


func update_sprite_animation():
 if turns > 0:
  tile.sprite_anim_player.play(get_sprite_animation())


func will_explode_on_turn_end():
 if not tile_exists() or tile.in_word() or is_exploded:
  return false

 if turns == 1:
  return true

 return tile.will_be_melted_on_turn_end()


func will_destroy_on_turn_end() -> bool:
 return turns == 1


func explode(stop_stop_stop: bool = false):
 if not tile_exists():
  return

 is_exploded = true

 AudioManager.play_sound(Sounds.TILE.BOMB_UHOH)

 tile.bomb_overlay.hide()
 tile.sprite_anim_player.play("bomb_explode")
 await tile.sprite_anim_player.animation_finished

 var small_explosion = SmallExplosion.instantiate()
 Game.main.add_child(small_explosion)
 small_explosion.global_position = tile.global_position

 tile.visible = false

 AudioManager.play_sound(Sounds.TILE.BOMB_DETONATE)

 if stop_stop_stop:
  Game.player.sprite.play_stop_stop_stop = true

 Game.player.hurt(get_status_value())
 Game.screenshake(12, 0.32)

 AchievementManager.bomb_exploded()


func defuse():
 is_exploded = true

 tile.add_poofcloud(Globals.COLORS.DARK_SMOKE, Globals.COLORS.LIGHT_SMOKE, false, 0.5)
 tile.visible = false


func get_status_value():
 var damage = max(1, tile.get_value())
 return damage * get_damage_multiplier()


func get_damage_multiplier():
 return Game.balance.bomb_multiplier


func get_save_data():
 return turns


func load_save_data(data):
 turns = data
