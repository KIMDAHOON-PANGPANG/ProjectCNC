# Dagger Marker Roadmap — Supplement

본 문서는 `dagger_marker_roadmap.html`의 보강 자료입니다. HTML은 진행 트래킹용(체크박스 / 게이팅), 본 문서는 구현 레퍼런스용(수치표 / 사양 / 파일 트리)입니다.

> **데드카피 원칙**: 이동·점프·코요테·점프버퍼·평타 캔슬은 Cyber Shadow / 닌자일섬 수치를 90% 그대로 카피합니다. 차별화는 단검 시스템(던지기 / Bounce Chain / 텔레포트)에 한정합니다.

---

## §A 데드카피 베이스라인 수치표

`scripts/globals/game_constants.gd`에 그대로 박힐 상수 표.

| 상수 | 값 | 비고 |
|---|---|---|
| `MAX_RUN` | 110 | 최대 지상 이동 속도 (px/s) |
| `RUN_ACCEL` | 800 | 지상 가속 |
| `RUN_DECEL` | 1200 | 지상 감속 (마찰) |
| `AIR_ACCEL` | 500 | 공중 좌우 제어 |
| `JUMP_VELOCITY` | -280 | 점프 초속 (위쪽 음수) |
| `JUMP_CUT_MULT` | 0.5 | 점프 키 떼면 상승속도 절반 |
| `COYOTE_TIME` | 0.08 | 5프레임 |
| `JUMP_BUFFER` | 0.10 | 6프레임 |
| `GRAVITY` | 980 | 중력 |
| `FALL_GRAVITY_MULT` | 1.4 | 하강 시 중력 가속 |
| `MAX_FALL` | 320 | 종속 (terminal velocity) |
| `TELEPORT_DURATION` | 0.12 | Tween 0.10~0.20 사이, 카타리나 점멸 느낌 |
| `TELEPORT_IFRAME` | 0.18 | 텔레포트 종료 후 6프레임 추가 무적 |
| `TELEPORT_BUFFER` | 0.10 | 점프 버퍼와 동일 |
| `DAGGER_SPEED` | 800 | 단검 초속 (px/s) |
| `DAGGER_LIFETIME` | 8.0 | 박힌 마커 자동 소멸 (초) |
| `MARKER_MAX_COUNT` | 3 | 동시 활성 마커 max |
| `DAGGER_AMMO_MAX` | 3 | 던질 수 있는 단검 잔여 max |
| `BOUNCE_SPEED_RATIO` | 0.7 | 적 튕김 후 속도 70% 유지 |
| `CHAIN_BONUS_WINDOW` | 0.4 | 텔레포트 후 다음 던지기 보너스 윈도우 |
| `CHAIN_TELEPORT_CD_REDUCTION` | 0.5 | 보너스 시 텔레포트 쿨다운 -50% |

### 데드카피 vs 차별화 매핑

| Cyber Shadow / 닌자일섬 | 본 게임 | 비고 |
|---|---|---|
| 더블 점프 | **삭제 — 단검+텔레포트로 대체** | 공중 기동력은 단검 1회 = 점프 1회 분량 |
| 벽 슬라이드 / 벽 점프 | **삭제 — 벽 박힘+텔레포트로 대체** | 모든 벽 등반은 마커 동사로 |
| 평타 3타 콤보 | 그대로 카피 | 마지막 타에서만 점프 캔슬 |
| 공격 캔슬 윈도우 | 그대로 카피 + **단검 던지기는 모든 모션 캔슬** | 단검 = 긴급 회피 일부 흡수 |
| 입력 우선순위 | 점프 > **텔레포트(마커 있을 때만)** > 대시 > 공격 | 텔레포트 우선순위 신규 |
| 코요테/점프버퍼 | 그대로 카피 | 텔레포트도 동일 버퍼 적용 |

---

## §B Bounce Chain 메커닉 사양

### B-1. 단검 비행 / 박힘 / 튕김

```
DaggerStates: FLYING -> [HIT_WALL | HIT_ENEMY | EXPIRED]

FLYING
 ├ body_entered(wall):
 │   - 즉시 박힘 (freeze=true)
 │   - marker_planted(pos) emit
 │   - state = STUCK
 │
 ├ body_entered(wall_bouncy):       # "튕김면" 태그
 │   - 1회 반사 (입사각 = 반사각, 속도 100% 유지)
 │   - bounce_count++ (max 1, 그 후엔 즉시 박힘)
 │
 ├ body_entered(enemy):
 │   - 적 1회 튕김 (반사 벡터 + 속도 70%)
 │   - 적 0.5초 경직 (처형 대기 상태)
 │   - bounce_count++ (max 1)
 │   - state = FLYING (계속 비행)
 │
 └ lifetime > 8s:
     - 박힌 상태에서 자동 소멸
     - marker_removed emit
```

### B-2. 마커 관리 (`marker_manager.gd` autoload)

```
markers: Array[Dagger]                # 활성 마커 (max 3)
ammo: int = 3                          # 던질 수 있는 단검 잔여

on dagger_thrown:
  ammo -= 1

on marker_planted(dagger):
  if markers.size() >= 3:
    markers[0].queue_free()            # 가장 오래된 것 제거
    markers.pop_front()
  markers.append(dagger)
  markers_changed emit

on marker_recovered(dagger):           # 텔레포트 도착 또는 처형
  markers.erase(dagger)
  ammo += 1
  markers_changed emit

on marker_expired(dagger):              # 8초 자동 소멸 — ammo 동일하게 +1
  markers.erase(dagger)
  ammo += 1                             # 단검 사라지면 어떤 경우든 ammo 복구
  markers_changed emit

func get_nearest_marker(player_pos: Vector2) -> Dagger:
  # 거리 + 각도 가중치로 선택 (입력 방향과 일치하면 가산점)
```

