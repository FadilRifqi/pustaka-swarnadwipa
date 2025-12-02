extends ParallaxBackground

@onready var sprite = $ParallaxLayer/Sprite2D # Sesuaikan path

func _ready():
	# Ambil ukuran layar
	var viewport_size = get_viewport().get_visible_rect().size
	# Ambil ukuran gambar
	var texture_size = sprite.texture.get_size()

	# Hitung scale yang dibutuhkan
	# (Pilih mau fit X atau Y, atau max keduanya seperti Keep Aspect Covered)
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	var final_scale = max(scale_x, scale_y)

	sprite.scale = Vector2(final_scale, final_scale)
