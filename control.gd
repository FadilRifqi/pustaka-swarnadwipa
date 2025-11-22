extends Control

@onready var volume_slider: HSlider = $"Panel/VBoxContainer/Volume Slider"
@onready var fullscreen_check: CheckBox = $"Panel/VBoxContainer/Fullscreen Check"

func _ready() -> void:
	# 1. Setup Volume Slider sesuai kondisi sekarang
	var bus_index = AudioServer.get_bus_index("Master")
	var current_db = AudioServer.get_bus_volume_db(bus_index)
	volume_slider.value = db_to_linear(current_db)
	
	# 2. Setup Checkbox Fullscreen sesuai kondisi sekarang
	var mode = DisplayServer.window_get_mode()
	fullscreen_check.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN)

# --- LOGIKA TOMBOL BACK ---
func _on_back_pressed() -> void:
	if Global.previous_scene != "":
		# Ini akan mengembalikan player ke Playground.tscn
		# Karena Global.is_returning_from_settings bernilai TRUE,
		# Maka PauseMenu.gd akan otomatis me-load posisi terakhir.
		get_tree().change_scene_to_file(Global.previous_scene)
	else:
		get_tree().change_scene_to_file("res://scene/MainMenu.tscn")

# --- LOGIKA AUDIO & DISPLAY ---
func _on_volume_slider_value_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
