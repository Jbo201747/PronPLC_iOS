extends TileModifierSpell


const COW_BIGRAMS: Dictionary[String, String] = {
 "a": "at", 
 "b": "bl", 
 "c": "ch", 
 "d": "di", 
 "e": "er", 
 "f": "fl", 
 "g": "gr", 
 "h": "he", 
 "i": "ie", 
 "j": "ju", 
 "k": "kn", 
 "l": "ld", 
 "m": "mp", 
 "n": "ng", 
 "o": "or", 
 "p": "ph", 
 "q": "qu", 
 "r": "rt", 
 "s": "sh", 
 "t": "tr", 
 "u": "un", 
 "v": "ve", 
 "w": "wh", 
 "x": "xp", 
 "y": "yp", 
 "z": "ze", 
}


func apply_to_tile(tile: Tile, real_tile: Tile, is_preview: bool, _is_preview_update: bool):
 tile.set_face(COW_BIGRAMS[real_tile.face])

 if not is_preview:
  tile.add_poofcloud(Globals.COLORS.INK_BLACK)


func is_tile_selectable(tile: Tile):
 return tile.is_single_letter(false) and not tile.has_status(TileStatus.MYSTERY) and tile.face in COW_BIGRAMS
