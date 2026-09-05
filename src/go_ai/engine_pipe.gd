## One child process on a pipe, read a line at a time without blocking the
## scene thread. FileAccess pipes have no non-blocking read, so each line is
## fetched on a worker and the worker is polled from the caller's coroutine.
## GtpOpponent and KataGoAnalysis both sit on this; neither owns a thread.
class_name EnginePipe
extends RefCounted

## The whole dictionary execute_with_pipe returns, kept alive on purpose: it
## also holds the child's stderr pipe, and dropping that closes it, after which
## KataGo dies of SIGPIPE on its first log line.
var _pipe: Dictionary = {}
var _stdio: FileAccess
var _pid: int = -1
var _reader: Thread


func open(command: String, args: PackedStringArray) -> bool:
    close()
    var resolved_args := PackedStringArray()
    for argument in args:
        resolved_args.append(_globalize(str(argument)))
    _pipe = OS.execute_with_pipe(_globalize(command), resolved_args)
    if _pipe.is_empty() or not _pipe.has("stdio"):
        _pipe.clear()
        return false
    _stdio = _pipe["stdio"]
    _pid = int(_pipe.get("pid", -1))
    return true


func is_open() -> bool:
    return _stdio != null and _stdio.is_open()


## The child has exited when the OS says so; an open pipe alone proves nothing,
## and get_line() on a dead child returns "" forever without ever blocking.
func is_running() -> bool:
    return _pid > 0 and OS.is_process_running(_pid)


func write_line(text: String) -> void:
    if not is_open():
        return
    _stdio.store_line(text)
    _stdio.flush()


## {"ready": true, "line": ...} or {"ready": false} after `timeout` seconds.
## A timed-out read leaves the worker blocked on the pipe; the next call
## picks that same worker up, so no line is ever lost between calls.
func read_line(timeout: float) -> Dictionary:
    if not is_open():
        return {"ready": false}
    if _reader == null:
        _reader = Thread.new()
        if _reader.start(_read_one_line) != OK:
            _reader = null
            return {"ready": false}
    # close() may clear the member while this coroutine yields. Keep the actual
    # worker locally and let close() own its final join.
    var reader := _reader
    var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
    while reader.is_alive() and Time.get_ticks_msec() < deadline:
        await (Engine.get_main_loop() as SceneTree).process_frame
    if reader.is_alive() or _reader != reader:
        return {"ready": false}
    var line: Variant = reader.wait_to_finish()
    _reader = null
    return {"ready": true, "line": str(line)}


func _read_one_line() -> String:
    # The pipe is owned by this object and only this worker touches it while a
    # read is pending. Godot's pipe backend nevertheless inherits the scene-thread
    # safety guard; disabling it locally avoids a false Node-thread error.
    Thread.set_thread_safety_checks_enabled(false)
    return _stdio.get_line() if _stdio != null and _stdio.is_open() else ""


func close() -> void:
    # Closing our end first is essential: on some Linux builds a killed child
    # does not wake FileAccess.get_line(). Joining that reader before the close
    # was the post-match deadlock that left the review overlay up forever.
    if _stdio != null and _stdio.is_open():
        _stdio.close()
    if _pid > 0:
        OS.kill(_pid)
    _pid = -1
    if _reader != null:
        # A finished worker still must be joined before its Thread is dropped.
        _reader.wait_to_finish()
    _reader = null
    _stdio = null
    _pipe.clear()


static func _globalize(path: String) -> String:
    return ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
