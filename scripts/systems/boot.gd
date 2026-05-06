extends Node

# main.tscn 부팅 헬퍼.
# 첫 룸을 RoomManager에 등록 + Player 위치를 룸 spawn으로 이동.


func _ready() -> void:
	await get_tree().process_frame
	var rm: Node = get_node_or_null("/root/RoomManager")
	if rm == null:
		return
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var world: Node = root.get_node_or_null("World")
	if world == null:
		return
	for c in world.get_children():
		if c is RoomBase:
			rm.register_room(c)
			var player: Node = root.get_node_or_null("Player")
			var spawn: Node = c.get_node_or_null("Spawn")
			if player != null and spawn != null and spawn is Node2D:
				player.global_position = (spawn as Node2D).global_position
			break
	# 챕터 시작 페이드 인
	var transition: Node = get_node_or_null("/root/Transition")
	if transition != null and transition.has_method("fade_in_only"):
		transition.fade_in_only()
	# BGM 시작 (옵션)
	var bgm: Node = get_node_or_null("/root/Bgm")
	if bgm != null and bgm.has_method("play"):
		bgm.play()
