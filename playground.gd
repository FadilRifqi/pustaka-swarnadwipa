extends Node2D

# --- AUDIO SETUP ---
@onready var bgm: AudioStreamPlayer = $bgm
@export var fade_duration: float = 2.0
@onready var bossmusic: AudioStreamPlayer = $bossmusic

# --- REFERENSI PLAYER ---
@onready var player: Player = $Player
@onready var void_area: Area2D = $Void

func _ready() -> void:
	# Cek apakah kita sedang Load Game atau Balik dari Setting?
	if Global.is_returning_from_settings or Global.load_saved_game:
		print(">> Mode LOAD/CONTINUE: Skip Fade In Music")
		
		# 1. Langsung set ke volume target (Normal)
		bgm.volume_linear = Global.master_volume 
		
		# 2. Play music jika belum jalan (untuk jaga-jaga)
		if not bgm.playing:
			bgm.play()
			
	else:
		# JIKA TIDAK (Game Baru): Jalankan efek Fade In
		fade_in_music(bgm)
	if void_area:
		# Hubungkan sinyal: Kalau ada body masuk -> Jalankan fungsi _on_void_body_entered
		if not void_area.body_entered.is_connected(_on_void_body_entered):
			void_area.body_entered.connect(_on_void_body_entered)
	else:
		print("Error: Node Void tidak ditemukan!")


func _on_void_body_entered(body: Node2D) -> void:
	# Cek apakah yang jatuh adalah Player
	if body is Player:
		print("Player jatuh ke Void!")
		
		# CARA 1: Beri damage sangat besar (agar health bar update jadi 0)
		# Gunakan 9999 agar mati seketika walau darah penuh
		if body.has_method("take_damage"):
			body.take_damage(9999) 
			
		# CARA 2 (Alternatif): Langsung panggil die()
		# body.die()	
	# KARENA MUSUH MANUAL:
	# Kita tidak perlu memanggil fungsi spawn apapun di sini.
	# Musuh yang kamu taruh di Editor akan otomatis jalan sendiri saat game mulai.

func switch_to_boss_music():
	# Hanya jalankan jika musik boss belum main
	if not bossmusic.playing:
		print(">> Battle Start: Switch to Boss Music")
		# Matikan BGM pelan-pelan
		fade_out_music(bgm)
		# Nyalakan Boss Music pelan-pelan
		fade_in_music(bossmusic)

func switch_to_level_music():
	# Hanya jalankan jika musik boss sedang main
	if bossmusic.playing:
		print(">> Battle End: Switch to Level Music")
		# Matikan Boss Music pelan-pelan
		fade_out_music(bossmusic)
		# Nyalakan BGM pelan-pelan
		fade_in_music(bgm)

func fade_in_music(music : AudioStreamPlayer) -> void:
	music.play()
	var tween = create_tween()
	tween.tween_property(music, "volume_db", Global.master_volume, fade_duration)

func fade_out_music(music: AudioStreamPlayer) -> void:
	# Cek agar tidak fade out musik yang sudah mati
	if music.playing:
		var tween = create_tween()
		# Turunkan volume ke -80 (hening)
		tween.tween_property(music, "volume_db", -80.0, fade_duration)
		# Matikan player setelah fade selesai
		tween.tween_callback(music.stop)
