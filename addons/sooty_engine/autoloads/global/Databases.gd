@tool
extends RefCounted

var databases := {}

func register(data_class_name: String, database: Object):
	prints("DB: %s." % [data_class_name])
	databases[data_class_name] = database.get_instance_id()

func get_all(data_type: Variant) -> Array:
	return get_database(data_type).get_all()

func get_data(data_type: Variant, data_id: String) -> Variant:
	var database = get_database(data_type)
	var data = database.get(data_id)
	# show error message
	if not data:
		var data_type_name = data_type
		if data_type is Script:
			data_type_name = UClass.get_class_name(data_type)
		UString.push_error_similar("No %s '%s'." % [data_type_name, data_id], data_id, database.get_all_ids())
	return data

func get_database(item_or_database: Variant) -> Variant:
	if item_or_database is Script:
		item_or_database = UClass.get_class_name(item_or_database)
	
	# use string name to find instance
	if item_or_database in databases:
		var m_instance_id: int = databases[item_or_database]
		return instance_from_id(m_instance_id)
	
#	push_error("Can't find database for %s." % item_or_database)
	return null
