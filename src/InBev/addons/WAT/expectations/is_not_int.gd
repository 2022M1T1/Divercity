extends "base.gd"

func _init(value, context: String) -> void:
	var passed: String = "%s is not builtin: int" % value
	var failed: String = "%s is builtin: int" % value
	self.context = context
	self.success = not value is int
	self.expected = passed
	self.result = passed if self.success else failed