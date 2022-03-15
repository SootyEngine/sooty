extends Node

signal notified(msg: Dictionary)

func message(msg: Dictionary):
	notified.emit(msg)
