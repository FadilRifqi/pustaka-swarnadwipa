class_name Cindaku
extends CharacterBody2D

# --- STATS BOSS ---
@export var max_health: int = 15 # Nyawa Maksimal
var health: int = max_health     # Nyawa Saat Ini

# Damage Values
@export var damage_normal: float = 1.0
@export var damage_skill_1: float = 1.0
@export var damage_skill_2: float = 1.0

# Movement & AI
@export var move_speed: float = 85.0
@export var gravity: float = 980.0
@export var chase_distance: float = 900.0
@export var attack_range: float = 90.0
@export var boss_scale: float = 3.5

# Cooldown Skill
var can_use_skill: bool = true
var skill_cooldown_time: float = 3.0

# Node References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Player = $"../Player"
@onready var health_bar: ProgressBar = $HealthBar

# HITBOXES
@onready var attack_area: Area2D = $AttackArea
@onready var skill_area: Area2D = $SkillArea

# States
var is_dead: bool = false
var is_attacking: bool = false
var is_hurt: bool = false
var current_attack_type: String = ""
var hurt_tween: Tween # Variabel untuk timer stun (Anti-Freeze)

func _ready() -> void:
	# 1. Reset Stats
	health = max_health
	add_to_group("enemies")
	scale = Vector2(boss_scale, boss_scale)
	
	# 2. SETUP HEALTH BAR (PENTING!)
	if health_bar:
		health_bar.max_value = max_health # Beri tahu bar batas penuhnya
		health_bar.value = health         # Isi penuh sekarang
		health_bar.visible = true
	else:
		print("WARNING: ProgressBar tidak ditemukan di Scene Cindaku!")
	
	# 3. Matikan Hitbox
	attack_area.monitoring = false
	skill_area.monitoring = false
	
	# 4. Hubungkan Signal (Manual via Kode biar aman)
	if not attack_area.body_entered.is_connected(_on_attack_area_entered):
		attack_area.body_entered.connect(_on_attack_area_entered)
	if not skill_area.body_entered.is_connected(_on_skill_area_entered):
		skill_area.body_entered.connect(_on_skill_area_entered)

	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if not is_dead:
		# PRIORITAS STATE
		# Jika Sakit -> Diam
		if is_hurt:
			velocity.x = 0
		# Jika Serang -> Diam
		elif is_attacking:
			velocity.x = 0
		# Jika Normal -> AI Jalan
		elif player:
			var distance = global_position.distance_to(player.global_position)
			var direction_x = sign(player.global_position.x - global_position.x)
			
			if distance <= attack_range:
				velocity.x = 0
				decide_attack()
			elif distance <= chase_distance:
				velocity.x = direction_x * move_speed
				handle_flip(velocity.x)
			else:
				velocity.x = move_toward(velocity.x, 0, move_speed)
	else:
		velocity.x = 0

	move_and_slide()
	update_animation()

func handle_flip(vel_x: float) -> void:
	if vel_x != 0:
		var is_left = vel_x < 0
		animated_sprite.flip_h = is_left
		if is_left:
			attack_area.scale.x = -1
			skill_area.scale.x = -1
		else:
			attack_area.scale.x = 1
			skill_area.scale.x = 1

# --- AI ATTACK DECISION ---
func decide_attack() -> void:
	var rng = randi() % 100
	if can_use_skill and rng < 40: start_skill_1()
	elif can_use_skill and rng < 70: start_skill_2()
	else: start_normal_attack()

func start_normal_attack():
	is_attacking = true
	current_attack_type = "attack"
	attack_area.monitoring = false

func start_skill_1():
	is_attacking = true
	current_attack_type = "skill1"
	skill_area.monitoring = false
	start_cooldown()

func start_skill_2():
	is_attacking = true
	current_attack_type = "skill2"
	attack_area.monitoring = false
	start_cooldown()

func start_cooldown():
	can_use_skill = false
	await get_tree().create_timer(skill_cooldown_time).timeout
	can_use_skill = true

# --- FRAME TIMING (HITBOX ON) ---
func _on_frame_changed() -> void:
	var anim = animated_sprite.animation
	var frame = animated_sprite.frame
	
	# Sesuaikan frame ini dengan sprite sheet kamu!
	if anim == "attack" and frame == 4: attack_area.monitoring = true
	elif anim == "skill2" and frame == 2: attack_area.monitoring = true
	elif anim == "skill1" and frame == 3: skill_area.monitoring = true

func _on_attack_area_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self and body is Player:
		var dmg = damage_normal
		if current_attack_type == "skill2": dmg = damage_skill_2
		body.take_damage(dmg, self)
		attack_area.call_deferred("set_monitoring", false)

func _on_skill_area_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self and body is Player:
		body.take_damage(damage_skill_1, self)
		skill_area.call_deferred("set_monitoring", false)

# --- DAMAGE SYSTEM (ANTI FREEZE) ---
func take_damage(amount: int, source: Node2D = null) -> void:
	if is_dead: return
	
	# 1. Kurangi Health
	health -= amount
	
	# 2. UPDATE UI BAR (INI YANG MEMBUAT BAR BERKURANG)
	if health_bar:
		health_bar.value = health
	
	print("Cindaku HP: ", health)
	
	if health <= 0:
		die()
	else:
		# 3. INTERUPSI AKSI
		is_attacking = false
		attack_area.monitoring = false
		skill_area.monitoring = false
		
		# 4. SET STATUS SAKIT
		is_hurt = true
		
		# 5. RESET TWEEN (KUNCI AGAR TIDAK FREEZE)
		if hurt_tween: hurt_tween.kill()
		hurt_tween = create_tween()
		
		# 6. EFEK VISUAL MERAH
		modulate = Color.RED
		
		# Knockback Sedikit
		if source:
			var knockback_dir = sign(global_position.x - source.global_position.x)
			velocity.x = knockback_dir * 50
		
		# 7. PULIH (Kembali Putih dalam 0.2 detik)
		hurt_tween.tween_property(self, "modulate", Color.WHITE, 0.2)
		
		# 8. SELESAI SAKIT (Dalam 0.4 detik total)
		hurt_tween.tween_callback(func(): is_hurt = false)

func die() -> void:
	is_dead = true
	if health_bar: health_bar.visible = false
	attack_area.monitoring = false
	skill_area.monitoring = false
	velocity = Vector2.ZERO
	update_animation()

# --- ANIMATION SYSTEM ---
func update_animation() -> void:
	var anim = "idle"
	
	if is_dead: 
		anim = "die"
	# HAPUS LOGIKA "elif is_hurt: anim = 'hurt'" karena tidak ada animasi hurt
	elif is_attacking: 
		if current_attack_type == "skill1": anim = "skill1"
		elif current_attack_type == "skill2": anim = "skill2"
		else: anim = "attack"
	elif velocity.x != 0: 
		anim = "walk"
	
	if animated_sprite.animation != anim:
		# Cek apakah animasi ada di sprite frames
		if animated_sprite.sprite_frames.has_animation(anim):
			animated_sprite.play(anim)

func _on_animation_finished() -> void:
	var anim = animated_sprite.animation
	
	if anim == "attack" or anim == "skill1" or anim == "skill2":
		is_attacking = false
		attack_area.monitoring = false
		skill_area.monitoring = false
		
	elif anim == "die":
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 2.0)
		await tween.finished
		queue_free()
