extends TileModifierSpell


enum AmmoType{
 BLANK, 
 BULLET, 
}

var chamber = []


func set_status_tooltips():
 status_tooltips = [TileStatus.HOLE]


func apply_to_tile(tile, _real_tile, is_preview, _is_preview_update):
 if is_preview:
  tile.set_face("6")
  return

 if chamber.is_empty():
  load_chamber()

 var ammo = chamber.pop_front()

 if ammo == AmmoType.BLANK:
  tile.set_face("6")
  tile.add_poofcloud(Globals.COLORS.INK_BLACK)

 elif ammo == AmmoType.BULLET:
  AudioManager.play_sound(Sounds.SPELLS.GUNSHOT)

  if tile.has_status(TileStatus.BOMB):
   await word_builder.remove_tiles()
   await tile_board.wait_for_idle_tiles()

  tile.apply_hole()
  tile.add_poofcloud(Globals.COLORS.SMOKE)


func is_tile_selectable(tile):
 return not (tile.is_space() or tile.only_face_is("6"))


func load_chamber():
 for i in range(6):
  if i == 0:
   chamber.append(AmmoType.BULLET)
  else:
   chamber.append(AmmoType.BLANK)

 rng.spell.shuffle(chamber)


func get_save_data():
 var save = super.get_save_data()
 save["chamber"] = chamber
 return save


func load_save_data(save):
 super.load_save_data(save)
 chamber = save.chamber
