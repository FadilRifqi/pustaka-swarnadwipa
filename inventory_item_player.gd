extends TextureRect 

@onready var grid_container: GridContainer = $GridContainer
@onready var item_slot_hud: TextureRect = $"../HealthPotion" 
@onready var player = $"../.." 

var slot_scene = preload("res://scene/InventorySlotItem.tscn")
signal request_close_inventory


# --- DATABASE ITEM ---
var all_items = {
	"health_potion": {
		"id": "health_potion",
		"name": "Health Potion",
		"type": "consumable",
		"value": 3, 
		"icon": preload("res://assets/ui/Potions by Onocentaur/Potions by Onocentaur/health_potion.png")
	},
	"stamina_potion": {
		"id": "stamina_potion",
		"name": "Stamina Potion",
		"type": "consumable",
		"value": 5, 
		"icon": preload("res://assets/ui/Potions by Onocentaur/Potions by Onocentaur/stamina_potion.png")
	}
}

var inventory_data = []

# --- NAVIGASI KEYBOARD VARIABLES ---
var current_index: int = 0
const COLUMNS: int = 4 # Jumlah kolom grid

func _ready():
	inventory_data.resize(16)
	inventory_data[0] = all_items["health_potion"]
	inventory_data[1] = all_items["stamina_potion"]
	
	update_inventory_ui()
	visible = false

func update_inventory_ui():
	for child in grid_container.get_children():
		child.queue_free()
	
	for i in range(inventory_data.size()):
		var item = inventory_data[i]
		var slot = slot_scene.instantiate()
		grid_container.add_child(slot)
		
		slot.set_item(item)
		
		# Matikan highlight di awal
		slot.set_highlight(false)
		
		# --- UPDATE PENTING: BIND INDEX SAAT KLIK ---
		# Ini agar saat diklik mouse, kita tahu itu slot nomor berapa
		if not slot.slot_clicked.is_connected(_on_slot_clicked):
			slot.slot_clicked.connect(_on_slot_clicked.bind(i))

	# Nyalakan highlight di posisi terakhir
	update_highlight_visual()

# --- LOGIKA UPDATE VISUAL HIGHLIGHT ---
func update_highlight_visual() -> void:
	var slots = grid_container.get_children()
	
	for i in range(slots.size()):
		if i == current_index:
			slots[i].set_highlight(true) # Nyalakan border kuning
		else:
			slots[i].set_highlight(false)

# --- LOGIKA INPUT KEYBOARD ---
func _input(event: InputEvent) -> void:
	if not visible: return
	
	if event.is_action_pressed("ui_right"):
		move_selection(1)
	elif event.is_action_pressed("ui_left"):
		move_selection(-1)
	elif event.is_action_pressed("ui_down"):
		move_selection(COLUMNS) 
	elif event.is_action_pressed("ui_up"):
		move_selection(-COLUMNS) 
	elif event.is_action_pressed("ui_accept"): 
		select_current_slot()

func move_selection(step: int) -> void:
	var new_index = current_index + step
	if new_index >= 0 and new_index < inventory_data.size():
		current_index = new_index
		update_highlight_visual()

# --- LOGIKA SELECT ITEM (DARI KEYBOARD) ---
func select_current_slot() -> void:
	var item_data = inventory_data[current_index]
	_process_selection(item_data, current_index)
	emit_signal("request_close_inventory")

# --- LOGIKA SELECT ITEM (DARI MOUSE KLIK) ---
func _on_slot_clicked(item_data, index_slot):
	# Update current_index agar sinkron dengan keyboard
	current_index = index_slot
	update_highlight_visual()
	
	_process_selection(item_data, index_slot)

# --- FUNGSI PROSES UMUM ---
func _process_selection(item_data, index):
	if item_data:
		print("Memilih item: ", item_data["name"], " di Slot: ", index)
		if item_slot_hud:
			item_slot_hud.texture = item_data["icon"]
		player.select_consumable(item_data, index)
	else:
		print("Slot kosong!")

# --- DATA HANDLING ---
func remove_item_at_index(index: int) -> void:
	if index >= 0 and index < inventory_data.size():
		inventory_data[index] = null
		update_inventory_ui()
		update_highlight_visual() 

func get_save_data() -> Array:
	var save_array = []
	for item in inventory_data:
		if item == null: save_array.append(null)
		else: save_array.append(item["id"])
	return save_array

func load_save_data(saved_array: Array) -> void:
	inventory_data = []
	inventory_data.resize(16)
	for i in range(saved_array.size()):
		var item_id = saved_array[i]
		if item_id != null and all_items.has(item_id):
			inventory_data[i] = all_items[item_id]
		else:
			inventory_data[i] = null
	update_inventory_ui()
