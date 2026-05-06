extends Node

# BGM placeholder — 단순 sine + 5도 화음 루프.
# 사용자가 BGM 트랙 받으면 _player.stream을 AudioStreamOggVorbis 등으로 교체.

const SAMPLE_RATE: int = 44100
const LOOP_DURATION: float = 4.0  # 4초 루프

var _player: AudioStreamPlayer
var _stream: AudioStreamWAV


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_stream = _build_loop()
	_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_stream.loop_begin = 0
	_stream.loop_end = int(SAMPLE_RATE * LOOP_DURATION)
	_player.stream = _stream
	_player.volume_db = -16.0
	# 자동 시작은 사용자 결정. boss 룸에서만 재생하거나 옵션화 가능.


func play() -> void:
	if not _player.playing:
		_player.play()


func stop() -> void:
	_player.stop()


func set_volume_db(db: float) -> void:
	_player.volume_db = db


# 종료 시 stream / player 정리 — ObjectDB leak 방지.
func _exit_tree() -> void:
	if _player != null and is_instance_valid(_player):
		if _player.playing:
			_player.stop()
		_player.stream = null
	_stream = null


func _build_loop() -> AudioStreamWAV:
	var n_samples: int = int(SAMPLE_RATE * LOOP_DURATION)
	var data := PackedByteArray()
	data.resize(n_samples * 2)

	# A minor (low): A2=110, C3=130.81, E3=164.81. 4초 동안 변주.
	var notes: Array = [
		[110.0, 130.81],
		[110.0, 164.81],
		[ 98.0, 130.81],  # G
		[110.0, 130.81],
	]
	var beat_dur: float = LOOP_DURATION / float(notes.size())

	for i in range(n_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat: int = int(t / beat_dur) % notes.size()
		var f1: float = notes[beat][0]
		var f2: float = notes[beat][1]
		var beat_t: float = fmod(t, beat_dur) / beat_dur
		# 각 비트마다 빠른 어택 + decay
		var env: float = exp(-1.0 * beat_t) * (1.0 - exp(-10.0 * beat_t))
		var s: float = sin(TAU * f1 * t) * 0.5 + sin(TAU * f2 * t) * 0.5
		var v: int = int(clamp(s * env * 0.18, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xff
		data[i * 2 + 1] = (v >> 8) & 0xff

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav
