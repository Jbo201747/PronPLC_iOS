class_name CharacterSelectorIcon extends SelectorIcon


var character: String = ""


func set_character(id: String, trans: bool = false):
 character = id
 %CharacterIcon.set_character(id, trans)
