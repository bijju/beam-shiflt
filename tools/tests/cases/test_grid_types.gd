extends TestCase


func test_reflect_table() -> void:
	eq(GridTypes.reflect(GridTypes.Direction.RIGHT, GridTypes.MirrorOrientation.SLASH), GridTypes.Direction.UP)
	eq(GridTypes.reflect(GridTypes.Direction.RIGHT, GridTypes.MirrorOrientation.BACKSLASH), GridTypes.Direction.DOWN)
