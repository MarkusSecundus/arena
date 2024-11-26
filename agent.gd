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

    
    var containing_polygon:int = find_containing_polygon(polygons, ship_position)
    print("containing polygon: {0}".format([containing_polygon]))
    
    debug_path.clear_points()
    if(containing_polygon >= 0): add_polygon_to_path(polygons[containing_polygon])
    
    return steer_to_destination(gems[0])

        
    


func steer_to_destination(destination: Vector2):
    
    debug_path.add_point(ship_position)
    debug_path.add_point(destination)
    
    var distance := destination - ship_position
    var velocity_distance := distance - ship_velocity
    var target_rotation := atan2(velocity_distance.y, velocity_distance.x)
    var rotation_distance := target_rotation - ship_rotation
    
    return make_action(sign(rotation_distance), abs(rotation_distance) < 0.1)




func make_action(spin: int, thrust: bool, shoot:bool = false)->Array:
    return [spin, thrust, shoot]

func report_error(message: String)->void:
    push_error(message)
    

func add_polygon_to_path(polygon : PackedVector2Array):
        for p in polygon: debug_path.add_point(p)
        debug_path.add_point(polygon[0])

func map_polygons_to_gems(gems: Array[Vector2], polygons: Array[PackedVector2Array])->Array[PackedInt32Array]:
    var ret : Array[PackedInt32Array] = []
    for i in range(polygons.size()): ret.append([])
    for g in range(gems.size()):
        var p := find_containing_polygon(polygons, gems[g])
        if p < 0: report_error("gem {0} not in any polygon".format([g]))
        else: ret[p].append(g)
    return ret
func map_gems_to_polygons(gems: Array[Vector2], polygons: Array[PackedVector2Array])->PackedInt32Array:
    var ret : PackedInt32Array = []
    for gem in gems: ret.append(find_containing_polygon(polygons, gem))
    return ret


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
