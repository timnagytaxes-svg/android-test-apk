extends Control

var game: V3Coordinator
var stage: V3Stage
var turn_label: Label
var prompt: Label
var events_label: Label
var initiative_label: Label
var progression_label: Label
var submenu: HBoxContainer
var target_row: HBoxContainer
var hud: Dictionary = {}
var equip_layer: Control
var equip_list: VBoxContainer
var equip_stats: Label
var equip_message: Label
var expanded_log: bool = false
var pending: String = ""
var current: Dictionary = {}
var last_events: Array[String] = []
var gear_cache: String = ""

func _ready() -> void:
    _build()
    game = V3Coordinator.new()
    add_child(game)
    game.state_changed.connect(_render)
    game.animate.connect(stage.show_action)
    stage.unit_tapped.connect(_select_target)
    game.new_encounter()

func _build() -> void:
    var background := ColorRect.new()
    background.color = Color("#091420")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    var pad := MarginContainer.new()
    pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side: String in ["left", "right", "top", "bottom"]:
        pad.add_theme_constant_override("margin_" + side, 10)
    add_child(pad)
    var main := VBoxContainer.new()
    main.add_theme_constant_override("separation", 7)
    pad.add_child(main)
    var heading := _label("IRONBOUND TACTICS  •  v0.4", 27, Color("#f2d18c"))
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    main.add_child(heading)
    turn_label = _label("",20,Color.WHITE)
    main.add_child(turn_label)
    initiative_label = _label("",16,Color("#b9dce2"))
    initiative_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    main.add_child(initiative_label)
    progression_label = _label("",17,Color("#e9c98c"))
    main.add_child(progression_label)
    stage = V3Stage.new()
    stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    main.add_child(stage)
    var party_grid := GridContainer.new()
    party_grid.columns = 2
    party_grid.add_theme_constant_override("h_separation",8)
    party_grid.add_theme_constant_override("v_separation",5)
    main.add_child(party_grid)
    for id: String in ["warden", "mira", "lyra", "kestrel"]:
        var panel := PanelContainer.new()
        panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        panel.custom_minimum_size = Vector2(0,62)
        party_grid.add_child(panel)
        var panel_row := HBoxContainer.new()
        panel_row.add_theme_constant_override("separation",5)
        panel.add_child(panel_row)
        var portrait := TextureRect.new()
        var atlas := AtlasTexture.new()
        atlas.atlas = preload("res://v03/assets/party.png")
        var portrait_row: int = 0
        match id:
            "mira": portrait_row = 1
            "lyra": portrait_row = 3
            "kestrel": portrait_row = 2
        atlas.region = Rect2(0, portrait_row*48, 48, 48)
        portrait.texture = atlas
        portrait.custom_minimum_size = Vector2(42,42)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        panel_row.add_child(portrait)
        var panel_col := VBoxContainer.new()
        panel_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        panel_col.add_theme_constant_override("separation",1)
        panel_row.add_child(panel_col)
        var name_line := _label("",17,Color("#d5e6f5"))
        panel_col.add_child(name_line)
        var hpbar := ProgressBar.new()
        hpbar.show_percentage = false
        hpbar.custom_minimum_size = Vector2(0,12)
        panel_col.add_child(hpbar)
        hud[id] = {"name": name_line,"hp": hpbar,"panel": panel}
    prompt = _label("Choose an action. Tap a highlighted target after selecting a skill.",17,Color("#f6d88d"))
    prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    main.add_child(prompt)
    var actions := GridContainer.new()
    actions.columns = 4
    actions.add_theme_constant_override("h_separation",5)
    actions.add_theme_constant_override("v_separation",6)
    main.add_child(actions)
    for title: String in ["ATTACK","SKILLS","MAGIC","ITEMS","DEFEND","EQUIP","END TURN","LOG"]:
        var button: Button = _button(title,18,54)
        actions.add_child(button)
        button.pressed.connect(_command_menu.bind(title))
    submenu = HBoxContainer.new()
    submenu.add_theme_constant_override("separation",5)
    main.add_child(submenu)
    target_row = HBoxContainer.new()
    target_row.add_theme_constant_override("separation",5)
    main.add_child(target_row)
    events_label = _label("",16,Color("#becfd9"))
    events_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    main.add_child(events_label)
    _make_equipment_layer()

