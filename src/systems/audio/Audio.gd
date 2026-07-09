class_name Audio
extends RefCounted
## Procedurally-synthesized audio (no binary assets — this GitHub integration
## can't commit raw audio, and code-gen suits the low-fi indie vibe anyway).
## Each sound is built once as an AudioStreamWAV from generated PCM and cached.
## The Audio agent can later swap these for authored clips via CI/base64.

const RATE := 22050
static var _cache := {}

static func get_stream(name: String) -> AudioStreamWAV:
    if _cache.has(name):
        return _cache[name]
    var s: AudioStreamWAV
    match name:
        "ambience": s = _ambience()
        "fire": s = _fire()
        "whoosh": s = _whoosh()
        "thud": s = _thud()
        "growl": s = _growl()
        "chime": s = _chime()
        "hurt": s = _hurt()
        _: s = _whoosh()
    _cache[name] = s
    return s

static func _make(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
    var s := AudioStreamWAV.new()
    s.format = AudioStreamWAV.FORMAT_16_BITS
    s.mix_rate = RATE
    s.stereo = false
    var n := samples.size()
    var bytes := PackedByteArray()
    bytes.resize(n * 2)
    for i in n:
        var v := clampf(samples[i], -1.0, 1.0)
        bytes.encode_s16(i * 2, int(v * 32767.0))
    s.data = bytes
    if loop:
        s.loop_mode = AudioStreamWAV.LOOP_FORWARD
        s.loop_begin = 0
        s.loop_end = n - 1
    return s

static func _ambience() -> AudioStreamWAV:
    var n := RATE * 3
    var buf := PackedFloat32Array()
    buf.resize(n)
    for i in n:
        var t := float(i) / RATE
        var v := sin(TAU * 42.0 * t) * 0.35
        v += sin(TAU * 56.0 * t) * 0.22
        v += sin(TAU * 63.0 * t) * 0.16
        v += (randf() * 2.0 - 1.0) * 0.05
        var lfo := 0.7 + 0.3 * sin(TAU * 0.15 * t)
        buf[i] = v * lfo * 0.5
    return _make(buf, true)

static func _fire() -> AudioStreamWAV:
    var n := int(RATE * 1.6)
    var buf := PackedFloat32Array()
    buf.resize(n)
    var level := 0.0
    for i in n:
        level = clampf(level + (randf() * 2.0 - 1.0) * 0.15, -1.0, 1.0)
        var v := level * 0.18
        if randf() < 0.004:
            v += (randf() * 2.0 - 1.0) * 0.6
        buf[i] = v
    return _make(buf, true)

static func _whoosh() -> AudioStreamWAV:
    var n := int(RATE * 0.22)
    var buf := PackedFloat32Array()
    buf.resize(n)
    var prev := 0.0
    for i in n:
        var t := float(i) / n
        var env := sin(PI * t)
        prev = prev * 0.6 + (randf() * 2.0 - 1.0) * 0.4
        buf[i] = prev * env * 0.5
    return _make(buf, false)

static func _thud() -> AudioStreamWAV:
    var n := int(RATE * 0.25)
    var buf := PackedFloat32Array()
    buf.resize(n)
    for i in n:
        var t := float(i) / RATE
        var env := exp(-t * 18.0)
        var v := sin(TAU * 95.0 * t) * env
        v += (randf() * 2.0 - 1.0) * env * 0.25
        buf[i] = v * 0.7
    return _make(buf, false)

static func _growl() -> AudioStreamWAV:
    var n := int(RATE * 0.5)
    var buf := PackedFloat32Array()
    buf.resize(n)
    for i in n:
        var t := float(i) / RATE
        var env := clampf(sin(PI * (t / 0.5)), 0.0, 1.0)
        var base := sin(TAU * 80.0 * t) + sin(TAU * 120.0 * t) * 0.5
        var trem := 0.6 + 0.4 * sin(TAU * 22.0 * t)
        buf[i] = (base * trem + (randf() * 2.0 - 1.0) * 0.2) * env * 0.35
    return _make(buf, false)

static func _chime() -> AudioStreamWAV:
    var n := int(RATE * 0.4)
    var buf := PackedFloat32Array()
    buf.resize(n)
    for i in n:
        var t := float(i) / RATE
        var env := exp(-t * 6.0)
        var v := sin(TAU * 660.0 * t) * 0.6 + sin(TAU * 990.0 * t) * 0.3
        buf[i] = v * env * 0.35
    return _make(buf, false)

static func _hurt() -> AudioStreamWAV:
    var n := int(RATE * 0.2)
    var buf := PackedFloat32Array()
    buf.resize(n)
    for i in n:
        var t := float(i) / RATE
        var env := exp(-t * 12.0)
        var f := maxf(220.0 - 400.0 * t, 60.0)
        var v := sin(TAU * f * t) * 0.6 + (randf() * 2.0 - 1.0) * 0.3
        buf[i] = v * env * 0.5
    return _make(buf, false)
