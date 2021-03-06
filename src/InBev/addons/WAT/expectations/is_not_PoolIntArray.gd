extends "base.gd"

func _init(value, context: String) -> void:
	var passed: String = "%s is not builtin: PoolIntArray" % value
	var failed: String = "%s is builtin: PoolIntArray" % value
	self.context = context
	self.success = not value is PoolIntArray
	self.expected = passed
	self.result = passed if self.success else failed