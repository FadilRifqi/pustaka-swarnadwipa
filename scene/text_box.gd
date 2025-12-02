extends MarginContainer

@onready var label: Label = $MarginContainer/Label
@onready var timer: Timer = $LetterDisplayTimer

const MAX_WIDTH : int = 256

var dialog_lines: Array[String] = []
var current_line_index: int = 0

var full_text: String = ""
var is_typing: bool = false
var auto_advance_duration: float = 0.0

# --- TAMBAHAN VARIABEL BARU ---
# Untuk menyimpan titik tengah asli di atas kepala NPC/Player
var origin_position: Vector2 = Vector2.ZERO 

func _ready() -> void:
	set_process_unhandled_input(true)

func setup(lines: Array[String], position: Vector2, duration: float = 0.0):
	dialog_lines = lines
	auto_advance_duration = duration
	current_line_index = 0
	
	# --- SIMPAN POSISI AWAL ---
	origin_position = position 
	
	display_current_line()

func display_current_line():
	if current_line_index >= dialog_lines.size():
		queue_free()
		return
		
	full_text = dialog_lines[current_line_index]
	
	# 1. Isi teks penuh untuk hitung ukuran
	label.text = full_text
	
	# 2. Tunggu frame update layout
	await get_tree().process_frame
	
	# 3. Atur Lebar
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await get_tree().process_frame 
		custom_minimum_size.y = size.y
	
	# --- PERBAIKAN POSISI DI SINI ---
	# Jangan pakai -= (kurang sama dengan), tapi hitung ulang dari origin_position
	global_position.x = origin_position.x - (size.x / 2)
	global_position.y = origin_position.y - (size.y + 24)
	
	# 4. Reset teks untuk animasi
	label.text = ""
	is_typing = true
	
	_display_letter_loop()

# ... (Sisa fungsi _display_letter_loop, finish_typing, skip, next, _input TETAP SAMA) ...
# Copy paste bagian bawah script sebelumnya, tidak ada perubahan logika di sana.

func _display_letter_loop():
	if not is_typing: return
	
	if label.text.length() < full_text.length():
		label.text += full_text[label.text.length()]
		var char = full_text[label.text.length() - 1]
		var wait_time = 0.03
		if char in [".", ",", "!", "?"]: wait_time = 0.1
		timer.start(wait_time)
		await timer.timeout
		_display_letter_loop()
	else:
		finish_typing()

func finish_typing():
	is_typing = false
	label.text = full_text
	if auto_advance_duration > 0:
		await get_tree().create_timer(auto_advance_duration).timeout
		if is_instance_valid(self): next_line()

func skip_typing():
	is_typing = false
	timer.stop()
	label.text = full_text
	finish_typing()

func next_line():
	current_line_index += 1
	if current_line_index >= dialog_lines.size():
		queue_free()
	else:
		display_current_line()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("advanced_line"):
		if is_typing:
			skip_typing()
			get_viewport().set_input_as_handled()
		elif auto_advance_duration == 0:
			next_line()
			get_viewport().set_input_as_handled()
