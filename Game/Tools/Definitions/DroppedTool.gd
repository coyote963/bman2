extends PhysicalObject

class_name DroppedTool

var tool: Tool
 
func set_tool(tool):
	tool = tool
	$Sprite2D.texture = tool.get_tool_texture()
