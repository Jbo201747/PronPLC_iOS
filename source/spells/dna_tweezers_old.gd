extends TileModifierSpell


func _init():
 id = SPELLS.DNA_TWEEZERS
 status_tooltips = [TileStatus.ENHANCED]


func apply_to_tile(tile, real_tile, is_preview, _is_preview_update):
 if real_tile.face == "a":
  tile.set_face("t")
 elif real_tile.face == "t":
  tile.set_face("a")

 elif real_tile.face == "g":
  tile.set_face("c")
 elif real_tile.face == "c":
  tile.set_face("g")

 if real_tile.has_status(TileStatus.ENHANCED):
  tile.add_status(TileStatus.DEFAULT)
 else:
  tile.add_status(TileStatus.ENHANCED)

 if not is_preview:
  tile.add_poofcloud(Globals.COLORS.INK_BLACK)


func is_tile_selectable(tile):
 return tile.only_face_is(["a", "t", "g", "c"])
