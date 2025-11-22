extends Area2D

# DI INSPECTOR: Tulis pesan menggunakan format {nama_action}
# Contoh: "Tekan {jump} untuk Lompat dan {basic_hit} untuk Serang"
@export_multiline var message: String = "Tekan {basic_hit} untuk Attack"
@export var show_duration: float = 3.0
@export var trigger_id: String = "attack_tutorial"

func _ready() -> void:
	if trigger_id != "" and trigger_id in Global.visited_triggers:
		queue_free()
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# 1. PROSES TEXT DULU SEBELUM DIKIRIM
		var final_message = parse_message(message)
		
		# 2. Kirim teks yang sudah jadi (bukan {basic_hit} lagi, tapi "Z")
		body.show_notification(final_message, show_duration)
		
		if trigger_id != "":
			if not trigger_id in Global.visited_triggers:
				Global.visited_triggers.append(trigger_id)
		
		queue_free()

# --- FUNGSI 1: GANTI PLACEHOLDER JADI NAMA TOMBOL ---
func parse_message(raw_text: String) -> String:
	var processed_text = raw_text
	
	# Daftar action yang mungkin kamu pakai di tutorial
	# Pastikan namanya SAMA PERSIS dengan di Input Map
	var actions_to_check = ["left", "right", "jump", "basic_hit", "run", "heavy_attak"]
	
	for action in actions_to_check:
		# Kita cari teks "{action}", misal "{jump}"
		var placeholder = "{" + action + "}"
		
		if placeholder in processed_text:
			# Ambil nama tombol asli (misal "Space" atau "Z")
			var key_name = get_input_key_name(action)
			
			# Ganti "{jump}" menjadi "Space"
			processed_text = processed_text.replace(placeholder, key_name)
			
	return processed_text

# --- FUNGSI 2: AMBIL NAMA TOMBOL DARI INPUT MAP ---
func get_input_key_name(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	
	if events.size() > 0:
		var event = events[0]
		
		if event is InputEventKey:
			# Ambil nama tombol keyboard (dan hapus tulisan "Physical")
			return event.as_text().trim_suffix(" (Physical)")
			
		elif event is InputEventMouseButton:
			# Ambil nama tombol mouse
			if event.button_index == MOUSE_BUTTON_LEFT: return "Left Click"
			if event.button_index == MOUSE_BUTTON_RIGHT: return "Right Click"
			return "Mouse " + str(event.button_index)
			
	return "???" # Jika tombol belum di-setting
