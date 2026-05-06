extends Node

# SFX placeholder — AudioStreamGenerator로 procedural tone 생성.
# 사용자가 freesound CC0 받으면 _make_tone를 AudioStreamWAV preload로 교체.

const SAMPLE_RATE: int = 44100

# (start_freq, end_freq, duration, attack, decay, kind)
# kind: "sine" | "noise" | "pulse"
const PRESETS: Dictionary = {
	"throw":    { "f0": 600.0, "f1": 200.0, "dur": 0.06, "kind": "sine",  "vol": 0.25 },
	"plant":    { "f0": 180.0, "f1":  80.0, "dur": 0.10, "kind": "noise", "vol": 0.30 },
	"teleport": { "f0": 800.0, "f1": 380.0, "dur": 0.12, "kind": "sine",  "vol": 0.30 },
	"execute":  { "f0": 120.0, "f1":  60.0, "dur": 0.20, "kind": "noise", "vol": 0.40 },
	"hit":      { "f0": 300.0, "f1": 150.0, "dur": 0.05, "kind": "pulse", "vol": 0.22 },
}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _player_idx: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 4개 player pool (동시 재생)
	for i in range(4):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	# preset stream 캐싱
	for key in PRESETS.keys():
		_streams[key] = _make_tone(PRESETS[key])


func play(name: String) -> void:
	if not _streams.has(name):
		return
	var stream: AudioStreamWAV = _streams[name]
	var p: AudioStreamPlayer = _players[_player_idx]
	_player_idx = (_player_idx + 1) % _players.size()
	p.stream = stream
	p.volume_db = -2.0
	p.play()


# autoload 종료 시 stream / playback 명시적 해제 — ObjectDB leak 방지.
func _exit_tree() -> void:
	for p in _players:
		if is_instance_valid(p):
			if p.playing:
				p.stop()
			p.stream = null
	_players.clear()
	_streams.clear()


# Procedural tone 생성. AudioStreamWAV(16-bit PCM mono).
func _make_tone(preset: Dictionary) -> AudioStreamWAV:
	var dur: float = preset.dur
	var f0: float = preset.f0
	var f1: float = preset.f1
	var kind: String = preset.kind
	var vol: float = preset.vol
	var n_samples: int = int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(n_samples * 2)

	var phase: float = 0.0
	var noise_seed: int = 12345
	for i in range(n_samples):
		var t: float = float(i) / float(n_samples)
		var freq: float = lerp(f0, f1, t)
		# envelope: 빠른 attack + 지수 decay
		var env: float = exp(-3.0 * t) * (1.0 - exp(-30.0 * t))
		var sample: float
		match kind:
			"sine":
				phase += TAU * freq / SAMPLE_RATE
				sample = sin(phase)
			"noise":
				noise_seed = (noise_seed * 1103515245 + 12345) & 0x7fffffff
				sample = float(noise_seed % 32767) / 32767.0 * 2.0 - 1.0
				phase += TAU * freq / SAMPLE_RATE
				sample = sample * 0.6 + sin(phase) * 0.4
			"pulse":
				phase += TAU * freq / SAMPLE_RATE
				sample = 1.0 if sin(phase) > 0.0 else -1.0
			_:
				sample = 0.0
		var v: int = int(clamp(sample * env * vol, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xff
		data[i * 2 + 1] = (v >> 8) & 0xff

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav
