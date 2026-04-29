@tool
class_name SpaceStation
extends Node2D


func _draw() -> void:
	var frame := Color("d7e4f2")
	var accent := Color("8fd0ff")
	var core := Color("5d7ea1")
	draw_rect(Rect2(Vector2(-6, -6), Vector2(12, 12)), frame)
	draw_rect(Rect2(Vector2(-18, -3), Vector2(12, 6)), accent)
	draw_rect(Rect2(Vector2(6, -3), Vector2(12, 6)), accent)
	draw_rect(Rect2(Vector2(-3, -10), Vector2(6, 4)), accent)
	draw_rect(Rect2(Vector2(-3, 6), Vector2(6, 4)), accent)
	draw_rect(Rect2(Vector2(-3, -3), Vector2(6, 6)), core)
