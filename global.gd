extends Node

var load_saved_game: bool = false
var previous_scene: String = ""
var is_returning_from_settings: bool = false
var visited_triggers: Array = []
const KEYBIND_PATH = "user://keybinds.json"
# DAFTAR AKSI YANG AKAN DISIMPAN KE JSON
const INPUT_ACTIONS = [
	"left", 
	"right", 
	"jump", 
	"basic_hit", 
	"slot_1", 
	"slot_2", 
	"slot_3",
	"heavy_attak" # <--- Pastikan ejaannya sama persis dengan Input Map Godot
]

func _ready() -> void:
	# Load keybind saat game pertama kali dibuka
	load_keybinds()

# --- FUNGSI SAVE KEYBIND ---
func save_keybinds() -> void:
	var key_data = {}
	
	for action in INPUT_ACTIONS:
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event = events[0]
			
			# Kita harus membedakan apakah itu Keyboard atau Mouse
			if event is InputEventKey:
				key_data[action] = {
					"type": "key",
					"code": event.physical_keycode # Gunakan physical agar posisi WASD tetap sama di keyboard beda bahasa
				}
			elif event is InputEventMouseButton:
				key_data[action] = {
					"type": "mouse",
					"index": event.button_index
				}
	
	# Simpan ke File JSON
	var file = FileAccess.open(KEYBIND_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(key_data)
		file.store_string(json_string)
		file.close()
		print("Keybinds Saved!")

# --- FUNGSI LOAD KEYBIND ---
func load_keybinds() -> void:
	if not FileAccess.file_exists(KEYBIND_PATH):
		return # Pakai default project settings jika file belum ada
		
	var file = FileAccess.open(KEYBIND_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if data == null: return
	
	# Terapkan data ke InputMap
	for action in INPUT_ACTIONS:
		if data.has(action):
			var info = data[action]
			var new_event
			
			# Buat ulang InputEvent berdasarkan data JSON
			if info["type"] == "key":
				new_event = InputEventKey.new()
				new_event.physical_keycode = int(info["code"])
			elif info["type"] == "mouse":
				new_event = InputEventMouseButton.new()
				new_event.button_index = int(info["index"])
			
			# Update InputMap Godot
			if new_event:
				InputMap.action_erase_events(action) # Hapus setting lama
				InputMap.action_add_event(action, new_event) # Masukkan setting baru

	print("Keybinds Loaded!")
