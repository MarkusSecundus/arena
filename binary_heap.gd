
class_name BinaryHeap

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
        if _comparator.call(_data[i], _data[chosen_son]) < 0 : 
            break
        _swap(_data, i, chosen_son)
        i = chosen_son
    return i


func size()->int:
    return _data.size()
    
func peek():
    return _data[0]
    
func pop():
    var ret = _data[0]
    _data[0] = _data[_data.size()-1]
    _data.remove_at(_data.size()-1)
    _bubble_down(0)
    return ret 
    
func push(item)->void:
    # add to the bottom and bubble up
    _data.append(item)
    
    _bubble_up(_data.size() - 1)
    
