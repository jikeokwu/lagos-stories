extends RefCounted
## Event Display - Renders event detail panel

const DetailPanel = preload("res://scripts/chronicles/ui/detail_panel.gd")
const ChroniclesUtils = preload("res://scripts/chronicles/utils.gd")

static func display_event_details(event: Dictionary, detail_panel: Control, detail_content: Control) -> void:
	detail_panel.visible = true
	DetailPanel.clear(detail_content)
	
	DetailPanel.add_header("Event: %s" % event.get("type", "Unknown"), detail_content)
	DetailPanel.add_section("Basic Info", {
		"ID": event.get("id", ""),
		"Type": event.get("type", ""),
		"Timestamp": ChroniclesUtils.format_timestamp(event.get("timestamp", 0)),
		"Location": event.get("location_id", "None")
	}, detail_content)
	
	var participants = event.get("participants", [])
	if participants.size() > 0:
		DetailPanel.add_text("\n[PARTICIPANTS]", detail_content, 16, Color(0.9, 0.85, 0.6, 1))
		for p_id in participants:
			var npc = DB.get_npc(p_id)
			DetailPanel.add_text("  → %s" % npc.get("name", "Unknown"), detail_content, 14, Color(0.9, 0.9, 0.9, 1))
	
	var description = event.get("description", "")
	if description != "":
		DetailPanel.add_text("\n[DESCRIPTION]", detail_content, 16, Color(0.9, 0.85, 0.6, 1))
		DetailPanel.add_text(description, detail_content, 14, Color(0.9, 0.9, 0.9, 1))

