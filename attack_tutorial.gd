extends Area2D

# --- PENGGANTI VARIABLE MESSAGE ---
# Masukkan SEMUA teks tutorial kamu di sini.
# Format: "trigger_id": "Isi Pesan"
const TUTORIAL_LIBRARY = {
	"attack_tutorial": "Tekan {basic_hit} untuk Serang.",
	"jump_tutorial": "Tekan {jump} untuk Melompat.",
	"inventory_tutorial": "Darah sekarat? Tekan {inventory} untuk buka Tas.",
	"skill_tutorial": "Tekan {skill} untuk menggunakan Jurus (Butuh Stamina).",
	"dash_tutorial": "Tekan {dash} untuk Dash.",
	"interact_tutorial": "Tekan {interact} untuk bicara atau membuka peti.",
	"move_tutorial": "Tekan Panah Kiri untuk Bergerak ke Kiri dan Panah Kanan Untuk Bergerak ke Kanan"
}

@export var show_duration: float = 1

# DI INSPECTOR: Cukup isi ID ini sesuai dengan nama di atas (misal: attack_tutorial)
@export var trigger_id: String = "attack_tutorial"

func _ready() -> void:
	if trigger_id != "" and trigger_id in Global.visited_triggers:
		queue_free()
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# 1. AMBIL TEKS DARI LIBRARY BERDASARKAN ID
		var raw_message = ""
		
		if TUTORIAL_LIBRARY.has(trigger_id):
			raw_message = TUTORIAL_LIBRARY[trigger_id]
		else:
			# Error handling kalau kamu lupa masukin teks di atas
			raw_message = "Tutorial tidak ditemukan untuk ID: " + trigger_id
			print("ERROR: ID " + trigger_id + " belum ada di TUTORIAL_LIBRARY")

		# 2. PROSES TEXT (Ganti {placeholder} jadi Tombol Asli)
		var final_message = parse_message(raw_message)
		
		# 3. KIRIM KE PLAYER
		body.show_notification(final_message, show_duration)
		
		# 4. SIMPAN PROGRESS
		if trigger_id != "":
			if not trigger_id in Global.visited_triggers:
				Global.visited_triggers.append(trigger_id)
		
		queue_free()

# --- FUNGSI PARSE (TETAP SAMA) ---
func parse_message(raw_text: String) -> String:
	var processed_text = raw_text
	
	var actions_to_check = [
		"left", "right", "up", "down", 
		"jump", "run", "basic_hit",  "dash",
		"skill", "inventory", "use_item", "interact",
		"slot_1", "slot_2", "slot_3"
	]
	
	for action in actions_to_check:
		var placeholder = "{" + action + "}"
		if placeholder in processed_text:
			var key_name = get_input_key_name(action)
			processed_text = processed_text.replace(placeholder, key_name)
			
	return processed_text

func get_input_key_name(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	
	if events.size() > 0:
		var event = events[0]
		if event is InputEventKey:
			return event.as_text().trim_suffix(" (Physical)")
		elif event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT: return "Left Click"
			if event.button_index == MOUSE_BUTTON_RIGHT: return "Right Click"
			return "Mouse " + str(event.button_index)
			
	return "[UNBOUND]"
