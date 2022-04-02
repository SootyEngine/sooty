@tool
extends EditorScript

var x = "Who"
var y = [9,1,1]
var clr := Color.WHITE

func Character(x):
	print("CALLED Character WITH ", x)

enum {WINTER, SPRING}

func _run():
	print(format_speaker_text("I'm *John*. (He get's angry.) [!@john.shake_no][w] [!@john.talk]I'm the angriest one."))
	print(format_speaker_text('(Tutning away.) [w]You never know, they could say, "He was robbed," tell you iy all! (Closed eyes.)'))
	print(format_speakerless_text('It\'s all "A Joke" he said.'))
	print(format_speakerless_text('"They are" he said.'))
	return

func format_speakerless_text(text: String) -> String:
	return _wrap(UString.fix_quotes(text), UString.CHAR_QUOTE_OPENED, UString.CHAR_QUOTE_CLOSED, '"', '"', '*', '*')

func format_speaker_text(text: String) -> String:
	return _wrap(text, "(", ")", "*", "*", UString.CHAR_QUOTE_OPENED, UString.CHAR_QUOTE_CLOSED)

func _wrap(text: String,
	inner_opened := "(",
	inner_closed := ")",
	quote_opened := "{",
	quote_closed := "}",
	pred_opened := "<",
	pred_closed := ">"
	) -> String:
	var out := ""
	var leading := ""
	
	var in_pred := not text.begins_with(inner_opened)
	var start := true
	var started := false
	var in_tag := false
	
	for c in text:
		if c == "[":
			in_tag = true
			leading += c
		elif c == "]":
			in_tag = false
			leading += c
		elif in_tag:
			leading += c
		
		elif c == inner_opened:
			in_pred = false
			start = true
			if started:
				out += pred_closed
			leading += quote_opened
		
		elif c == inner_closed:
			in_pred = true
			start = true
			out += quote_closed
		
		elif c == " ":
			leading += " "
		
		else:
			if in_pred:
				if leading:
					out += leading
					leading = ""
				
				if start:
					start = false
					started = true
					out += pred_opened
			
			else:
				if leading:
					out += leading
					leading = ""
			
			out += c
	
	if in_pred and not start:
		out += pred_closed
	
	return out

#func fix_functions(t: String) -> String:
#	var i := 0
#	var out := ""
#	var off := 0
#	while i < len(t):
#		var j := t.find("(", i)
#		# find a bracket.
#		if j != -1:
#			var k := j-1
#			var method_name := ""
#			# walk backwards
#			while k >= 0 and t[k] in ".abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789":
#				method_name = t[k] + method_name
#				k -= 1
#			# if head isn't empty, it's a function not wrapping brackets.
#			if method_name != "":
#				out += UString.part(t, i, k+1)
#				# don't wrap property methods, since those will be globally accessible from _get
#				# don't wrap built in GlobalScope methods (sin, round, randf...)
#				if "." in method_name or method_name in UObject.GLOBAL_SCOPE_METHODS:
#					out += "%s(" % method_name
#				else:
#					out += "_C.%s.call(" % method_name
#				out += UString.part(t, k+1+len(method_name), j)
#				i = j + 1
#				continue
#		i += 1
#	# add on the remainder.
#	out += UString.part(t, i-2)
#	return out
