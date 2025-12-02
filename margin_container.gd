extends MarginContainer

# --- REFERENSI NODE (Sesuai Screenshot) ---
# Path ini relatif terhadap MarginContainer tempat script dipasang
@onready var label: Label = $MarginContainer/Label
@onready var timer: Timer = $LetterDisplayTimer
@onready var next_indicator: TextureRect = $NextIndicator

# --- PENGATURAN KECEPATAN ---
const LETTER_TIME = 0.03   # Kecepatan normal per huruf
const SPACE_TIME = 0.06    # Kecepatan spasi
const PUNCTUATION_TIME = 0.2 # Jeda saat titik/koma (biar natural)

var text_to_display: String = ""
var letter_index: int = 0

# Sinyal untuk memberitahu Cutscene.gd kalau teks sudah selesai
signal finished_typing()

func _ready() -> void:
	# Hubungkan signal timer secara otomatis lewat kode
	# (Biar ga perlu connect manual di editor satu-satu)
	if timer:
		if not timer.timeout.is_connected(_on_letter_display_timer_timeout):
			timer.timeout.connect(_on_letter_display_timer_timeout)
	
	# Sembunyikan panah next di awal
	if next_indicator:
		next_indicator.visible = false

# --- FUNGSI MEMULAI DIALOG ---
func start_typing(text: String) -> void:
	text_to_display = text
	label.text = ""
	letter_index = 0
	
	if next_indicator:
		next_indicator.visible = false
	
	# Mulai ngetik huruf pertama
	_display_next_letter()

# --- LOGIKA NGETIK ---
func _display_next_letter() -> void:
	# Cek apakah huruf sudah habis?
	if letter_index >= text_to_display.length():
		finish()
		return
	
	# Tambahkan satu huruf ke label
	label.text += text_to_display[letter_index]
	
	# Cek karakter saat ini untuk menentukan kecepatan
	var current_char = text_to_display[letter_index]
	letter_index += 1
	
	var wait_time = LETTER_TIME
	
	# Logika jeda natural
	match current_char:
		".", ",", "!", "?":
			wait_time = PUNCTUATION_TIME
		" ":
			wait_time = SPACE_TIME
		_:
			wait_time = LETTER_TIME
			
	# Jalankan timer untuk huruf berikutnya
	timer.start(wait_time)

# --- FUNGSI SAAT TIMER HABIS (Looping) ---
func _on_letter_display_timer_timeout() -> void:
	_display_next_letter()

# --- FUNGSI SELESAI / SKIP ---
func finish() -> void:
	label.text = text_to_display # Tampilkan semua teks langsung
	letter_index = text_to_display.length()
	timer.stop()
	
	if next_indicator:
		next_indicator.visible = true
		
	emit_signal("finished_typing")

# --- FUNGSI PUBLIC UNTUK SKIP ---
# Panggil ini jika player menekan tombol saat teks sedang jalan
func skip():
	finish()
