@tool
class_name SectionedPanel extends Control


@export var alternating_page_box: AlternatingPageBox
@export var dotted_line_box: DottedLineBox
@export var scroll: ControllableScrollContainer
@export var contents_box: VBoxContainer

@export var mask_type: String = "MenuTicketBottomMask":
 set(value):
  mask_type = value
  if is_node_ready():
   main_mask.theme_type_variation = mask_type
@export var mask_no_aa_type: String = "MenuTicketBottomMaskNoAA":
 set(value):
  mask_no_aa_type = value
  if is_node_ready():
   page_mask.theme_type_variation = mask_no_aa_type


@onready var page_mask: Panel = %PageMask
@onready var main_mask: Panel = %MainMask

@export_tool_button("Refresh") var tool_button: = update_panels


func _ready() -> void :
 main_mask.theme_type_variation = mask_type
 page_mask.theme_type_variation = mask_no_aa_type


func update_panels() -> void :
 if alternating_page_box != null:
  alternating_page_box.update_panels()

 if dotted_line_box != null:
  dotted_line_box.update_panels()