### B-3. 카타리나 W+E 횡스크롤 변환

| LoL Katarina | 본 게임 | 변환 노트 |
|---|---|---|
| W (대거 떨굼, 1.5s 후 폭발) | `dagger_throw`: 즉시 박힘, 8s 후 소멸 | 폭발은 Phase 3 변수로 미룸 |
| E (대상 점멸 + 데미지) | `teleport`: 가장 가까운 마커로 점멸 | 도착 위치 적이면 `attack` 0.3s 윈도우 = 처형 |
| Q (단검 회수 + 첫 적 데미지) | 평타가 회수 역할 | 적 처형 시 자동 회수 +1 |
| 패시브 (대거 줍기 = 쿨감) | 마커 회수 시 단검 잔여 +1 | LoL 그대로 |

### B-4. 체인 보너스

- 텔레포트 직후 **0.4초** (`CHAIN_BONUS_WINDOW`) 내 `dagger_throw` 시 → 다음 텔레포트 쿨다운 50% 감소
- 4연쇄 이상 성공 시: 카메라 줌펀치(scale 1.05) + 화면 채도 1.2배 (시각 보상)

### B-5. 충전 던지기 (Phase 3 변수, 기본은 비활성)

- `dagger_throw` 길게 누르기(0.5s) → 관통 + 2회 튕김 강화 단검
- Phase 3에서 도입 결정 시에만 활성화

---

## §C 코어 룸 5개 사양 (Phase 2)

### Room 01: Tutorial Pit
- **공간**: 30×20 타일, 좌측 발판 → 우측 발판 사이 거리 12타일 (점프로 불가능)
- **강제 패턴**: 천장에 단검 박기 → 텔레포트 → 우측 착지
- **적**: 없음 (튜토리얼)
- **평균 텔레포트**: 1회
- **메커닉 우회 가능?**: 불가 (점프 거리 부족)

### Room 02: Bounce Wall
- **공간**: 8타일 폭 / 30타일 높이 수직 통로, 좌우 벽 모두 "튕김면"
- **강제 패턴**: 사선 던지기 → 좌→우→좌 사다리 형성 → 마커 점멸 사다리
- **적**: 통로 중간 원거리 적 1마리 (텔레포트 위치 견제)
- **평균 텔레포트**: 3회
- **메커닉 우회 가능?**: 불가 (8타일 폭은 점프로 못 오름)

### Room 03: Enemy Hopscotch
- **공간**: 가로 40타일, 바닥 절반은 가시 즉사존
- **강제 패턴**: 적 → 적 → 적 사이 단검 튕김 → 적 위 마커 연속 텔레포트 처형
- **적**: 가시 위에 부유 더미 4마리 일렬
- **평균 텔레포트**: 4회
- **메커닉 우회 가능?**: 부분적 가능 (적 우회 시 가시에 빠짐)

### Room 04: Falling Ceiling
- **공간**: 가로 30타일, 천장이 매초 1타일씩 내려옴 (15초 제한)
- **강제 패턴**: 천장→벽→천장 마커 체인 빠른 형성 + 빠른 소비 (3초 윈도우)
- **적**: 없음 (시간 압박이 적 역할)
- **평균 텔레포트**: 5회
- **메커닉 우회 가능?**: 부분적 가능 (그러나 시간 부족)

### Room 05: Boss Mini Arena
- **공간**: 24×16 닫힌 원형 아레나
- **강제 패턴**: Bounce Chain으로 4마커 형성 → 4연쇄 텔레포트 처형
- **적**: 근접 2 + 원거리 2 (동시 등장)
- **평균 텔레포트**: 4~6회
- **메커닉 우회 가능?**: 불가 (원거리 적 견제 + 시간 압박)

> **검증 룰**: 5룸 중 최소 3룸이 "Bounce Chain 강제"여야 함. `room_base.gd`가 클리어 시 텔레포트 횟수를 기록하고, 평균 텔레포트 < 1이면 우회된 것으로 카운트.

---

## §D Game Feel 체크리스트

### D-1. Phase 1 placeholder (Day 5에 일괄 적용)

| 동사 | 시각 (Visual) | 청각 (Audio) | 촉각 (Rumble) |
|---|---|---|---|
| **던지기** | Line2D 트레일 6프레임 + alpha fade | freesound CC0 "whoosh" | 0.08s / amp 0.2 |
| **박힘** | 마커 위치 색깔 점멸 1회 | freesound CC0 "metal hit" | 0.06s / amp 0.6 (강한 단발) |
| **텔레포트** | Sprite 5복제 잔상 (60ms 간격) + 줌펀치 1.05 (0.15s) | freesound CC0 "zap" | 0.1s / amp 0.3 |
| **처형** | 히트스탑 50ms + 카메라셰이크 amp 4 / 80ms | (위 SFX 합성) | 0.12s / amp 0.7 |

**구현 가이드**:
- 히트스탑: `hit_stop.gd` autoload → `Engine.time_scale = 0.0` → 50ms 후 `1.0`
- 카메라 셰이크: `phantom_camera` addon (Day 5에 도입)
- 트레일: `Line2D` 자식 + 마지막 6프레임 위치 추적
- 잔상: `Sprite2D` 5복제 + alpha decay 0.2/frame
- 진동: `Input.start_joy_vibration(0, weak, strong, duration)`

### D-2. Phase 3 폴리시 (광고용 수준 재작업)

