@tool
extends EditorScript

var test_string := "

=== Chapter 1 ((x:10 y:30)) // First node.
	@score += 999
	@node do thing 10 20
	john: HI PAUL {{player_name == \"paul\"}}
	john: HI MARY {{player_name == \"mary\"}}
	line with options
		<> option 1 >> Chapter 2 ((prop:true b:false)) {{score > 20}} // Comment.
			|score:true
			|needs_it:false
			@okay
			@well 
		<> option 2 {{score == 4}}
		<> option 3 >> westo
			this happens on option 3
			and then this
	line after options
	more lines

=== middle
	CALLED IN THE MIDDLE
	score += 10

=== Chapter 2
	another node
	:: middle
	:: middle
	and we're back
"

func _action(a: String):
	print("ACTION ", a)

func _run():
	print(EvalHelper.new().parse('ok.who_cares who $cares 1,false,ok,4 dmg:10 str:20,30 quest:true'))
	print(EvalHelper.new().parse('score++'))
	print(EvalHelper.new().parse('score += 20'))
#	print(EvalHelper.parse("ok who cares not me"))

func _dtest():
#	_parse_test()
	var d := Dialogue.new(test_string, false)
	var dm := DialogueManager.new()
	
	dm.action.connect(_action)
	dm.add_dialogue("mister", d)
	dm.start("mister")
	var safety := 20
	while dm.is_active():
		safety -= 1
		if safety <= 0:
			print("safety")
			break
		
		var line := dm.get_next_line()
		
		if "options" in line:
			dm.select_option(line, 0)
		
		if "action" in line:
			dm.do_action(line.action)
#			dm.action.emit(line.action)
		else:
			print(line)

func _parse_test():
	var d := Dialogue.new(test_string, false)
	print("F L O W S")
	print(JSON.new().stringify(d.flows, "\t", false))
	print("L I N E S")
	print(JSON.new().stringify(d.lines, "\t", false))

