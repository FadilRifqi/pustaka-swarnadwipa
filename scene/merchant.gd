extends Area2D

@onready var label: Label = $Label
@onready var shop_ui = get_tree().root.find_child("ShopUi", true, false)

var player_in_range = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.visible = false

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		if shop_ui:
			shop_ui.open_shop()

func _on_body_entered(body):
	if body is Player:
		print("masuk")
		player_in_range = true
		label.visible = true

func _on_body_exited(body):
	if body is Player:
		player_in_range = false
		label.visible = false