| 동사 | Phase 1 → Phase 3 |
|---|---|
| 던지기 | Line2D → `GPUParticles2D` + 잔광 + 모션블러 셰이더 |
| 박힘 | 색깔 점멸 → 표면별 5종 다른 이펙트 (벽=먼지/철=스파크/적=피/돌=파편/나무=조각) |
| 박힘 SFX | "metal hit" 1종 → 표면 5종 × SFX |
| 텔레포트 | Sprite 잔상 → 디졸브 셰이더 + 잔상 8장 + 색수차 + 모션 라인 |
| 진동 | 단발 → 출발/도착 분리 진동 곡선 (양 끝 펀치) |

### D-3. Phase 2는 폴리시 손대지 않음

Phase 2의 목표는 룸 디자인 검증. 폴리시를 만지면 검증 시간이 줄어듭니다. Day 5 placeholder 그대로 Phase 2 통과 → Phase 3에서 일괄 폴리시.

---

## §E 핵심 파일 / 씬 트리

### E-1. 씬 (`res://scenes/`)

| 경로 | 루트 노드 | 자식 |
|---|---|---|
| `main.tscn` | Node | World, Player, DaggerLayer, HUD, DebugOverlay |
| `player/player.tscn` | CharacterBody2D | Sprite2D, CollisionShape2D, StateMachine |
| `player/player_camera.tscn` | Camera2D (or PhantomCamera2D Day 5+) | — |
| `dagger/dagger.tscn` | RigidBody2D (CCD 켬) | Sprite2D, CollisionShape2D, Trail(Line2D), LifetimeTimer |
| `dagger/marker_indicator.tscn` | Node2D | Sprite2D (마커 박힘 위치 표시) |
| `enemies/dummy.tscn` | CharacterBody2D | Sprite2D, CollisionShape2D, HealthComponent |
| `ui/hud.tscn` | CanvasLayer | DaggerAmmoCount, EdgeIndicator |
| `ui/edge_indicator.tscn` | Control | (자식 동적 생성) |

### E-2. 스크립트 (`res://scripts/`)

| 경로 | 역할 |
|---|---|
| `globals/game_constants.gd` (autoload) | §A 표 상수 — 한 파일에서 다 만짐 |
| `globals/debug.gd` (autoload) | F3 토글 디버그 오버레이 + 입력 시퀀스 CSV 로깅 |
| `player/player.gd` | 입력 라우팅 + StateMachine 위임 |
| `player/player_state_machine.gd` | IDLE/RUN/JUMP/FALL/ATTACK/TELEPORT/HIT 7상태 FSM |
| `player/input_buffer.gd` | 점프 / 텔레포트 / 코요테 버퍼 |
| `dagger/dagger.gd` | 비행 / 튕김 / 박힘 / 수명 (B-1 상태머신) |
| `dagger/marker_manager.gd` (autoload) | 활성 마커 배열 / 가장 가까운 마커 검색 / 시그널 (B-2) |
| `enemies/enemy_base.gd` | 공통 HP / 경직 / 처형 인터페이스 |
| `enemies/dummy.gd` | HP1 + 0.5s 경직 (Phase 1) |
| `systems/hit_stop.gd` (autoload) | `Engine.time_scale` 제어 |
| `systems/camera_shake.gd` | phantom_camera 어댑터 (Day 5+) |
| `systems/rumble.gd` | 진동 통합 헬퍼 |
| `rooms/room_base.gd` | 리스폰 / 마커 초기화 / 클리어 시그널 + 텔레포트 횟수 통계 |
| `ui/edge_indicator.gd` | 화면 밖 마커 화살표 (markers_changed 수신) |

### E-3. Autoload 등록 순서 (의존성 순)

```
1. game_constants  (의존성 0)
2. debug           (의존성 0)
3. hit_stop        (의존성 0)
4. marker_manager  (game_constants 의존)
```

---

## §F 입력맵 / 프로젝트 설정

### F-1. 입력맵 (Project Settings → Input Map)

| Action | Keyboard / Mouse | Gamepad (미등록) |
|---|---|---|
| `move_left` | A | DPad-Left + LStick X (-) |
| `move_right` | D | DPad-Right + LStick X (+) |
| `move_down` | S | DPad-Down |
| `jump` | Space | A (button 0) |
| `attack` | **Mouse Left** | X (button 2) |
| `dagger_throw` | **Mouse Right** + K | RT (axis 5 > 0.5) |
| `teleport` | **F** | LT (axis 4 > 0.5) |
| `dash` | Shift | B (button 1) |
| `pause` | Esc | Start (button 6) |

**단검 던지기 방향 결정 룰** (`_resolve_throw_direction`):
1. **마우스 우클릭 시**: 마우스 커서 → player 벡터 (자유 방향, 카타리나 W 스타일)
2. **K 키 + 방향키**: A/D + Space/S 8방향
3. **K 키 단독**: facing 좌우만 (fallback)

마우스 던지기 시 facing도 마우스 방향에 맞춰 자동 갱신.

### F-2. project.godot 추가 설정

```ini
[display]
; 게임 내부 해상도 (픽셀 아트 단위, 모든 좌표/박스 사이즈 기준)
window/size/viewport_width=480
window/size/viewport_height=270
; 실제 OS 창 크기 (4배 확대 표시, 1080p 기준)
window/size/window_width_override=1920
window/size/window_height_override=1080
window/stretch/mode="viewport"
window/stretch/aspect="keep"

[rendering]
; 픽셀 스냅은 false. 켜면 sub-pixel 이동(MAX_RUN=110 → frame당 1.83px)이
; 정수로 반올림되며 jitter 발생. viewport stretch가 자동 픽셀 정렬 처리함.
2d/snap/snap_2d_transforms_to_pixel=false
2d/snap/snap_2d_vertices_to_pixel=false

[physics]
common/physics_ticks_per_second=60
2d/default_gravity=980

[input_devices]
buffering/agile_event_flushing=true
```

