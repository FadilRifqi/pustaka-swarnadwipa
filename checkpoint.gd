extends Area2D

@export var message: String = "Checkpoint Reached!"

func _ready() -> void:
	# Hubungkan sinyal body entered
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("Masuk Checkpoint")
		
		# 1. Tampilkan Notifikasi di Player
		body.show_notification(message, 2.0)
		
		# 2. Panggil Fungsi Save di PauseMenu
		# Kita cari PauseMenu yang ada di root level
		var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
		
		if pause_menu and pause_menu.has_method("save_game"):
			pause_menu.save_game()
			
		else:
			print("Error: PauseMenu tidak ditemukan untuk melakukan Save!")
