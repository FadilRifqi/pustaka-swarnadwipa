extends TextureRect

# Signal untuk memberitahu Inventory Utama saat slot ini diklik
signal slot_clicked(item_data)

# Referensi Node Anak
# Pastikan nama node di Scene InventorySlotItem.tscn sesuai dengan ini
@onready var icon_visual: TextureRect = $Icon 
@onready var highlight: ReferenceRect = $Highlight 

var my_item_data = null

func _ready():
	# Biarkan mouse filter IGNORE agar input bisa tembus jika perlu,
	# atau STOP jika ingin menangkap input di sini (default Control)
	# Untuk kasus inventory grid, STOP biasanya lebih aman agar klik terdeteksi _gui_input
	#mouse_filter = Control.MOUSE_FILTER_STOP 
	
	# Pastikan highlight mati saat game mulai
	if highlight:
		highlight.visible = false
		# FIX: Paksa ukuran highlight memenuhi slot (Full Rect) secara kode
		# Ini memperbaiki masalah kotak kuning cuma di pojok kiri atas
		highlight.set_anchors_preset(Control.PRESET_FULL_RECT)

# Fungsi untuk mengisi data item ke slot ini (Dipanggil oleh Inventory Utama)
func set_item(data):
	my_item_data = data
	
	if data:
		# Jika ada item, tampilkan ikonnya
		icon_visual.texture = data["icon"]
		icon_visual.visible = true
	else:
		# Jika kosong, sembunyikan ikon
		icon_visual.texture = null
		icon_visual.visible = false

# Fungsi untuk menyalakan/mematikan Border Kuning (Highlight)
func set_highlight(is_active: bool):
	if highlight:
		highlight.visible = is_active

# Deteksi Klik Mouse pada Slot ini
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Kirim sinyal bahwa slot ini diklik
		# (Inventory Utama akan menangkap sinyal ini dan tahu slot mana yg diklik)
		slot_clicked.emit(my_item_data)
