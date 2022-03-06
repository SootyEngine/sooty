@tool
extends Resource
class_name UFlag

#func is_bit_enabled(mask, index):
#    return mask & (1 << index) != 0
#
#func enable_bit(mask, index):
#    return mask | (1 << index)
#
#func disable_bit(mask, index):
#    return mask & ~(1 << index)

static func has(bit:int, flag: int) -> bool:
	return bit & flag != 0

static func enable(bit: int, flag: int) -> int:
	return bit | flag

static func disable(bit: int, flag: int) -> int:
	return bit & ~flag

static func toggle(bit: int, flag: int) -> int:
	return disable(bit, flag) if has(bit, flag) else enable(bit, flag)
#	if flag is Array:
#		for f in flag:
#			if not (bit & (1 << flag) != 0):
#				return false
#		return true
#	else:
#		return bit & (1 << flag) != 0

#static func enable(bit:int, flag) -> int:
##	bit = bit | flag
#	if flag is Array:
#		for f in flag:
#			bit = bit | (1 << flag)
#		return bit
#	else:
#		return bit | (1 << flag)
#
#static func disable(bit:int, flag) -> int:
##	bit = bit & ~flag
#	if flag is Array:
#		for f in flag:
#			bit = bit & ~(1 << flag)
#		return bit
#	else:
#		return bit & ~(1 << flag)
#
#static func toggle(bit:int, flag) -> int:
#	if has(bit, flag):
#		return disable(bit, flag)
#	else:
#		return enable(bit, flag)
