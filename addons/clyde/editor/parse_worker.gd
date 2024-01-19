extends Node

signal processing_finished()
signal processing_failed(result)

const Parser = preload("../parser/Parser.gd")

var mutex: Mutex
var semaphore: Semaphore
var thread: Thread
var exit_thread := false
var _parse_result = null
var _text_to_parse: String = ""

var _was_initialized = false
var _just_failed = false

func _initialize():
	_was_initialized = true
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	exit_thread = false

	thread = Thread.new()
	thread.start(_thread_function)


func _thread_function():
	while true:
		semaphore.wait()
		mutex.lock()
		var should_exit = exit_thread
		mutex.unlock()

		if should_exit:
			break

		mutex.lock()
		_parse_result = _parse(_text_to_parse)
		mutex.unlock()

		if not _just_failed:
			processing_finished.emit()


func parse(text: String):
	if not _was_initialized:
		_initialize()
	_text_to_parse = text
	_just_failed = false
	semaphore.post()


func get_parse_result():
	mutex.lock()
	var result = _parse_result
	mutex.unlock()
	return result


func stop_worker():
	if not _was_initialized:
		return

	mutex.lock()
	exit_thread = true
	mutex.unlock()

	semaphore.post()
	thread.wait_to_finish()


func _parse(input):
	var parser = Parser.new()
	parser.parsing_failure.connect(_on_parsing_failure)
	return parser.parse(input, true)


func _on_parsing_failure(result):
	_just_failed = true
	processing_failed.emit(result)
