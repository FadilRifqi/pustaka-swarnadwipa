extends CanvasLayer

# --- REFERENSI NODE ---
@onready var black_bottom: ColorRect = $BlackBottom
@onready var black_top: ColorRect = $BlackTop
@onready var char_left: TextureRect = $CharLeft
@onready var char_right: TextureRect = $CharRight
@onready var label_left: Label = $Label
@onready var label_right: Label = $Label2

# --- KONFIGURASI ---
const DURATION: float = 1.0 
const OFFSET: float = 350.0 # Sesuaikan dengan tinggi setengah layar (misal layar 648, setengahnya 324)
const NEXT_SCENE_PATH: String = "res://Level1.tscn" # Ganti dengan path Level 1 kamu

var dialog_index := 0
var is_transitioning := false # Agar tidak bisa skip saat animasi berjalan

# --- DATA NASKAH ---
var dialog = [
	{ "speaker": "left", "text": "Hawa jahat di tempat ini sangat pekat... Aku bisa merasakannya menusuk tulang." },
	{ "speaker": "right", "text": "Kita sudah sampai. Di balik gerbang ini, Raja Kegelapan bersemayam." },
	{ "speaker": "left", "text": "Jadi ini akhirnya. Penentuan nasib desa kalian." },
	{ "speaker": "right", "text": "Berhati-hatilah. Kekuatannya jauh melampaui monster yang pernah kau hadapi sebelumnya." },
	{ "speaker": "right", "text": "Dia menggunakan kekuatan Keris Pusaka untuk memanggil bayangan kematian." },
	{ "speaker": "left", "text": "Jangan khawatir. Pedang dan tekadku sudah siap. Aku akan merebut kembali pusaka itu." },
	{ "speaker": "right", "text": "Kami percayakan nyawa kami padamu. Pergilah, kalahkan kegelapan itu!" },
	{ "speaker": "left", "text": "Tunggu aku kembali membawa kemenangan." }
]

func _ready():
	# 1. Setup Posisi Awal (Menutup Layar)
	# Pastikan di Editor, BlackTop dan BlackBottom menutupi layar penuh
	black_top.visible = true
	black_bottom.visible = true
	
	label_left.visible = false
	label_right.visible = false
	char_left.visible = true
	char_right.visible = true
	
	# 2. Jalankan Animasi Buka (Cinematic Bars Opening)
	start_opening_animation()

func _input(event):
	# Cegah input saat transisi animasi
	if is_transitioning: return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		show_dialog()

func show_dialog():
	# --- CEK APAKAH DIALOG SUDAH HABIS? ---
	if dialog_index >= dialog.size():
		end_cutscene() # Pindah ke Level 1
		return

	# --- TAMPILKAN TEKS ---
	var d = dialog[dialog_index]

	# Reset Label
	label_left.visible = false
	label_right.visible = false
	
	# Efek fokus (Gelapkan yang tidak bicara)
	var dim_color = Color(0.5, 0.5, 0.5)
	var bright_color = Color(1, 1, 1)

	if d.speaker == "left":
		label_left.visible = true
		label_left.text = d.text
		char_left.modulate = bright_color
		char_right.modulate = dim_color

	elif d.speaker == "right":
		label_right.visible = true
		label_right.text = d.text
		char_right.modulate = bright_color
		char_left.modulate = dim_color

	dialog_index += 1

# --- ANIMASI BUKA (BARS MENJAUH) ---
func start_opening_animation() -> void:
	is_transitioning = true
	var tween = create_tween().set_parallel(true)
	
	# Geser Top ke Atas (Y minus)
	tween.tween_property(black_top, "position:y", black_top.position.y - OFFSET, DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Geser Bottom ke Bawah (Y plus)
	tween.tween_property(black_bottom, "position:y", black_bottom.position.y + OFFSET, DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	is_transitioning = false
	
	# Mulai dialog pertama otomatis setelah animasi selesai
	show_dialog()

# --- ANIMASI TUTUP (BARS MENDEKAT & PINDAH SCENE) ---
func end_cutscene() -> void:
	print("Cutscene Selesai -> Pindah ke Level 1")
	is_transitioning = true
	
	# Sembunyikan teks dan karakter biar bersih
	label_left.visible = false
	label_right.visible = false
	
	var tween = create_tween().set_parallel(true)
	
	# Geser Top Kembali ke Posisi Awal (Turun)
	tween.tween_property(black_top, "position:y", black_top.position.y + OFFSET, DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Geser Bottom Kembali ke Posisi Awal (Naik)
	tween.tween_property(black_bottom, "position:y", black_bottom.position.y - OFFSET, DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await tween.finished
	# >>> PINDAH SCENE KE LEVEL 1 <<<
	get_tree().change_scene_to_file("res://Level_1.tscn")
