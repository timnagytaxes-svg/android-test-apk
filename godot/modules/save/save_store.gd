class_name ModuleSaveStore
extends RefCounted

const SAVE_PATH: String = "user://modular_battle_slot.json"

func write(data: Dictionary) -> bool:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    file.flush()
    var ok: bool = file.get_error() == OK
    file.close()
    return ok

func read() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary:
        return parsed
    return {}
