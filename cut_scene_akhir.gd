extends CanvasLayer

@onready var black_bottom: ColorRect = $BlackBottom
@onready var black_top: ColorRect = $BlackTop
@onready var char_left: TextureRect = $CharLeft
@onready var char_right: TextureRect = $CharRight
@onready var label_left: Label = $Label
@onready var label_right: Label = $Label2

const DURATION: float = 0.5 
const OFFSET: float = 1000.0 

var dialog_index := 0

var dialog = [
	{"speaker": "left", "text": "Hah... Hah... Akhirnya makhluk itu tumbang juga." },
	{ "speaker": "right", "text": "Luar biasa! Aku tidak percaya kau berhasil mengalahkannya sendirian!" },
	{ "speaker": "left", "text": "Dia memang kuat, tapi aku lebih cepat. Ini, aku menemukan Rencong Emas yang dicurinya." },
	{ "speaker": "right", "text": "Ah! Pusaka desa kami! Terima kasih, Pahlawan. Harapan kami mulai kembali bersinar." },
	{ "speaker": "right", "text": "Tapi jangan lengah dulu. Sumber dari segala kegelapan ini masih ada." },
	{ "speaker": "left", "text": "Maksudmu Raja Kegelapan? Dimana dia bersembunyi?" },
	{ "speaker": "right", "text": "Dia berada di kuil terlarang di puncak bukit. Dia memegang Keris Pusaka terakhir." },
	{ "speaker": "left", "text": "Baiklah. Aku akan segera ke sana dan mengakhiri semua ini." }
]

func _ready():
	# Jalankan animasi buka
	start_animation()

	# Sembunyikan kedua label dulu
	label_left.visible = false
	label_right.visible = false

	# Mulai dialog setelah animasi selesai
	await get_tree().create_timer(0.6).timeout
	show_dialog()

func show_dialog():
	if dialog_index >= dialog.size():
		return # dialog selesai

	var d = dialog[dialog_index]

	# Reset
	label_left.visible = false
	label_right.visible = false

	if d.speaker == "left":
		label_left.visible = true
		label_left.text = d.text

	elif d.speaker == "right":
		label_right.visible = true
		label_right.text = d.text

	dialog_index += 1

func _input(event):
	if event.is_action_pressed("advanced_line"):  # Tekan Enter / Space untuk lanjut
		show_dialog()

func start_animation() -> void:
	black_bottom.visible = true
	black_top.visible = true
	
	var tween_bottom = create_tween()
	tween_bottom.tween_property(
		black_bottom, "position:y",
		black_bottom.position.y + OFFSET, DURATION
	).set_ease(Tween.EASE_IN_OUT)

	var tween_top = create_tween()
	tween_top.tween_property(
		black_top, "position:y",
		black_top.position.y - OFFSET, DURATION
	).set_ease(Tween.EASE_IN_OUT)
