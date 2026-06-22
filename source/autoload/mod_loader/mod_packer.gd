@tool
extends EditorScript


var files: Array[String] = [
 "res://arte/enemies/cat.png", 
]


func _run() -> void :
 var packer: = PCKPacker.new()
 packer.pck_start("pack.pck")
 for file in files:
  if ResourceLoader.exists(file):
   var loaded: Resource = ResourceLoader.load(file)
   if loaded is CompressedTexture2D:
    packer.add_file(loaded.load_path, loaded.load_path)
    packer.add_file(file + ".import", file + ".import")
   else:
    packer.add_file(file, file)
  else:
   packer.add_file(file, file)

 packer.flush()
