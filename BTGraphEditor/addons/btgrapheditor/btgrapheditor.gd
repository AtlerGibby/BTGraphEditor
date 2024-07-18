@tool
extends EditorPlugin

var dock

func _enter_tree():
	# Initialization of the plugin goes here.
	dock = preload("res://addons/btgrapheditor/Components/BTGraphDock.tscn").instantiate()
	add_control_to_bottom_panel(dock, "BTGraph Editor")
	dock.undo_redo = get_undo_redo()
	get_undo_redo().version_changed.connect(dock.undo_redo_save)
	pass


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_control_from_bottom_panel(dock)
	dock.queue_free()
	pass
