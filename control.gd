extends Control

# --- REFERENSI TOMBOL ---
# Pastikan nama node di Editor SAMA PERSIS dengan yang ditulis di sini
@onready var buttons = {
	"left": $Panel/VBoxContainer/GridContainer/BtnLeft,
	"right": $Panel/VBoxContainer/GridContainer/BtnRight,
	"up": $Panel/VBoxContainer/GridContainer/BtnUp,
	"down": $Panel/VBoxContainer/GridContainer/BtnDown,
	"jump": $Panel/VBoxContainer/GridContainer/BtnJump,
	"run": $Panel/VBoxContainer/GridContainer/BtnRun,
	"basic_hit": $Panel/VBoxContainer/GridContainer/BtnAttack,
	"slot_1": $Panel/VBoxContainer/GridContainer/BtnSlot1,
	"slot_2": $Panel/VBoxContainer/GridContainer/BtnSlot2,
	"slot_3": $Panel/VBoxContainer/GridContainer/BtnSlot3,
	"skill" : $Panel/VBoxContainer/GridContainer/BtnHeavyAttack

}

@onready var volume_slider: HSlider = $"Panel/VBoxContainer/Volume Slider"


# --- VARIABEL LOGIKA ---
var action_to_remap: String = ""
var is_remapping: bool = false
var current_button: Button = null

func _ready() -> void:
	# Loop semua tombol di dictionary untuk update teksnya di awal game
	for action in buttons:
		var btn = buttons[action]
		if btn:
			update_button_text(action, btn)
	volume_slider.value = Global.master_volume
# --- FUNGSI UPDATE TAMPILAN ---
func update_button_text(action_name: String, btn_node: Button) -> void:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		btn_node.text = get_event_text(events[0])
	else:
		btn_node.text = "Empty"

func get_event_text(event: InputEvent) -> String:
	if event is InputEventKey:
		return event.as_text().trim_suffix(" (Physical)")
	if event is InputEventMouseButton:
		return "Mouse Btn " + str(event.button_index)
	return event.as_text()

# --- CORE LOGIC REMAPPING ---
func start_remapping(action_name: String, btn_node: Button) -> void:
	# Cegah remapping dobel
	if is_remapping: return
	
	is_remapping = true
	action_to_remap = action_name
	current_button = btn_node
	current_button.text = "Press any key..."

func _input(event: InputEvent) -> void:
	if is_remapping:
		# Hanya terima Keyboard atau Mouse Click
		if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
			
			# 1. Hapus semua event lama di action ini
			InputMap.action_erase_events(action_to_remap)
			
			# 2. Tambahkan event baru
			InputMap.action_add_event(action_to_remap, event)
			
			# 3. Update teks tombol
			update_button_text(action_to_remap, current_button)
			
			# 4. Reset status
			is_remapping = false
			action_to_remap = ""
			current_button = null
			
			# Stop input agar tidak nembus
			get_viewport().set_input_as_handled()

func _on_btn_left_pressed() -> void:
	start_remapping("left", buttons["left"])

func _on_btn_right_pressed() -> void:
	start_remapping("right", buttons["right"])

func _on_btn_jump_pressed() -> void:
	start_remapping("jump", buttons["jump"])

func _on_btn_attack_pressed() -> void:
	start_remapping("basic_hit", buttons["basic_hit"])

func _on_btn_slot_1_pressed() -> void:
	start_remapping("slot_1", buttons["slot_1"])

func _on_btn_slot_2_pressed() -> void:
	start_remapping("slot_2", buttons["slot_2"])

func _on_btn_slot_3_pressed() -> void:
	start_remapping("slot_3", buttons["slot_3"])
	
func _on_btn_heavy_attack_pressed() -> void:
	start_remapping("skill", buttons["skill"])

# --- TOMBOL BACK ---
func _on_back_pressed() -> void:
	# 1. Cek jika user mau cancel remapping
	if is_remapping:
		is_remapping = false
		# Kembalikan teks tombol ke semula (karena batal ganti)
		if current_button and action_to_remap != "":
			update_button_text(action_to_remap, current_button)
		return

	# 2. SIMPAN PERUBAHAN KE FILE
	Global.save_keybinds()

	# 3. PINDAH SCENE (Navigasi)
	if Global.previous_scene != "":
		get_tree().change_scene_to_file(Global.previous_scene)
	else:
		get_tree().change_scene_to_file("res://scene/MainMenu.tscn")

func _on_volume_slider_value_changed(value: float) -> void:
	Global.master_volume = value
