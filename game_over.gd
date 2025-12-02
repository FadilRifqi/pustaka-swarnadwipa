extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var restart_btn: Button = $MenuContainer/VBoxContainer/Restart
@onready var main_menu_btn: Button = $MenuContainer/VBoxContainer/MainMenu

func _ready() -> void:
	# Sembunyikan di awal (opsional, tapi aman)
	visible = false
	
	# Hubungkan tombol
	restart_btn.pressed.connect(_on_restart_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)

func start_game_over_sequence():
	visible = true
	
	# 1. Pause Game agar musuh/player berhenti
	get_tree().paused = true
	
	# 2. Jalankan animasi shutter
	animation_player.play("game_over")
	
	# 3. Munculkan mouse
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_pressed() -> void:
	# Matikan pause sebelum reload
	Global.load_saved_game = false 
	Global.is_returning_from_settings = false
	Global.visited_triggers = []
	Global.tutorial_energy_shown = false
	Global.tutorial_potion_shown = false
	Global.unlocked_weapons = {
	"rencong": false,
	"keris": false
}
	get_tree().paused = false
	DialogManager.remove_all_dialogs()
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	# Ganti dengan path Main Menu kamu
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")
