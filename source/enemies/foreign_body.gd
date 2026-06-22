extends "res://source/enemies/freezer.gd"


const SLASH_COUNT = 4
const GOLD_SAWBLADE_TEXTURE = preload("res://arte/enemies/foreign_body_gold.png")
const GOLD_SHINE_TEXTURE = preload("res://arte/enemies/foreign_body_shine_gold.png")
const GOLD_PANTS_TEXTURE = preload("res://arte/enemies/pants_gold.png")

var is_gold = false
var loaded_from_save: = false

@onready var sawblade = $Sprite / Sprite
@onready var sawblade_shine = $Sprite / ShineMask / Shine
@onready var pants = $Sprite / Pants
@onready var pants_mist_spawner = $Sprite / Pants / MistSpawner


func _init():
 FreezerProjectile = preload("res://source/effects/foreign_body_projectile.tscn")

 id = Enemies.FOREIGN_BODY
 inherited_id = Enemies.FREEZER
 next_move = "first_crash"
 explode_animation = "explode_foreign"

 moves = {
  first_crash = {
   custom_call = "crash", 
   damage = {
    0: 3, 
    1: 4, 
    2: 5, 
    3: 6, 
   }, 
   next = "crash", 
  }, 
  crash = {
   damage = {
    0: 5, 
    1: 6, 
    2: 7, 
    3: 8, 
   }, 
   next = "crash", 
  }, 
 }


func _init_rng():
 super._init_rng()
 rng.gold = RNG.new()


func _ready():
 super._ready()

 if launching_from_enemy_scene:
  return

 Game.taking_screenshot.connect(_on_take_screenshot)


func post_ready():
 if loaded_from_save:
  return

 if rng.gold.randf() <= 0.02:
  is_gold = true
  be_gold()


func display_intent():
 add_intent(Intent.ATTACK, {damage = moves[next_move].damage})
 add_intent(Intent.CONVERT_STATUS, 
   {statuses = [TileStatus.FROZEN, TileEffect.SLASHED], 
   count = SLASH_COUNT, 
   name_override = "frozen_slashed"})


func freeze():
 var slashed_tiles = get_tiles({
  amount = SLASH_COUNT, 
  include_effects = [TileEffect.SLASHED], 
 })

 var target_tiles = get_tiles({
  amount = SLASH_COUNT - slashed_tiles.size(), 
  effect_priority = PURE_EFFECT_PRIORITY, 
  exclude_effects = [TileEffect.SLASHED, TileEffect.SUIT], 
  single_letter = true, 
 })

 target_tiles += slashed_tiles

 for tile: Tile in target_tiles:
  tile.apply_slashed(rng.move)
  tile.add_status(TileStatus.FROZEN)
  tile.add_poofcloud(Globals.COLORS.ICE)

  await Game.timeout(0.08)


func _on_word_submitted(_words: WordList, _damage: int, _ending_turn: bool) -> void :
 return


func post_launch():
 if not is_gold:
  return

 var projectile_sprite = freezer_projectile.get_child(0)
 var projectile_mist_spawner = projectile_sprite.get_child(0)

 projectile_sprite.texture = GOLD_SAWBLADE_TEXTURE
 projectile_mist_spawner.is_gold = is_gold


func be_gold():
 sawblade.texture = GOLD_SAWBLADE_TEXTURE
 sawblade_shine.texture = GOLD_SHINE_TEXTURE
 pants.texture = GOLD_PANTS_TEXTURE

 mist_spawner.is_gold = true
 pants_mist_spawner.is_gold = true


func _on_take_screenshot():
 hide_it()

 sprite.get_node("Pants").visible = true
 var mists = get_tree().get_nodes_in_group("pants_mist")
 for mist in mists:
  mist.visible = true

 await RenderingServer.frame_post_draw

 show_it()

 sprite.get_node("Pants").visible = false
 for mist in mists:
  mist.visible = false



func get_save_data():
 var save = super.get_save_data()

 save["is_gold"] = is_gold

 return save


func load_save_data(save):
 super.load_save_data(save)

 loaded_from_save = true
 is_gold = save.is_gold

 if is_gold:
  be_gold()


func apply_fish(tile: Tile, fish: Fish) -> void :
 super.apply_fish(tile, fish)
 if tile.has_status(TileStatus.FROZEN):
  tile.apply_slashed(fish.rng)
