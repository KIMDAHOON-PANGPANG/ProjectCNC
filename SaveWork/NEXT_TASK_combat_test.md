# NEXT_TASK: 미니멀 전투 테스트 셋업

**작성**: 2026-05-07
**대상**: 다음 세션의 Claude (집 PC에서 이어 작업)
**사용자 요청 원문**: "돌아다니는 기본 근접 추적 몬스터 1개랑 레벨 플레이 할 수 있도록 어떻게 하면 좋을지 제안해줘. 단검과 3타를 활용한 전투와 레벨 플레이 가볍게 테스트 해보고 싶어"

---

## 0. 결정된 방향 (옵션 b 채택)

**기존 자산 검토 결과**:
- `scenes/sandbox.tscn` — Player + Dummy(행동 없음) + 단순 벽 4면 → 적이 안 움직임
- `scripts/enemies/melee_charger.gd` — "정지 → 텔레그래프(0.6s) → 돌진" 패턴 → **계속 추적 아님**
- `scenes/rooms/room_01_tutorial.tscn` — 좌/우 플랫폼 + 골 트리거 → 적 없음

사용자가 원하는 "**돌아다니며 추적**"은 charger와 다른 행동이라 신규 스크립트 필요. 추후 적 4종 검증용 테스트 베드로 재사용 가능하도록 **새 chaser + 새 테스트 씬** 방향 채택.

대안 (b)/(c)는 본 문서 §5 참고.

---

## 1. 작업 목록

### 1-A. 신규 파일 — `scripts/enemies/melee_chaser.gd` (~40줄)

**사양**:
- `class_name MeleeChaser extends EnemyBase`
- 텔레그래프 없이 **항상 플레이어 방향으로 천천히 걸어옴**
- 벽 / 절벽 만나면 잠깐 정지 (절벽 추락 방지 — `is_on_floor()` + 전방 RayCast)
- HP 1 (기존 `enemy_base.gd` 사양 유지)
- 단검 경직 → F 워프 → 좌클릭 처형 플로우 그대로 작동해야 함
- 그룹 `"enemies"` 자동 등록 (EnemyBase가 처리)

**제안 파라미터**:
```gdscript
@export var detect_range: float = 200.0   # 발견 거리 (charger보다 넓게)
@export var chase_speed: float = 40.0     # 천천히 추적 (charger 80 절반)
@export var stop_at_player_dist: float = 16.0  # 너무 가까우면 멈춤
```

**AI 로직 (단순)**:
```
- player not detected → IDLE (그냥 서있음, 또는 좌우 패트롤 옵션)
- player detected & dist > stop_at_player_dist → 플레이어 방향 horizontal 이동
- player detected & dist <= stop_at_player_dist → velocity.x = 0 (접촉 데미지는 일단 X)
- 절벽 또는 벽 감지 → 정지
```

절벽 감지 패턴:
```gdscript
# 진행 방향 발 끝 앞에 raycast 내려서 floor가 없으면 멈춤
var probe_offset: float = 8.0 * sign(velocity.x)
var probe_pos: Vector2 = global_position + Vector2(probe_offset, 8)
# 간단히: $FloorProbe RayCast2D 노드를 씬에 추가하거나, PhysicsRayQueryParameters2D 사용
```

> 제일 간단한 구현은 **씬에 RayCast2D 두 개** (전방 벽 감지 + 전방 발 아래 절벽 감지) 추가 후 코드에서 `is_colliding()` 체크.

### 1-B. 신규 비주얼 리소스 (선택)

- `resources/visual/enemy_chaser_2d.tres` — 기존 `enemy_charger_2d.tres` 복제 후 색만 다르게 (예: 연한 빨강 vs 진한 빨강) → 시각적으로 구분
- 또는 그냥 `enemy_charger_2d.tres` 재사용 (스킵 가능)

### 1-C. 신규 씬 — `scenes/test/combat_test.tscn`

**구조** (room_01 레이아웃 베이스):
```
CombatTest (Node2D)
├── World (Node2D)
│   ├── Floor (StaticBody2D) — 480×16
│   ├── Ceiling (StaticBody2D) — 480×16
│   ├── WallLeft (StaticBody2D) — 16×240
│   ├── WallRight (StaticBody2D) — 16×240
│   ├── LeftPlatform (StaticBody2D) — 16×32 @ (80, 200)
│   ├── RightPlatform (StaticBody2D) — 16×32 @ (400, 200)
│   └── MidPlatform (StaticBody2D) — 32×8 @ (240, 180)  ← 추가
├── Chaser (instance: melee_chaser_2d.tscn) @ (380, 240)
├── DaggerLayer (Node2D, z_index=10)
├── Player (instance: player_2d.tscn) @ (100, 200)
│   └── Camera (Camera2D)
└── HUD (CanvasLayer)
    ├── EdgeIndicator (Control + edge_indicator.gd)
    └── (선택) HUD 라벨 추가 — DAGGERS/MARKERS
```

**참고 기준 씬**: `scenes/sandbox.tscn` (구조 거의 동일, Dummy → Chaser 교체 + 플랫폼 1개 추가)

### 1-D. 신규 씬 — `scenes/enemies/melee_chaser_2d.tscn`

