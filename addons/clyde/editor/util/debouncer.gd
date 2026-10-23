extends Node

func debounced(fn: Callable, delay_in_seconds: float) -> Callable:
	var timer := Timer.new()
	timer.autostart = false
	timer.wait_time = delay_in_seconds
	timer.one_shot = true
	timer.timeout.connect(fn)
	add_child(timer)

	return func():
		if timer.is_stopped():
			timer.start()
		else:
			timer.stop()
			timer.start()
