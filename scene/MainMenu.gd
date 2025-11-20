extends Node2D

var button_type = null

func _ready():
	pass	


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Playground.tscn")

func _on_continue_pressed() -> void:
	pass # Replace with function body.

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_exit_pressed() -> void:
	pass # Replace with function body.