func _make_equipment_layer() -> void:
    equip_layer = Control.new()
    equip_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    equip_layer.visible = false
    add_child(equip_layer)
    var shade := ColorRect.new()
    shade.color = Color(0.025,0.045,0.075,0.97)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    equip_layer.add_child(shade)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side: String in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_"+side,18)
    equip_layer.add_child(margin)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation",12)
    margin.add_child(body)
    body.add_child(_label("INVENTORY & EQUIPMENT",28,Color("#f4cf84")))
    var back: Button = _button("RETURN TO BATTLE",20,63)
    back.pressed.connect(func() -> void: equip_layer.visible = false)
    body.add_child(back)
    var hint := _label("Equipment uses Warden's regular action in battle. Bonus potions are used via ITEMS after a regular action.",19,Color("#c0d8e3"))
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(hint)
    equip_stats = _label("",20,Color("#88d8ff"))
    body.add_child(equip_stats)
    body.add_child(_label("CLASS FOR NEXT BATTLE",21,Color("#f3d18c")))
    var class_row := HBoxContainer.new()
    class_row.add_theme_constant_override("separation",6)
    body.add_child(class_row)
    for name: String in V4Progression.CLASSES.keys():
        var class_button: Button = _button(str(V4Progression.CLASSES[name]["name"]),16,54)
        class_row.add_child(class_button)
        class_button.pressed.connect(_choose_class.bind(name))
    equip_message = _label("",17,Color("#f2ca8f"))
    equip_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(equip_message)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(scroll)
    equip_list = VBoxContainer.new()
    equip_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    equip_list.add_theme_constant_override("separation",9)
    scroll.add_child(equip_list)
    var utilities := GridContainer.new()
    utilities.columns = 2
    utilities.add_theme_constant_override("h_separation",8)
    utilities.add_theme_constant_override("v_separation",8)
    body.add_child(utilities)
    for title: String in ["SAVE","LOAD","NEXT ENCOUNTER","NEW CAMPAIGN"]:
        var b: Button = _button(title,18,55)
        utilities.add_child(b)
        b.pressed.connect(_utility.bind(title))

func _command_menu(title: String) -> void:
    if current.is_empty():
        return
    if bool(current.get("finished",false)) and title not in ["EQUIP", "LOG"]:
        return
    match title:
        "ATTACK": _begin_targeting("attack")
        "SKILLS": _options(["arc","cleave","surge","bastion"])
        "MAGIC": _options(["ember","frost","mend"])
        "ITEMS": _options(["potion"])
        "DEFEND": _begin_targeting("guard")
        "EQUIP":
            equip_layer.visible = true
            _refresh_gear(true)
        "END TURN":
            _clear_targeting()
            game.end_player_turn()
        "LOG":
            expanded_log = not expanded_log
            _update_feed()

func _options(kinds: Array[String]) -> void:
    _clear_targeting()
    for kind: String in kinds:
        var def: Dictionary = V3Abilities.DATA[kind]
        var name: String = str(def["name"])
        var cost: int = int(def["cost"])
        var b: Button = _button("%s  %d SP" % [name,cost],16,53)
        b.disabled = game.available_targets(kind).is_empty()
        submenu.add_child(b)
        b.pressed.connect(_begin_targeting.bind(kind))
    prompt.text = "Choose a spell or skill, then tap a highlighted target."

