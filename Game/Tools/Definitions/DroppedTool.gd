extends PhysicalObject

class_name DroppedTool

var tool: Tool
 
func set_tool(new_tool):
	tool = new_tool
	$Sprite2D.texture = tool.get_tool_texture()

func get_tool():
	return tool
