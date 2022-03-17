extends Node

const VERSION := "0.1_alpha"
const S_ACTION_EVAL := "~"
const S_ACTION_SHORTCUT := "@"

#@export var shortcuts := {}
#
#func _ready() -> void:
#	var config: Dictionary = UFile.load_json("res://config.json", {})
#	for sh in config.sooty_shortcuts:
#		var list: Array = config.sooty_shortcuts[sh]
#		for i in len(list):
#			var cmd = list[i]
#			# fix functions
#			cmd = UString.replace_between(cmd, "@", "(", func(i,s): return "_calls.%s.call(" % s)
#			# fix translations
#			cmd = UString.replace_between(cmd, "_(", ")", func(i,s): return "tr(%s)" % s)
#			list[i] = cmd
#		shortcuts[sh] = list
#	UDict.log(shortcuts)

var _shrt := {}

func add_shortcut(id: String, shortcut: String, call: Callable):
	State._call[id] = call
	_shrt[id] = shortcut

func process_shortcut(input: String) -> String:
	var p := input.split(" ", true, 1)
	var shortcut: String
	var sc := "SC_%s" % p[0]
	
	if p[0] in _shrt:
		shortcut = _shrt[p[0]]
	elif sc in State:
		shortcut = State[sc]
	else:
		push_error("No shortcut '%s'." % p[0])
		return ""
	
	# fix functions
	shortcut = UString.replace_between(shortcut, "@", "(", func(i,s): return "_call.%s.call(" % s)
	# fix translations
	shortcut = UString.replace_between(shortcut, "_(", ")", func(i,s): return "tr(%s)" % s)
	
	var args = _get_properties(p[1])
	
	var keys := {ARGS=args}
	for i in len(args):
		keys["arg%s" % i] = args[i]
	
	if args[-1] is Dictionary:
		keys.KWARGS=args[-1]
		for k in args[-1]:
			keys[k] = args[-1][k]
	
#	print(keys)
	return shortcut.format(keys, "$_")

func _get_properties(s: String) -> Array:
	var args := []
	var parts := UString.split_on_spaces(s)
	for p in parts:
		if ":" in p:
			var kv = p.split(":", true, 1)
			if not len(args) or not args[-1] is Dictionary:
				args.append({})
			args[-1][kv[0]] = kv[1]#str_to_var(kv[1])
		else:
			args.append(p)# str_to_var(p))
	return args

