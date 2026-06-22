class_name TileModifierSpell extends Spell


const TileRegion = TileCollision.Region

enum Selection{
 LEFT_RIGHT, 
 CENTER, 
 TOP_BOTTOM, 
}

const REGION_OFFSETS = {
 TileRegion.LEFT: Vector2(-6, 0), 
 TileRegion.RIGHT: Vector2(6, 0), 
 TileRegion.CENTER: Vector2(0, 0), 
 TileRegion.TOP: Vector2(0, -6), 
 TileRegion.BOTTOM: Vector2(0, 6), 
}

const NO_SELECTION = [Selection.CENTER]

var selectable_regions = NO_SELECTION
var selected_tile_region: TileRegion = TileRegion.NONE


func _use():
 selected_tile_region = TileRegion.NONE
 var tile: Tile = await get_selection()

 if tile == null:
  _end_use()
  return

 if selectable_regions != NO_SELECTION:
  selected_tile_region = tile.tile_collision.last_selected_region

 await apply_to_tile(tile, tile, false, false)


 if player.is_using_spell():
  _post_use()


func generate_tile_tooltip(tile: Tile, tooltip: GameTooltip) -> void :
 if selectable_regions != NO_SELECTION:
  tile.tile_collision.selected_region_changed.connect(update_tile_tooltip.bind(tile, tooltip))
  tooltip.tree_exiting.connect(disconnect_tile_tooltip.bind(tile))
  selected_tile_region = tile.tile_collision.selected_region

 var preview_tile = tile_board.create_preview_tile(tile)
 apply_to_tile(preview_tile, tile, true, false)
 tooltip.add_subtooltip(
  get_preview_title(tile), 
  "", 
  preview_tile, 
  get_preview_description(tile)
 )


func update_tile_tooltip(tile: Tile, tooltip: GameTooltip) -> void :
 if tile.tile_collision.selected_region != selected_tile_region:
  selected_tile_region = tile.tile_collision.selected_region
  apply_to_tile(tooltip.get_preview_tile(), tile, true, true)


func disconnect_tile_tooltip(tile: Tile) -> void :
 tile.tile_collision.selected_region_changed.disconnect(update_tile_tooltip)
 tile.tile_sprite.region_overlay.visible = false


func has_special_tile_tooltip():
 return true



func apply_to_tile(_tile, _real_tile, _is_preview, _is_preview_update):
 pass



func get_preview_title(_tile):
 if StringManager.has_string("spell/" + id + "/preview_title"):
  return StringManager.get_string("spell/" + id + "/preview_title", get_tooltip_context())
 else:
  return StringManager.get_string("spell/default_preview_title")



func get_preview_description(_tile):
 if StringManager.has_string("spell/" + id + "/preview_description"):
  return StringManager.get_string("spell/" + id + "/preview_description", get_tooltip_context())
 else:
  return ""


func get_selectable_tile_regions() -> Array[TileRegion]:
 var regions: Array[TileRegion] = []
 for region in selectable_regions:
  if region == Selection.LEFT_RIGHT:
   regions.append_array([TileRegion.LEFT, TileRegion.RIGHT])
  elif region == Selection.TOP_BOTTOM:
   regions.append_array([TileRegion.TOP, TileRegion.BOTTOM])
  elif region == Selection.CENTER:
   regions.append_array([TileRegion.CENTER])

 return regions


func get_region_target_positions() -> Dictionary[TileRegion, Vector2]:
 var targets: Dictionary[TileRegion, Vector2] = {}
 for region in get_selectable_tile_regions():
  targets[region] = REGION_OFFSETS[region]

 return targets
