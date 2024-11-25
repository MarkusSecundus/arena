extends Node2D

@onready var ship = get_parent()
@onready var debug_path : Line2D = ship.get_node('../debug_path')

var ship_position: Vector2:
	get: return ship.global_position
var ship_velocity: Vector2:
	get: return ship.velocity
var ship_rotation: float:
	get: return ship.rotation
	
var ticks = 0
var spin = 0
var thrust = false

# This method is called on every tick to choose an action.  See README.md
# for a detailed description of its arguments and return value.
func action(walls: Array[PackedVector2Array], gems: Array[Vector2], 
			polygons: Array[PackedVector2Array], neighbors: Array[Array]):

	# This is a dummy agent that just moves around randomly.
	# Replace this code with your actual implementation.
	ticks += 1
	if ticks % 30 == 0:
		spin = Random.randi_range(-1, 1)
		thrust = bool(Random.randi_range(0, 1))
	
	var containing_polygon:int = find_containing_polygon(polygons, ship_position)
	
	
	debug_path.clear_points()
	if(containing_polygon >= 0):
		add_polygon_to_path(polygons[containing_polygon])
	
	return steer_to_destination(gems[0])

func _ready() -> void:
	
	var heap := BinaryHeap.new(func(a:int, b:int): return b-a)
	
	for i in range(10000):
		heap.push(Random.randi_range(0, 9999))
	
	var last :int = 99999
	while heap.size() > 0:
		var num:int = heap.pop()
		if num > last: print("ERROR: {0} > {1}".format([num, last]))
		last = num
	print("finished!")
		
	

class BinaryHeap:
	var _data : Array
	var _comparator : Callable
	
	func _init(comparator : Callable) -> void:
		_data = []
		_comparator = comparator
	
	static func _swap(array : Array, i :int, j:int)->void:
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
	
	func _bubble_up(i:int)->int:
		while i != 0:
			var parent :int = int(floor((i-1) / 2))
			if _comparator.call(_data[i], _data[parent]) >= 0: 
				break
			_swap(_data, i, parent)
			i = parent
		return i
	func _bubble_down(i:int)->int:
		while 2*i + 1 < _data.size():
			var son1 :int = 2*i + 1
			var son2 :int = 2*i + 2
			var chosen_son = son1 if (son2 >= _data.size() || _comparator.call(_data[son1], _data[son2]) <= 0) else son2
			_swap(_data, i, chosen_son)
			i = chosen_son
		return i
	
	
	func size()->int:
		return _data.size()
		
	func peek():
		return _data[0]
		
	func pop():
		var ret = _data[0]
		var i :=_bubble_down(0)
		if i != (_data.size() - 1):
			_data[i] = _data[_data.size()-1]
			_bubble_up(i)
		_data.remove_at(_data.size()-1)
		return ret 
		
	func push(item)->void:
		# add to the bottom and bubble up
		_data.append(item)
		
		_bubble_up(_data.size() - 1)
		


func steer_to_destination(destination: Vector2):
	
	debug_path.clear_points()
	debug_path.add_point(ship_position)
	debug_path.add_point(destination)
	
	var trajectory := destination - ship_position
	var target_rotation := atan2(trajectory.y, trajectory.x)
	var rotation_distance := target_rotation - ship_rotation
	
	return make_action(sign(rotation_distance), true)

func get_polygons_to_gems(gems: Array[Vector2], polygons: Array[PackedVector2Array])->Array[PackedInt32Array]:
	var ret : Array[PackedInt32Array] = []
	for gem in gems:
		var poly := find_containing_polygon(polygons, gem)
		if poly < 0: push_error("A gem is outside the navmesh!")
		ret
	return ret
			


func make_action(spin: int, thrust: bool, shoot:bool = false)->Array:
	return [spin, thrust, shoot]


func add_polygon_to_path(polygon : PackedVector2Array):
		for p in polygon: debug_path.add_point(p)
		debug_path.add_point(polygon[0])

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
