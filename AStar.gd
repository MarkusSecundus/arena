class_name AStar
"""
Implementation of full-fledged AStar algorithm, although in practice it's used mostly just as glorified BFS.
I was lazy so I pretty much just copypasted the implementation that I wrote and tested last year for Artifical Inteligence 1. 
"""

class AStarSolution:
    var actions_sequence: Array
    var end_state
    var cost: float
    
    func _init(actions_sequence: Array, end_state, cost: float) -> void:
        self.actions_sequence = actions_sequence
        self.end_state = end_state
        self.cost = cost
    
class HeuristicProblem:
    func initial_state():return null
    func actions(state)->Array:return []
    func cost(state, action)->float: return 0
    func result(state, action):return null
    func estimate(state)->float:return 0

class AStarNode:
    var last : AStarNode
    var action
    var state
    var cost: float
    var estimated_cost: float

    func _init(last: AStarNode, action, state, cost: float, estimated_cost:float) -> void:
        self.last = last
        self.action = action
        self.state = state
        self.cost = cost
        self.estimated_cost = estimated_cost

    static func less_then(a: AStarNode, b: AStarNode)->bool: return a.estimated_cost < b.estimated_cost

    func as_solution()->AStarSolution:
        var path :Array= []
        var node := self
        while node.last != null:
            path.append(node.action)
            node = node.last
        path.reverse()
        return AStarSolution.new(path, self.state, self.cost)

    static func make_empty(initial_state, estimate: float)->AStarNode: 
        return AStarNode.new(null,null, initial_state, 0, estimate);

    func make_next(action, state, added_cost:float, estimate: float)->AStarNode:
        return AStarNode.new(self, action, state, self.cost + added_cost, self.cost + added_cost + estimate);


static func run_astar(prob: HeuristicProblem) -> AStarSolution:
    """Return Solution of the problem solved by AStar search."""

    var initial_state= prob.initial_state()
    var initial_node := AStarNode.make_empty(initial_state, prob.estimate(initial_state))

    var queue := BinaryHeap.new(AStarNode.less_then)
    queue.push(initial_node)
    var already_visited :Dictionary = {initial_state:initial_node}

    while queue.size() > 0:
        var current := queue.pop() as AStarNode;
        var state = current.state
        if prob.estimate(state) <= 0.0:
            return current.as_solution()
        for action in prob.actions(state):
            var cost := prob.cost(state, action)
            var total_cost := current.cost + cost
            var result_state = prob.result(state, action)
            if not (result_state in already_visited) or already_visited[result_state].cost > total_cost:
                var new_node := current.make_next(action, result_state, cost, prob.estimate(result_state))
                already_visited[result_state] = new_node;
                queue.push(new_node)
    return null
