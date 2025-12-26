extends RefCounted
## List Utilities - Helper functions for managing list containers

## Clear all children from a list container
static func clear_list(list_container: Control) -> void:
	for child in list_container.get_children():
		child.queue_free()

