extends CanvasLayer

# Referensi ke Script TextBox
@onready var box_kiri = $Panel/MarginContainer
@onready var box_kanan = $Panel2/MarginContainer

# --- DATA NASKAH LANGSUNG DI SINI ---
var dialogs = [
	{"side": "left", "text": "Hah... Hah... Akhirnya tumbang juga."},
	{"side": "left", "text": "Kekuatan kegelapan Raja Kegelapan sudah sirna. Semuanya sudah berakhir."},
	{"side": "right", "text": "Hei! Kau di sana! Apakah... apakah gempa barusan itu ulahmu?"},
	{"side": "right", "text": "Astaga! Lihat itu... Raksasa itu... dia sudah mati?!"},
	{"side": "left", "text": "Tenang saja. Dia tidak akan mengganggu desa kalian lagi."},
	{"side": "left", "text": "Dan ini... Keris Pusaka yang dicurinya. Tolong kembalikan ke Tetua kalian."},
	{"side": "right", "text": "Aku tidak percaya ini... Kau benar-benar menyelamatkan kami semua!"},
	{"side": "right", "text": "Langit di atas desa sudah mulai cerah kembali. Terima kasih, Pahlawan!"},
	{"side": "left", "text": "Jaga desa ini baik-baik. Aku harus melanjutkan perjalananku."},
	{"side": "right", "text": "Tentu! Hati-hati di jalan! Namamu akan selalu kami kenang!"}
]

var current_idx = 0
var is_typing = false

# Sinyal wajib agar Playground tahu kapan cutscene selesai
signal cutscene_finished()

func _ready():
	# Sembunyikan UI saat game mulai
	visible = false 

# --- FUNGSI START TANPA PARAMETER ---
# Dipanggil dari Playground cukup dengan: cutscene_ui.start_cutscene()
func start_cutscene():
	current_idx = 0
	visible = true
	show_dialog()

func show_dialog():
	if dialogs.size() == 0: return

	var data = dialogs[current_idx]
	is_typing = true
	
	if data["side"] == "left":
		$Panel.visible = true
		$Panel2.visible = false
		
		# Mulai ngetik di box kiri
		box_kiri.start_typing(data["text"])
		
		# Tunggu sinyal selesai dari script text_box.gd
		await box_kiri.finished_typing
		
	else:
		$Panel.visible = false
		$Panel2.visible = true
		
		# Mulai ngetik di box kanan
		box_kanan.start_typing(data["text"])
		
		# Tunggu sinyal selesai
		await box_kanan.finished_typing
	
	is_typing = false

func _input(event):
	if not visible: return

	if event.is_action_pressed("ui_accept"):
		# Jika sedang ngetik, skip teksnya
		if is_typing:
			if $Panel.visible: box_kiri.skip()
			if $Panel2.visible: box_kanan.skip()
		
		# Jika sudah selesai ngetik, lanjut dialog berikutnya
		else:
			current_idx += 1
			if current_idx < dialogs.size():
				show_dialog()
			else:
				end_cutscene()

func end_cutscene():
	print("Cutscene Selesai")
	visible = false
	emit_signal("cutscene_finished")
