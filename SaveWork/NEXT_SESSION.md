# NEXT_SESSION.md — Claude 다음 작업 인수인계

**대상**: 다음 세션의 Claude (사용자 아님)
**프로젝트**: C:\DEV\GODOT\project-cnc — Godot 4.7-dev2 횡스크롤 단검 마커 액션
**원격**: https://github.com/KIMDAHOON-PANGPANG/ProjectCNC (master)
**작성일**: 2026-05-05

---

## 1. 절대 먼저 읽어야 할 파일 (3개, 순서대로)

1. `C:\Users\sk992\.claude\plans\c-dev-godot-project-cnc-doc-dapper-parnas.md` — 원래 계획. Day 1~7 + Phase 2~5 사양.
2. `DOC/dagger_marker_roadmap_supplement.md` — 가장 중요한 단일 진실 소스. 특히 다음 섹션:
   - **§A** 데드카피 수치표 (game_constants.gd 근거)
   - **§B-2** Bounce Chain 사양
   - **§H-2** Logic-View-Body 차원 무관 아키텍처
   - **§I-7** 강제 자체 검증 워크플로우 ← **모든 코드 변경 후 무조건 따라야 함**
   - **§J** 룸 모듈 카탈로그
3. `DOC/dagger_marker_roadmap.html` — 진행 트래킹 (Phase 0~5 체크리스트)

---

## 2. 현재까지 완료된 항목 (스킵 가능)

### Day 0 ~ Day 7 (Phase 1) — 100% 코드 완료
- 폴더 트리, project.godot, 입력맵 9종, 15개 autoload
- PlayerLogic + PlayerBody2D (차원 무관 아키텍처)
- DaggerLogic + DaggerBody2D (RigidBody2D + CCD CAST_RAY)
- MarkerManager (max 3 / 8s lifetime / **expire 시 ammo +1 — 사용자 의도 반영**)
- 텔레포트 (Tween 0.12s + 자동 흡착 + 마커 회수)
- Bounce Chain v0 (적 1회 / 튕김면 1회)
- Game Feel 7종 (히트스탑 / 셰이크 / 줌펀치 / 트레일 / 잔상 / 진동 / SFX)
- Edge Indicator + 평타 3타 콤보 + 충전 던지기 (관통 2회)

### Phase 2 ~ Phase 5 — 코드 완료, 사용자 작업 대기
- 룸 10개 + 보스 (chapter_1.tscn 챕터 시퀀스)
- 4 표면 타입 (spike / breakable / moving / iron_grate)
- Transition autoload (검정 fade out → 룸 교체 → fade in)
- Pause Menu (Esc), Debug Overlay (F3), HUD (DAGGERS/MARKERS/ROOM)
- 적 4종 (charger / ranged / denier / bomber) + 보스 2 페이즈
- Procedural SFX (5 presets) + BGM (4초 루프, A minor)
- Hit FX 파티클, Aim Reticle, Facing Indicator + Aim Dot
- analyze_csv.py (Day 7 Levenshtein KILL 판정 자동화)

---

## 3. 다음 작업 우선순위 (이걸 먼저 체크)

### **A. 사용자 마지막 미응답 검증** ← 가장 시급
사용자에게 **자체 시뮬레이션 1차 검증 결과 보고**한 직후 푸시 요청을 받음. 사용자가 실제 GUI에서 챕터를 끝까지 (10룸 + 보스) 플레이할 수 있는지 **검증 결과를 아직 못 받음**. 다음 세션 시작 시 사용자에게 묻거나, 사용자가 결과 알려주면 그것부터 처리.

체크할 항목:
- F5로 chapter_1.tscn 부팅 → Room01 페이드 인 정상?
- 우클릭/F/좌클릭/Esc/F3 모두 작동?
- Room01 → 02 → ... → 10 → 06_boss 자동 전환?
- 보스 처형 가능?