> **주의**: 게임 로직/에셋은 480×270 픽셀 단위로만 작성. 4배 확대는 Godot가 자동 처리. 1920×1080을 직접 좌표로 쓰지 말 것.

### F-3. Layer 명명 (2D Physics Layers)

| Layer | 용도 |
|---|---|
| 1 | World (벽/바닥/천장) |
| 2 | World_Bouncy (튕김면) |
| 3 | Player |
| 4 | Enemy |
| 5 | Dagger |
| 6 | Hazard (가시 등) |

---

## §G Phase 1 Day 1~7 체크리스트 (실행용)

| Day | 작업 | 검증 |
|---|---|---|
| 1 | game_constants.gd + player.tscn + 이동/점프/코요테/버퍼 | 30초 손맛 자연스러움 |
| 2 | dagger.tscn + RigidBody2D CCD + 던지기 + 박힘 + max 3개 룰 | 5번 던져 5개 박힘, 위치 정확 |
| 3 | teleport_to() Tween + i-frame + 자동 흡착 | 던지기→점멸 1.5초 내 |
| 4 | Bounce Chain v0 (적/벽 1회 튕김) + dummy.gd + 처형 윈도우 | 적-벽-적-벽 4연쇄 점멸 |
| 5 | Game Feel placeholder 7종 + phantom_camera + hit_stop | Day 4 vs Day 5 영상 "맛" 차이 명확 |
| 6 | edge_indicator.gd + ±10% 미세 튜닝 + debug.gd CSV 로깅 | 화면 밖 마커 의식 자연스러움 |
| 7 | OBS 60초 × 5회 녹화 + 시퀀스 추출 + KILL 판정 | 5영상 + 시퀀스표 + GO/PIVOT/KILL 메모 |

---

## §J 룸 모듈 카탈로그 (Phase 2 §C 확장)

8~10종 모듈로 어떤 룸도 조립 가능. 각 모듈의 "강제 동사"가 그 룸의 검증 포인트.

| 모듈 ID | 공간 | 강제 동사 | 평균 텔레포트 | 적용 룸 |
|---|---|---|---|---|
| **M-VERTICAL** | 좁은 수직 통로, 상단 goal | 천장/벽 사선 박기 → 점멸 사다리 | 3~5회 | 01, 07 |
| **M-BOUNCE_WALL** | 좌우 튕김면 통로 | 사선 던지기 → 좌→우→좌 사다리 | 3~4회 | 02 |
| **M-HOPSCOTCH** | 가시 위 부유 적 일렬 | 적 사이 단검 튕김 → 적 위 마커 연쇄 처형 | 4~6회 | 03 |
| **M-FALLING** | 천장 하강 / 시간 압박 | 빠른 마커 형성+소비 (3초 윈도우) | 4~5회 | 04 |
| **M-CHASE** | 횡으로 긴 통로, 추격 적 | 후방 적 회피 + 마커로 가속 도주 | 2~3회 | 08 |
| **M-PUZZLE** | 가시 + 부유 발판 | 사선 던지기로 점프 거리 보강 | 2~4회 | 09 |
| **M-MOB** | 닫힌 아레나, 적 4종 혼합 | 다중 마커 + 처형 우선순위 | 5~7회 | 10 |
| **M-BOSS_MINI** | 닫힌 원형, 4적 동시 | Bounce Chain + 4연쇄 처형 | 4~6회 | 05 |
| **M-BOSS** | 보스룸, 페이즈 전환 | 텔레포트 회피 + 처형 윈도우 | 6~10회 | 06 |
| **M-DENIER_GAUNTLET** | (예비) 마커 거부 적 다수 | 빠른 회수 + 짧은 마커 사이클 | 3~5회 | (Phase 4 후보) |

**조립 룰**: 한 챕터(8~12룸)에 같은 모듈 2회 이상 반복 금지. 난이도 곡선 = 텔레포트 평균 횟수의 단조 증가.

**현재 챕터 1 흐름**:
```
01 VERTICAL → 02 BOUNCE_WALL → 03 HOPSCOTCH → 04 FALLING → 05 BOSS_MINI
→ 07 VERTICAL(고급) → 08 CHASE → 09 PUZZLE → 10 MOB → 06 BOSS
```
총 10룸. 평균 텔레포트 1→3→4→5→4→4→3→3→6→8 (단조 증가, 보스 직전 살짝 하강해 휴식).

---

## §H 아키텍처: Greybox-First / 차원 무관 / 에셋 교체

본 섹션은 **에셋 없이 그레이박스만으로 Phase 1~4 진행**, **추후 에셋 교체 1줄**, **2D ↔ 3D 전환 가능 구조**라는 3대 요구사항의 구현 가이드입니다.

### §H-1 Greybox-First 원칙

**룰**:
- Phase 1~4 동안 **텍스처/모델/사운드 직접 참조 금지**. 모든 비주얼은 `Greybox` autoload를 거쳐 생성.
- 색깔과 도형 크기로만 식별 가능해야 함 (이게 안 되면 인지 부하가 너무 큰 것).
- 폴리시(Phase 3)에서 일괄 교체.

