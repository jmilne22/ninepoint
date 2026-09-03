## Tiny assertion kit for the headless suite. No dependencies, no editor plugin.
class_name TestKit
extends RefCounted

var passed := 0
var failed := 0
var current := ""
var failures: Array[String] = []


func section(name: String) -> void:
    current = name


func ok(cond: bool, msg: String) -> void:
    if cond:
        passed += 1
    else:
        failed += 1
        failures.append("[%s] %s" % [current, msg])


func eq(a, b, msg: String) -> void:
    var good: bool = a == b
    if not good and (a is float or b is float):
        good = absf(float(a) - float(b)) < 0.0001
    if good:
        passed += 1
    else:
        failed += 1
        failures.append("[%s] %s  (got %s, want %s)" % [current, msg, str(a), str(b)])


func report() -> String:
    var s := "\n%d passed, %d failed" % [passed, failed]
    for f in failures:
        s += "\n  FAIL %s" % f
    return s
