extends Node

class_name Brain, "brain.png"

enum { SUCCESS, FAILURE, RUNNING }

enum METHOD { PROCESS, PHYSICAL_PROCESS }

# ------------------------------------------------------------------------------

onready var actor:Actor = get_parent()
onready var sequence: = make_sequence()
onready var data: = BTData.new()

export (METHOD) var method = METHOD.PHYSICAL_PROCESS

export (bool) var enabled: = true

func enable() -> void:
	enabled = true

func disable() -> void:
	enabled = false
	
func _ready() -> void:
	data.set_actor(actor)
	data.set_brain(self)

func _process(delta: float) -> void:
	if method == METHOD.PROCESS:
		_tick(delta)

func _physics_process(delta:float) -> void:
	if method == METHOD.PHYSICAL_PROCESS:
		_tick(delta)

func _tick(delta:float) -> void:
	data.set_delta(delta)
	if enabled:
		sequence.tick(data)

# ------------------------------------------------------------------------------

class BTData:
	
	const P_ACTOR = "_actor"
	const P_BRAIN = "_brain"
	const P_DELTA = "_delta"

	var params = {}
	
	func has(key) -> bool:
		return params.has(key)

	func erase(key) -> void:
		if params.has(key):
			params.erase(key)

	func get(key):
		if has(key):
			return params[key]
		return null
	
	func get_delta() -> float:
		return get(P_DELTA) as float
	
	func get_actor():
		return get(P_ACTOR)
	
	func get_brain() -> Brain:
		return get(P_BRAIN) as Brain
	
	func set(key, value):
		params[key] = value
	
	func set_delta(delta:float) -> void:
		set(P_DELTA, delta)
	
	func set_actor(actor) -> void:
		set(P_ACTOR, actor)
	
	func set_brain(brain:Brain) -> void:
		set(P_BRAIN, brain)

# ------------------------------------------------------------------------------

class BTNode:
	
	enum { SUCCESS, FAILURE, RUNNING }

	func tick(data:BTData) -> int:
		return SUCCESS

# ------------------------------------------------------------------------------
# COMPOSITES
# ------------------------------------------------------------------------------

class BTComposite:
	
	extends BTNode

	var _childs: = []

	func has_childs() -> bool:
		return _childs.size() > 0

	func get_childs() -> Array:
		return _childs

	func get_child(id:int) -> BTNode:
		assert(id >= 0 and id < _childs.size(), "Child index not found")
		return _childs[id]
	
	func add(node:BTNode) -> BTNode:
		if node != null:
			_childs.append(node)
		return node
	
	func add_sequence() -> BTSequence:
		return add(BTSequence.new()) as BTSequence
	
	func add_sequence_random() -> BTSequenceRandom:
		return add(BTSequenceRandom.new()) as BTSequenceRandom
	
	func add_selector() -> BTSelector:
		return add(BTSelector.new()) as BTSelector
	
	func add_selector_random() -> BTSelectorRandom:
		return add(BTSelectorRandom.new()) as BTSelectorRandom
	
	func add_repeater() -> BTRepeater:
		return add(BTRepeater.new()) as BTRepeater

	func add_parallel(required_to_failure:int = 1, required_to_success:int = 1) -> BTParallel:
		return add(BTParallel.new(required_to_failure, required_to_success)) as BTParallel
	
	func add_failer() -> BTFailer:
		return add(BTFailer.new()) as BTFailer
	
	func add_succeeder() -> BTSucceeder:
		return add(BTSucceeder.new()) as BTSucceeder
	
	func add_inverter() -> BTInverter:
		return add(BTInverter.new()) as BTInverter
	
	func add_limiter(max_count:int) -> BTLimiter:
		return add(BTLimiter.new(max_count)) as BTLimiter
	
	func add_action(callback:String, owner = null) -> BTAction:
		return add(BTAction.new(callback, owner)) as BTAction
	
	func add_action_with_data(callback:String, owner = null) -> BTActionWithData:
		return add(BTActionWithData.new(callback, owner)) as BTActionWithData
	
	func add_wait(seconds:float) -> BTWait:
		return add(BTWait.new(seconds)) as BTWait
	
	func add_wait_random(seconds_min:float, seconds_max:float) -> BTWaitRandom:
		return add(BTWaitRandom.new(seconds_min, seconds_max)) as BTWaitRandom
	
	func add_print(value) -> BTPrint:
		return add(BTPrint.new(value)) as BTPrint
	
	func add_data_assert(key) -> BTDataAssert:
		return add(BTDataAssert.new(key)) as BTDataAssert
	
	func add_data_cleaner(key) -> BTDataCleaner:
		return add(BTDataCleaner.new(key)) as BTDataCleaner
	
	func add_data_setter(key, value) -> BTDataSetter:
		return add(BTDataSetter.new(key, value)) as BTDataSetter
	
