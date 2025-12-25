extends Control
## World Generation Screen - Shows progress during world generation

@onready var status_label = $VBoxContainer/StatusLabel
@onready var progress_bar = $VBoxContainer/ProgressBar
@onready var log_text = $VBoxContainer/LogScrollContainer/LogText

var world_generator: Node = null

func _ready():
	# Add to group so world generator can find us
	add_to_group("world_gen_ui")
	
	# Find the world generator node
	world_generator = get_node_or_null("WorldGenerator")
	if world_generator == null:
		# Try to find it in the scene tree
		world_generator = get_tree().get_first_node_in_group("world_generator")
	
	# Initialize UI
	status_label.text = "Initializing world generation..."
	progress_bar.value = 0
	log_text.text = "Starting world generation...\n"
	
	# Note: The actual generation happens in world_generator.gd _ready()
	# Progress updates will come via update_status/update_progress calls

func update_status(text: String):
	if status_label:
		status_label.text = text
	if log_text:
		log_text.text += text + "\n"
		# Auto-scroll to bottom
		call_deferred("_scroll_log_to_bottom")

func update_progress(value: float):
	if progress_bar:
		progress_bar.value = value

func _scroll_log_to_bottom():
	if log_text:
		var scrollbar = log_text.get_v_scroll_bar()
		if scrollbar:
			scrollbar.value = scrollbar.max_value

