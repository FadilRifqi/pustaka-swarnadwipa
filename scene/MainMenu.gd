extends Node2D

# Path ke file save (Sama seperti di PauseMenu)
const SAVE_PATH = "user://savegame.json"
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	# Pastikan kursor terlihat saat di menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	audio_stream_player.play(12)

func _on_new_game_pressed() -> void:
	# Pastikan flag load mati, agar game mulai dari awal (posisi default)
	Global.load_saved_game = false 
	Global.is_returning_from_settings = false
	Global.visited_triggers = []
	Global.tutorial_energy_shown = false
	Global.tutorial_potion_shown = false
	Global.tutorial_move = false
	Global.skill_tutorial = false
	Global.unlocked_weapons = {
	"rencong": false,
	"keris": false
}
	get_tree().change_scene_to_file("res://Level_1.tscn")

func _on_continue_pressed() -> void:
	# 1. Cek apakah ada file save
	if not FileAccess.file_exists(SAVE_PATH):
		print("Tidak ada file save!")
		return

	# 2. Buka file save HANYA untuk mengintip nama scene-nya
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	
	# 3. Cek apakah data valid dan punya key "scene"
	if data != null and data.has("scene"):
		var scene_path = data["scene"]
		print("Melanjutkan ke scene: ", scene_path)
		
		# 4. Set Global Flag
		Global.load_saved_game = true
		
		# 5. Pindah ke scene yang tersimpan di file
		# (Bukan lagi hardcode ke Playground.tscn)
		get_tree().change_scene_to_file(scene_path)
		
	else:
		print("Error: Data save rusak atau tidak ada info scene.")

func _on_settings_pressed() -> void:
	Global.previous_scene = scene_file_path 
	get_tree().change_scene_to_file("res://setting.tscn") 

func _on_exit_pressed() -> void:
	get_tree().quit()
