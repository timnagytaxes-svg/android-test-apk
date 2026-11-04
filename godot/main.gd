extends Control

var message: Label

func _ready() -> void:
    var layout := VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layout.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_theme_constant_override("separation", 28)
    add_child(layout)

    message = Label.new()
    message.text = "GODOT APK TEST"
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message.add_theme_font_size_override("font_size", 42)
    layout.add_child(message)

    var button := Button.new()
    button.text = "TEST GODOT BUTTON"
    button.custom_minimum_size = Vector2(0, 100)
    button.add_theme_font_size_override("font_size", 28)
    button.pressed.connect(_on_button_pressed)
    layout.add_child(button)

func _on_button_pressed() -> void:
    message.text = "GODOT WORKS!"
