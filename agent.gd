extends Node2D

@onready var ship = get_parent()
@onready var debug_path : Line2D = ship.get_node('../debug_path')

var ticks = 0
var spin = 0
var thrust = false

# This method is called on every tick to choose an action.  See README.md
# for a detailed description of its arguments and return value.
func action(_walls: Array[PackedVector2Array], _gems: Array[Vector2], 
			_polygons: Array[PackedVector2Array], _neighbors: Array[Array]):

	# This is a dummy agent that just moves around randomly.
	# Replace this code with your actual implementation.
	ticks += 1
	if ticks % 30 == 0:
		spin = Random.randi_range(-1, 1)
		thrust = bool(Random.randi_range(0, 1))
	
	var containing_polygon:int = find_containing_polygon(_polygons, self.global_position)
	print("Pos: {0} -> polygon {1}".format([self.global_position, find_containing_polygon(_polygons, self.global_position)]))
	
	debug_path.clear_points()
	if(containing_polygon >= 0):
		for p in _polygons[containing_polygon]: debug_path.add_point(p)
		debug_path.add_point(_polygons[containing_polygon][0])
	
	return [spin, thrust, false]


func find_containing_polygon(polygons: Array[PackedVector2Array], point: Vector2)->int:
	var i:int = 0
	while i < polygons.size():
		if polygon_contains_point(polygons[i], point):
			return i
		i+=1
	return -1

func polygon_contains_point(polygon : PackedVector2Array, point: Vector2)->bool:
	var i : int = 0
	while i < polygon.size():
		var a := polygon[i]
		var b := polygon[(i+1) % polygon.size()]
		var c := polygon[(i+2) % polygon.size()]
		var normal := get_orthogonal(b-a)
		var reference_dir = c-b
		var dir_to_point = point - b
		if(sign(normal.dot(reference_dir)) != sign(normal.dot(dir_to_point))):
			return false
		i+=1
	return true


func get_orthogonal(v:Vector2)->Vector2:
	return Vector2(-v.y, v.x)

# Called every time the agent has bounced off a wall.
func bounce():
	return

# Called every time a gem has been collected.
func gem_collected():
	return

# Called every time a new level has been reached.
func new_level():
	return
