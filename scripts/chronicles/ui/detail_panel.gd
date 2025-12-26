extends RefCounted
## Detail Panel Helpers - Functions for rendering detail panel content

## Add a section header to the detail panel
static func add_header(text: String, content_container: Control) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1))
	content_container.add_child(label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	content_container.add_child(spacer)

## Add a key-value section to the detail panel
static func add_section(title: String, data: Dictionary, content_container: Control) -> void:
	var title_label = Label.new()
	title_label.text = "[%s]" % title.to_upper()
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1))
	content_container.add_child(title_label)
	
	for key in data.keys():
		var value_label = Label.new()
		value_label.text = "  %s: %s" % [key, str(data[key])]
		value_label.add_theme_font_size_override("font_size", 14)
		value_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		content_container.add_child(value_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	content_container.add_child(spacer)

## Add text label to the detail panel
static func add_text(text: String, content_container: Control, size: int = 14, color: Color = Color(0.9, 0.9, 0.9, 1)) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	content_container.add_child(label)

## Clear all children from the detail panel
static func clear(content_container: Control) -> void:
	for child in content_container.get_children():
		child.queue_free()

