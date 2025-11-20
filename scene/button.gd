extends Button

@onready var spr1 = $Sprite2D
@onready var spr2 = $Sprite2D2

func _ready():
	# Sembunyikan sprite saat awal
	spr1.hide()
	spr2.hide()
	
	# Koneksi signal
	connect("mouse_entered", _on_hover)
	connect("mouse_exited", _on_unhover)
	connect("pressed", _on_hover) # biar muncul saat aktif

func _on_hover():
	spr1.show()
	spr2.show()

func _on_unhover():
	# Hanya hilang jika tidak sedang ditekan
	if not button_pressed:
		spr1.hide()
		spr2.hide()
