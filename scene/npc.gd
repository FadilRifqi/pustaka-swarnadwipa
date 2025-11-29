extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
# Pastikan kamu sudah membuat Area2D di scene tree seperti instruksi di atas
@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt_label: Label = $Label # Opsional: Label petunjuk tombol

var player_in_range: bool = false

func _ready() -> void:
	# 1. Scale 2x
	scale = Vector2(2.5, 2.5)
	
	# 2. Mainkan animasi default
	animated_sprite_2d.play("default")
	
	# Sembunyikan label "Tekan E" di awal
	if prompt_label:
		prompt_label.visible = false
	
	# Hubungkan sinyal Area2D secara manual lewat kode (atau bisa lewat editor)
	# Pastikan node InteractionArea sudah dibuat di scene!
	if not interaction_area.body_entered.is_connected(_on_interaction_area_body_entered):
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)
	if not interaction_area.body_exited.is_connected(_on_interaction_area_body_exited):
		interaction_area.body_exited.connect(_on_interaction_area_body_exited)

func _physics_process(delta: float) -> void:
	# 3. Buat diam saja (tambahkan gravitasi jika perlu agar menapak tanah)
	if not is_on_floor():
		velocity.y += 980.0 * delta # Gravitasi standar
	else:
		velocity = Vector2.ZERO # Pastikan diam
	
	move_and_slide()

# --- LOGIKA INPUT INTERAKSI ---
func _input(event: InputEvent) -> void:
	# Cek jika tombol 'interact' ditekan DAN player ada di dekatnya
	if event.is_action_pressed("interact") and player_in_range:
		start_dialog()

# --- FUNGSI DIALOG ---
func start_dialog() -> void:
	print("Dialog dimulai!") 
	# Di sini kamu bisa memanggil UI Dialog kamu, contoh:
	# DialogManager.show_text("Halo, selamat datang di desa kami!")

# --- SINYAL DETEKSI PLAYER ---
func _on_interaction_area_body_entered(body: Node2D) -> void:
	# Cek apakah yang masuk adalah Player (bukan musuh/tanah)
	if body is Player: # Pastikan script player kamu class_name-nya 'Player'
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true # Munculkan tulisan "Tekan E"

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false # Sembunyikan tulisan
