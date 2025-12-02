extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
# Pastikan kamu sudah membuat Area2D di scene tree seperti instruksi di atas
@onready var interaction_area: Area2D = $InteractionArea
@onready var margin_container: MarginContainer = $MarginContainer

var position_text : Vector2

var player_in_range: bool = false

const lines: Array[String] = [
	"Anak muda... Syukurlah kau datang.",
	"Desa kami sedang dilanda musibah besar.",
	"Dua benda pusaka leluhur kami telah dicuri oleh para monster jahat di luar sana.",
	"Mereka mengambil Rencong Emas dan Keris Pusaka dari kuil penyimpanan.",
	"Tanpa kedua pusaka itu, kami tidak punya kekuatan untuk melindungi diri.",
	"Aku sudah terlalu tua untuk mengejar mereka...",
	"Kumohon, pergilah ke menara itu, kalahkan monster-monster itu, dan rebut kembali pusaka kami!",
	"Keselamatan desa ini ada di tanganmu."
]

func _ready() -> void:
	# 1. Scale 2x
	scale = Vector2(2.5, 2.5)
	
	# 2. Mainkan animasi default
	animated_sprite_2d.play("default")
	
	# Sembunyikan label "Tekan E" di awal
	if margin_container:
		margin_container.visible = false
	
	# Hubungkan sinyal Area2D secara manual lewat kode (atau bisa lewat editor)
	# Pastikan node InteractionArea sudah dibuat di scene!
	if not interaction_area.body_entered.is_connected(_on_interaction_area_body_entered):
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	if not interaction_area.body_exited.is_connected(_on_interaction_area_body_exited):
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)

func _physics_process(delta: float) -> void:
	# 3. Buat diam saja (tambahkan gravitasi jika perlu agar menapak tanah)
	pass

# --- LOGIKA INPUT INTERAKSI ---
func _input(event: InputEvent) -> void:
	# Cek jika tombol 'interact' ditekan DAN player ada di dekatnya
	if event.is_action_pressed("interact") and player_in_range:
		start_dialog()

# --- FUNGSI DIALOG ---
func start_dialog() -> void:
	margin_container.visible = false
	position_text = global_position
	position_text.x += 30
	position_text.y -= 60
	DialogManager.start_dialog(position_text, lines)

# --- SINYAL DETEKSI PLAYER ---
func _on_interaction_area_body_entered(body: Node2D) -> void:
	# Cek apakah yang masuk adalah Player (bukan musuh/tanah)
	if body is Player: # Pastikan script player kamu class_name-nya 'Player'
		player_in_range = true
		if margin_container:
			margin_container.visible = true # Munculkan tulisan "Tekan E"

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		if margin_container:
			margin_container.visible = false # Sembunyikan tulisan
