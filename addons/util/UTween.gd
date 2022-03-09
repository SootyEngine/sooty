@tool
extends Resource
class_name UTween

static func find_ease(s: Variant) -> int:
	if s is int:
		return s
	s = "EASE_" + s.to_upper()
	for i in len(EASE):
		if s == EASE[i]:
			return i
	return 0

static func find_trans(s: Variant) -> int:
	if s is int:
		return s
	s = "TRANS_" + s.to_upper()
	for i in len(TRANS):
		if s == TRANS[i]:
			return i
	return 0

const EASE := ["EASE_IN", "EASE_OUT", "EASE_IN_OUT", "EASE_OUT_IN"]
const TRANS := ["TRANS_LINEAR", "TRANS_SINE", "TRANS_QUINT", "TRANS_QUART", "TRANS_QUAD", "TRANS_EXPO", "TRANS_ELASTIC", "TRANS_CUBIC", "TRANS_CIRC", "TRANS_BOUNCE", "TRANS_BACK"]
