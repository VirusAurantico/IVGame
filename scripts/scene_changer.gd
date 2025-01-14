extends CanvasLayer

signal scene_changed()

onready var animation_player = $AnimationPlayer
onready var black = $Control/Black

func change_scene(path, delay = 0.5):
	yield(get_tree().create_timer(delay), "timeout")
	animation_player.play("fade")
	yield(animation_player, "animation_finished")
	if (get_tree().change_scene(path) == OK):
		animation_player.play_backwards("fade")
		yield(animation_player, "animation_finished")
		emit_signal("scene_changed")
