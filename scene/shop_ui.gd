extends CanvasLayer

@onready var item_list_container: VBoxContainer = $Panel/ScrollContainer/ItemList
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var gold: Sprite2D = $Gold
@onready var label: Label = $Label

# Data Barang Dagangan (ID, Nama, Harga, Icon)
var shop_items = [
	{
		"id": "health_potion",
		"name": "Health Potion",
		"price": 10,
		"type": "consumable"
	},
	{
		"id": "stamina_potion",
		"name": "Stamina Potion",
		"price": 15,
		"type": "consumable"
	}
]

func _ready() -> void:
	visible = false # Sembunyi di awal
	label.text = str(player.money)
	_populate_shop()

func _populate_shop() -> void:
	# Hapus list lama
	for child in item_list_container.get_children():
		child.queue_free()
	
	# Buat tombol untuk setiap item
	for item in shop_items:
		var btn = Button.new()
		btn.text = item["name"] + " - " + str(item["price"]) + " Gold"
		btn.custom_minimum_size.y = 40
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Hubungkan sinyal klik
		btn.pressed.connect(_on_buy_item.bind(item))
		
		item_list_container.add_child(btn)

func open_shop():
	visible = true
	update_money_display()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func update_money_display() -> void:
	if player:
		label.text = str(player.money)
	else:
		label.text = str(0)

func close_shop():
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_close_btn_pressed() -> void:
	close_shop()

func _on_buy_item(item_data):
	print("tes")
	if not player: return
	
	# 1. Cek Uang Cukup?
	if player.money >= item_data["price"]:
		
		# 2. Logika Beli Berdasarkan Tipe
		if item_data["type"] == "consumable":
			# Tambah ke inventory (Pastikan fungsi add_item ada di script inventory kamu)
			var added = player.inventory_item.add_item_by_id(item_data["id"])
			if added:
				player.add_money(-item_data["price"]) # Kurangi uang
				print("Membeli ", item_data["name"])
			else:
				print("Inventory Penuh!")
				
		elif item_data["type"] == "weapon":
			# Cek apakah sudah punya?
			if Global.unlocked_weapons[item_data["id"]] == true:
				print("Sudah punya senjata ini!")
			else:
				Global.unlocked_weapons[item_data["id"]] = true
				player.add_money(-item_data["price"])
				player.check_weapon_unlocks()
				print("Senjata Terbuka!")
	else:
		print("Uang tidak cukup!")
