# Copyright (c) 2021-2023 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
# This file is licensed under the MIT License
# https://github.com/ImmersiveRPG/GodotAsyncLoader

extends Node

var _is_running := false
var _thread : Thread

var _to_load := []
var _to_load_mutex := Mutex.new()


func load_with_cb(scene_path : String, loaded_cb : Callable, data := {}, has_priority := false) -> void:
	var entry := {
		"scene_path" : scene_path,
		"loaded_cb" : loaded_cb,
		"data" : data,
	}

	_to_load_mutex.lock()
	if has_priority:
		_to_load.push_front(entry)
	else:
		_to_load.push_back(entry)
	_to_load_mutex.unlock()

func _run_loader_thread() -> void:
	_is_running = true
	var config = AsyncLoaderConfig #get_node("/root/AsyncLoaderConfig")

	while _is_running:
		_to_load_mutex.lock()
		var to_load := _to_load.duplicate()
		_to_load.clear()
		_to_load_mutex.unlock()

		for entry in to_load:
			var scene_path = entry["scene_path"]
			var loaded_cb = entry["loaded_cb"]
			var data = entry["data"]
			var packed_scene = AsyncLoader.load_and_cache_scene(scene_path)
			loaded_cb.call_deferred(packed_scene, data)

		OS.delay_msec(config._thread_sleep_msec)
