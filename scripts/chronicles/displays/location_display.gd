extends RefCounted
## Location Display - Renders location detail panel

const DetailPanel = preload("res://scripts/chronicles/ui/detail_panel.gd")

static func display_location_details(location: Dictionary, detail_panel: Control, detail_content: Control) -> void:
	detail_panel.visible = true
	DetailPanel.clear(detail_content)
	
	DetailPanel.add_header("Location: %s" % location.get("name", "Unknown"), detail_content)
	DetailPanel.add_section("Basic Info", {
		"ID": location.get("id", ""),
		"Name": location.get("name", ""),
		"Type": location.get("type", ""),
		"District": location.get("district_id", ""),
		"Parent": location.get("parent_id", "None")
	}, detail_content)
	
	var features = location.get("features", {})
	if not features.is_empty():
		DetailPanel.add_section("Features", features, detail_content)

