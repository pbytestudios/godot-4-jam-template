class_name ObservableArray
extends Observable

var value : Array:
	set(v):
		value = v
		_propagate()
		return value

func _init(val : Array = []) -> void:
	value = val

func get_at(i : int) -> Variant:
	return value[i]

func set_at(i : int, v : Variant) -> void:
	value[i] = v
	_propagate()

func append(v : Variant) -> void:
	value.append(v)
	_propagate()

func append_array(array : Array) -> void:
	value.append_array(array)
	_propagate()

func assign(array : Array) -> void:
	value.assign(array)
	_propagate()

func clear() -> void:
	value.clear()
	_propagate()

func erase(v : Variant) -> void:
	value.erase(v)
	_propagate()

func insert(position : int, v : Variant) -> void:
	value.insert(position, v)
	_propagate()

func pop_at(index : int) -> Variant:
	var tmp = value.pop_at(index)
	_propagate()
	return tmp

func pop_back() -> Variant:
	var tmp = value.pop_back()
	_propagate()
	return tmp

func pop_front() -> Variant:
	var tmp = value.pop_front()
	_propagate()
	return tmp

func push_back(v : Variant) -> void:
	append(v)

func remove_at(index : int) -> void:
	value.remove_at(index)
	_propagate()

func shuffle() -> void:
	value.shuffle()
	_propagate()

func sort() -> void:
	value.sort()
	_propagate()

func sort_custom(callable : Callable) -> void:
	value.sort_custom(callable)
	_propagate()
