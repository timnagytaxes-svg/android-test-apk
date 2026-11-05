class_name ModuleActor
extends RefCounted

var id: String
var display_name: String
var team: String
var max_hp: int
var hp: int
var power: int
var armor: int
var initiative: int
var stamina: int = 3
var guarding: bool = false
var chilled: bool = false
var action_used: bool = false
var bonus_used: bool = false

func _init(actor_id: String, actor_name: String, actor_team: String, health: int, strength: int, protection: int, speed: int) -> void:
    id = actor_id
    display_name = actor_name
    team = actor_team
    max_hp = health
    hp = health
    power = strength
    armor = protection
    initiative = speed

func alive() -> bool:
    return hp > 0

func receive_damage(amount: int) -> int:
    var applied: int = mini(hp, maxi(amount, 0))
    hp -= applied
    return applied

func heal(amount: int, cap: int = -1) -> int:
    var limit: int = max_hp if cap < 0 else cap
    var applied: int = mini(maxi(0, limit - hp), maxi(amount, 0))
    hp += applied
    return applied

func begin_turn() -> void:
    guarding = false
    action_used = false
    bonus_used = false
    stamina = mini(3, stamina + 1)

func to_dict() -> Dictionary:
    return {
        "id": id, "name": display_name, "team": team,
        "max_hp": max_hp, "hp": hp, "power": power, "armor": armor,
        "initiative": initiative, "stamina": stamina,
        "guarding": guarding, "chilled": chilled, "action_used": action_used,
        "bonus_used": bonus_used
    }

static func from_dict(data: Dictionary) -> ModuleActor:
    var actor := ModuleActor.new(
        str(data.get("id", "")), str(data.get("name", "")),
        str(data.get("team", "")), int(data.get("max_hp", 0)),
        int(data.get("power", 0)), int(data.get("armor", 0)),
        int(data.get("initiative", 0))
    )
    actor.hp = int(data.get("hp", -1))
    actor.stamina = int(data.get("stamina", -1))
    actor.guarding = bool(data.get("guarding", false))
    actor.chilled = bool(data.get("chilled", false))
    actor.action_used = bool(data.get("action_used", false))
    actor.bonus_used = bool(data.get("bonus_used", false))
    if actor.max_hp < 1 or actor.max_hp > 999 or actor.hp < 0 or actor.hp > actor.max_hp + 12:
        return null
    if actor.stamina < 0 or actor.stamina > 3:
        return null
    return actor
