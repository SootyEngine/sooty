@tool
extends FE_Editor

func update_settings():
	delimiter_strings += ["` `", "[ ]"]

func get_comment_head() -> String:
	return "<!-- "

func get_comment_tail() -> String:
	return " -->"

func update_colors():
	var h:CodeHighlighter = CodeHighlighter.new()
	h.add_color_region("#", " ", Color.BURLYWOOD, true)
	h.add_color_region("<!--", "-->", Color.DARK_GRAY)
	h.add_color_region("~~~", "~~~", Color.BURLYWOOD, true)
	h.add_color_region("`", "`", Color.BURLYWOOD)
	h.add_color_region("```", "```", Color.BURLYWOOD, true)
	
	# bold italics
	h.add_color_region("***", "***", Color.TOMATO.darkened(.3), false)
	# bold
	h.add_color_region("**", "**", Color.TOMATO, false)
	# italic
	h.add_color_region("*", "*", Color.TOMATO.lightened(.3), false)
	
	set_syntax_highlighter(h)
