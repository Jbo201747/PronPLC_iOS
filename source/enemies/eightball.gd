extends "res://source/enemies/snowball.gd"


func _init():
 super._init()

 id = Enemies.EIGHTBALL
 inherited_id = Enemies.SNOWBALL

 exclude_effects = [TileStatus.MYSTERY, TileEffect.FACELESS]


func display_other_intent():
 add_intent(Intent.BLOW)


func ashen_tile(tile):
 tile.randomize_similar_face(rng.move)
 tile.add_poofcloud(Globals.COLORS.ASH)
 tile.tile_overlay_anim_player.play("dust")


func apply_fish(_tile: Tile, _fish: Fish) -> void :
 pass
