extends Enemy


var is_suicide = false
var been_touched: = false
var suwucide_anim: String = "suwucide"

@onready var strawman_sprite = $Sprite / Sprite


func _init():
 id = Enemies.STRAWMAN
 next_move = "countdown_3"

 moves = {
  countdown_3 = {
   custom_call = "countdown", 
   next = "countdown_2", 
  }, 
  countdown_2 = {
   custom_call = "countdown", 
   next = "countdown_1", 
  }, 
  countdown_1 = {
   custom_call = "countdown", 
   next = "explode", 
  }, 
  explode = {
   damage = {
    0: 10, 
    1: 12, 
    2: 15, 
    3: 18, 
   }, 
   next = "none", 
  }, 
  none = {
   next = "none", 
  }, 
 }


func _ready():
 super._ready()
 if not launching_from_enemy_scene:
  sprite.touched.connect(_on_touch)


func display_intent():
 if next_move == "explode":
  add_intent(Intent.DETONATE, {damage = moves.explode.damage})
 elif next_move == "countdown_3":
  add_intent(Intent.TICKING, {turns = 4, damage = moves.explode.damage})
 elif next_move == "countdown_2":
  add_intent(Intent.TICKING, {turns = 3, damage = moves.explode.damage})
 elif next_move == "countdown_1":
  add_intent(Intent.TICKING, {turns = 2, damage = moves.explode.damage})

 play_intent_sound()


func play_intent_sound() -> void :
 if next_move == "explode":
  AudioManager.play_sound(Sounds.STRAWMAN.NOBODY_WUBS_ME)
 elif not been_touched or Game.random.randi_range(1, 2) == 1:
  AudioManager.play_sound(Sounds.STRAWMAN.TOUCH_ME)
 else:
  AudioManager.play_sound(Sounds.STRAWMAN.DONT_STOP)


func countdown():
 return


func animate_flinch(_damage):
 been_touched = true
 await super.animate_flinch(_damage)


func animate_flinch_lethal():
 anim_player.play("flinch_lethal")
 await anim_player.animation_finished

 sprite.blood_explode()
 sprite.hide()

 await Game.timeout(0.5)


func explode():
 sprite.can_xd = false

 while true:
  await sprite.bopped
  if anim_player.current_animation == "bop_up":
   break

 await anim_player.pend_animation_stopped("bop_up")

 sprite.can_idle = false
 is_suicide = true
 anim_player.play(suwucide_anim)

 await sprite.hit
 health = 0
 hit_player(moves.explode.damage)
 Game.screenshake(16, 0.24)

 await anim_player.animation_finished

 sprite.blood_explode()
 sprite.hide()

 await Game.timeout(0.5)


func _on_touch() -> void :
 been_touched = true


func apply_any_fish(tile: Tile, _fish: Fish) -> void :
 if tile.has_status(TileStatus.CRIT):
  tile.add_status(TileStatus.BOMB, 1)


func get_save_data():
 var save = super.get_save_data()
 save.been_touched = been_touched
 return save


func load_save_data(save):
 super.load_save_data(save)
 been_touched = save.get("been_touched", false)
