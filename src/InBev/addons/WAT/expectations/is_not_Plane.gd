extends "base.gd"

func _init(value, context: String) -> void:
	var passed: String = "%s is not builtin: Plane" % value
	var failed: String = "%s is builtin: Plane" % value
	self.context = context
	self.success = not value is Plane
	self.expected = passed
	self.result = passed if self.success else failed