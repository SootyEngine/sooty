@tool
extends Node

var databases := {}
var signals := {}

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 9223372036854775807

# queue a solo signal that will only fire once per tick
func queue_solo_signal(sig: Signal, args := []):
	signals[sig] = args

func _physics_process(delta: float) -> void:
	if signals:
		for sig in signals:
			var args: Array = signals[sig]
			match len(args):
				0: sig.emit()
				1: sig.emit(args[0])
				2: sig.emit(args[1], args[2])
				3: sig.emit(args[1], args[2], args[3])
				4: sig.emit(args[1], args[2], args[3], args[4])
				5: sig.emit(args[1], args[2], args[3], args[4], args[5])
				_: push_error("Not implemented.")
		signals.clear()

func register(data_class_name: String, database: Object):
	databases[data_class_name] = database.get_instance_id()

func get_all(data_type: Variant) -> Array:
	return get_database(data_type).get_all()

func get_data(data_type: Variant, data: String) -> Variant:
	return get_database(data_type).get(data)

func get_database(item_or_database: Variant) -> Variant:
	if item_or_database is Script:
		item_or_database = UClass.get_class_name(item_or_database)
	
	# use string name to find instance
	if item_or_database in databases:
		var m_instance_id: int = databases[item_or_database]
		return instance_from_id(m_instance_id)
	
#	push_error("Can't find database for %s." % item_or_database)
	return null
