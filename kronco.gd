class_name Kronco
extends CharacterBody2D

# --- VARIABLES ---
@export var max_health: int = 8
var health: int = max_health

@export var move_speed: float = 100.0
@export var gravity: float = 980.0
@export var chase_distance: float = 600.0 # Jarak mulai mengejar (Detect Range)
@export var attack_range: float = 50.0    # Jarak mulai menyerang (Stop & Hit)
@export var knockback_force: float = 200.0 

# Node References
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var idle: Sprite2D = $Idle 
@onready var player: Player = $"../Player"
@onready var attack_area: Area2D = $AttackArea

# Variable Logika
var is_dead: bool = false
var is_hurt: bool = false 

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	
	# --- PERBAIKAN 1: NYALAKAN MONITORING ---
	# Agar hitbox aktif dan bisa memberi damage 2
	attack_area.monitoring = true 
	
	# Hubungkan signal
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

func _process(delta: float) -> void:
	if not player or is_dead: return
	
	# Update Animasi sederhana
	if not is_hurt:
		animation_player.play("idle")

# --- LOGIKA MEMBERI DAMAGE (DAMAGE 2) ---
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		print(body)
		if body is Player:
			print("tes")
			# Kronco memberi damage 2
			body.take_damage(1, self)

func _physics_process(delta: float) -> void:
	if not player or is_dead: return

	# 1. GRAVITASI
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# 2. LOGIKA AI (MIRIP SKELETON)
	if not is_hurt:
		var distance = global_position.distance_to(player.global_position)
		var direction_x = sign(player.global_position.x - global_position.x)
		
		# A. Jika dekat sekali -> STOP & SERANG
		if distance <= attack_range:
			velocity.x = 0
			# Jika nanti Kronco punya animasi attack, panggil start_attack() disini
			
		# B. Jika dalam jarak kejar -> KEJAR
		elif distance <= chase_distance:
			velocity.x = direction_x * move_speed
			
			# --- PERBAIKAN 2: FLIP LOGIC ---
			if velocity.x != 0:
				# Flip Sprite
				idle.flip_h = velocity.x > 0
				
				# Flip Hitbox (Ikut arah wajah)
				# Sesuaikan angka 1 dan -1 ini dengan arah asli sprite kamu di editor
				if velocity.x > 0:
					attack_area.scale.x = -1 # Jika hadap kanan perlu dibalik
				else:
					attack_area.scale.x = 1  # Normal
		
		# C. Player jauh -> DIAM
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			
	else:
		# Jika sedang sakit, diam
		velocity.x = 0

	move_and_slide()

# --- LOGIKA MENERIMA DAMAGE ---
func take_damage(amount: int):
	if is_dead: return
	health -= amount
	print("Kronco HP: ", health)
	_play_hurt_effect()
	if health <= 0: die()

func _play_hurt_effect():
	is_hurt = true
	modulate = Color.RED
	if player:
		var knockback_dir = global_position - player.global_position
		velocity.x = sign(knockback_dir.x) * knockback_force
		velocity.y = -150 
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE 
	is_hurt = false

func die():
	is_dead = true
	print("Kronco Mati")
	
	# Matikan hitbox saat mati
	attack_area.monitoring = false
	
	animation_player.stop()
	velocity = Vector2.ZERO
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5) 
	await tween.finished
	queue_free()
