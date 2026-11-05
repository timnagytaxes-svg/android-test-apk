class_name V6ZoneWorld
extends V5WorldState

const GATE_FORWARD: Vector2i = Vector2i(12, 2)
const GATE_BACK: Vector2i = Vector2i(1, 9)
const MERCHANT: Vector2i = Vector2i(8, 2)
const CAMP: Vector2i = Vector2i(3, 10)
const CHRONICLE: Vector2i = Vector2i(8, 9)

const ZONE_DATA: Array[Dictionary] = [
    {
        "name": "Hearthwood Vale", "subtitle": "The Ashen Covenant",
        "mentor": "Elder Rowan", "boss": "Ashfang, Rift Wyrm",
        "story": "The great fire beneath the vale has begun to speak. Before it can wake, clear its two sentries and confront Ashfang.",
        "patrols": ["Ash Raider", "Ash Shaman"],
        "victory": "The Ember Rift dims. An ancient passage to Glimmerfen awakens.",
        "lore": "When the Starforgers sealed the Rift, they hid a key beneath Hearthwood. Now the old covenant is crumbling."
    },
    {
        "name": "Glimmerfen Marsh", "subtitle": "The Frostbound Oracle",
        "mentor": "Oracle Elira", "boss": "The Frostbound Herald",
        "story": "Cold stars are falling into the marsh. The oracle needs two wardstones reclaimed before the Herald can be challenged.",
        "patrols": ["Frost Stalker", "Mist Conjurer"],
        "victory": "The marsh spirit is freed. The last star points toward the Skyvault.",
        "lore": "The marsh remembers every vow spoken beneath its moonlit water. Some vows have waited for centuries."
    },
    {
        "name": "Skyvault Citadel", "subtitle": "The Last Star",
        "mentor": "Keeper Caldor", "boss": "The Star-Eater",
        "story": "The Star-Eater tears open the sky. Silence the two sentinels, face its avatars, then seal the crown of night.",
        "patrols": ["Void Sentinel", "Umbral Magus"],
        "victory": "The Star-Eater falls. Dawn returns to Ironbound. Your name joins the Starforgers in the Hall of Ages.",
        "lore": "The crown held the last light of an older world. It was forged to protect life, not command it."
    }
]
var chapter: int = 0

func _init(zone_index: int = 0) -> void:
    chapter = clampi(zone_index, 0, 2)

func terrain(at: Vector2i) -> String:
    var base: String = super.terrain(at)
    if chapter == 1:
        if base == "grass":
            return "snow"
        if base == "water":
            return "ice"
        if base == "tree":
            return "crystal"
    elif chapter == 2:
        if base == "grass":
            return "ash"
        if base == "water":
            return "lava"
        if base == "tree":
            return "spire"
    return base

func passable(at: Vector2i) -> bool:
    return terrain(at) in ["grass", "snow", "ash"]

func location_id(at: Vector2i) -> String:
    if at == GATE_FORWARD:
        return "gate_forward"
    if at == GATE_BACK:
        return "gate_back"
    if at == MERCHANT:
        return "merchant"
    if at == CAMP:
        return "camp"
    if at == CHRONICLE:
        return "chronicle"
    return super.location_id(at)

func inspect(inventory: ModuleInventory) -> Dictionary:
    if chapter == 0:
        return super.inspect(inventory)
    var spot: String = super.location_id(player)
    var data: Dictionary = ZONE_DATA[chapter]
    match spot:
        "elder":
            if not quest_started:
                quest_started = true
                changed.emit(str(data["mentor"]) + " entrusts you with the wardstones.")
                return {"kind": "dialogue", "speaker": data["mentor"], "text": data["story"]}
            if bool(cleared["boss"]) and not quest_claimed:
                quest_claimed = true
                inventory.potions = mini(99, inventory.potions + 3)
                changed.emit("Chapter complete! Three healing potions received.")
                return {"kind": "dialogue", "speaker": data["mentor"], "text": data["victory"]}
            return {"kind": "dialogue", "speaker": data["mentor"], "text": objective_text()}
        "chest":
            chest_opened = true
            inventory.potions = mini(99, inventory.potions + 2)
            changed.emit("An ancient chest holds two potions.")
            return {"kind": "treasure", "text": "You found two healing potions inside an old reliquary."}
        "raider", "shaman":
            if not quest_started:
                return {"kind": "dialogue", "speaker": "A sealed passage",
                    "text": "Seek %s first." % str(data["mentor"])}
            return {"kind": "battle", "encounter": spot}
        "boss":
            if not quest_started or not bool(cleared["raider"]) or not bool(cleared["shaman"]):
                return {"kind": "dialogue", "speaker": "The sealed altar",
                    "text": "Defeat both sentinels to unlock the passage."}
            return {"kind": "battle", "encounter": "boss"}
    return {"kind": "none"}

func objective_text() -> String:
    if chapter == 0:
        return super.objective_text()
    var data: Dictionary = ZONE_DATA[chapter]
    if not quest_started:
        return "Speak with %s." % str(data["mentor"])
    if quest_claimed:
        return "Chapter complete • %s" % str(data["victory"])
    if bool(cleared["boss"]):
        return "Return to %s for the chapter reward." % str(data["mentor"])
    var patrols: int = int(bool(cleared["raider"])) + int(bool(cleared["shaman"]))
    if patrols < 2:
        return "Defeat both sentinels (%d/2)." % patrols
    return "Confront %s." % str(data["boss"])

func portal_ready() -> bool:
    return quest_claimed

func battle_key(encounter: String) -> String:
    var prefixes: Array[String] = ["", "frost_", "void_"]
    return prefixes[chapter] + encounter

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["chapter"] = chapter
    return data

func restore(data: Dictionary) -> bool:
    if int(data.get("chapter",-1)) != chapter:
        return false
    return super.restore(data)