# ------------------------------------------------------------------------------

class BTSequence:
	
	extends BTComposite

	func tick(data:BTData):
		for c in get_childs():
			var result = c.tick(data)
			if result != SUCCESS:
				return result
		return SUCCESS

# ------------------------------------------------------------------------------

class BTSequenceRandom:
	
	extends BTSequence

	func get_childs() -> Array:
		var childs = _childs
		childs.shuffle()
		return childs

# ------------------------------------------------------------------------------

class BTSelector:
	
	extends BTComposite

	func tick(data:BTData):
		for c in get_childs():
			var result = c.tick(data)
			if result != FAILURE:
				return result
		return FAILURE

# ------------------------------------------------------------------------------

class BTSelectorRandom:
	
	extends BTSelector

	func get_childs() -> Array:
		var childs = _childs
		childs.shuffle()
		return childs

# ------------------------------------------------------------------------------

class BTRepeater:
	
	extends BTComposite
	
	func tick(data:BTData):
		for c in get_childs():
			var result = c.tick(data)
			if result == FAILURE:
				return FAILURE
		return RUNNING

# ------------------------------------------------------------------------------

class BTParallel:
	
	extends BTComposite
	
	var _required_to_failure:int
	var _required_to_success:int
	
	func _init(required_to_failure:int = 1, required_to_success:int = 1):
		_required_to_failure = max(1, required_to_failure)
		_required_to_success = max(1, required_to_success)
	
	func tick(data:BTData):
		
		var children_suceess = 0
		var children_failure = 0
		
		for c in get_childs():
			var result = c.tick(data)
			if result == SUCCESS: children_suceess += 1
			if result == FAILURE: children_failure += 1
		
		if children_suceess >= _required_to_success:
			return SUCCESS
		
		if children_failure >= _required_to_failure:
			return FAILURE
			
		return RUNNING

# ------------------------------------------------------------------------------
# DECORATORS
# ------------------------------------------------------------------------------

class BTDecorator:
	
	extends BTComposite

# ------------------------------------------------------------------------------

class BTFailer:
	
	extends BTDecorator

	func tick(data:BTData) -> int:
		for c in get_childs():
			var result = c.tick(data)
			if result == RUNNING: return RUNNING
			return FAILURE
		return SUCCESS

# ------------------------------------------------------------------------------

class BTSucceeder:
	
	extends BTDecorator

	func tick(data:BTData) -> int:
		for c in get_childs():
			var result = c.tick(data)
			if result == RUNNING: return RUNNING
			return SUCCESS
		return SUCCESS

# ------------------------------------------------------------------------------

class BTInverter:
	
	extends BTDecorator

	func tick(data:BTData) -> int:
		for c in get_childs():
			var result = c.tick(data)
			if result == SUCCESS: return FAILURE
			if result == FAILURE: return SUCCESS
			return RUNNING
		return SUCCESS

# ------------------------------------------------------------------------------

class BTLimiter:
	
	extends BTDecorator

	onready var data_key = 'limiter_%s' % self.get_instance_id()

	export (float) var limit = 0

	func _init(max_count:int) -> void:
		limit = max_count

	func tick(data:BTData) -> int:
		
		var count = data.get(data_key)

		if count == null:
			count = 0

		if count < limit:
			data.set(data_key, count + 1)
			for c in get_childs():
				var result = c.tick(data)
				if result != SUCCESS:
					return result
		else:
			return FAILED
		
		return SUCCESS

# ------------------------------------------------------------------------------
# LEAFS
# ------------------------------------------------------------------------------

class BTLeaf:
	
	extends BTNode

# ------------------------------------------------------------------------------

class BTAction:
	
	extends BTLeaf

	var _callback = ""
	var _owner = null

	func _init(callback:String, owner = null) -> void:
		_owner = owner
		_callback = callback

	func tick(data:BTData):
		var owner = data.get_actor() if _owner == null else _owner
		assert(owner.has_method(_callback), "Actor must have [ %s ] method" % _callback)
		var result = _execute(owner, _callback, data)
		if result is int: return result
		return SUCCESS
	
	func _execute(owner, callback, data:BTData):
		return owner.call(callback)

# ------------------------------------------------------------------------------

class BTActionWithData:
	
	extends BTAction
	
	func _init(callback:String, owner = null).(callback, owner) -> void:
		pass

	func _execute(owner, callback, data:BTData):
		return owner.call(callback, data)

# ------------------------------------------------------------------------------

