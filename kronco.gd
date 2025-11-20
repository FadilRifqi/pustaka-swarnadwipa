class_name Kronco
extends CharacterBody2D

# --- VARIABLES ---
@export var max_health: int = 3
var health: int = max_health

@export var move_speed: float = 100.0
@export var gravity: float = 980.0
@export var chase_distance: float = 600.0
@export var knockback_force: float = 200.0 # Kekuatan terpental saat kena hit

# Node References
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var idle: Sprite2D = $Idle # Asumsi ini sprite utamanya
@onready var player: Player = $"../Player" # Pastikan path ini benar di scene tree kamu

# Variable Logika
var is_dead: bool = false
var is_hurt: bool = false # Untuk stop gerak sebentar saat kena hit

func _ready() -> void:
	health = max_health
	add_to_group("enemies") # Berguna untuk deteksi masal nanti

func _process(delta: float) -> void:
	if not player or is_dead:
		return

	var distance = global_position.distance_to(player.global_position)

	# Update Animasi (Hanya jika tidak sedang hurt/terluka)
	if not is_hurt:
		if distance <= chase_distance:
			# Jika kamu punya animasi lari, ganti "idle" dengan "run" atau "walk"
			animation_player.play("idle") 
		else:
			animation_player.play("idle")

func _physics_process(delta: float) -> void:
	if not player or is_dead:
		return

	# 1. GRAVITASI
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# 2. GERAKAN (CHASE)
	# Musuh hanya mengejar jika:
	# - Jarak cukup dekat
	# - Tidak sedang terkena hit (stun)
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= chase_distance and not is_hurt:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * move_speed
		
		# FLIP SPRITE
		# Logika: Jika gerak ke kanan (x > 0), sesuaikan flip
		if velocity.x != 0:
			# Logic kamu: velocity.x > 0 -> flip_h = true
			# (Ini berarti gambarmu aslinya menghadap KIRI)
			idle.flip_h = velocity.x > 0
			
	elif not is_hurt:
		# Jika player jauh, diam (decelerate)
		velocity.x = move_toward(velocity.x, 0, move_speed)

	move_and_slide()

# --- LOGIKA MENERIMA DAMAGE ---
# Fungsi ini dipanggil oleh script Player saat Attack Hitbox mengenai musuh
func take_damage(amount: int):
	if is_dead: return
	
	health -= amount
	print("Kronco HP: ", health)
	
	# Efek Visual & Knockback
	_play_hurt_effect()
	
	if health <= 0:
		die()

func _play_hurt_effect():
	is_hurt = true
	
	# 1. Efek Visual (Flash Merah)
	modulate = Color.RED
	
	# 2. Efek Knockback (Terpental sedikit ke belakang)
	# Cari arah datangnya player, lalu musuh mental ke arah sebaliknya
	if player:
		var knockback_dir = global_position - player.global_position
		velocity.x = sign(knockback_dir.x) * knockback_force
		velocity.y = -150 # Sedikit mental ke atas
	
	# Tunggu sebentar (0.2 detik) sebelum normal lagi
	await get_tree().create_timer(0.2).timeout
	
	modulate = Color.WHITE # Kembali ke warna normal
	is_hurt = false

func die():
	is_dead = true
	print("Kronco Mati")
	
	# Stop animasi & physics
	animation_player.stop()
	velocity = Vector2.ZERO
	
	# Efek menghilang (Fade out) opsional
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5) # Transparan dalam 0.5 detik
	await tween.finished
	
	queue_free() # Hapus musuh dari game