func _begin_targeting(kind: String) -> void:
    _clear_targeting()
    var choices: Array[String] = game.available_targets(kind)
    if choices.is_empty():
        prompt.text = "Unavailable: check MP, turn, and whether the target needs healing. Potions require your action first."
        return
    if kind in ["guard","bastion"]:
        game.player_action(kind,"warden")
        return
    if kind == "potion" and choices.size() == 1:
        _select_target(choices[0],kind)
        return
    pending = kind
    stage.set_targetable(choices)
    prompt.text = "TARGET FOR %s • Tap highlighted combatant or choose below" % str(V3Abilities.DATA[kind]["name"])
    for id: String in choices:
        var actor: V3Unit = game.battle.unit_by_id(id)
        var button: Button = _button(actor.name,15,49)
        target_row.add_child(button)
        button.pressed.connect(_select_target.bind(id))
    var cancel := _button("CANCEL",15,49)
    target_row.add_child(cancel)
    cancel.pressed.connect(_clear_targeting)

func _select_target(id: String, override_kind: String = "") -> void:
    var kind: String = pending if override_kind.is_empty() else override_kind
    if kind.is_empty():
        return
    var used: bool = game.player_action(kind,id)
    if used:
        _clear_targeting()

func _clear_targeting() -> void:
    pending = ""
    stage.set_targetable([])
    for child: Node in submenu.get_children():
        submenu.remove_child(child)
        child.queue_free()
    for child: Node in target_row.get_children():
        target_row.remove_child(child)
        child.queue_free()
    prompt.text = "Select ATTACK, SKILLS, MAGIC, or ITEMS. Healing targets allies."

func _choose_class(klass: String) -> void:
    if game.choose_class(klass):
        equip_message.text = "Class set for your next encounter. Level 2 unlocks a signature skill."
        _refresh_gear(true)

func _utility(title: String) -> void:
    match title:
        "SAVE": game.save_game()
        "LOAD":
            if game.load_game():
                _clear_targeting()
        "NEXT ENCOUNTER":
            if game.battle.finished:
                _clear_targeting()
                game.new_encounter()
                equip_layer.visible = false
            else:
                equip_message.text = "Finish the current battle first. Levels carry forward after victory."
        "NEW CAMPAIGN":
            _clear_targeting()
            game.new_encounter(true)
            equip_layer.visible = false
    if title in ["SAVE", "LOAD"]:
        equip_message.text = title + " command processed."
    _refresh_gear(true)

func _render(state: Dictionary, messages: Array[String]) -> void:
    current = state
    last_events = messages.duplicate()
    var all: Dictionary = {}
    for unit: Dictionary in state["actors"]:
        all[str(unit["id"])] = unit
    var actor: V3Unit = game.battle.active_unit()
    turn_label.text = "ROUND %d   •   %s" % [int(state["round"]),game.battle.result if actor == null else actor.name.to_upper()+"'S TURN"]
    var upcoming := PackedStringArray()
    for index: int in range(int(state["index"]),mini(int(state["index"])+7,state["order"].size())):
        var unit: V3Unit = game.battle.unit_by_id(str(state["order"][index]))
        if unit != null:
            upcoming.append(unit.name)
    initiative_label.text = "NEXT: " + "  ›  ".join(upcoming)
    var progress: Dictionary = state.get("progression", {})
    var members: Dictionary = progress.get("heroes", {})
    var player_progress: Dictionary = members.get("warden", {"level": 1, "xp": 0})
    var current_class: String = str(progress.get("hero_class", "vanguard"))
    progression_label.text = "CLASS: %s   •   LEVEL %d   •   XP %d/%d   •   WINS %d" % [
        str(V4Progression.CLASSES[current_class]["name"]).to_upper(),
        int(player_progress["level"]), int(player_progress["xp"]),
        game.progression.xp_needed(int(player_progress["level"])), int(progress.get("victories", 0))]
    for id: String in hud.keys():
        var unit: Dictionary = all[id]
        var panel: Dictionary = hud[id]
        panel["name"].text = "%s  Lv%d  %d/%d HP  %d MP%s" % [str(unit["name"]).to_upper(),int(unit["level"]),int(unit["hp"]),int(unit["max_hp"]),int(unit["mp"]),"  ❄" if int(unit["chilled"]) > 0 else ""]
        panel["hp"].max_value = float(unit["max_hp"])
        panel["hp"].value = float(unit["hp"])
        panel["name"].add_theme_color_override("font_color", Color("#f6dc93") if actor != null and id == actor.id else Color("#d2e2ec"))
    stage.refresh(state)
    if bool(state["finished"]):
        _clear_targeting()
        prompt.text = "Battle complete: %s. Open EQUIP → NEXT ENCOUNTER to keep XP and gear." % str(state["result"])
    elif actor != null and actor.id != "warden":
        if not pending.is_empty():
            _clear_targeting()
        prompt.text = "AI turns: allies react to wounded teammates; enemies choose tactical targets."
    elif actor != null and actor.action_used:
        prompt.text = "Your regular action is spent. Potion is a BONUS action if anyone is injured. END TURN when ready."
    _update_feed()
    _refresh_gear()

