class_name Blood
extends AnimatedSprite3D


func _ready() -> void:
	await get_tree().create_timer(0.25).timeout
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0, 1.0)
	await tween.finished
	queue_free()
