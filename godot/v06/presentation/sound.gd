class_name V6Sound
extends Node

# Entirely original synthesized fantasy chimes. No external audio libraries,
# licensed music or network streams. WAV buffers are generated only once.
const RATE: int = 16000

var enabled: bool = true
var _effects: Dictionary = {}
var _themes: Dictionary = {}
var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _current_theme: String = ""

func _ready() -> void:
    _music = AudioStreamPlayer.new()
    _music.volume_db = -26.0
    add_child(_music)
    for i: int in range(3):
        var voice := AudioStreamPlayer.new()
        voice.volume_db = -12.0
        add_child(voice)
        _voices.append(voice)
    _effects["ui"] = _tone(740.0, 0.09, "sine")
    _effects["step"] = _tone(360.0, 0.07, "low")
    _effects["shop"] = _tone(980.0, 0.17, "bell")
    _effects["potion"] = _tone(580.0, 0.21, "bell")
    _effects["spell"] = _tone(880.0, 0.24, "bell")
    _effects["hit"] = _tone(180.0, 0.16, "low")
    _effects["victory"] = _tone(1175.0, 0.37, "bell")
    _effects["defeat"] = _tone(190.0, 0.37, "low")
    _effects["portal"] = _tone(630.0, 0.40, "bell")
    _themes["world"] = _melody([220.0, 329.6, 392.0, 329.6, 261.6, 349.2, 440.0, 349.2], 0.42)
    _themes["battle"] = _melody([164.8, 220.0, 246.9, 220.0, 164.8, 196.0, 293.7, 261.6], 0.26)
    set_theme("world")

func set_enabled(value: bool) -> void:
    enabled = value
    if enabled:
        set_theme("world" if _current_theme.is_empty() else _current_theme)
    else:
        _music.stop()
        for voice: AudioStreamPlayer in _voices:
            voice.stop()

func set_theme(mode: String) -> void:
    if not _themes.has(mode):
        return
    if _current_theme == mode and _music.playing:
        return
    _current_theme = mode
    if not enabled:
        return
    _music.stop()
    _music.stream = _themes[mode]
    _music.play()

func play_sfx(kind: String) -> void:
    if not enabled or not _effects.has(kind) or _voices.is_empty():
        return
    var voice: AudioStreamPlayer = _voices[_next_voice]
    _next_voice = (_next_voice + 1) % _voices.size()
    voice.stop()
    voice.stream = _effects[kind]
    voice.play()

func _tone(frequency: float, length_seconds: float, waveform: String) -> AudioStreamWAV:
    var count: int = int(float(RATE)*length_seconds)
    var pcm := PackedByteArray()
    pcm.resize(count*2)
    for i: int in range(count):
        var t: float = float(i)/float(RATE)
        var progress: float = float(i)/float(count)
        var pitch: float = frequency*(1.0-0.23*progress)
        var carrier: float = sin(TAU*pitch*t)
        if waveform == "bell":
            carrier += 0.31*sin(TAU*pitch*2.02*t)
        elif waveform == "low":
            carrier += 0.45*sin(TAU*pitch*0.51*t)
        var envelope: float = pow(1.0-progress, 2.3)
        var amplitude: int = int(clampf(carrier*envelope*9500.0,-32000.0,32000.0))
        pcm.encode_s16(i*2,amplitude)
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = pcm
    return stream

func _melody(notes: Array[float], note_duration: float) -> AudioStreamWAV:
    var frames_per_note: int = int(float(RATE)*note_duration)
    var count: int = frames_per_note*notes.size()
    var pcm := PackedByteArray()
    pcm.resize(count*2)
    for i: int in range(count):
        var note_index: int = mini(i/frames_per_note,notes.size()-1)
        var local: float = float(i%frames_per_note)/float(frames_per_note)
        var t: float = float(i)/float(RATE)
        var f: float = notes[note_index]
        var signal_value: float = 0.54*sin(TAU*f*t)+0.21*sin(TAU*f*2.0*t)+0.18*sin(TAU*f/2.0*t)
        var envelope: float = minf(1.0,local*10.0)*pow(1.0-local,0.6)
        pcm.encode_s16(i*2,int(clampf(signal_value*envelope*6600.0,-32000.0,32000.0)))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = pcm
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = count
    return stream
