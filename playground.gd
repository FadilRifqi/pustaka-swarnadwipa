extends Node2D

# --- AUDIO SETUP ---
@onready var bgm: AudioStreamPlayer = $bgm
@export var target_volume: float = 7.0 
@export var fade_duration: float = 2.0

# --- REFERENSI PLAYER ---
@onready var player: Player = $Player

func _ready() -> void:
	# Cek apakah kita sedang Load Game atau Balik dari Setting?
	if Global.is_returning_from_settings or Global.load_saved_game:
		print(">> Mode LOAD/CONTINUE: Skip Fade In Music")
		
		# 1. Langsung set ke volume target (Normal)
		bgm.volume_db = target_volume 
		
		# 2. Play music jika belum jalan (untuk jaga-jaga)
		if not bgm.playing:
			bgm.play()
			
	else:
		# JIKA TIDAK (Game Baru): Jalankan efek Fade In
		fade_in_music()
	
	# KARENA MUSUH MANUAL:
	# Kita tidak perlu memanggil fungsi spawn apapun di sini.
	# Musuh yang kamu taruh di Editor akan otomatis jalan sendiri saat game mulai.

func fade_in_music() -> void:
	bgm.volume_db = -80.0
	bgm.play()
	var tween = create_tween()
	tween.tween_property(bgm, "volume_db", target_volume, fade_duration)