class BTWait:
	
	extends BTLeaf

	var _seconds:float

	onready var data_key = 'wait_%s' % self.get_instance_id()

	func _init(seconds:int) -> void:
		_seconds = seconds

	func tick(data:BTData):
		
		var time = OS.get_ticks_msec()
		
		if !data.has(data_key):
			data.set(data_key, time)
			return RUNNING
		
		var prev_time = data.get(data_key)
		var diff_time = time - prev_time
		
		if diff_time >= _seconds * 1000:
			data.erase(data_key)
			return SUCCESS
		
		return RUNNING

# ------------------------------------------------------------------------------

class BTWaitRandom:
	
	extends BTLeaf

	onready var data_key = 'wait_random_%s' % self.get_instance_id()

	var _seconds:float = 1
	var _seconds_min:float = 1
	var _seconds_max:float = 2

	func _init(seconds_min:float, seconds_max:float) -> void:
		_seconds_min = seconds_min
		_seconds_max = seconds_max
		_seconds = rand_range(_seconds_min, _seconds_max)

	func tick(data:BTData):
		
		var time = OS.get_ticks_msec()
		
		if !data.has(data_key):
			data.set(data_key, time)
			return RUNNING
		
		var prev_time = data.get(data_key)
		var diff_time = time - prev_time
		
		if diff_time < _seconds * 1000:
			return RUNNING
			
		data.erase(data_key)
		
		_seconds = rand_range(_seconds_min, _seconds_max)
		
		return SUCCESS

# ------------------------------------------------------------------------------

class BTPrint:
	
	extends BTLeaf

	var _value

	func _init(value) -> void:
		_value = value

	func tick(data:BTData):
		
		var actor = data.get_actor()
		var value = _value
		
		if actor.has_method(_value):
			value = actor.call(_value)
		
		print(value as String)
		
		return SUCCESS

# ------------------------------------------------------------------------------

class BTDataAssert:
	
	extends BTLeaf

	var _key

	func _init(key):
		_key = key

	func tick(data:BTData) -> int:
		if data.has(_key):
			return SUCCESS
		return FAILURE

# ------------------------------------------------------------------------------

class BTDataCleaner:
	
	extends BTLeaf

	var _key

	func _init(key):
		_key = key

	func tick(data:BTData) -> int:
		if data.has(_key):
			data.erase(_key)
		return SUCCESS

# ------------------------------------------------------------------------------

class BTDataSetter:
	
	extends BTLeaf

	var _key
	var _value

	func _init(key, value):
		_key = key
		_value = value

	func tick(data:BTData) -> int:
		
		var actor = data.get_actor()
		
		if _value is String and actor.has_method(_value):
			var value = actor.call(_value)
			if value == null:
				return FAILURE
			data.set(_key, value)
			return SUCCESS
			
		if _value == null:
			return FAILURE
		
		data.set(_key, _value)
		
		return SUCCESS

# ------------------------------------------------------------------------------
# FACTORY
# ------------------------------------------------------------------------------

static func make_sequence() -> BTSequence:
	return BTSequence.new()

static func make_sequence_random() -> BTSequenceRandom:
	return BTSequenceRandom.new()

static func make_selector() -> BTSelector:
	return BTSelector.new()

static func make_selector_random() -> BTSelectorRandom:
	return BTSelectorRandom.new()
	
static func make_repeater() -> BTRepeater:
	return BTRepeater.new()

static func make_parallel(required_to_failure:int = 1, required_to_success:int = 1) -> BTParallel:
	return BTParallel.new(required_to_failure, required_to_success)

# ------------------------------------------------------------------------------

static func make_failer() -> BTFailer:
	return BTFailer.new()

static func make_succeeder() -> BTSucceeder:
	return BTSucceeder.new()

static func make_inverter() -> BTInverter:
	return BTInverter.new()

static func make_limiter(max_count:int) -> BTLimiter:
	return BTLimiter.new(max_count)
	
# ------------------------------------------------------------------------------

static func make_action(callback:String, owner = null) -> BTAction:
	return BTAction.new(callback, owner)

static func make_action_with_data(callback:String, owner = null) -> BTActionWithData:
	return BTActionWithData.new(callback, owner)

static func make_wait(seconds:float) -> BTWait:
	return BTWait.new(seconds)

static func make_wait_random(seconds_min:float, seconds_max:float) -> BTWaitRandom:
	return BTWaitRandom.new(seconds_min, seconds_max)

static func make_print(value) -> BTPrint:
	return BTPrint.new(value)

static func make_data_assert(key) -> BTDataAssert:
	return BTDataAssert.new(key)

static func make_data_cleaner(key) -> BTDataCleaner:
	return BTDataCleaner.new(key)

static func make_data_setter(key, value) -> BTDataSetter:
	return BTDataSetter.new(key, value)

# ------------------------------------------------------------------------------
