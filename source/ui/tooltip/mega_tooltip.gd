extends MarginContainer


const mega_paragraph_scene = preload("res://source/ui/tooltip/mega_tooltip_paragraph.tscn")


func add_paragraph(header: String, paragraph: String) -> void :
 var mega_paragraph: Control = mega_paragraph_scene.instantiate()
 mega_paragraph.get_node("%Label").text = header
 mega_paragraph.get_node("%RichTextLabel").text = paragraph
 if header == "2.4.":
  mega_paragraph.custom_minimum_size.y = 90
 %VFlowContainer.add_child(mega_paragraph)


func set_description(description: String):
 var paragraphs: = description.split("\n", false)
 var header: String = ""
 var combined_paragraph: String = ""
 for paragraph in paragraphs:
  var stripped: String = paragraph.strip_edges()
  var first_character: String = stripped[0]
  if first_character.is_valid_int():
   if header != "":
    add_paragraph(header.strip_edges(), combined_paragraph.strip_edges())

   header = paragraph
   combined_paragraph = ""
  else:
   combined_paragraph += paragraph + " "

 if combined_paragraph != "":
  add_paragraph(header.strip_edges(), combined_paragraph.strip_edges())


func display() -> void :
 pass
