extends "res://source/enemies/rubber_animal.gd"


func _init():
 super._init()
 id = Enemies.PINK_RUBBER_ANIMAL
 inherited_id = Enemies.RUBBER_ANIMAL

 moves.lunge.parry = {
  0: 7, 
  1: 8, 
  2: 9, 
 }


func get_applied_face(use_rng: RNG = rng.move) -> String:
 var bigram: = Letters.pick_from_pool(Letters.BIGRAMS, use_rng, {
  must_have_vowel = true, 
  min_weight = 0.5, 
  backup_cutoff = 0.5, 
 })
 var replace_character = use_rng.randi_range(0, 1)
 for letter in bigram:
  if letter in Letters.CONSONANTS:
   replace_character = bigram.find(letter)
 bigram[replace_character] = "*"
 return bigram


func apply_fish(tile: Tile, fish: Fish) -> void :
 if fish.rng.randi_range(1, 3) == 1:
  tile.add_status(TileStatus.BLEED)
  if fish.rng.randi_range(1, 3) == 1:
   tile.set_face(get_applied_face(fish.rng))
