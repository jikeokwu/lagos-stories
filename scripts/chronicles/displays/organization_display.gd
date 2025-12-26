extends RefCounted
## Organization Display - Renders organization detail panel

const DetailPanel = preload("res://scripts/chronicles/ui/detail_panel.gd")

static func display_org_details(org: Dictionary, detail_panel: Control, detail_content: Control) -> void:
	detail_panel.visible = true
	DetailPanel.clear(detail_content)
	
	DetailPanel.add_header("Organization: %s" % org.get("name", "Unknown"), detail_content)
	DetailPanel.add_section("Basic Info", {
		"ID": org.get("id", ""),
		"Name": org.get("name", ""),
		"Type": org.get("type", ""),
		"HQ Location": org.get("hq_location_id", "None")
	}, detail_content)
	
	var effective = org.get("effective", {})
	if not effective.is_empty():
		DetailPanel.add_section("Effective Values", effective, detail_content)