**참고**: `scenes/enemies/melee_charger_2d.tscn` 복제 후
- 스크립트 → `melee_chaser.gd`
- visual → `enemy_chaser_2d.tres` (또는 charger 재사용)
- 자식 노드로 RayCast2D 두 개 추가:
  - `WallProbe` (전방 8px, 수평)
  - `CliffProbe` (전방 8px, 아래 16px)

---

## 2. 테스트 방법

### 부팅
```
Godot 에디터 → scenes/test/combat_test.tscn 열기 → F6 (현재 씬 실행)
```

main_scene 변경 불필요. 그래도 검증하려면:
```bash
"$GODOT_BIN" --path "$PROJECT_PATH" "res://scenes/test/combat_test.tscn"
```

### 테스트 시나리오 (사용자 수동)
| # | 동작 | 확인 |
|---|---|---|
| 1 | 적이 플레이어 향해 천천히 걸어옴 | detect_range 안 들어가면 추적 시작 |
| 2 | 좌클릭 3타 콤보 | 1→2→3 시각화 + 3타 시 hit stop 0.035s |
| 3 | 콤보로 적 경직 → 처형 가능? | EnemyBase.is_executable() 통과 |
| 4 | 우클릭 단검 → F 워프 → 좌클릭 | 처형 플로우 정상? |
| 5 | 우클릭 0.5s 충전 던지기 | 관통 모션 작동? |
| 6 | 좌측 플랫폼에서 적 향해 던지기 | 레벨 동선 + 마커 박힘? |
| 7 | 절벽 (없으면 추가) 가장자리에서 적 행동 | 떨어지지 않음? |

### KILL 기준
- 적이 절벽에서 떨어지면 → CliffProbe 로직 수정
- 추적 너무 빠르거나 느리면 → `chase_speed` 조정
- 콤보 hit이 적에 안 맞으면 → `enemy_base.gd`의 collision_layer (현재 `8`) 확인 + player attack hitbox mask 확인

---

## 3. §I-7 자체 검증 (작업 완료 후 필수)

기존 워크플로우 그대로:
```bash
source <(bash SaveWork/env_check.sh --export)

rm -rf "$PROJECT_PATH/.godot" /tmp/run_*.log "$CSV_PATH" 2>/dev/null
"$GODOT_BIN" --headless --path "$PROJECT_PATH" --import 1>/tmp/run_import.log 2>&1
"$GODOT_BIN" --path "$PROJECT_PATH" "res://scenes/test/combat_test.tscn" --quit-after 300 1>/tmp/run_combat.log 2>&1

grep -iE "error|fail|push_error|push_warning|invalid|cannot|not found|null inst" /tmp/run_*.log | \
  grep -vE "DOTNET|Asio|Vulkan|D3D12|TextServer|XR_|OpenXR|FFmpeg|Native mobile|Failed to bind|MultiUma|Orphan|unclaimed|AudioStreamWAV|AudioStreamPlayback|leaked at exit|^$"
```
빈 줄이면 통과.

---

## 4. 예상 작업 시간

| 작업 | 추정 |
|---|---|
| melee_chaser.gd 작성 | 15분 |
| RayCast 노드 추가 + 씬 구성 | 10분 |
| combat_test.tscn 빌드 | 10분 |
| visual 리소스 복제 (선택) | 5분 |
| 자체 검증 + 디버그 | 15분 |
| **합계** | **45~55분** |

---

## 5. 대안 (참고용, 채택 안 함)

- **(a) 기존 `melee_charger`를 sandbox에 끼워넣기**
  - 가장 빠름 (5분), 단 텔레그래프 패턴이라 "돌아다니며 추적" 느낌 약함
- **(c) sandbox.tscn에 charger 즉시 끼우고 chaser는 나중에**
  - 즉시 콤보 테스트는 가능하나, 결국 chaser 만들어야 함 → 작업 분리되는 단점

---

## 6. 시작 체크리스트 (집 PC 도착 후)

```
1. SaveWork/NEXT_SESSION.md §0 절차 따라 환경 셋업 (env_check.sh)
2. §I-7 3단계 검증으로 현재 코드 정상 작동 확인
3. 본 파일 (NEXT_TASK_combat_test.md) §1 순서대로 작업
   3-1. melee_chaser.gd 작성
   3-2. melee_chaser_2d.tscn 작성
   3-3. combat_test.tscn 작성
4. F6으로 부팅 → §2 시나리오 수동 테스트
5. §3 §I-7 검증 통과 후 커밋 + 푸시
6. SaveWork/NEXT_SESSION.md §3 진행 상황 업데이트
```

---

## 7. 참고 파일 위치

| 항목 | 경로 |
|---|---|
| 인수인계 | `SaveWork/NEXT_SESSION.md` |
| 단일 진실 소스 | `DOC/dagger_marker_roadmap_supplement.md` (§I-7, §J 룸 카탈로그) |
| 진행 트래킹 | `DOC/dagger_marker_roadmap.html` |
| EnemyBase | `scripts/enemies/enemy_base.gd` |
| 참고할 적 | `scripts/enemies/melee_charger.gd` |
| 참고할 룸 | `scenes/rooms/room_01_tutorial.tscn` |
| 참고할 sandbox | `scenes/sandbox.tscn` |
| Player | `scripts/player/player_body_2d.gd` (콤보 로직 line 327~) |