**색상 코드 컨벤션** (`Greybox.COLORS`):
| 역할 | 2D Hex | 비고 |
|---|---|---|
| Player | `#3da5ff` (밝은 파랑) | 단일 박스 8×16 |
| Enemy (Dummy) | `#ff3d3d` (빨강) | 8×8 |
| Enemy (Ranged) | `#ff7700` (주황) | Phase 3 |
| Enemy (Bouncer) | `#a83dff` (보라) | Phase 3, 마커 거부 |
| Wall | `#666666` (회색) | 일반 면 |
| Wall_Bouncy | `#ff3d8a` (마젠타) | 튕김 면 |
| Dagger (flying) | `#00e5ff` (시안) | 4×2 가로 |
| Marker (planted) | `#f5b041` (앰버) | 박힘 후 색 변경 |
| Hazard (가시) | `#f5b041` 줄무늬 | 죽음 |
| Goal | `#4ade80` (초록) | 룸 클리어 트리거 |

**금지 사항**: Phase 2까지 sprite 텍스처 참조 0개. `Sprite2D.texture = preload(...)` 같은 코드 보이면 KILL 신호.

### §H-2 차원 무관 아키텍처 (Logic / Body / View 분리)

```
┌──────────────────────────────────────────────────────────┐
│ Logic 레이어 (RefCounted, 차원 무관)                       │
│   - PlayerLogic, DaggerLogic, StateMachine               │
│   - 입력 의도 → 룰 → 상태 (Vector는 X/Y만 사용)              │
│   - GameConstants, MarkerManager (autoload, 이미 무관)     │
└──────────────────────────────────────────────────────────┘
              ▲                              ▲
              │ logic 인스턴스 호스팅              │
┌──────────────────────────┐    ┌──────────────────────────┐
│ Body 레이어 (2D)            │    │ Body 레이어 (3D)            │
│   - PlayerBody2D            │    │   - PlayerBody3D            │
│   - DaggerBody2D            │    │   - DaggerBody3D            │
│   - CharacterBody2D 상속      │    │   - CharacterBody3D 상속      │
│   - move_and_slide 처리       │    │   - move_and_slide 처리       │
└──────────────────────────┘    └──────────────────────────┘
              ▲                              ▲
              │ 비주얼 자식                       │
┌──────────────────────────┐    ┌──────────────────────────┐
│ View 레이어 (2D)            │    │ View 레이어 (3D)            │
│   - VisualResource(2D)      │    │   - VisualResource(3D)      │
│   - Sprite2D / ColorRect    │    │   - MeshInstance3D          │
│   - AnimationPlayer 2D       │    │   - AnimationPlayer 3D       │
└──────────────────────────┘    └──────────────────────────┘
```

**원칙**:
1. Logic 레이어에는 `Vector2`/`Vector3`/`CharacterBody*` 어떤 것도 import 금지. 순수 float / int / 커스텀 데이터.
2. Body 레이어가 매 frame Logic을 update하고, Logic 결과를 Node로 반영.
3. View 레이어는 Body의 자식. Greybox 또는 VisualResource로 swap 가능.

### §H-3 VisualResource 패턴

**Resource 정의** (`scripts/data/visual_resource.gd`):
```gdscript
class_name VisualResource extends Resource

@export_enum("2D", "3D") var dimension: int = 0

# 그레이박스 (에셋 없을 때 fallback)
@export var greybox_color: Color = Color.WHITE
@export var greybox_size_2d: Vector2 = Vector2(8, 16)
@export var greybox_size_3d: Vector3 = Vector3(0.5, 1.0, 0.5)

# 2D 에셋 (있으면 사용)
@export var texture_2d: Texture2D
@export var sprite_frames: SpriteFrames

# 3D 에셋 (있으면 사용)
@export var mesh_3d: PackedScene
@export var animation_library: AnimationLibrary
```

**사용**:
```gdscript
# Body가 자식으로 visual을 자동 생성
@export var visual: VisualResource

func _ready():
    var view = Greybox.spawn_view(visual, self)  # texture/mesh 우선, 없으면 색깔 박스
```

**에셋 교체**: `player_visual_2d.tres`의 `texture_2d` 필드를 채우면 끝. 코드 변경 0줄.

### §H-4 갱신된 폴더 / 파일 트리

```
res://
├── scenes/
│   ├── player/
│   │   ├── player_2d.tscn          (Day 1)
│   │   └── player_3d.tscn          (Day N, 차원 전환 시)
│   ├── dagger/
│   │   ├── dagger_2d.tscn
│   │   └── dagger_3d.tscn
│   ├── enemies/
│   ├── rooms/
│   ├── ui/
│   └── main.tscn
├── scripts/
│   ├── globals/
│   │   ├── game_constants.gd       (autoload, 차원 무관)
│   │   └── debug.gd                (autoload)
│   ├── systems/
│   │   ├── hit_stop.gd             (autoload)
│   │   ├── greybox.gd              (autoload, NEW)
│   │   ├── camera_shake.gd
│   │   └── rumble.gd
│   ├── data/                        (NEW, Resource 정의)
│   │   ├── visual_resource.gd
│   │   ├── enemy_data.gd            (Phase 3)
│   │   └── room_data.gd             (Phase 2)
│   ├── player/
│   │   ├── player_logic.gd          (RefCounted, 차원 무관)
│   │   ├── player_body_2d.gd        (CharacterBody2D wrap)
│   │   ├── player_body_3d.gd        (CharacterBody3D wrap, Day N)
│   │   ├── player_state_machine.gd  (차원 무관)
│   │   └── input_buffer.gd          (차원 무관)
│   ├── dagger/
│   │   ├── dagger_logic.gd          (차원 무관)
│   │   ├── dagger_body_2d.gd        (RigidBody2D wrap)
│   │   ├── dagger_body_3d.gd        (RigidBody3D wrap, Day N)
│   │   └── marker_manager.gd        (autoload, 차원 무관)
│   ├── enemies/
│   │   ├── enemy_logic.gd           (차원 무관 base)
│   │   ├── enemy_body_2d.gd
│   │   └── enemy_body_3d.gd
│   └── rooms/
│       ├── room_base.gd             (차원 무관 통계 + 시그널)
│       ├── room_2d.gd
│       └── room_3d.gd
├── resources/                       (NEW, .tres 데이터)
│   └── visual/
│       ├── player_visual_2d.tres
│       ├── dagger_visual_2d.tres
│       └── (3D는 차원 전환 시 추가)
├── assets/
│   ├── sprites/                     (Phase 3 폴리시에서 채움)
│   ├── meshes/                      (3D 전환 시 채움, Phase 3+)
│   ├── sfx/
│   ├── shaders/
│   └── particles/
└── addons/
    └── phantom_camera/              (Day 5에 도입)
```

