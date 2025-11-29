extends TextureRect 

# Referensi Node
@onready var grid_container: GridContainer = $GridContainer
@onready var item_slot_hud: Sprite2D = $"../HealthPotion"
@onready var player = $"../.." 

# Preload Scene Slot
var slot_scene = preload("res://scene/InventorySlotItem.tscn")

# --- DATABASE ITEM SEDERHANA ---
# UPDATED: Ditambahkan "id" agar bisa disimpan ke JSON
var all_items = {
	"health_potion": {
		"id": "health_potion", # ID UNIK (Wajib ada untuk Save System)
		"name": "Health Potion",
		"type": "consumable",
		"value": 3, 
		"icon": preload("res://assets/ui/Potions by Onocentaur/Potions by Onocentaur/health_potion.png")
	},
	"stamina_potion": {
		"id": "stamina_potion", # ID UNIK
		"name": "Stamina Potion",
		"type": "consumable",
		"value": 5, 
		"icon": preload("res://assets/ui/Potions by Onocentaur/Potions by Onocentaur/stamina_potion.png")
	}
}

# Data Inventory Player (Array 16 Slot)
var inventory_data = []

func _ready():
	# Inisialisasi data kosong (16 slot)
	inventory_data.resize(16)
	
	# --- STARTER ITEMS (Item awal saat New Game) ---
	# Item ini akan tertimpa (overwrite) jika ada proses Load Game nantinya
	inventory_data[0] = all_items["health_potion"]
	inventory_data[1] = all_items["health_potion"]
	inventory_data[2] = all_items["stamina_potion"]
	inventory_data[3] = all_items["health_potion"]
	inventory_data[4] = all_items["health_potion"]
	inventory_data[5] = all_items["stamina_potion"]
	inventory_data[6] = all_items["health_potion"]
	inventory_data[7] = all_items["health_potion"]
	inventory_data[8] = all_items["stamina_potion"]
	
	# Render Grid
	update_inventory_ui()
	
	# Sembunyikan inventory saat awal main
	visible = false

func update_inventory_ui():
	# Hapus semua slot lama (refresh)
	for child in grid_container.get_children():
		child.queue_free()
	
	# Buat slot baru berdasarkan data
	for i in range(inventory_data.size()):
		var item = inventory_data[i]
		var slot = slot_scene.instantiate()
		grid_container.add_child(slot)
		
		slot.set_item(item)
		
		# --- PERUBAHAN PENTING DI SINI ---
		# Kita gunakan .bind(i) untuk mengirim nomor index bersamaan dengan sinyal
		slot.slot_clicked.connect(_on_slot_clicked.bind(i))

func remove_item_at_index(index: int) -> void:
	# Pastikan index valid
	if index >= 0 and index < inventory_data.size():
		# Kosongkan slot spesifik ini
		inventory_data[index] = null
		
		# Update tampilan
		update_inventory_ui()

# --- SAAT SLOT DIKLIK ---
func _on_slot_clicked(item_data, index_slot):
	print("Memilih item: ", item_data["name"], " di Slot: ", index_slot)
	
	if item_slot_hud:
		item_slot_hud.texture = item_data["icon"]
	
	# Kirim data DAN nomor slot ke Player
	player.select_consumable(item_data, index_slot)

# ==========================================
#       LOGIKA SAVE & LOAD INVENTORY
# ==========================================

# Fungsi ini dipanggil oleh PauseMenu saat Save Game
# Mengubah inventory objek menjadi array string ID: ["health_potion", null, "stamina_potion", ...]
func get_save_data() -> Array:
	var save_array = []
	
	for item in inventory_data:
		if item == null:
			save_array.append(null) # Slot kosong simpan sebagai null
		else:
			# Simpan ID-nya saja (Hemat memori & bisa disimpan di JSON)
			save_array.append(item["id"]) 
			
	return save_array

# Fungsi ini dipanggil oleh PauseMenu saat Load Game
# Menerima array string ID dan mengubahnya kembali menjadi data item lengkap
func load_save_data(saved_array: Array) -> void:
	# Reset data saat ini
	inventory_data = []
	inventory_data.resize(16)
	
	# Loop data yang di-load
	for i in range(saved_array.size()):
		var item_id = saved_array[i]
		
		if item_id != null:
			# Cari detail item berdasarkan ID di database (all_items)
			# Contoh: ID "health_potion" -> diambil data lengkapnya
			if all_items.has(item_id):
				inventory_data[i] = all_items[item_id]
			else:
				print("Warning: Item ID tidak dikenal -> ", item_id)
				inventory_data[i] = null
		else:
			inventory_data[i] = null
			
	# Update Tampilan Grid setelah data dimuat
	update_inventory_ui()
func add_item_by_id(item_id: String) -> bool:
	# 1. Cari slot kosong (null)
	var empty_slot_index = -1
	for i in range(inventory_data.size()):
		if inventory_data[i] == null:
			empty_slot_index = i
			break
	
	# 2. Jika ada slot kosong, isi dengan data dari database
	if empty_slot_index != -1:
		if all_items.has(item_id):
			inventory_data[empty_slot_index] = all_items[item_id]
			update_inventory_ui()
			return true # Berhasil masuk
	
	return false # Gagal (Penuh)
