extends Node

@onready var text_box_scene : PackedScene = preload("res://scene/text_box.tscn")

var dialog_lines : Array[String] = []
var current_line_index : int = 0

var text_box
var text_box_position : Vector2

var is_dialog_active : bool = false
var can_advance_line : bool = false

# Variable untuk menyimpan durasi timer (0 = manual, >0 = otomatis)
var auto_advance_duration : float = 0.0

# Update start_dialog untuk menerima parameter duration (Default 0 = Manual)
func start_dialog(position : Vector2, lines : Array[String], duration: float = 0.0):
	if is_dialog_active:
		return
	
	dialog_lines = lines
	text_box_position = position
	auto_advance_duration = duration # Simpan durasi
	current_line_index = 0
	
	_show_text_box()
	is_dialog_active = true

func _show_text_box():
	# Hapus box lama jika ada (safety check)
	if text_box != null:
		text_box.queue_free()
		
	text_box = text_box_scene.instantiate()
	text_box.finish_displaying.connect(_on_text_finished_displaying)
	get_tree().root.add_child(text_box)
	text_box.global_position = text_box_position
	text_box.display_text(dialog_lines[current_line_index])
	can_advance_line = false

func _on_text_finished_displaying():
	can_advance_line = true
	
	# --- LOGIKA TIMER ---
	# Jika durasi di-set lebih dari 0, jalankan timer otomatis
	if auto_advance_duration > 0:
		# Tunggu selama durasi
		await get_tree().create_timer(auto_advance_duration).timeout
		
		# Cek apakah dialog masih aktif dan barisnya masih sama?
		# (Penting agar tidak double skip jika user menekan tombol duluan)
		if is_dialog_active and can_advance_line:
			advance_line()

# --- FUNGSI BARU: MAJU KE BARIS BERIKUTNYA ---
# Fungsi ini dipanggil oleh Timer ATAU Input User
func advance_line():
	if text_box != null:
		text_box.queue_free()
		text_box = null
	
	current_line_index += 1
	
	# Jika baris habis, tutup dialog
	if current_line_index >= dialog_lines.size():
		close_dialog()
		return
	
	# Jika masih ada, tampilkan baris berikutnya
	_show_text_box()

func close_dialog():
	if text_box != null:
		text_box.queue_free()
		text_box = null
	
	is_dialog_active = false
	can_advance_line = false
	current_line_index = 0

func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("advanced_line") && 
		is_dialog_active && 
		can_advance_line
	):
		# Panggil fungsi yang sama dengan Timer
		advance_line()