### **B. Phase 3 폴리시 강화 (계획 §G "광고용 수준")**
현재 Phase 1 placeholder 수준. 사용자가 원하면:
- GPUParticles2D (트레일 / 박힘 / 처형)
- 디졸브 셰이더 (텔레포트)
- 표면별 5종 SFX (벽/철/나무/살/돌)
- 색수차 / 모션 라인

### **C. Phase 4 메뉴 확장**
현재 Pause만. 사용자 원하면:
- 사운드 설정 (마스터 / SFX / BGM 슬라이더)
- 화면 설정 (창 크기 / 풀스크린 / vsync)
- 입력 리매핑 UI

### **D. ObjectDB leak 정밀 fix (선택)**
`AudioStreamWAV / AudioStreamPlaybackWAV` leak 2개 — Godot 4.7-dev2 종료 시점 이슈. 게임플레이 영향 0이라 §I-7-A 화이트리스트에 등록됨. 안정 4.x 출시 시 자동 해소 예정.

---

## 4. **§I-7 강제 자체 검증 워크플로우** ← 모든 코드 변경 후 필수

```bash
GODOT="/c/Users/sk992/Desktop/Godot_v4.7-dev2_win64.exe/Godot_v4.7-dev2_win64_console.exe"
PROJ="C:/DEV/GODOT/project-cnc"
CSV="/c/Users/sk992/AppData/Roaming/Godot/app_userdata/ProjectCNC/session_log.csv"

# 1. 캐시 클린 + 출력 분리 저장
rm -rf "$PROJ/.godot" && rm -f /tmp/run_*.log "$CSV"

# 2. import (class_name 캐시 빌드 — 반드시 먼저!)
"$GODOT" --headless --path "$PROJ" --import 1>/tmp/run_import.log 2>&1

# 3. GUI 5초 부팅
"$GODOT" --path "$PROJ" --quit-after 300 1>/tmp/run_gui.log 2>&1

# 4. sandbox 시뮬
"$GODOT" --headless --path "$PROJ" "res://scenes/test/sim_main.tscn" 1>/tmp/run_sim.log 2>&1

# 5. 에러 grep + 화이트리스트 적용
grep -iE "error|fail|push_error|push_warning|invalid|cannot|not found|null inst" /tmp/run_*.log | \
  grep -vE "DOTNET|Asio|Vulkan|D3D12|TextServer|XR_|OpenXR|FFmpeg|Native mobile|Failed to bind|MultiUma|Orphan|unclaimed|AudioStreamWAV|AudioStreamPlayback|leaked at exit|^$"

# 빈 줄이면 통과. 한 줄이라도 잡히면 즉시 수정 → 1단계부터 재실행 → 통과까지 반복.
```

### 화이트리스트 (무시 가능, supplement §I-7-A)
- `Failed to bind socket. Error: 3` (다른 Godot 인스턴스 충돌)
- `AudioStreamWAV/Playback leaked at exit` (Godot dev 빌드 minor)
- `XR_/Native mobile/OpenXR/D3D12/FFmpeg/MultiUmaBuffer/Orphan StringName` (엔진 정상)

### 즉시 수정 대상 (supplement §I-7-B)
- `Identifier not found: <X>` → `@onready var _x = get_node_or_null("/root/X")` 우회 (autoload identifier 직접 사용 X)
- `Could not find type "<class>"` → **--import 먼저** 실행 (class_name 캐시 빌드)
- `Can't change state while flushing queries` → `set_deferred(...)`
- `Leaked instance: <Resource>` (게임플레이 중) → autoload `_exit_tree`에서 정리

---

## 5. 핵심 파일 위치 (빠른 참조)

