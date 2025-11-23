extends TextureRect # Atau Control, sesuai node kamu

# Referensi Node
@onready var grid_container: GridContainer = $GridContainer
@onready var item_slot_hud: Sprite2D = $"../HealthPotion"
@onready var player = $"../.." # Referensi ke root Player (sesuaikan path tree)

# Preload Scene Slot yang dibuat di Tahap 1
var slot_scene = preload("res://scene/InventorySlotItem.tscn")

# --- DATABASE ITEM SEDERHANA ---
# (Nanti bisa dipindah ke Global script biar rapi)
var all_items = {
	"health_potion": {
		"name": "Health Potion",
		"type": "consumable",
		"value": 3, # Nambah 3 darahres://assets/items/health_potion.png
		"icon": preload("res://assets/ui/Potions by Onocentaur/Potions by Onocentaur/health_potion.png") # Ganti path icon kamu
	},
	"stamina_potion": {
		"name": "Stamina Potion",
		"type": "consumable",
		"value": 5, # Nambah 5 stamina
		"icon": preload("res://assets/ui/Potions by Onocentaur/Potions by Onocentaur/stamina_potion.png") # Ganti path icon kamu
	}
}

# Data Inventory Player (Array 16 Slot)
var inventory_data = []

func _ready():
	# Inisialisasi data kosong (16 slot)
	inventory_data.resize(16)
	
	# CONTOH: Isi beberapa item buat ngetes
	inventory_data[0] = all_items["health_potion"]
	inventory_data[1] = all_items["health_potion"]
	inventory_data[2] = all_items["stamina_potion"]
	
	# Render Grid
	update_inventory_ui()
	
	# Sembunyikan inventory saat awal main
	visible = false

func update_inventory_ui():
	# Hapus semua slot lama (refresh)
	for child in grid_container.get_children():
		child.queue_free()
	
	# Buat slot baru berdasarkan data
	for item in inventory_data:
		var slot = slot_scene.instantiate()
		grid_container.add_child(slot)
		
		# Isi slot dengan data item
		slot.set_item(item)
		
		# Hubungkan sinyal klik
		slot.slot_clicked.connect(_on_slot_clicked)

func remove_item(item_data) -> void:
	# 1. Cari posisi index item tersebut di dalam Array
	var index = inventory_data.find(item_data)
	
	# 2. Jika ketemu (index tidak -1)
	if index != -1:
		# Kosongkan datanya
		inventory_data[index] = null
		
		# 3. Update Tampilan Grid agar itemnya hilang visualnya
		update_inventory_ui()

# --- SAAT SLOT DIKLIK ---
func _on_slot_clicked(item_data):
	print("Memilih item: ", item_data["name"])
	
	# 1. Tampilkan di ItemSlot HUD (Pojok Kanan Atas)
	if item_slot_hud:
		item_slot_hud.texture = item_data["icon"]
	
	# 2. Simpan data item yang dipilih ke Player
	# Kita panggil fungsi di script Player
	player.select_consumable(item_data)
