extends Control
## World Selection Screen - Choose from generated/saved worlds

@onready var worlds_list = $VBoxContainer/WorldsScrollContainer/WorldsList
@onready var select_button = $VBoxContainer/ButtonContainer/SelectButton
@onready var delete_button = $VBoxContainer/ButtonContainer/DeleteButton
@onready var back_button = $VBoxContainer/ButtonContainer/BackButton
@onready var no_worlds_label = $VBoxContainer/NoWorldsLabel

var selected_world_id = ""

func _ready():
	# Connect buttons
	select_button.pressed.connect(_on_select_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Load worlds
	_load_worlds()
	_update_button_states()

func _load_worlds():
	# Clear existing items
	for child in worlds_list.get_children():
		child.queue_free()
	
	var worlds = GameState.get_generated_worlds()
	
	if worlds.size() == 0:
		no_worlds_label.visible = true
		return
	
	no_worlds_label.visible = false
	
	# Create world items
	for world in worlds:
		var item = _create_world_item(world)
		worlds_list.add_child(item)

func _create_world_item(world_data: Dictionary) -> Control:
	# Create a panel for each world
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 100)
	
	# Create background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.17, 1)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.3, 0.3, 0.35, 1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)
	
	# Main container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	margin.add_child(hbox)
	
	# Info container
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(vbox)
	
	# World name
	var name_label = Label.new()
	name_label.text = world_data.get("name", "Unnamed World")
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1))
	vbox.add_child(name_label)
	
	# Stats
	var stats_label = Label.new()
	stats_label.text = "Population: %d NPCs | Districts: %d" % [
		world_data.get("population", 0),
		world_data.get("districts", 1)
	]
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	vbox.add_child(stats_label)
	
	# Date info
	var date_label = Label.new()
	var created_time = world_data.get("created_at", 0)
	var date_dict = Time.get_datetime_dict_from_unix_time(created_time)
	date_label.text = "Created: %04d-%02d-%02d" % [date_dict.year, date_dict.month, date_dict.day]
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	vbox.add_child(date_label)
	
	# Select button
	var select_btn = Button.new()
	select_btn.text = "Select"
	select_btn.custom_minimum_size = Vector2(100, 0)
	select_btn.add_theme_font_size_override("font_size", 16)
	hbox.add_child(select_btn)
	
	# Connect button
	var world_id = world_data.get("id", "")
	select_btn.pressed.connect(_on_world_item_selected.bind(world_id, panel))
	
	# Store world ID in metadata
	panel.set_meta("world_id", world_id)
	
	return panel

func _on_world_item_selected(world_id: String, panel: PanelContainer):
	# Deselect all
	for child in worlds_list.get_children():
		if child is PanelContainer:
			var style = child.get_theme_stylebox("panel").duplicate()
			style.border_color = Color(0.3, 0.3, 0.35, 1)
			child.add_theme_stylebox_override("panel", style)
	
	# Select this one
	var style = panel.get_theme_stylebox("panel").duplicate()
	style.border_color = Color(0.7, 0.85, 0.6, 1)
	panel.add_theme_stylebox_override("panel", style)
	
	selected_world_id = world_id
	_update_button_states()
	print("Selected world: ", world_id)

func _update_button_states():
	var has_selection = selected_world_id != ""
	select_button.disabled = not has_selection
	delete_button.disabled = not has_selection

func _on_select_pressed():
	if selected_world_id != "":
		GameState.select_world(selected_world_id)
		GameState.enter_chronicles()

func _on_delete_pressed():
	if selected_world_id != "":
		# Show confirmation (for now, just delete)
		print("Deleting world: ", selected_world_id)
		GameState.delete_world(selected_world_id)
		selected_world_id = ""
		_load_worlds()
		_update_button_states()

func _on_back_pressed():
	GameState.back_to_home_from_selection()

