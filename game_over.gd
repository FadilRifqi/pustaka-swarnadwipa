extends CanvasLayer

@onready var top_bar: ColorRect = $TopBar
@onready var bottom_bar: ColorRect = $BottomBar
@onready var menu_container: Control = $MenuContainer

@onready var restart_btn: Button = $MenuContainer/VBoxContainer/Restart
@onready var main_menu_btn: Button = $MenuContainer/VBoxContainer/MainMenu

func _ready() -> void:
	visible = false
	
	# Hubungkan tombol
	restart_btn.pressed.connect(_on_restart_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)

func start_game_over_sequence():
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# --- HITUNG UKURAN LAYAR SAAT INI ---
	var screen_size = get_viewport().get_visible_rect().size
	var half_height = screen_size.y / 2.0
	
	# 1. RESET POSISI & UKURAN BAR (Agar pas layar)
	# Top Bar: Tingginya setengah layar, posisi awal di atas layar (-tinggi)
	top_bar.size = Vector2(screen_size.x, half_height)
	top_bar.position.y = -half_height
	
	# Bottom Bar: Tingginya setengah layar, posisi awal di bawah layar
	bottom_bar.size = Vector2(screen_size.x, half_height)
	bottom_bar.position.y = screen_size.y
	
	# Reset Menu (Transparan)
	menu_container.modulate.a = 0.0
	
	# --- 2. ANIMASI MENUTUP (TWEEN) ---
	var tween = create_tween()
	tween.set_parallel(true) # Jalankan animasi bersamaan
	
	# Gerakkan Top Bar ke Y = 0
	tween.tween_property(top_bar, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Gerakkan Bottom Bar ke Tengah Layar
	tween.tween_property(bottom_bar, "position:y", half_height, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# --- 3. MUNCULKAN MENU SETELAH BAR MENUTUP ---
	# Kita buat tween baru agar berurutan (setelah 1 detik)
	var menu_tween = create_tween()
	menu_tween.tween_interval(1.0) # Tunggu bar menutup
	menu_tween.tween_property(menu_container, "modulate:a", 1.0, 0.5) # Fade In menu

func _on_restart_pressed() -> void:
	get_tree().paused = false
	DialogManager.remove_all_dialogs()
	Global.load_saved_game = false 
	Global.is_returning_from_settings = false
	Global.visited_triggers = []
	Global.skill_tutorial = false
	Global.tutorial_move = false
	Global.tutorial_energy_shown = false
	Global.tutorial_potion_shown = false
	Global.unlocked_weapons = {
	"rencong": false,
	"keris": false
}
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	DialogManager.remove_all_dialogs()
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")
