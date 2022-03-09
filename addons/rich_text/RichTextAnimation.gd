@tool
extends RichTextLabel2
class_name RichTextAnimation

signal command(command: String)
signal character_shown(index: int)

signal started()				# animation starts.
signal paused()					# 'play' is set to false.
signal ended()					# animation ended.
signal faded_in()				# ended fade in
signal faded_out()				# ended fade out

signal hold_started()			# called when waiting for user input
signal hold_ended()				# called when user ended a hold

signal wait_started()			# wait timer started.
signal wait_ended()				# wait timer ended.
signal quote_started()			# "quote" starts.
signal quote_ended()			# "quote" ends.

enum {
	TRIG_NONE = 1000,
	TRIG_WAIT, TRIG_PACE, TRIG_HOLD,
	TRIG_SKIP_STARTED, TRIG_SKIP_ENDED,
	TRIG_ACTION, TRIG_COMMAND,
	TRIG_QUOTE_STARTED, TRIG_QUOTE_ENDED
}

#@export_enum("","back","console","fader","focus","prickle","redact","wfc")
@export var animation:String = "fader":
	set(a):
		animation = a

@export var play := true
@export var play_speed := 30.0
@export var fade_out := false
@export var fade_speed := 10.0
@export var fade_out_speed := 120.0

@export_range(0.0, 1.0) var progress := 0.0: set = set_progress
@export var effect_time := 0.0
@export var visible_character := -1

@export var _wait := 0.0
@export var _pace := 1.0
@export var _skip := false
@export var _triggers := {}
@export var _alpha_real: Array[float] = []
@export var _alpha_goal: Array[float] = []
@export var _advance_finished := false

func is_finished() -> bool:
	return progress == 0 if fade_out else progress == 1.0

func is_waiting() -> bool:
	return _wait > 0.0

func is_playing() -> bool:
	return play

func set_bbcode(btext: String):
	_triggers.clear()
	_skip = false
	_wait = 0.0
	_pace = 1.0
	_advance_finished = false
	progress = 0.0
	effect_time = 0.0
	visible_character = -1
	super.set_bbcode(btext)
	
	var l := get_total_character_count()
	_alpha_real.resize(l)
	_alpha_goal.resize(l)
	_alpha_real.fill(0.0)
	_alpha_goal.fill(0.0)

func advance():
	if not play:
		play = true
	else:
		finish()

func finish():
	_triggers.clear()
	_wait = 0.0
	_advance_finished = true
	set_progress(1.0)

func _preparse(btext: String) -> String:
	var final := "[%s]%s[]" % [animation, super._preparse(btext)]
	return final

func _parse_tag_unused(tag: String, info: String, raw: String) -> bool:
	if raw.begins_with("@"):
		return _register_trigger(TRIG_ACTION, raw.substr(1))
	
	elif raw.begins_with("!"):
		return _register_trigger(TRIG_COMMAND, raw.substr(1))
	
	match tag:
		"skip":
			_stack_push(TRIG_SKIP_STARTED, null, true)
			return _register_trigger(TRIG_SKIP_STARTED, info_to_dict(info))
		"w", "wait": return _register_trigger(TRIG_WAIT, info_to_dict(info))
		"h", "hold": return _register_trigger(TRIG_HOLD, info_to_dict(info))
		"p", "pace": return _register_trigger(TRIG_PACE, info_to_dict(info))
		"q", "quote":
			_stack_push(TRIG_QUOTE_STARTED, null, true)
			return _register_trigger(TRIG_QUOTE_STARTED, info_to_dict(info))
	
	return super._parse_tag_unused(tag, info, raw)

func _tag_closed(tag: int, data: Variant):
	match tag:
		TRIG_SKIP_STARTED: _register_trigger(TRIG_SKIP_ENDED)
		TRIG_QUOTE_STARTED: _register_trigger(TRIG_QUOTE_ENDED)

func _trigger(type: int, data: Variant):
	match type:
		TRIG_COMMAND: command.emit(data)
		TRIG_ACTION: StringAction.do(data)
		TRIG_WAIT: _wait += data.get("wait", data.get("w", 1.0))
		TRIG_HOLD: play = false
		TRIG_PACE: _pace = data.get("pace", data.get("p", 1.0))
		TRIG_QUOTE_STARTED: quote_started.emit()
		TRIG_QUOTE_ENDED: quote_ended.emit()
		TRIG_SKIP_STARTED: _skip = true
		TRIG_SKIP_ENDED: _skip = false
		_: print("UNKOWN TRIGGER")

func _register_trigger(type: int, data: Variant=null) -> bool:
	var at := get_total_character_count()-1
	var tr = [type, data]
	
	if not at in _triggers:
		_triggers[at] = [tr]
	else:
		_triggers[at].append(tr)
	
	return true

func set_progress(p:float):
	var last_progress := progress
	var last_visible_character := visible_character
	
	var next_progress = clampf(p, 0.0, 1.0)
	var next_visible_character = int(floor(get_total_character_count() * next_progress))
	
	if last_progress == next_progress:
		return
	
	# emit signal and pop triggers
	if last_visible_character < next_visible_character:
		for i in range(last_visible_character, next_visible_character):
			
			if i in _triggers:
				for t in _triggers[i]:
					_trigger(t[0], t[1])
				
				if is_waiting():
					next_progress = (i+1) / float(get_total_character_count())
					next_visible_character = (i+1)
					break
			
			if is_waiting():
				break
	
	progress = next_progress
	visible_character = next_visible_character
	
	# set alpha
	for i in len(_alpha_goal):
		_alpha_goal[i] = 1.0 if i < visible_character else 0.0
	
	# emit signals
	if last_visible_character < visible_character:
		if visible_character == 0:
			emit_signal("started")
	
		for i in range(last_visible_character, visible_character):
			emit_signal("character_shown", i)
	
		if visible_character == get_total_character_count():
			emit_signal("ended")
	
	if fade_out:
		if progress == 0.0:
			emit_signal("faded_out")
	else:
		if progress == 1.0:
			emit_signal("faded_in")

func _process(delta: float) -> void:
	if play:
		effect_time += delta
	
	if len(_alpha_real) != get_total_character_count():
		return
	
	if fade_out:
		for i in get_total_character_count():
			if _alpha_real[i] > 0.0:
				_alpha_real[i] = maxf(0.0, _alpha_real[i] - delta * fade_speed)
		
		if progress > 0.0:
			progress -= delta * fade_out_speed
	
	else:
		var fs := delta * fade_speed
		
		if _advance_finished:
			fs *= 4.0
		
		for i in get_total_character_count():
			if _alpha_real[i] > _alpha_goal[i]:
				_alpha_real[i] = maxf(_alpha_goal[i], _alpha_real[i] - fs)
			
			elif _alpha_real[i] < _alpha_goal[i]:
				_alpha_real[i] = minf(_alpha_goal[i], _alpha_real[i] + fs)
		
		if _wait > 0.0:
			_wait = maxf(0.0, _wait - delta)
		
		elif play and progress < 1.0 and get_total_character_count():
			if _skip:
				while _skip:
					progress += 1.0 / float(get_total_character_count())
				
#				for i in get_total_character_count():
#					_alpha_real[i] = _alpha_goal[i]
			else:
				var t = (1.0 / float(get_total_character_count()))
				progress += delta * t * play_speed * _pace

func _get_character_alpha(index:int) -> float:
	if index < 0 or index >= get_total_character_count():
		return 1.0
	return _alpha_real[index]
