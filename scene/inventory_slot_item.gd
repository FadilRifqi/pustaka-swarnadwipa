extends TextureRect

signal slot_clicked(item_data)

@onready var icon_visual: TextureRect = $Icon # Atau Sprite2D, sesuaikan node kamu

var my_item_data = null

func _ready():
	# Agar bisa diklik, TextureRect harus ubah mouse filter
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_item(data):
	my_item_data = data
	
	if data:
		icon_visual.texture = data["icon"]
		icon_visual.visible = true
	else:
		icon_visual.visible = false

# Deteksi Klik Mouse
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if my_item_data:
			# Kirim sinyal ke Inventory utama bahwa slot ini diklik
			slot_clicked.emit(my_item_data)