| 카테고리 | 파일 |
|---|---|
| **튜닝 수치** | `scripts/globals/game_constants.gd` (모든 상수 한 곳) |
| **메인 씬** | `scenes/chapter_1.tscn` (project.godot main_scene) |
| **사용자 sandbox** | `scenes/sandbox.tscn` (단일 룸 검증용) |
| **시뮬 러너** | `scripts/test/sim_runner.gd` + `scenes/test/sim_main.tscn` |
| **분석 도구** | `DOC/analyze_csv.py` (Day 7 KILL 판정) |
| **Player 로직** | `scripts/player/player_logic.gd` (차원 무관) |
| **Player 바디** | `scripts/player/player_body_2d.gd` (CharacterBody2D wrapper) |
| **Dagger** | `scripts/dagger/dagger_logic.gd` + `dagger_body_2d.gd` |
| **MarkerManager** | `scripts/dagger/marker_manager.gd` (autoload) |
| **룸 베이스** | `scripts/rooms/room_base.gd` |
| **룸 매니저** | `scripts/systems/room_manager.gd` (autoload, fade transition) |
| **룸 씬들** | `scenes/rooms/room_01_*.tscn` ~ `room_10_*.tscn` + `room_06_boss.tscn` |
| **적 4종** | `scripts/enemies/{melee_charger,ranged_shooter,marker_denier,suicide_bomber}.gd` |
| **보스** | `scripts/enemies/boss.gd` (2 페이즈) |
| **HUD** | `scripts/ui/hud.gd` |
| **Reticle** | `scripts/ui/aim_reticle.gd` (autoload) |

---

## 6. Autoload 등록 순서 (project.godot 기준, 의존성 순)

```
GameConstants  → 다른 모든 게 참조
DebugLog       → action_logged signal 발행
HitStop        → Engine.time_scale 제어
Greybox        → COLORS dict + spawn_view
CameraShake    → shake / zoom_punch
Rumble         → 컨트롤러 진동
MarkerManager  → markers Array + ammo
RoomManager    → 룸 전환 + 통계 집계
Transition     → fade out/in (RoomManager가 호출)
Sfx            → procedural tone 5종
Bgm            → 4초 루프
HitFx          → 파편 spawn
PauseMenu      → Esc 토글
DebugOverlay   → F3 토글
AimReticle     → 마우스 reticle
```

---

## 7. 입력 매핑 (project.godot)

| 동작 | 키/마우스 |
|---|---|
| 이동 | A/D |
| 점프 | Space |
| 단검 던지기 | **우클릭** + K (0.5s 길게 = 충전 던지기, 적 2명 관통) |
| 워프(텔레포트) | **F** |
| 공격 | **좌클릭** (J 제거됨, 사용자 요청) |
| 대시 | Shift (미구현) |
| 일시정지 | Esc |
| 디버그 오버레이 | F3 |

---

## 8. 사용자 환경 정보

- **OS**: Windows
- **사용자명**: sk992
- **Godot CLI**: `C:/Users/sk992/Desktop/Godot_v4.7-dev2_win64.exe/Godot_v4.7-dev2_win64_console.exe`
- **Godot 버전**: 4.7-dev2 (dev 빌드 — 일부 minor 이슈 있음)
- **Godot 4 사용자 데이터**: `C:/Users/sk992/AppData/Roaming/Godot/app_userdata/ProjectCNC/`
  - `session_log.csv` — DebugLog 액션 기록
  - `logs/godot.log` — Godot 자체 로그
- **Python**: 사용 가능 (analyze_csv.py 실행됨)

### 주의: 사용자 에디터 캐시 stale 자주 발생
사용자가 새 autoload / class_name 추가 시 에디터 reload 안 하면 `Identifier not found` 에러 자주 봄.
**해결 가이드**:
1. Project → Reload Current Project (Ctrl+Shift+T)
2. 또는 에디터 완전 종료 → 다시 열기 (자동 import 1~2분)
3. 그래도 안 되면 `.godot` 폴더 삭제 후 에디터 다시 열기

---

## 9. 알려진 이슈 + 회피 패턴 (supplement §I-7-D)

