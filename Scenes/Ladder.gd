extends Area2D


# Refactor this is terrible

func _on_body_entered(body):
	print(body)
	if body.is_in_group("CanClimb"):
		if not body.climbing:
			body.climbing = true

func _on_body_exited(body):
	if body.is_in_group("CanClimb"):
		if body.climbing:
			body.climbing = false
