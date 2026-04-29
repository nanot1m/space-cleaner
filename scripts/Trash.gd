@tool
class_name OrbitTrash
extends Node2D

var velocity := Vector2.ZERO
var is_cargo := false


func _draw() -> void:
	draw_rect(Rect2(Vector2(-3, -3), Vector2(6, 6)), Color("aeb7c2"))
	draw_rect(Rect2(Vector2(-1, -5), Vector2(3, 2)), Color("d5dce6"))
	draw_rect(Rect2(Vector2(-5, 1), Vector2(3, 2)), Color("6d7783"))
	if is_cargo:
		draw_rect(Rect2(Vector2(-6, -7), Vector2(12, 1)), Color(1, 1, 1, 0.45))
