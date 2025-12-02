extends Node

@onready var text_box_scene : PackedScene = preload("res://scene/text_box.tscn")

# Fungsi ini sekarang bisa dipanggil berkali-kali untuk NPC berbeda
func start_dialog(position : Vector2, lines : Array[String], duration: float = 0.0):
	var new_text_box = text_box_scene.instantiate()
	get_tree().root.add_child(new_text_box)
	
	# Panggil fungsi setup di script TextBox yang baru kita buat
	new_text_box.setup(lines, position, duration)
