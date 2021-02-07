# BRAIN

**Behaviour Tree** implementation for **Godot**

## Basic usage

Create a *Brain* node under the actor and extend the *Brain.gd* script

```
extends Brain

func _ready() -> void:
	var selector = sequence.add_selector()
	selector.add(make_limited_prints())
	selector.add(make_custom_sequence())

func make_limited_prints() -> Brain.BTNode:
	var limiter = make_limiter(3)
	limiter.add_print("1")
	limiter.add_print("2")
	limiter.add_print("3")
	return limiter

func make_custom_sequence() -> Brain.BTNode:
	var seq = make_sequence()
	seq.add_data_assert("target")
	seq.add_wait_random(.5, 2)
	seq.add_action("free_target", self)
	seq.add_data_cleaner("target")
	return seq

func free_target() -> void:
	var target = data.get("target")
	if target != null and target is Node:
		target.queue_free()

```

