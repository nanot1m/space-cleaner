class_name Astronaut
extends Node2D

const HFRAMES := 14
const VFRAMES := 4
const FRAME_RATE := 8.0

const ROW_FRAME_COUNTS := [4, 14, 9, 7]

var _anim_row := 0
var _frame := 0
var _anim_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = load("res://assets/sprites/Astronaut-Sheet.png")
	sprite.hframes = HFRAMES
	sprite.vframes = VFRAMES
	sprite.frame = 0


func set_anim_row(row: int) -> void:
	_anim_row = clampi(row, 0, ROW_FRAME_COUNTS.size() - 1)
	_frame = 0
	_anim_timer = 0.0
	sprite.frame = _anim_row * HFRAMES


func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 1.0 / FRAME_RATE:
		_anim_timer -= 1.0 / FRAME_RATE
		_frame = (_frame + 1) % ROW_FRAME_COUNTS[_anim_row]
		sprite.frame = _anim_row * HFRAMES + _frame
