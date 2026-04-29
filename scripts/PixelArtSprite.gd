class_name PixelArtSprite
extends Node2D

@export var texture_path := ""
@export var art_scale := 1.0

@onready var art: Sprite2D = get_node_or_null("Art")


func _ready() -> void:
	_apply_external_art()


func _apply_external_art() -> void:
	if art == null or texture_path.is_empty():
		return
	var texture := load(texture_path) as Texture2D
	if texture == null:
		return
	art.texture = texture
	art.centered = true
	art.scale = Vector2.ONE * art_scale
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
