class_name BeguGanjang
extends CharacterBody2D

# --- STATS BOSS ---
@export var max_health: int = 30
var health: int = max_health
@export var damage_amount: int = 6 # Damage sakit
@export var move_speed: float = 65.0 # Boss biasanya jalan pelan tapi mematikan
@export var gravity: float = 980.0

# AI Settings
@export var chase_distance: float = 800.0 # Jarak pandang lebih jauh
@export var attack_range: float = 200.0   # Jangkauan pukul
@export var boss_scale: float = 4.0      # Ukuran Boss (4x lipat)

# Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
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
	
	# Set Ukuran Boss
	scale = Vector2(boss_scale, boss_scale)
	
	# Setup Health Bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = true # Boss bar selalu terlihat (opsional)
	
	# Setup Hitbox (Mati di awal)
	attack_area.monitoring = false
	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	# Setup Signal Animasi
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Setup Signal Frame (Untuk timing serangan)
	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	# Gravitasi
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if not is_dead:
		if player and not is_hurt and not is_attacking:
			var distance = global_position.distance_to(player.global_position)
			var direction_x = sign(player.global_position.x - global_position.x)
			
			# A. SERANG (Jarak Dekat)
			if distance <= attack_range:
				velocity.x = 0
				start_attack()
				
			# B. KEJAR (Jarak Jauh)
			elif distance <= chase_distance:
				velocity.x = direction_x * move_speed
				
				# Flip Logic
				if velocity.x != 0:
					var is_moving_left = velocity.x < 0
					animated_sprite.flip_h = is_moving_left
					
					# Flip Hitbox
					if is_moving_left: attack_area.scale.x = -1
					else: attack_area.scale.x = 1
			
			# C. DIAM
			else:
				velocity.x = move_toward(velocity.x, 0, move_speed)
		
		# Stop gerak jika sedang sibuk
		if is_attacking or is_hurt:
			velocity.x = 0
	else:
		velocity.x = 0

	move_and_slide()
	update_animation()

# --- SYSTEM SERANGAN (TIMING FRAME) ---
func start_attack() -> void:
	print(is_attacking)
	if is_attacking: return
	is_attacking = true
	# Hitbox jangan nyala dulu, tunggu frame pukulan
	attack_area.monitoring = false 

func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack":
		# PENTING: Ganti angka '3' ini sesuai frame di mana tangan boss memukul tanah/player
		if animated_sprite.frame == 8: 
			attack_area.monitoring = true
			# print("BeguGanjang Hantam!")

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
		if body is Player:
			# Kirim damage 6 dan 'self' agar player terpental menjauh dari boss
			body.take_damage(damage_amount, self)
			
			# Matikan hitbox segera agar tidak double hit dalam 1 animasi
			attack_area.call_deferred("set_monitoring", false)

# --- SYSTEM DAMAGE & HEALTH ---
func take_damage(amount: int, source: Node2D = null) -> void:
	if is_dead: return
	
	health -= amount
	print("BeguGanjang HP: ", health)
	
	# Update UI
	if health_bar:
		health_bar.value = health
	
	if health <= 0:
		die()
	else:
		# Boss effect: Tidak selalu stun (Hurt) setiap kali dipukul
		# Agar boss tetap mengancam. Kita buat 50% chance stun atau tanpa stun.
		is_hurt = true
		is_attacking = false
		attack_area.monitoring = false
		
		# Knockback Resistance (Boss cuma mundur dikit banget)
		if source:
			var knockback_dir = sign(global_position.x - source.global_position.x)
			velocity.x = knockback_dir * 50 # Angka kecil biar berasa berat
		
		# Efek visual merah
		modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		modulate = Color.WHITE

func die() -> void:
	if is_dead: return
	is_dead = true
	print("BOSS DEFEATED!")
	
	attack_area.monitoring = false
	if health_bar: health_bar.visible = false
	
	velocity = Vector2.ZERO
	update_animation()

# --- ANIMASI ---
func update_animation() -> void:
	var anim_name = "idle"
	
	if is_dead: anim_name = "die"
	elif is_hurt: anim_name = "hurt"
	elif is_attacking: anim_name = "attack"
	elif velocity.x != 0: anim_name = "walk"
	
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)

func _on_animation_finished() -> void:
	var anim = animated_sprite.animation
	
	if anim == "attack":
		is_attacking = false
		attack_area.monitoring = false
	elif anim == "hurt":
		is_hurt = false
	elif anim == "die":
		# Boss mati pelan-pelan (Fade out)
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 2.0)
		await tween.finished
		queue_free()
