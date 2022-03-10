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
#	print(UString.find_either("one it >> happens @happens :: who cares >> what about.", [">>", "@", "::"]))
#	UDict.log(get_trailing_tokens("one it >> happens @happens :: who cares >> what about.", [">>", "@", "::"]))
	DialogueParser.parse("res://dialogue/test.soot")
