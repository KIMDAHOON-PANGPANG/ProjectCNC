class_name VisualResource extends Resource

# 캐릭터 / 단검 / 적의 비주얼을 한 Resource로 묶는다.
# 에셋이 없으면 greybox 색깔/크기로 fallback. 에셋이 들어오면 자동 사용.
# 사양: DOC/dagger_marker_roadmap_supplement.md §H-3

enum Dimension { D2 = 0, D3 = 1 }

@export var dimension: Dimension = Dimension.D2

# ── 그레이박스 (에셋 없을 때 fallback) ─────────────────────────
@export var greybox_color: Color = Color.WHITE
@export var greybox_size_2d: Vector2 = Vector2(8.0, 16.0)
@export var greybox_size_3d: Vector3 = Vector3(0.5, 1.0, 0.5)

# ── 2D 에셋 (들어오면 사용) ─────────────────────────────────────
@export var texture_2d: Texture2D
@export var sprite_frames: SpriteFrames

# ── 3D 에셋 (들어오면 사용) ─────────────────────────────────────
@export var mesh_3d: PackedScene
@export var animation_library: AnimationLibrary


func has_2d_asset() -> bool:
	return texture_2d != null or sprite_frames != null


func has_3d_asset() -> bool:
	return mesh_3d != null
