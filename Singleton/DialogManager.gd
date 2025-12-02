extends Node

@onready var text_box_scene : PackedScene = preload("res://scene/text_box.tscn")

func start_dialog(position : Vector2, lines : Array[String], duration: float = 0.0):
	var new_text_box = text_box_scene.instantiate()
	
	# 1. Tambahkan ke Group agar mudah dilacak
	new_text_box.add_to_group("active_dialogs") 
	
	# 2. Masukkan ke Root (tetap seperti kode kamu)
	get_tree().root.add_child(new_text_box)
	
	new_text_box.setup(lines, position, duration)

# --- FUNGSI PEMBERSIH (BARU) ---
func remove_all_dialogs():
	# Panggil fungsi 'queue_free' untuk SEMUA node di dalam grup ini
	get_tree().call_group("active_dialogs", "queue_free")
	print("Semua dialog dibersihkan.")
