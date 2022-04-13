@tool
extends RefCounted
class_name UDebug

static func log(a=null, b=null, c=null, d=null, e=null, f=null, g=null):
	print("    ".\
		join([a,b,c,d,e,f,g]\
		.filter(func(x): return x != null)\
		.map(func(x): return "|%s|" % [x])
	))

func print_table(items: Array):
	var col_lengths := []
	var row_data := []
	for i in len(items):
		col_lengths.append(0)
		row_data.append([])
		for j in len(items[i]):
			row_data[i].append(str(items[i][j]))
			col_lengths[i] = maxi(col_lengths[i], len(row_data[i][j]))
	for i in len(row_data):
		var s := ""
		var c = col_lengths[i]
		for j in len(items[i]):
			var l := len(row_data[i][j])
			s += " ".repeat(c-l)
			s += row_data[i][j]
		print(s)