### §H-5 차원 전환 마이그레이션 절차

3D로 전환할 때(예: Phase 3 끝 또는 GO 결정 후):

1. **Logic 그대로 재사용** — `player_logic.gd`, `dagger_logic.gd`, `state_machine.gd`, `input_buffer.gd`, `marker_manager.gd`, `game_constants.gd` 0줄 수정.
2. **Body 레이어만 평행 작성** — `player_body_3d.gd` (CharacterBody3D 상속), velocity 입출력만 `Vector3(x, y, 0)`로 변환.
3. **씬 평행 작성** — `player_3d.tscn`, `dagger_3d.tscn`, `room_3d.gd` 등.
4. **Greybox 3D 분기** — `Greybox.spawn_view()`가 dimension 플래그 보고 BoxMesh 생성.
5. **VisualResource 3D 필드 채움** — `mesh_3d` 슬롯에 `.glb` PackedScene 할당.
6. **Main 씬 분기** — `main_2d.tscn` / `main_3d.tscn` 둘 중 하나만 활성.

**예상 비용**: Body + 씬 평행 작성 = **1~2일** (Logic이 잘 분리된 상태에서). Logic이 Vector2/CharacterBody2D를 직접 import 하면 비용 폭증.

### §H-6 Body Adapter 인터페이스 컨벤션

GDScript에 인터페이스가 없으므로 **컨벤션**으로 강제:

| 메서드 / 시그널 | Body2D / Body3D 둘 다 구현 |
|---|---|
| `func apply_logic_velocity(vx: float, vy: float) -> void` | velocity 갱신 후 move_and_slide |
| `func get_position_2d() -> Vector2` | 3D는 Vector2(x, y) 반환 |
| `func is_on_floor_logic() -> bool` | floor 판정 |
| `signal hit_received(amount: int, source: Node)` | 피격 |
| `signal grounded_changed(is_grounded: bool)` | 착지/이륙 |

**코드 리뷰 체크**: Logic에서 `extends Node2D` / `Vector2` / `CharacterBody2D` 검색 시 0건이어야 함.

### §H-7 Greybox autoload API

```gdscript
# scripts/systems/greybox.gd
extends Node

const COLORS = {
    "player":      Color("#3da5ff"),
    "enemy":       Color("#ff3d3d"),
    "wall":        Color("#666666"),
    "wall_bouncy": Color("#ff3d8a"),
    "dagger":      Color("#00e5ff"),
    "marker":      Color("#f5b041"),
    "hazard":      Color("#ff7700"),
    "goal":        Color("#4ade80"),
}

func spawn_view(visual: VisualResource, parent: Node) -> Node:
    # 텍스처/메시 있으면 그걸로, 없으면 그레이박스 박스로 생성
    ...

func make_box_2d(size: Vector2, color: Color) -> ColorRect: ...
func make_box_3d(size: Vector3, color: Color) -> MeshInstance3D: ...
```

**Phase 1~2**: VisualResource에 색상만 채워두면 자동 그레이박스. **Phase 3+**: 텍스처/메시 채우면 자동 교체. 코드 변경 0.

---

## §I 개발 워크플로우 (자체 실행 / 검증 / 계획 참조 의무)

### §I-1 매 Day 작업 전후 의무 절차

**작업 시작 전**:
1. **계획 파일 확인**: `C:\Users\sk992\.claude\plans\c-dev-godot-project-cnc-doc-dapper-parnas.md` 읽기 (현재 Day 위치 / 다음 작업 / KILL Criteria 재확인)
2. **로드맵 HTML 체크리스트 확인**: 해당 Phase의 미완료 항목 매핑
3. **supplement §A~§H 참조**: 수치 / 사양 / 컨벤션 일관성 유지

**작업 종료 후**:
1. **자체 실행 검증** (§I-2 절차) 통과
2. **에러 0건** 확인 (godot.log + session_log.csv)
3. **사용자에게 다음 작업 제안** — Day N 결과물 + 다음 Day의 첫 액션 명시

### §I-2 자체 실행 검증 절차 (Godot CLI)

**Godot 4.7 CLI 경로**:
```
C:/Users/sk992/Desktop/Godot_v4.7-dev2_win64.exe/Godot_v4.7-dev2_win64_console.exe
```

**Step 1: Import (스크립트 파싱 + 전역 클래스 등록 검증)**
```
godot --headless --path "C:/DEV/GODOT/project-cnc" --import
```
- `update_scripts_classes` 단계에서 새로 만든 `class_name`이 등록되는지 확인
- `ERROR` / `parse error` / `Could not preload` 0건이어야 통과

**Step 2: Headless Boot (런타임 _ready 검증)**
```
godot --headless --path "C:/DEV/GODOT/project-cnc" --quit-after 120
```
- 120 frame (≈2초) 후 자동 종료
- stdout에 `ERROR` / `script error` / `null instance` 0건이어야 통과

**Step 3: 로그 / 산출물 확인**
- godot 자체 로그: `C:/Users/sk992/AppData/Roaming/Godot/app_userdata/ProjectCNC/logs/godot.log`
- DebugLog autoload 산출물: `C:/Users/sk992/AppData/Roaming/Godot/app_userdata/ProjectCNC/session_log.csv`
- session_log.csv가 새로 생성되어 있으면 autoload `_ready` 작동 확인됨
- Day 2부터는 throw / plant / teleport 액션이 csv에 기록되어야 함

**Step 4 (선택): Play Test 영상 녹화**
- Day 7 KILL 판정용. 사용자가 직접 OBS로 60초 × 5회 녹화

### §I-3 자체 검증 실패 시 처리

| 증상 | 원인 후보 | 조치 |
|---|---|---|
| `Parse Error` / `Identifier not declared` | autoload 등록 누락, `class_name` 미정의 | project.godot autoload 섹션 / class_name 선언 확인 |
| `Could not preload` | .tscn / .tres / .gd 경로 오타 | 경로 정확히 확인, ext_resource id 일치 확인 |
| `null instance` 런타임 에러 | export 변수 미할당, get_node 실패 | .tscn에서 export 값 / NodePath 확인 |
| `signal not connected` | 시그널 연결 누락 | _ready 또는 .tscn에서 connect 확인 |
| 헤드리스 boot 무한 hang | 무한 루프 / 동기 대기 | _ready / _process에 await 또는 무한 while 의심 |

**사용자에게 보고할 때**: 위 표 형식으로 증상 / 원인 / 조치를 1-2줄로 요약.

### §I-4 Day 단위 종료 보고 템플릿

```
**Day N 완료 / 자체 검증 통과**

생성/수정 파일:
- scripts/...
- scenes/...

자체 검증 결과 (자동):
- godot --import: ERROR 0건
- headless boot: ERROR 0건
- session_log.csv: <기록된 액션 N건>

수동 검증 체크리스트 (사용자가 게임 실행 후 확인):
- [ ] 항목 1: 기대 동작 → 실제 확인 방법 → 통과 기준
- [ ] 항목 2: ...
- [ ] 항목 N: ...
- 실패 시 보고 방법: <어떤 csv / 로그 / 영상을 보내달라>

다음 작업 (Day N+1 첫 액션):
- <구체적 다음 단계 1줄>

진행할까요? (Y/계속 진행 시 자동 / 추가 요청 시 알려주세요)
```

### §I-5 자동 진행 vs 사용자 컨펌

- **자체 검증 통과** + **다음 Day가 supplement §G에 정의됨** = 자동 진행 OK (사용자가 명시적으로 "next day까지" 요청 시)
- **자체 검증 실패** = 즉시 중단, 원인 표 + 조치안 보고
- **새 KILL Criteria 도달** (예: Day 7 60초 5회 시퀀스 비교) = 반드시 사용자 컨펌
- **계획 파일 / supplement 수정** = 매번 보고

### §I-7 강제 자체 검증 워크플로우 (모든 코드 변경 종료 시 필수)

매 코드 변경 후 사용자에게 보고하기 **전에** 반드시 다음 절차를 수행한다. 어느 한 단계라도 실패 / 에러 / 경고 발견 시 즉시 수정 + 재실행 + 통과까지 반복.

```bash
# 1. 캐시 클린 + 출력 파일 분리
rm -rf "C:/DEV/GODOT/project-cnc/.godot"
rm -f /tmp/run_*.log

# 2. import (verbose, stdout+stderr 분리 저장)
godot --verbose --headless --path <project> --import \
  1>/tmp/run_import.log 2>&1

# 3. GUI 5초 부팅 (실제 렌더 파이프라인까지)
godot --verbose --path <project> --quit-after 300 \
  1>/tmp/run_gui.log 2>&1

# 4. 시뮬 (입력 시뮬, 동사 시퀀스 실행)
godot --headless --path <project> "res://scenes/test/sim_main.tscn" \
  1>/tmp/run_sim.log 2>&1

# 5. 모든 .log에서 에러/경고 grep (Godot 내부 메시지 제외)
grep -iE "error|fail|push_error|push_warning|invalid|cannot|not found|leak|undefined|null inst" \
  /tmp/run_*.log \
  | grep -vE "DOTNET|Asio|Vulkan|D3D12|TextServer|XR|OpenXR|FFmpeg|movie|video|Native mobile|Failed to bind socket"
```

### §I-7-A 무시 가능한 메시지 화이트리스트

| 메시지 | 이유 |
|---|---|
| `Failed to bind socket. Error: 3` | 디버그 어댑터 소켓 충돌 (다른 Godot 인스턴스 점유). 게임 영향 0. |
| `XR_ / Native mobile / OpenXR removed` | XR 인터페이스 정리 메시지. headless 모드 정상. |
| `D3D12 / Vulkan / TextServer / DOTNET / FFmpeg` 초기화 라인 | 엔진 부팅 정보. |
| `2 ObjectDB instances were leaked: AudioStreamWAV / AudioStreamPlaybackWAV` | Godot 4.7-dev2 종료 시점 ref counting minor 이슈. _exit_tree 정리 후에도 잔존. **게임플레이 0 영향, 메모리 0 누수 (프로세스 종료 시 OS 회수)**. 4.x 안정 버전에서 자동 해소 예정. |
| `MultiUmaBuffer ... used a total of N buffers` | VRAM 사용 정보, 정상. |
| `Orphan StringName: Master / unclaimed string names` | StringName 풀 정리 메시지, 정상. |

### §I-7-B 즉시 수정 대상 (반드시 0건)

| 메시지 패턴 | 수정 방향 |
|---|---|
| `Compile Error: Identifier not found: <name>` | 1) autoload 등록 확인. 2) `@onready var _x = get_node_or_null("/root/<name>")` 패턴으로 우회. (§I-3 표) |
| `Can't change this state while flushing queries` | `set_deferred("freeze"/"linear_velocity")` 사용. |
| `Leaked instance: <Resource>` | autoload `_exit_tree`에서 명시적 정리. Resource는 `null` 할당 + Dict/Array `clear()`. |
| `Could not preload <path>` | 경로 오타 / .tscn UID 누락. ext_resource id 확인. |
| `Invalid set/get index` | export 변수 미할당 또는 NodePath 오타. |
| `null instance` 런타임 에러 | export / get_node 결과에 `is_instance_valid` 가드 추가. |

### §I-7-C 보고 전 강제 절차

1. 위 grep 결과가 **빈 줄**이어야 함
2. 단 한 줄이라도 §I-7-B에 해당하면 **즉시 수정 → 처음부터 1단계 재실행**
3. 통과 후에만 사용자 보고
4. 보고 시 §I-4 템플릿에 **"수행한 검증 명령 + 출력 파일 경로"** 명시
5. 통과 못하고 사용자 보고하면 자체 워크플로우 실패 — 다음 보고 시 명시 + 재발 방지 메모

### §I-7-D 수정 이력 기록 룰

수정한 모든 에러는 §I-3 (자체 검증 실패 시 처리) 표에 추가한다. 동일 에러 재발 시 즉시 표 참조 → 같은 패턴 적용.

| 발견 일자 | 에러 텍스트 (앞 60자) | 원인 | 수정 |
|---|---|---|---|
| 2026-05-04 | `Identifier not found: Rumble/CameraShake` | 에디터 stale cache + dev 빌드 autoload identifier 인식 실패 | `@onready var _x = get_node_or_null("/root/X")` 패턴으로 우회 |
| 2026-05-04 | `Can't change state while flushing queries (body_set_mode)` | RigidBody2D `body_entered` 콜백에서 freeze 직접 변경 | `set_deferred("freeze", true)` |
| 2026-05-05 | `Leaked instance: AudioStreamWAV / Playback` | Sfx/Bgm autoload 종료 시 stream 미정리 | `_exit_tree`에서 stream=null + Dict.clear() |

### §I-6 수동 검증 체크리스트 작성 룰

매 작업 종료 보고 시 **반드시** 수동 검증 항목을 카테고리별로 명시한다. 사용자가 직접 게임을 실행해 확인할 수 있는 구체적 기대치를 적는다 ("자연스러운가" 같은 모호한 표현 금지).

**카테고리별 체크 템플릿**:

| 작업 카테고리 | 수동 검증 항목 |
|---|---|
| **이동 / 점프** | 입력 반응 즉시성 / 가속·감속 손맛 / 코요테(발판 끝에서 0.08s 후 점프 가능) / 점프버퍼(착지 직전 점프 키 → 즉시 점프) / 점프 컷(키 떼면 작은 점프) / 벽 충돌 시 깔끔한 멈춤 / 떨림 / 카메라 추종 |
| **단검 던지기** | 발사 방향(facing 일치) / 비행 직진성 / 박힘 위치 정확성 / 마커 max 3개 룰 / ammo 0 시 차단 / 8초 자동 소멸 |
| **텔레포트** | 마커 자동 흡착 / 점멸 시간(0.12s) / i-frame 동안 무적 / 회수 후 ammo +1 / 0.4s 체인 윈도우 / 쿨다운 -50% 보너스 |
| **Bounce Chain** | 적 1회 튕김 후 다음 표면 박힘 / 튕김면 1회 반사 / 4연쇄 가능 / 충전 던지기 (Phase 3) |
| **적 AI** | 패턴 작동 / HP 표시 / 경직 0.5s / 처형 0.3s 윈도우 / 1대多 시 우선순위 |
| **룸 / 레벨** | 클리어 가능성 / 메커닉 우회 불가 / 평균 텔레포트 횟수 (room_base.gd 통계 csv) / 리스폰 시 마커 초기화 |
| **Game Feel** | 히트스탑 50ms 체감 / 카메라 셰이크 강도 / 잔상 잘 보임 / 진동 강약 / 줌펀치 자연스러움 |
| **아키텍처 / 차원 무관** | `grep -r "Vector2\|CharacterBody2D" scripts/{logic,player,dagger}/*_logic.gd` 결과 0건 / 3D 플레이스홀더로 swap 가능 |
| **그레이박싱 / 에셋 교체** | Greybox.COLORS 컨벤션 일치 (Player=#3da5ff 등) / VisualResource.texture_2d 채우면 자동 교체 / 직접 텍스처 preload 0건 |
| **셋업 (project.godot)** | F5 부팅 / 입력맵 9종 작동 / autoload 5종 _ready 호출 / viewport 480×270 + 창 1920×1080 |
| **버그 수정** | 수정된 증상 재현 안 됨 / 회귀 없음 (이전에 통과했던 동작 그대로) / 엣지 케이스 (입력 빠르게 / 천천히) |

**작성 룰**:
1. 한 항목당 "기대 동작 → 확인 방법 → 통과 기준" 3요소를 한 줄로
2. 실패 시 사용자가 보내야 할 데이터 명시 (영상 / csv 경로 / 스크린샷)
3. 검증 시간이 1분을 넘지 않도록 항목 5개 이내로 압축 (Day 7 KILL 판정만 예외)
4. 모호한 단어 금지: "자연스러운가" → "60fps 유지, 캐릭터 떨림 0픽셀"
