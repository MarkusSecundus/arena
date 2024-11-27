class_name ArenaAgent
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


class AgentActionContext:
    var walls : Array[PackedVector2Array]
    var gems : Array[Vector2]
    var polygons: Array[PackedVector2Array]
    var neighbors : Array[PackedInt32Array]
    var gems_to_polygons : PackedInt32Array
    var polygons_to_gems : Array[PackedInt32Array]
    
    func _init(walls: Array[PackedVector2Array], gems: Array[Vector2], polygons: Array[PackedVector2Array], neighbors: Array[Array]) -> void:
        self.walls = walls
        self.gems = gems
        self.polygons = polygons
        self.neighbors = []
        for n in neighbors: self.neighbors.append(PackedInt32Array(n))
        self.gems_to_polygons = ArenaAgent.map_gems_to_polygons(gems, polygons)
        self.polygons_to_gems = ArenaAgent.map_polygons_to_gems(gems_to_polygons, polygons)

# This method is called on every tick to choose an action.  See README.md
# for a detailed description of its arguments and return value.
func action(walls: Array[PackedVector2Array], gems: Array[Vector2], polygons: Array[PackedVector2Array], neighbors: Array[Array]):

    var ctx := AgentActionContext.new(walls, gems, polygons, neighbors)
    
    var containing_polygon:int = find_containing_polygon(polygons, ship_position)
    
    debug_path.clear_points()
    
    var path:= find_path_to_nearest_gem(ctx)
    debug_path.add_point(ship_position)
    for segment in path: debug_path.add_point(segment)
    return steer_to_destination(path[0])




class SimpleArenaProblem:
    extends AStar.HeuristicProblem
    var _ctx : AgentActionContext
    var _initial_position : Vector2
    func _init(initial_position:Vector2, ctx:AgentActionContext) -> void:
        _initial_position = initial_position
        _ctx = ctx

    func initial_state():
        for tolerance in [0, 0.01, 0.05, 0.1, 0.15]:
            var ret := ArenaAgent.find_containing_polygon(_ctx.polygons, _initial_position, tolerance)
            if ret >= 0 : return ret
        return 0
    
    func actions(state:int)->Array:
        return _ctx.neighbors[state]
    func cost(state:int, action:int)->float: return 1
    func result(state, action):return action
    func estimate(state:int)->float:
        # we are basically just using aStar to get behavior of bfs (ofc there was an attempt to do a proper aStar, but it didn't work in practice nearly as well as this simplistic approach) 
        if _ctx.polygons_to_gems[state].size() > 0: return 0 # we reached a polygon that contains some gems
        return 0.1 # must be non-zero - estimate=0 is interpreted as sign that we reached the goal state 


func find_path_to_nearest_gem(ctx :AgentActionContext)->PackedVector2Array:
    var arena_problem:= SimpleArenaProblem.new(ship_position, ctx)
    var solution:= AStar.run_astar(arena_problem)
    if ! solution:
        print("NO SOLUTION!")
        return [get_min(ctx.gems, func(gem:Vector2)->float: return ship_position.distance_squared_to(gem))]
    
    var ret:= PackedVector2Array()
    var pos:= ship_position
    for poly in solution.actions_sequence:
        var new_pos :Vector2= Util.get_closest_point_on_polygon(pos, ctx.polygons[poly])
        if pos.distance_squared_to(new_pos) < (ship.RADIUS*1.4)**2: continue
        ret.append(new_pos)
        pos=new_pos
    var end_polygon :int= arena_problem.initial_state() if solution.actions_sequence.is_empty() else solution.actions_sequence[solution.actions_sequence.size()-1]
    var nearest_gem : int = get_min(ctx.polygons_to_gems[end_polygon], func(gem:int)->float: return ship_position.distance_squared_to(ctx.gems[gem]))
    ret.append( ctx.gems[nearest_gem])
    
    return ret



func steer_to_destination(destination: Vector2):
    
    var distance := destination - ship_position
    var velocity_distance := distance - ship_velocity
    var target_rotation := atan2(velocity_distance.y, velocity_distance.x)
    var rotation_distance := normalize_radians(target_rotation - ship_rotation)
    print("rotation_distance: {0}".format([rotation_distance/PI*180]))
    
    return make_action(sign(rotation_distance), abs(rotation_distance) < 0.2)

static func normalize_radians(rad: float)->float:
    const PI_DOUBLE = PI*2
    rad = fmod(rad, PI_DOUBLE)
    if rad > PI: rad -= PI_DOUBLE
    elif rad < -PI: rad += PI_DOUBLE
    return rad

static func make_action(spin: int, thrust: bool, shoot:bool = true)->Array:
    return [spin, thrust, shoot]

static func report_error(message: String)->void:
    print("ERROR: " + message)
    push_error(message)
    


static func map_polygons_to_gems(gems_to_polygons: PackedInt32Array, polygons: Array[PackedVector2Array])->Array[PackedInt32Array]:
    var ret : Array[PackedInt32Array] = []
    for i in range(polygons.size()): ret.append(PackedInt32Array())
    for g in range(gems_to_polygons.size()):
        var p := gems_to_polygons[g]
        if p < 0: report_error("gem {0} not in any polygon".format([g]))
        else: ret[p].append(g)
    return ret
static func map_gems_to_polygons(gems: Array[Vector2], polygons: Array[PackedVector2Array])->PackedInt32Array:
    var ret : PackedInt32Array = []
    for gem in gems: ret.append(find_containing_polygon(polygons, gem))
    return ret


static func find_containing_polygon(polygons: Array[PackedVector2Array], point: Vector2, tolerance :float = 0.0)->int:
    var i:int = 0
    while i < polygons.size():
        if polygon_contains_point(polygons[i], point, tolerance):
            return i
        i+=1
    return -1
    
static func find_containing_polygons( out_found_polygons:PackedInt32Array, polygons: Array[PackedVector2Array], point: Vector2, tolerance :float = 0.0)->void:
    out_found_polygons.clear()
    var i:int = 0
    while i < polygons.size():
        if polygon_contains_point(polygons[i], point, tolerance):
            out_found_polygons.append(i)
        i+=1
        

static func polygon_contains_point(polygon : PackedVector2Array, point: Vector2, tolerance :float = 0.0)->bool:
    var i : int = 0
    while i < polygon.size():
        var a := polygon[i]
        var b := polygon[(i+1) % polygon.size()]
        var c := polygon[(i+2) % polygon.size()]
        var normal := get_orthogonal(b-a).normalized()
        var reference_dir = (c-b).normalized()
        var dir_to_point = (point - b).normalized()
        if not (sign(normal.dot(reference_dir)) == sign(normal.dot(dir_to_point)) or abs(normal.dot(dir_to_point)) < tolerance):
            return false
        i+=1
    return true

static func get_min(items: Array, estimate_selector: Callable):
    var min_estimate :float= INF
    var min_item = null
    for item in items:
        var current_estimate :float= estimate_selector.call(item)
        if current_estimate < min_estimate:
            min_estimate = current_estimate
            min_item = item
    return min_item

static func get_orthogonal(v:Vector2)->Vector2:
    return Vector2(-v.y, v.x)


func bounce():
    return

# Called every time a gem has been collected.
func gem_collected():
    return

# Called every time a new level has been reached.
func new_level():
    return
