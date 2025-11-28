class_name Demon
extends CharacterBody2D

# --- VARIABLES ---
@export var max_health: int = 8
var health: int = max_health

@export var damage_amount: float = 0.5
@export var move_speed: float = 110.0
@export var gravity: float = 980.0
@export var chase_distance: float = 500.0 
@export var attack_range: float = 70.0  
@export var knockback_force: float = 250.0 

# Node References
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var player: Player = $"../Player" 
@onready var health_bar: ProgressBar = $HealthBar

# States
var is_dead: bool = false
var is_attacking: bool = false
var is_hurt: bool = false

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	
	# --- 1. SET UKURAN 3X ---
	scale = Vector2(3.0, 3.0) 
	
	health_bar.max_value = max_health # Set batas atas bar
	health_bar.value = health         # Isi penuh di awal
	health_bar.visible = false        # (Opsional) Sembunyikan kalau darah penuh
	
	# Setup Hitbox (Awalnya Mati)
	attack_area.monitoring = false
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	# Setup Signal Animasi Selesai
	if not animated_sprite_2d.animation_finished.is_connected(_on_animated_sprite_2d_animation_finished):
		animated_sprite_2d.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

	# --- 2. SETUP SIGNAL FRAME CHANGED (BARU) ---
	# Ini penting untuk mendeteksi kapan Frame ke-3 dimainkan
	if not animated_sprite_2d.frame_changed.is_connected(_on_animated_sprite_2d_frame_changed):
		animated_sprite_2d.frame_changed.connect(_on_animated_sprite_2d_frame_changed)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if not is_dead:
		if player and not is_hurt and not is_attacking:
			var distance = global_position.distance_to(player.global_position)
			print(distance)
			var direction_x = sign(player.global_position.x - global_position.x)
			
			if distance <= attack_range:
				velocity.x = 0
				start_attack()
				
			elif distance <= chase_distance:
				velocity.x = direction_x * move_speed
				
				# Flip Logic
				if velocity.x != 0:
					var is_moving_left = velocity.x < 0
					animated_sprite_2d.flip_h = is_moving_left
					# Flip Hitbox juga
					if is_moving_left: attack_area.scale.x = -1 
					else: attack_area.scale.x = 1
				
			else:
				velocity.x = move_toward(velocity.x, 0, move_speed)
		
		if is_attacking or is_hurt:
			velocity.x = 0
	else:
		velocity.x = 0

	move_and_slide()
	update_animation()

# --- LOGIKA SERANGAN (MODIFIKASI FRAME 3) ---
func start_attack() -> void:
	if is_attacking: return
	is_attacking = true
	
	# CATATAN PENTING:
	# Jangan nyalakan monitoring di sini!
	# Kita nyalakan nanti di fungsi _on_animated_sprite_2d_frame_changed
	attack_area.monitoring = false 

# --- FUNGSI BARU: DETEKSI FRAME ---
func _on_animated_sprite_2d_frame_changed() -> void:
	# Hanya cek jika sedang animasi attack
	if animated_sprite_2d.animation == "attack":
		# Cek Frame Index (Dimulai dari 0)
		# Jika Frame == 3, nyalakan hitbox
		if animated_sprite_2d.frame == 3:
			attack_area.monitoring = true
			# print("Frame 3 tercapai: Hitbox ON!")

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		if body is Player:
			# print("Demon Hantam Player!")
			body.take_damage(damage_amount, self)
			
			# Opsional: Matikan hitbox setelah kena 1 kali agar tidak spam damage dalam 1 animasi
			# attack_area.call_deferred("set_monitoring", false) 

# --- LOGIKA TERKENA DAMAGE ---
func take_damage(amount: int, source: Node2D = null) -> void:
	if is_dead or source.is_in_group("enemies"): return
	health -= amount
	
	health_bar.value = health
	health_bar.visible = true # Munculkan bar saat kena pukul
	
	if health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false
		attack_area.monitoring = false # Matikan hitbox jika terpukul
		
		if source:
			var knockback_dir = sign(global_position.x - source.global_position.x)
			velocity.x = knockback_dir * 150
			velocity.y = -150

func die() -> void:
	if is_dead: return
	is_dead = true
	health_bar.visible = false
	attack_area.monitoring = false
	velocity = Vector2.ZERO
	update_animation()

func update_animation() -> void:
	var anim_name = "idle"
	if is_dead: anim_name = "die"
	elif is_hurt: anim_name = "hurt"
	elif is_attacking: anim_name = "attack"
	elif velocity.x != 0: anim_name = "walk"
	else: anim_name = "idle"
	
	animated_sprite_2d.play(anim_name)

func _on_animated_sprite_2d_animation_finished() -> void:
	var current_anim = animated_sprite_2d.animation
	
	if current_anim == "attack":
		is_attacking = false
		attack_area.monitoring = false # Pastikan mati setelah animasi selesai
	elif current_anim == "hurt":
		is_hurt = false
	elif current_anim == "die":
		queue_free()
