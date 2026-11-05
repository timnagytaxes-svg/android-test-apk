class_name V3Unit
extends RefCounted

var id: String
var name: String
var faction: String
var role: String
var health: int
var hp: int
var power: int
var defense: int
var speed: int
var mp: int
var max_mp: int
var level: int = 1
var experience: int = 0
var chilled: int = 0
var guarding: bool = false
var action_used: bool = false
var bonus_used: bool = false

func _init(p_id: String, p_name: String, p_faction: String, p_role: String,
        p_health: int, p_power: int, p_defense: int, p_speed: int, p_mp: int) -> void:
    id = p_id
    name = p_name
    faction = p_faction
    role = p_role
    health = p_health
    hp = p_health
    power = p_power
    defense = p_defense
    speed = p_speed
    max_mp = p_mp
    mp = p_mp

func alive() -> bool:
    return hp > 0

func initiative() -> int:
    return speed - (5 if chilled > 0 else 0)

func begin_turn() -> void:
    guarding = false
    action_used = false
    bonus_used = false
    mp = mini(max_mp, mp + 1)

func hurt(amount: int) -> int:
    var dealt: int = mini(hp, maxi(0, amount))
    hp -= dealt
    return dealt

func heal(amount: int, cap: int) -> int:
    var recovered: int = mini(maxi(0, cap - hp), maxi(0, amount))
    hp += recovered
    return recovered

func serialize() -> Dictionary:
    return {"id": id,"hp": hp,"mp": mp,"level": level,"chilled": chilled,"guarding": guarding,
        "action_used": action_used,"bonus_used": bonus_used}

func restore(data: Dictionary, cap: int) -> bool:
    if str(data.get("id", "")) != id or int(data.get("level", level)) != level:
        return false
    var new_hp: int = int(data.get("hp", -1))
    var new_mp: int = int(data.get("mp", -1))
    var new_chill: int = int(data.get("chilled", -1))
    if new_hp < 0 or new_hp > cap or new_mp < 0 or new_mp > max_mp or new_chill < 0 or new_chill > 4:
        return false
    hp = new_hp
    mp = new_mp
    chilled = new_chill
    guarding = bool(data.get("guarding", false))
    action_used = bool(data.get("action_used", false))
    bonus_used = bool(data.get("bonus_used", false))
    return true
