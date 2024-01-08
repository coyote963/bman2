extends Camera2D


const Dead_Zone = 60


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var _target = event.position - get_viewport().size * 0.5
		if _target.length() < Dead_Zone:
			self.position = Vector2(0,0)
		else:
			self.position = _target.normalized() * (_target.length() -  Dead_Zone) * 0.5
	