func _update_feed() -> void:
    var selected: Array[String] = last_events if expanded_log else last_events.slice(maxi(0,last_events.size()-2),last_events.size())
    events_label.text = "BATTLE LOG: " + "  |  ".join(PackedStringArray(selected))

func _refresh_gear(force: bool = false) -> void:
    if current.is_empty():
        return
    var player_ready: bool = game.is_player_turn() and not game.battle.active_unit().action_used
    var token: String = JSON.stringify([current["bag"],current["equipment"],current["actors"][0]["hp"],player_ready,current.get("progression",{})])
    if token == gear_cache and not force:
        return
    gear_cache = token
    for child: Node in equip_list.get_children():
        equip_list.remove_child(child)
        child.queue_free()
    var hero: Dictionary = current["actors"][0]
    equip_stats.text = "WARDEN:  %d/%d HP  |  %d POWER  |  %d ARMOR\nPotions: %d" % [
        int(hero["hp"]),int(hero["max_hp"]),int(hero["power"]),int(hero["armor"]),int(current["potions"])]
    var progress: Dictionary = current.get("progression", {})
    var desired_class: String = str(progress.get("hero_class", "vanguard"))
    equip_stats.text += "\nNEXT CLASS: %s   •   VICTORIES: %d" % [V4Progression.CLASSES[desired_class]["name"],int(progress.get("victories",0))]
    for slot: String in ModuleInventory.SLOTS:
        var worn_id: String = str(current["equipment"].get(slot,""))
        var worn_name: String = "Empty" if worn_id.is_empty() else str(ModuleInventory.ITEMS[worn_id]["name"])
        equip_list.add_child(_label(slot.to_upper()+"  •  "+worn_name,21,Color("#f3d18c")))
        if not worn_id.is_empty():
            var remove: Button = _button("UNEQUIP  "+worn_name,18,52)
            remove.disabled = not player_ready
            equip_list.add_child(remove)
            remove.pressed.connect(_change_gear.bind("",slot,false))
    equip_list.add_child(_label("BACKPACK",24,Color("#9eddf4")))
    for id: String in ModuleInventory.ITEMS.keys():
        if int(current["bag"].get(id,0)) < 1:
            continue
        var item: Dictionary = ModuleInventory.ITEMS[id]
        var text_value: String = "%s   +%d PWR  +%d ARM  +%d HP" % [str(item["name"]),int(item["power"]),int(item["armor"]),int(item["hp"])]
        var button: Button = _button(text_value,18,54)
        button.disabled = not player_ready
        equip_list.add_child(button)
        button.pressed.connect(_change_gear.bind(id,"",true))

func _change_gear(item_id: String, slot: String, wearing: bool) -> void:
    if game.alter_equipment(item_id,slot,wearing):
        equip_message.text = "Equipment updated. Regular action spent; return to battle."
    else:
        equip_message.text = "Can't change equipment this turn."
    _refresh_gear(true)

func _label(txt: String, font_size: int, color: Color) -> Label:
    var l := Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size",font_size)
    l.add_theme_color_override("font_color",color)
    return l

func _button(txt: String, font_size: int, height: float) -> Button:
    var b := Button.new()
    b.text = txt
    b.custom_minimum_size = Vector2(0,height)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size",font_size)
    return b