| 일자 | 에러 | 원인 | 수정 |
|---|---|---|---|
| 2026-05-04 | `Identifier not found: Rumble/CameraShake` | autoload identifier 인식 실패 | `@onready var _x = get_node_or_null("/root/X")` |
| 2026-05-04 | `Can't change state while flushing queries` | RigidBody2D body_entered에서 freeze 직접 | `set_deferred("freeze", true)` |
| 2026-05-05 | `AudioStreamWAV/Playback leaked` | Godot dev 빌드 종료 시점 minor | 화이트리스트 처리 (게임 영향 0) |
| 2026-05-05 | `Could not find type "VisualResource"` | --import 안 거치고 GUI 부팅 시 class_name 캐시 미빌드 | 항상 `--import` 먼저 강제 실행 |
| 2026-05-05 | 단검 expire 시 ammo 복구 안 됨 | 원 사양은 expire +0이었음 | 사용자 의도 따라 +1로 변경 |

---

## 10. 사용자 작업 대기 항목 (코드로 불가)

| 항목 | 상태 |
|---|---|
| Day 7 OBS 60초 × 5회 녹화 | 사용자 수동 (analyze_csv.py로 자동 분석은 가능) |
| Phase 3 30분 풀플레이 매너리즘 측정 | 사용자 수동 |
| Phase 4 외부 5명 플레이테스트 | 사용자 수동 |
| Phase 4 트레일러 30초 클립 | 영상 편집 도구 |
| Phase 5 시장 포지셔닝 / 스팀 페이지 / 결정 메모 | 사용자 의사결정 |

---

## 11. 사용자 마지막 메시지 흐름 (참고)

1. 평타 3타 시각화 추가 요청 → 완료
2. F 키로 워프 변경 요청 → 완료
3. Aim Reticle 추가 요청 → 완료
4. Facing Indicator 추가 요청 → 완료
5. 단검 expire 시 ammo 복구 요청 → 완료
6. 자체 시뮬 검증 요청 → 1차 완료 (chapter_1 부팅 / sandbox sim / csv 분석 모두 통과)
7. **GitHub 푸시 요청 → 완료** ← 마지막 작업
8. **이 SaveWork 작성 요청** ← 현재

다음 세션 시작 시:
- 사용자 검증 결과 받기 (마지막 검증 chapter_1 끝까지 가능?)
- 또는 사용자가 새 요청을 던지면 그걸 처리

---

## 12. 워크플로우 룰 정착 사항

1. **모든 코드 변경 후 §I-7 3단계 검증 필수**. 통과 후에만 사용자 보고.
2. **Autoload 추가/변경 시** `@onready var _x = get_node_or_null("/root/X")` 패턴 사용 (autoload identifier 직접 의존 X — dev 빌드 호환).
3. **RigidBody2D 충돌 콜백**(body_entered)에서 mode 변경 시 `set_deferred(...)` 필수.
4. **사용자에게 보고 시 §I-4 템플릿 준수**: 변경 파일 / 자체 검증 결과 / 수동 체크리스트 / 다음 작업 명시.
5. **수동 체크리스트는 §I-6 카테고리별 작성**, "자연스러운가" 같은 모호한 표현 금지.

---

## 13. 다음 세션 첫 행동 가이드

```
1. 이 파일 (NEXT_SESSION.md) 읽기
2. supplement.md §I-7 워크플로우 재확인
3. 사용자 메시지 받기:
   a. 검증 결과 보고 받음 → 새 이슈면 즉시 §I-7-B 표 매칭 → 수정
   b. 새 기능 요청 → 즉시 코드 작성 → §I-7 검증 → 보고
   c. 의문점 → AskUserQuestion 또는 명확화 질문 (Auto mode면 합리적 가정 후 진행)
4. 작업 종료 시 이 파일 갱신 (특히 §3 우선순위 / §11 마지막 흐름)
```
