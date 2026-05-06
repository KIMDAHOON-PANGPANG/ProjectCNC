extends Node

# 모든 튜닝 수치를 한 파일에서 관리한다.
# Cyber Shadow / 닌자일섬 베이스라인 90% 카피 + 단검 시스템만 차별화.
# 출처: DOC/dagger_marker_roadmap_supplement.md §A

# ── 이동 (데드카피) ────────────────────────────────────────────
const MAX_RUN: float = 110.0
const RUN_ACCEL: float = 800.0
const RUN_DECEL: float = 1200.0
const AIR_ACCEL: float = 500.0

# ── 점프 (데드카피) ────────────────────────────────────────────
const JUMP_VELOCITY: float = -280.0
const JUMP_CUT_MULT: float = 0.5
const COYOTE_TIME: float = 0.08
const JUMP_BUFFER: float = 0.10

# ── 중력 (데드카피) ────────────────────────────────────────────
const GRAVITY: float = 980.0
const FALL_GRAVITY_MULT: float = 1.4
const MAX_FALL: float = 320.0

# ── 텔레포트 (차별화) ──────────────────────────────────────────
const TELEPORT_DURATION: float = 0.12
const TELEPORT_IFRAME: float = 0.18
const TELEPORT_BUFFER: float = 0.10

# ── 단검 / 마커 (차별화) ───────────────────────────────────────
const DAGGER_SPEED: float = 800.0
const DAGGER_LIFETIME: float = 8.0
const MARKER_MAX_COUNT: int = 3
const DAGGER_AMMO_MAX: int = 3
const BOUNCE_SPEED_RATIO: float = 0.7

# ── 체인 보너스 (차별화) ───────────────────────────────────────
const CHAIN_BONUS_WINDOW: float = 0.4
const CHAIN_TELEPORT_CD_REDUCTION: float = 0.5

# ── 적 (Phase 1) ───────────────────────────────────────────────
const DUMMY_HP: int = 1
const DUMMY_STUN_DURATION: float = 0.5
const EXECUTION_WINDOW: float = 0.3

# ── Game Feel placeholder (Day 5 일괄) ─────────────────────────
const HIT_STOP_MS: float = 0.05
const SHAKE_AMPLITUDE: float = 4.0
const SHAKE_DURATION: float = 0.08
const ZOOM_PUNCH_SCALE: float = 1.05
const ZOOM_PUNCH_DURATION: float = 0.15

# ── 진동 (Game Feel placeholder) ───────────────────────────────
const RUMBLE_THROW_DURATION: float = 0.08
const RUMBLE_THROW_AMP: float = 0.2
const RUMBLE_PLANT_DURATION: float = 0.06
const RUMBLE_PLANT_AMP: float = 0.6
const RUMBLE_TELEPORT_DURATION: float = 0.1
const RUMBLE_TELEPORT_AMP: float = 0.3
const RUMBLE_EXECUTION_DURATION: float = 0.12
const RUMBLE_EXECUTION_AMP: float = 0.7

# ── Physics Layers (project.godot Layer 명명과 일치) ───────────
const LAYER_WORLD: int = 1
const LAYER_WORLD_BOUNCY: int = 2
const LAYER_PLAYER: int = 3
const LAYER_ENEMY: int = 4
const LAYER_DAGGER: int = 5
const LAYER_HAZARD: int = 6
