class_name V6SaveStore
extends RefCounted

# Three offline slots. Every save goes to a temporary file and keeps a backup
# of the previous valid save, preventing a partial write from destroying progress.
const PREFIX: String = "user://ironbound_v06_slot_"

func slot_path(slot: int) -> String:
    if slot < 1 or slot > 3:
        return ""
    return PREFIX + str(slot) + ".json"

func save(slot: int, payload: Dictionary) -> bool:
    var destination: String = slot_path(slot)
    if destination.is_empty():
        return false
    var wrapped: Dictionary = {
        "format": 1,
        "checksum": JSON.stringify(payload).sha256_text(),
        "payload": payload
    }
    var tempfile: String = destination + ".tmp"
    var backup: String = destination + ".bak"
    var file: FileAccess = FileAccess.open(tempfile, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(wrapped))
    file.flush()
    var successful: bool = file.get_error() == OK
    file.close()
    if not successful:
        return false
    var final_absolute: String = ProjectSettings.globalize_path(destination)
    var temp_absolute: String = ProjectSettings.globalize_path(tempfile)
    var backup_absolute: String = ProjectSettings.globalize_path(backup)
    if FileAccess.file_exists(destination):
        if FileAccess.file_exists(backup):
            DirAccess.remove_absolute(backup_absolute)
        if DirAccess.rename_absolute(final_absolute, backup_absolute) != OK:
            return false
    if DirAccess.rename_absolute(temp_absolute, final_absolute) != OK:
        if FileAccess.file_exists(backup):
            DirAccess.rename_absolute(backup_absolute, final_absolute)
        return false
    return true

func load(slot: int) -> Dictionary:
    var destination: String = slot_path(slot)
    if destination.is_empty():
        return {}
    var primary: Dictionary = _read_checked(destination)
    if not primary.is_empty():
        return primary
    return _read_checked(destination + ".bak")

func _read_checked(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not parsed is Dictionary:
        return {}
    if int(parsed.get("format",0)) != 1 or not parsed.get("payload") is Dictionary:
        return {}
    var payload: Dictionary = parsed["payload"]
    if str(parsed.get("checksum","")) != JSON.stringify(payload).sha256_text():
        return {}
    return payload
