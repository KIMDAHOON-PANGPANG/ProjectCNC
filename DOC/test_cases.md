# Test Cases — Days 1~6 검증

본 문서는 정적 분석 + 헤드리스 시뮬레이션 + 사용자 수동 검증을 통합한 테스트 케이스 카탈로그입니다.

- **자동(SIM)**: `scenes/test/sim_main.tscn` headless 실행 + `session_log.csv` 분석으로 검증
- **수동(MAN)**: 사용자가 F5 실행 후 직접 입력 + 화면 관찰
- **정적(STA)**: 코드 읽기 / API 시그니처 / 컨벤션 위배 여부

---

## 발견된 이슈 + 수정 이력

| ID | 심각도 | 위치 | 증상 | 수정 |
|---|---|---|---|---|
| **ISSUE-1** | CRITICAL | `player_body_2d.gd` `_start_teleport` | 연속 텔레포트 시 `_saved_collision_mask=0` 덮어쓰기 → collision 영구 0 | `_ready`에서 한 번만 저장 |
| **ISSUE-2** | MEDIUM | `dagger_body_2d.gd` `_on_body_entered` | RigidBody2D 충돌 시 `linear_velocity≈0`이면 `refl_dir=0` → 단검 정지 | `logic.velocity_x/y` fallback + 최후 `_plant` |
| **ISSUE-RUNTIME-1** | CRITICAL | `dagger_body_2d.gd` `_plant` | `body_entered` 콜백에서 `freeze=true` 직접 변경 → "Can't change state while flushing queries" 에러 | `set_deferred("freeze", true)` |

---

## TC 카탈로그

### [TC-MOV] 이동 (Day 1)

| ID | 항목 | 사전 | 절차 | 기대 | 통과 기준 | 모드 |
|---|---|---|---|---|---|---|
| TC-MOV-01 | A/D 가속 | floor 안착 | A 또는 D 0.5초 누름 | velocity_x가 `RUN_ACCEL=800` 비율로 증가, max `MAX_RUN=110` | 0.14s 후 max 도달 | MAN |
| TC-MOV-02 | 감속 | velocity_x=110 | 키 떼기 | `RUN_DECEL=1200` 비율로 0까지 감속 | 0.09s 후 정지 | MAN |
| TC-MOV-03 | 공중 가속 | 점프 중 | A/D 입력 | `AIR_ACCEL=500` (지상보다 약함) | 공중 좌우 제어 가능하지만 둔함 | MAN |
| TC-MOV-04 | 떨림 0 | 안착 정지 | 좌우 이동 후 정지 | 캐릭터/벽 떨림 0픽셀 | 시각 1픽셀도 떨리지 않음 | MAN |
| TC-MOV-05 | facing 갱신 | — | A 입력 → D 입력 | `logic.facing` -1 → +1 | 단검 방향이 좌→우 변경 (TC-DAG-04에서 검증) | SIM |

### [TC-JMP] 점프 (Day 1)

| ID | 항목 | 사전 | 절차 | 기대 | 통과 기준 | 모드 |
|---|---|---|---|---|---|---|
| TC-JMP-01 | 기본 점프 | floor 위 | Space 길게 누름 | `JUMP_VELOCITY=-280` 적용 | 점프 높이 일정 | MAN |
| TC-JMP-02 | 점프 컷 | 점프 직후 | Space 짧게(60ms 내) 떼기 | velocity_y *= 0.5 | 작은 점프 | SIM (jump press 0.9s + release 0.96s) |
| TC-JMP-03 | 코요테 | floor 끝에서 떨어짐 | 떨어진 직후 0.08s 안에 Space | 점프 발동 | 발판 끝에서도 점프 가능 | MAN |
| TC-JMP-04 | 점프 버퍼 | 공중 | 착지 직전 0.10s 안에 Space | 착지 즉시 점프 | 부드러운 연속 점프 | MAN |
| TC-JMP-05 | 중력 분리 | 점프 정점 후 | 하강 시 | `FALL_GRAVITY_MULT=1.4` 적용 | 빠르게 떨어짐 | MAN |

### [TC-DAG] 단검 던지기 (Day 2)

| ID | 항목 | 사전 | 절차 | 기대 | 통과 기준 | 모드 |
|---|---|---|---|---|---|---|
| TC-DAG-01 | K 발사 | ammo > 0 | K 누름 | dagger 인스턴스 spawn + facing 방향 비행 | csv `throw,1.00,0.00` | SIM ✓ |
| TC-DAG-02 | 박힘 (World) | dagger 비행 | 회색 벽 명중 | freeze=true + marker 등록 | csv `plant,x,y` | SIM ✓ |
| TC-DAG-03 | 비행 속도 | — | dagger 발사 | `DAGGER_SPEED=800px/s` | 0.6s 안에 480px 횡단 | STA |
| TC-DAG-04 | facing 반영 | A 누른 채 K | 좌측 발사 | dir = (-1, 0) | csv `throw,-1.00,0.00` | MAN |
| TC-DAG-05 | 8s 자동 소멸 | 박힌 마커 | 8초 대기 | `MarkerManager.expire_marker` | 마커가 사라짐 | MAN |

### [TC-MRK] 마커 / ammo 관리 (Day 2)

| ID | 항목 | 사전 | 절차 | 기대 | 통과 기준 | 모드 |
|---|---|---|---|---|---|---|
| TC-MRK-01 | ammo 차감 | ammo=3 | K 1회 | ammo=2 | 다음 K 가능 | SIM ✓ |
| TC-MRK-02 | ammo 0 차단 | ammo=0 | K 시도 | `consume_ammo→false`, dagger spawn 안 됨 | csv `throw_blocked,no_ammo` | SIM ✓ |
| TC-MRK-03 | recover 시 ammo +1 | 텔레포트 도착 | 마커 회수 | ammo += 1 (max 3) | 다음 K 가능 | SIM ✓ (3.7s throw 후 ammo 0 차단) |
| TC-MRK-04 | 마커 max 3 | marker=3, dagger 비행중 | 4번째 plant | `pop_front` 가장 오래된 제거 | (ammo로 사실상 도달 불가, dead code) | STA |

### [TC-TPT] 텔레포트 (Day 3)

| ID | 항목 | 사전 | 절차 | 기대 | 통과 기준 | 모드 |
|---|---|---|---|---|---|---|
| TC-TPT-01 | 마커 흡착 | 마커 1개 | L 누름 | 가장 가까운 마커로 점멸 | csv `teleport_start,x,y` | SIM ✓ |
| TC-TPT-02 | Tween 0.12s | teleport_start | — | TELEPORT_DURATION 후 도착 | csv `teleport_end` (123ms 후) | SIM ✓ (3026 → 3149ms) |
| TC-TPT-03 | i-frame | TELEPORT 중 | 적/투사체 통과 | `collision_mask=0` | 적 통과 가능 | MAN |
| TC-TPT-04 | i-frame 복원 | teleport_end | 0.18s 후 | `collision_mask` 복원 | floor 충돌 정상 | STA (ISSUE-1 수정 후) |
| TC-TPT-05 | 마커 없음 차단 | 마커=0 | L 누름 | `teleport_blocked,no_marker` | csv 기록 + state 유지 | SIM (timing 의존, 1차 시뮬에서 발생) |
| TC-TPT-06 | 마커 회수 | teleport_end | — | `recover_marker` 호출 + ammo +1 | TC-MRK-03와 동일 | SIM ✓ |
| TC-TPT-07 | 체인 윈도우 | teleport_end | 0.4s 안 dagger_throw | `start_chain_window` 활성 | `is_chain_active=true` | MAN |
| TC-TPT-08 | 연속 텔레포트 | 1차 teleport_end 직후 | 2차 teleport | collision 영구 0 안 됨 | floor 충돌 유지 | STA (ISSUE-1 수정) |

### [TC-BNC] Bounce Chain (Day 4)

| ID | 항목 | 사전 | 절차 | 기대 | 통과 기준 | 모드 |
|---|---|---|---|---|---|---|
| TC-BNC-01 | 적 1회 튕김 | dagger 비행 | dummy 명중 | `try_bounce_enemy=true` + `velocity *= 0.7` | csv `enemy_stun` + 단검 계속 비행 | SIM ✓ |
| TC-BNC-02 | 적 2회째 박힘 | bounce_count_enemy=1 | 다음 적 명중 | `try_bounce_enemy=false` → `_plant` | csv `plant` | SIM ✓ (3.387ms / 3.942ms plant) |
| TC-BNC-03 | 튕김면 1회 반사 | dagger 비행 | 마젠타 벽(WallRight, layer 2) 명중 | `linear_velocity.bounce(normal)` 100% 속도 | 다음 표면까지 비행 | MAN (sim 시나리오에 미포함) |
| TC-BNC-04 | 일반 벽 즉시 박힘 | dagger 비행 | 회색 벽(layer 1) 명중 | `_plant` | csv `plant` | SIM ✓ |
| TC-BNC-05 | 적 stun 지속 | enemy_stun | 0.5초 지속 | `is_stunned=true` 유지 | TC-EXE-01에 사용 | SIM ✓ |
| TC-BNC-06 | velocity fallback | linear_velocity≈0 | 충돌 | logic.velocity_x/y 사용 → 단검 안 멈춤 | ISSUE-2 수정 검증 | STA |

### [TC-EXE] 처형 (Day 4)

| ID | 항목 | 사전 | 절차 | 기대 | 통과 기준 | 모드 |
|---|---|---|---|---|---|---|
| TC-EXE-01 | 처형 윈도우 | teleport_end + stunned 적 가까이 | 0.3s 안 J | `receive_execution()` → 적 free | csv `execute` + `enemy_executed` | SIM ✓ (3178ms 동시 기록) |
| TC-EXE-02 | 윈도우 밖 attack | 0.3s 경과 후 J | — | 일반 attack (처형 X) | csv `attack,` | SIM (1차 시뮬에서) |
| TC-EXE-03 | stun 종료 후 attack | 적 stun 종료 | J | execution_target.is_executable=false | 일반 attack | STA |
| TC-EXE-04 | 처형 시 Game Feel | 처형 트리거 | — | HitStop + 강한 셰이크 + 줌펀치 + 진동 | 시각/청각 확인 | MAN |
| TC-EXE-05 | 거리 20px 안 | 마커-적 거리 > 20 | 텔레포트 후 J | execution_target=null | 일반 attack | STA |

### [TC-FEEL] Game Feel placeholder (Day 5)

| ID | 항목 | 사전 | 절차 | 기대 | 통과 기준 | 모드 |
|---|---|---|---|---|---|---|
| TC-FEEL-01 | 단검 트레일 | dagger 비행 | — | Line2D top_level + 6프레임 추적 | 시안 잔광 보임 | MAN |
| TC-FEEL-02 | 박힘 셰이크 | _plant | — | `CameraShake.shake(amp 4, dur 0.08)` | 카메라 진동 | MAN |
| TC-FEEL-03 | 박힘 진동 | _plant | — | `Rumble.plant()` 게임패드 진동 | 컨트롤러 진동 | MAN (게임패드) |
| TC-FEEL-04 | 텔레포트 잔상 | _start_teleport | — | ColorRect 5장 alpha fade 0.3s | 출발 위치 잔상 | MAN |
| TC-FEEL-05 | 줌펀치 | _start_teleport | — | zoom 1.0 → 1.05 → 1.0 (0.15s) | 카메라 살짝 들어갔다 나옴 | MAN |
| TC-FEEL-06 | 처형 히트스탑 | _try_attack 처형 | — | `Engine.time_scale=0` 50ms | 화면 정지 | MAN |
| TC-FEEL-07 | trail freeze | _plant | — | `freeze_trail()` → 0.3s 후 free | 박힌 후 잔광 페이드 | MAN |

### [TC-EDG] Edge Indicator (Day 6)

| ID | 항목 | 사전 | 절차 | 기대 | 통과 기준 | 모드 |
|---|---|---|---|---|---|---|
| TC-EDG-01 | 화면 밖 마커 | 마커가 viewport 밖 | — | 화면 가장자리에 노란 박스 (`marker` 색) | 6×6 ColorRect 보임 | MAN |
| TC-EDG-02 | 화면 안 마커 | 마커 viewport 안 | — | 박스 사라짐 + `_arrows` 정리 | 화살표 없음 | MAN |
| TC-EDG-03 | 마커 수명 만료 | 8초 경과 | — | `expire_marker` + 화살표 정리 | 화살표 사라짐 | MAN |
| TC-EDG-04 | 카메라 동기 | player 이동 | — | viewport 영역이 player 따라감 | 화살표 위치 갱신 | MAN |

### [TC-ARCH] 아키텍처 / 차원 무관 (§H-2)

| ID | 항목 | 검증 | 통과 기준 | 모드 |
|---|---|---|---|---|
| TC-ARCH-01 | player_logic.gd 차원 무관 | `Vector2`, `CharacterBody2D` 검색 | 0건 | STA ✓ |
| TC-ARCH-02 | dagger_logic.gd 차원 무관 | 동일 | 0건 | STA ✓ |
| TC-ARCH-03 | autoload 차원 무관 | game_constants/marker_manager/hit_stop/rumble | 0건 | STA ✓ (greybox/camera_shake는 2D만 사용 — Body 어댑터 레이어로 분류) |
| TC-ARCH-04 | VisualResource swap | texture_2d 채워서 spawn_view 호출 | Sprite2D 반환 | STA |
| TC-ARCH-05 | Greybox fallback | visual.texture_2d=null | ColorRect 색깔 박스 반환 | STA ✓ |

### [TC-INPUT] 입력맵 (Day 0)

| ID | 항목 | 키 | 통과 기준 |
|---|---|---|---|
| TC-INPUT-01 | move_left | A | 키보드 A 매핑 ✓ |
| TC-INPUT-02 | move_right | D | ✓ |
| TC-INPUT-03 | move_down | S | ✓ |
| TC-INPUT-04 | jump | Space | ✓ |
| TC-INPUT-05 | attack | J | ✓ |
| TC-INPUT-06 | dagger_throw | K | ✓ |
| TC-INPUT-07 | teleport | F | ✓ |
| TC-INPUT-08 | dash | Shift | ✓ (Day 4 미구현, 입력만 존재) |
| TC-INPUT-09 | pause | Esc | ✓ |

---

## SIM 실행 결과 요약 (2026-05-04)

```
SIM 시나리오: scripts/test/sim_runner.gd
실행: godot --headless res://scenes/test/sim_main.tscn

검증된 csv 시퀀스:
  throw → enemy_stun → plant → throw → enemy_stun → plant
  → throw → enemy_stun → teleport_start → teleport_end
  → execute + enemy_executed
  → throw (ammo 1 회수 후) → throw_blocked × 4 (ammo 0)

자동 통과: TC-MOV-05, TC-JMP-02, TC-DAG-01/02, TC-MRK-01/02/03,
          TC-TPT-01/02/06, TC-BNC-01/02/04/05, TC-EXE-01,
          TC-INPUT-* (autoload + 입력 처리)

수동 필요: TC-MOV-01/02/03/04, TC-JMP-01/03/04/05,
         TC-DAG-04/05, TC-TPT-03/05/07, TC-BNC-03,
         TC-EXE-02/04, TC-FEEL-* 전부, TC-EDG-* 전부
```

---

## 시뮬 재실행 방법

```bash
# 1. 캐시 비우기
rm "/c/Users/sk992/AppData/Roaming/Godot/app_userdata/ProjectCNC/session_log.csv"

# 2. 헤드리스 실행
"/c/Users/sk992/Desktop/Godot_v4.7-dev2_win64.exe/Godot_v4.7-dev2_win64_console.exe" \
  --headless \
  --path "C:/DEV/GODOT/project-cnc" \
  "res://scenes/test/sim_main.tscn"

# 3. csv 분석
cat "/c/Users/sk992/AppData/Roaming/Godot/app_userdata/ProjectCNC/session_log.csv"
```

시나리오 변경 시 `scripts/test/sim_runner.gd`의 `_scenario` 배열만 수정.
