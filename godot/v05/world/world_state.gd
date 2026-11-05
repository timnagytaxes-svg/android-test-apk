class_name V5WorldState
extends RefCounted

signal changed(message: String)

const MAP_SIZE: Vector2i = Vector2i(14, 12)
const START: Vector2i = Vector2i(2, 2)
const ELDER: Vector2i = Vector2i(4, 3)
const CHEST: Vector2i = Vector2i(3, 9)
const ENCOUNTERS: Dictionary = {
    "raider": Vector2i(10, 3),
    "shaman": Vector2i(10, 8),
    "boss": Vector2i(12, 10)
}
const ORTHOGONAL: Array[Vector2i] = [
    Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
]

var player: Vector2i = START
var quest_started: bool = false
var quest_claimed: bool = false
var chest_opened: bool = false
var cleared: Dictionary = {"raider": false, "shaman": false, "boss": false}

func terrain(at: Vector2i) -> String:
    if at.x <= 0 or at.y <= 0 or at.x >= MAP_SIZE.x - 1 or at.y >= MAP_SIZE.y - 1:
        return "wall"
    if at.x == 6 and at.y in [1, 2, 3, 5, 7, 8, 9]:
        return "stone"
    if at.y == 6 and at.x in [2, 3, 4]:
        return "water"
    if at.x == 9 and at.y in [5, 6]:
        return "tree"
    if at.x in [2, 11] and at.y == 5:
        return "tree"
    return "grass"

func passable(at: Vector2i) -> bool:
    return terrain(at) == "grass"

func location_id(at: Vector2i) -> String:
    if at == ELDER:
        return "elder"
    if at == CHEST:
        return "chest" if not chest_opened else ""
    for id: String in ENCOUNTERS.keys():
        if at == ENCOUNTERS[id] and not bool(cleared[id]):
            return id
    return ""

func move(direction: Vector2i) -> bool:
    if abs(direction.x) + abs(direction.y) != 1:
        return false
    var destination: Vector2i = player + direction
    if not passable(destination):
        changed.emit("That way is blocked.")
        return false
    player = destination
    changed.emit("")
    return true

func path_to(destination: Vector2i) -> Array[Vector2i]:
    var route: Array[Vector2i] = []
    if not passable(destination):
        return route
    var frontier: Array[Vector2i] = [player]
    var previous: Dictionary = {player: player}
    var index: int = 0
    while index < frontier.size():
        var current: Vector2i = frontier[index]
        index += 1
        if current == destination:
            break
        for delta: Vector2i in ORTHOGONAL:
            var next: Vector2i = current + delta
            if not previous.has(next) and passable(next):
                previous[next] = current
                frontier.append(next)
    if not previous.has(destination):
        return route
    var cursor: Vector2i = destination
    while cursor != player:
        route.push_front(cursor)
        cursor = previous[cursor]
    return route

func inspect(inventory: ModuleInventory) -> Dictionary:
    var spot: String = location_id(player)
    match spot:
        "elder":
            if not quest_started:
                quest_started = true
                changed.emit("Elder Rowan asks you to defeat two patrols and Ashfang.")
                return {"kind": "dialogue", "speaker": "Elder Rowan",
                    "text": "The Ember Rift is open! Defeat the raider and shaman, then slay Ashfang. Return for your reward."}
            if bool(cleared["boss"]) and not quest_claimed:
                quest_claimed = true
                inventory.potions = mini(99, inventory.potions + 3)
                changed.emit("QUEST COMPLETE! Rowan gives you three healing potions.")
                return {"kind": "dialogue", "speaker": "Elder Rowan",
                    "text": "The rift is quiet again. Take these three potions, champion. The village is safe!"}
            return {"kind": "dialogue", "speaker": "Elder Rowan",
                "text": "Your progress: %s. Return after defeating Ashfang." % objective_text()}
        "chest":
            chest_opened = true
            inventory.potions = mini(99, inventory.potions + 2)
            changed.emit("Found a hidden supply cache: +2 potions.")
            return {"kind": "treasure", "text": "Treasure discovered! Two healing potions added."}
        "raider", "shaman":
            if not quest_started:
                return {"kind": "dialogue", "speaker": "A warning",
                    "text": "Elder Rowan in the village has a mission. Speak with her first."}
            return {"kind": "battle", "encounter": spot}
        "boss":
            if not quest_started or not bool(cleared["raider"]) or not bool(cleared["shaman"]):
                return {"kind": "dialogue", "speaker": "The sealed rift",
                    "text": "The rift rejects you. First clear both patrols to weaken the seal."}
            return {"kind": "battle", "encounter": "boss"}
    return {"kind": "none"}

func finish_encounter(encounter: String, victory: bool) -> bool:
    if not ENCOUNTERS.has(encounter) or bool(cleared[encounter]) or not quest_started:
        return false
    if encounter == "boss" and (not bool(cleared["raider"]) or not bool(cleared["shaman"])):
        return false
    if victory:
        cleared[encounter] = true
        changed.emit("%s defeated. Return to the village when the rift is sealed." % encounter.capitalize())
    else:
        changed.emit("Your party withdrew. Regroup and try that encounter again.")
    return victory

func objective_text() -> String:
    if not quest_started:
        return "Talk to Elder Rowan in the village."
    if quest_claimed:
        return "Quest complete • The Ember Rift is sealed."
    if bool(cleared["boss"]):
        return "Return to Elder Rowan for your reward."
    var wins: int = int(bool(cleared["raider"])) + int(bool(cleared["shaman"]))
    if wins < 2:
        return "Clear both patrols (%d/2). Then approach the rift." % wins
    return "Both patrols defeated. Defeat Ashfang at the rift!"

func to_dict() -> Dictionary:
    return {"x": player.x, "y": player.y, "quest_started": quest_started,
        "quest_claimed": quest_claimed, "chest_opened": chest_opened, "cleared": cleared.duplicate()}

func restore(data: Dictionary) -> bool:
    if not data.get("cleared") is Dictionary:
        return false
    var point: Vector2i = Vector2i(int(data.get("x", -1)), int(data.get("y", -1)))
    if not passable(point):
        return false
    var flags: Dictionary = data["cleared"]
    if flags.size() != ENCOUNTERS.size():
        return false
    for key: String in ENCOUNTERS.keys():
        if not flags.has(key) or not flags[key] is bool:
            return false
    if not data.get("quest_started") is bool or not data.get("quest_claimed") is bool or not data.get("chest_opened") is bool:
        return false
    if bool(data["quest_claimed"]) and not bool(flags["boss"]):
        return false
    if bool(flags["boss"]) and (not bool(flags["raider"]) or not bool(flags["shaman"])):
        return false
    if not bool(data["quest_started"]) and (bool(flags["raider"]) or bool(flags["shaman"]) or bool(flags["boss"])):
        return false
    player = point
    quest_started = bool(data["quest_started"])
    quest_claimed = bool(data["quest_claimed"])
    chest_opened = bool(data["chest_opened"])
    cleared = flags.duplicate()
    return true
