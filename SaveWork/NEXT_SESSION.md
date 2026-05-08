# NEXT_SESSION.md — Claude 다음 작업 인수인계

**대상**: 다음 세션의 Claude (사용자 아님 — 어떤 로컬 환경에서든 즉시 이어서 작업)
**프로젝트**: Godot 4.7-dev2 횡스크롤 단검 마커 액션 (Cyber Shadow + 카타리나)
**원격**: https://github.com/KIMDAHOON-PANGPANG/ProjectCNC (master)
**최종 갱신**: 2026-05-08

---

## 0. **사용자의 다른 PC (집 / 노트북 등)에서 시작하는 절차** (5분)

> **주 시나리오**: 같은 사용자가 다른 Windows PC에서 이어서 작업.
> macOS/Linux도 부산물로 작동하지만 주 대상은 **다른 Windows PC**.
> 사용자명 / Godot 경로 / 클론 위치만 PC마다 다르고, 나머지는 동일.

### Step 1. 의존성 확인
| 도구 | 검증 명령 | 비고 |
|---|---|---|
| Git + git-bash | `git --version` | Windows: Git for Windows 설치 시 git-bash 포함 |
| Godot 4.7-dev2 | `<godot_path> --version` | Windows: 압축 푼 폴더의 `_console.exe` 권장 |
| Python 3 | `python --version` | analyze_csv.py 용 (Windows에선 Microsoft Store 또는 python.org) |

### Step 2. Godot 4.7-dev2 (없으면 받기)
- 공식: https://godotengine.org/download/archive/4.7-dev2/
- Windows: `Godot_v4.7-dev2_win64_console.zip` (console 버전이 stdout 캡처 가능)
- 압축 풀어 **Desktop / Downloads / C:\Godot / D:\Godot 중 어디든** 두기 (env_check.sh가 자동 검색)

### Step 3. 프로젝트 클론
```bash
# git-bash에서:
git clone https://github.com/KIMDAHOON-PANGPANG/ProjectCNC.git
cd ProjectCNC
```
※ 첫 PC에서는 GitHub 인증 필요 (PAT 또는 SSH key). git config user.email/name도 PC별 셋업.

### Step 4. 환경 자동 검출 + 검증
```bash
bash SaveWork/env_check.sh                      # 1. 환경 검출
source <(bash SaveWork/env_check.sh --export)   # 2. env 적용
bash SaveWork/env_check.sh --verify             # 3. §I-7 자동 검증
```

`env_check.sh`가 자동 처리하는 PC별 차이:
- **사용자명**: `$HOME` / `$USERNAME` 자동
- **Godot 위치**: PATH → Desktop / Downloads / Program Files / C:\Godot / D:\Godot 순서 자동 검색
- **프로젝트 위치**: `$(pwd)` 자동
- **AppData 경로**: `$APPDATA` 자동 (사용자명 포함된 절대경로 변환)

### Step 5. Godot 검출 실패 시
env_check.sh가 `[ERROR] Godot CLI not found` 출력하면 수동 export:
```bash
export GODOT_BIN="/c/Users/<USERNAME>/Downloads/Godot_v4.7-dev2_win64.exe"  # 실제 위치로
bash SaveWork/env_check.sh --verify
```
이 경로를 env_check.sh의 `GODOT_CANDIDATES`에 추가하면 다음 PC에서도 자동 검출됨.

### Step 5. 첫 import (필수, class_name 캐시 빌드)
```bash
"$GODOT_BIN" --headless --path "$(pwd)" --import
```
1~2분 소요. **import 안 하고 바로 GUI 띄우면 `Could not find type "VisualResource"` 등 컴파일 에러 발생** (§9 표 참조).

### Step 6. 동작 확인
```bash
"$GODOT_BIN" --headless --path "$(pwd)" --quit-after 600
# exit 0이면 부팅 성공
```

### Step 7. supplement.md §I-7 워크플로우 한 번 실행
SaveWork/env_check.sh 끝부분 명령 그대로. 통과 후 작업 시작.

---

## 1. 절대 먼저 읽어야 할 파일 (3개, 순서대로)

1. **이 파일** (NEXT_SESSION.md) — 인수인계
2. `DOC/dagger_marker_roadmap_supplement.md` — **단일 진실 소스**. 특히:
   - **§A** 데드카피 수치표 (game_constants.gd 근거)
   - **§B-2** Bounce Chain 사양
   - **§H-2** Logic-View-Body 차원 무관 아키텍처
   - **§I-7** 강제 자체 검증 워크플로우 ← **모든 코드 변경 후 무조건**
   - **§J** 룸 모듈 카탈로그
3. `DOC/dagger_marker_roadmap.html` — 진행 트래킹 (Phase 0~5 체크리스트)
4. (선택) 사용자 PC에 있을 수도: `C:\Users\sk992\.claude\plans\c-dev-godot-project-cnc-doc-dapper-parnas.md` — 다른 PC엔 없으니 supplement로 충분

---

## 2. 현재까지 완료된 항목

### Day 0~7 (Phase 1) — 100% 코드 완료
- 폴더 트리, project.godot, 입력맵 9종, **15개 autoload**
- PlayerLogic + PlayerBody2D (차원 무관 아키텍처)
- DaggerLogic + DaggerBody2D (RigidBody2D + CCD CAST_RAY)
- MarkerManager (max 3 / 8s lifetime / **expire 시 ammo +1 — 사용자 의도 반영**)
- 텔레포트 (Tween 0.12s + 자동 흡착 + 마커 회수)
- Bounce Chain v0 (적 1회 / 튕김면 1회)
- Game Feel 7종 (히트스탑 / 셰이크 / 줌펀치 / 트레일 / 잔상 / 진동 / SFX)
- Edge Indicator + 평타 3타 콤보 + 충전 던지기 (관통 2회)

### Phase 2~5 — 코드 완료, 사용자 작업 대기
- 룸 10개 + 보스 (chapter_1.tscn 챕터 시퀀스)
- 4 표면 타입 (spike / breakable / moving / iron_grate)
- Transition autoload (검정 fade out → 룸 교체 → fade in)
- Pause Menu (Esc), Debug Overlay (F3), HUD (DAGGERS/MARKERS/ROOM)
- 적 4종 (charger / ranged / denier / bomber) + 보스 2 페이즈
- Procedural SFX (5 presets) + BGM (4초 루프, A minor)
- Hit FX 파티클, Aim Reticle, Facing Indicator + Aim Dot
- analyze_csv.py (Day 7 Levenshtein KILL 판정 자동화)

---

## 3. 다음 작업 우선순위

### **A. 사용자 마지막 미응답 검증** ← 가장 시급
사용자가 챕터 끝까지 (10룸 + 보스) 플레이 가능한지 결과 미수신. 다음 세션에서 사용자가 결과 보고하면:
- 정상 → Phase 5 GO/PIVOT/KILL 의사결정 또는 추가 폴리시
- 에러 → §9 표 매칭 → 즉시 수정

체크 항목:
- F5로 chapter_1.tscn 부팅 → Room01 페이드 인 정상?
- 우클릭/F/좌클릭/Esc/F3 모두 작동?
- Room01 → 02 → ... → 10 → 06_boss 자동 전환?
- 보스 처형 가능?

### **A-2. 미니멀 전투 테스트 씬** ← 사용자 수동 검증 대기 (2026-05-08)
- `scripts/enemies/melee_chaser.gd` (텔레그래프 X, 항상 추적, RayCast로 절벽/벽 감지)
- `scenes/enemies/melee_chaser_2d.tscn` (charger visual 재사용)
- `scenes/test/combat_test.tscn` (sandbox 베이스 + Left/Right/Mid 플랫폼 + Chaser @ (380,240))
- §I-7 3단계 검증 PASS (import / combat_test 5s 부팅 / sandbox sim 모두 exit 0, 필터링 후 에러 0)
- 사용자: 에디터에서 `scenes/test/combat_test.tscn` 열고 F6 → NEXT_TASK_combat_test.md §2 시나리오 7개 수동 테스트
- 결과 보고 시 정상 → 적 4종 통합 / 에러 → §9 표 매칭 → 수정

### **B. Phase 3 폴리시 강화** (계획 §G "광고용 수준")
GPUParticles2D / 디졸브 셰이더 / 표면별 5종 SFX / 색수차 / 모션 라인.

### **C. Phase 4 메뉴 확장**
사운드 슬라이더 / 화면 설정 / 입력 리매핑 UI.

### **D. ObjectDB leak 정밀 fix** (선택)
화이트리스트 처리 중. 안정 4.x 출시 시 자동 해소.

---

## 4. **§I-7 강제 자체 검증 워크플로우** ← 모든 코드 변경 후 필수

### 4-A. 환경변수 (먼저 export)

```bash
# 자동 (env_check.sh가 출력하는 줄을 그대로 source)
source <(bash SaveWork/env_check.sh --export)

# 또는 수동 (예시 — 실제 경로로 교체)
export GODOT_BIN="/c/Users/<USER>/Desktop/Godot_v4.7-dev2_win64.exe/Godot_v4.7-dev2_win64_console.exe"
export PROJECT_PATH="$(pwd)"
```

### 4-B. CSV 위치 (OS별)

| OS | session_log.csv 경로 |
|---|---|
| **Windows** | `$APPDATA/Godot/app_userdata/ProjectCNC/session_log.csv`<br>`= /c/Users/<USER>/AppData/Roaming/Godot/app_userdata/ProjectCNC/` |
| **macOS** | `~/Library/Application Support/Godot/app_userdata/ProjectCNC/` |
| **Linux** | `~/.local/share/godot/app_userdata/ProjectCNC/` |

env_check.sh가 자동 검출해 `CSV_PATH` 환경변수 export.

### 4-C. 3단계 검증 (universal)

```bash
# 1. 캐시 클린 + 출력 분리
rm -rf "$PROJECT_PATH/.godot" /tmp/run_*.log "$CSV_PATH" 2>/dev/null

# 2. import (class_name 캐시 빌드 — 반드시 먼저!)
"$GODOT_BIN" --headless --path "$PROJECT_PATH" --import 1>/tmp/run_import.log 2>&1
[ $? -eq 0 ] && echo "[1/3] import OK"

# 3. GUI 5초 부팅
"$GODOT_BIN" --path "$PROJECT_PATH" --quit-after 300 1>/tmp/run_gui.log 2>&1
[ $? -eq 0 ] && echo "[2/3] gui boot OK"

# 4. sandbox 시뮬
"$GODOT_BIN" --headless --path "$PROJECT_PATH" "res://scenes/test/sim_main.tscn" 1>/tmp/run_sim.log 2>&1
[ $? -eq 0 ] && echo "[3/3] sim OK"

# 5. 에러 grep + 화이트리스트
grep -iE "error|fail|push_error|push_warning|invalid|cannot|not found|null inst" /tmp/run_*.log | \
  grep -vE "DOTNET|Asio|Vulkan|D3D12|TextServer|XR_|OpenXR|FFmpeg|Native mobile|Failed to bind|MultiUma|Orphan|unclaimed|AudioStreamWAV|AudioStreamPlayback|leaked at exit|^$"

# 빈 줄이면 통과. 한 줄이라도 잡히면 즉시 §9 표 매칭 → 수정 → 1단계 재실행 → 통과까지 반복.
```

### 4-D. 화이트리스트 (무시 가능, supplement §I-7-A)
- `Failed to bind socket. Error: 3` (다른 Godot 인스턴스 충돌)
- `AudioStreamWAV/Playback leaked at exit` (Godot dev 빌드 minor)
- `XR_/Native mobile/OpenXR/D3D12/FFmpeg/MultiUmaBuffer/Orphan StringName` (엔진 정상)

### 4-E. 즉시 수정 대상 (supplement §I-7-B)
- `Identifier not found: <X>` → `@onready var _x = get_node_or_null("/root/X")` 우회
- `Could not find type "<class>"` → **--import 먼저** 실행 (class_name 캐시 빌드)
- `Can't change state while flushing queries` → `set_deferred(...)`
- `Leaked instance: <Resource>` (게임플레이 중) → autoload `_exit_tree`에서 정리

---

## 5. 핵심 파일 위치 (OS 무관 res:// 경로)

| 카테고리 | 파일 |
|---|---|
| **튜닝 수치** | `res://scripts/globals/game_constants.gd` |
| **메인 씬** | `res://scenes/chapter_1.tscn` (project.godot main_scene) |
| **사용자 sandbox** | `res://scenes/sandbox.tscn` (단일 룸 검증용) |
| **시뮬 러너** | `res://scripts/test/sim_runner.gd` + `res://scenes/test/sim_main.tscn` |
| **분석 도구** | `DOC/analyze_csv.py` (Day 7 KILL 판정) |
| **Player 로직** | `res://scripts/player/player_logic.gd` (차원 무관) |
| **Player 바디** | `res://scripts/player/player_body_2d.gd` (CharacterBody2D wrapper) |
| **Dagger** | `res://scripts/dagger/{dagger_logic,dagger_body_2d,dagger_trail}.gd` |
| **MarkerManager** | `res://scripts/dagger/marker_manager.gd` (autoload) |
| **룸 베이스** | `res://scripts/rooms/room_base.gd` |
| **룸 매니저** | `res://scripts/systems/room_manager.gd` (autoload, fade transition) |
| **룸 씬들** | `res://scenes/rooms/room_01_*.tscn` ~ `room_10_*.tscn` + `room_06_boss.tscn` |
| **적 4종** | `res://scripts/enemies/{melee_charger,ranged_shooter,marker_denier,suicide_bomber}.gd` |
| **보스** | `res://scripts/enemies/boss.gd` (2 페이즈) |
| **HUD** | `res://scripts/ui/hud.gd` |
| **Reticle** | `res://scripts/ui/aim_reticle.gd` (autoload) |

---

## 6. Autoload 등록 순서 (project.godot, 의존성 순)

```
GameConstants → DebugLog → HitStop → Greybox → CameraShake → Rumble →
MarkerManager → RoomManager → Transition → Sfx → Bgm → HitFx →
PauseMenu → DebugOverlay → AimReticle
```
총 15개. 의존성:
- 거의 모든 autoload가 GameConstants 참조
- RoomManager가 Transition 호출
- HUD/EdgeIndicator/DebugOverlay는 MarkerManager / RoomManager 시그널 수신
- 신규 autoload 추가 시 **반드시 @onready var _x = get_node_or_null("/root/X") 패턴** (직접 identifier 참조 X — 사용자 에디터 stale cache 회피)

---

## 7. 입력 매핑 (project.godot)

| 동작 | 키/마우스 |
|---|---|
| 이동 | A/D |
| 점프 | Space |
| 단검 던지기 | **우클릭** + K (0.5s 길게 = 충전 던지기, 적 2명 관통) |
| 워프(텔레포트) | **F** |
| 공격 | **좌클릭** (J 제거됨) |
| 대시 | Shift (미구현) |
| 일시정지 | Esc |
| 디버그 오버레이 | F3 |

---

## 8. 환경별 사용자 데이터 경로

| OS | session_log.csv | godot.log |
|---|---|---|
| **Windows** | `%APPDATA%\Godot\app_userdata\ProjectCNC\session_log.csv` | `%APPDATA%\Godot\app_userdata\ProjectCNC\logs\godot.log` |
| **macOS** | `~/Library/Application Support/Godot/app_userdata/ProjectCNC/session_log.csv` | 동일 디렉터리/logs/ |
| **Linux** | `~/.local/share/godot/app_userdata/ProjectCNC/session_log.csv` | 동일/logs/ |

bash에서 OS 자동 검출:
```bash
case "$(uname -s)" in
  CYGWIN*|MINGW*|MSYS*) USERDATA="$APPDATA/Godot/app_userdata/ProjectCNC" ;;
  Darwin*) USERDATA="$HOME/Library/Application Support/Godot/app_userdata/ProjectCNC" ;;
  Linux*)  USERDATA="$HOME/.local/share/godot/app_userdata/ProjectCNC" ;;
esac
export CSV_PATH="$USERDATA/session_log.csv"
export GODOT_LOG="$USERDATA/logs/godot.log"
```
이건 `SaveWork/env_check.sh`가 자동으로 처리.

---

## 9. 알려진 이슈 + 회피 패턴 (supplement §I-7-D)

| 일자 | 에러 | 원인 | 수정 패턴 |
|---|---|---|---|
| 2026-05-04 | `Identifier not found: Rumble/CameraShake` | autoload identifier 인식 실패 (dev 빌드 stale cache) | `@onready var _x = get_node_or_null("/root/X")` |
| 2026-05-04 | `Can't change state while flushing queries` | RigidBody2D body_entered에서 freeze 직접 변경 | `set_deferred("freeze", true)` |
| 2026-05-05 | `AudioStreamWAV/Playback leaked` | Godot dev 빌드 종료 시점 minor | 화이트리스트 처리 (게임 영향 0) |
| 2026-05-05 | `Could not find type "VisualResource"` | --import 안 거치고 GUI 부팅 시 class_name 캐시 미빌드 | 항상 `--import` 먼저 강제 실행 |
| 2026-05-05 | 단검 expire 시 ammo 복구 안 됨 | 원 사양은 expire +0이었음 | 사용자 의도 따라 +1로 변경 (marker_manager.gd) |

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

## 11. 사용자 마지막 메시지 흐름

1. 평타 3타 시각화 추가 → 완료
2. F 키로 워프 변경 → 완료
3. Aim Reticle 추가 → 완료
4. Facing Indicator 추가 → 완료
5. 단검 expire 시 ammo 복구 → 완료
6. 자체 시뮬 검증 → 1차 완료
7. GitHub 푸시 → 완료
8. SaveWork 작성 → 완료
9. 이 문서 환경 호환성 강화 + env_check.sh 추가 → 완료
10. NEXT_TASK_combat_test.md 작성 (chaser + 전투 테스트 씬 계획) → 완료
11. **melee_chaser + combat_test.tscn 구현 + §I-7 검증 PASS** ← 현재 (2026-05-08)

다음 세션 시작 시:
- 사용자 chapter_1 검증 결과 받기 (미응답)
- 사용자 combat_test.tscn 수동 테스트 결과 받기 (NEXT_TASK_combat_test.md §2 시나리오)
- 또는 새 요청 처리

---

## 12. 워크플로우 룰 정착 사항 (변경 금지)

1. **모든 코드 변경 후 §I-7 3단계 검증 필수**. 통과 후에만 사용자 보고.
2. **Autoload 추가/변경 시** `@onready var _x = get_node_or_null("/root/X")` 패턴 (autoload identifier 직접 의존 X).
3. **RigidBody2D body_entered 콜백**에서 mode 변경 시 `set_deferred(...)` 필수.
4. **사용자 보고 시 §I-4 템플릿 준수**: 변경 파일 / 자체 검증 결과 / 수동 체크리스트 / 다음 작업.
5. **수동 체크리스트는 §I-6 카테고리별** ("자연스러운가" 같은 모호한 표현 금지).
6. **새 autoload 추가 시** 사용자에게 **반드시 에디터 reload 안내** (Project → Reload Current Project).

---

## 13. 다음 세션 첫 행동 가이드

```
1. SaveWork/NEXT_SESSION.md (이 파일) 읽기
2. DOC/dagger_marker_roadmap_supplement.md §I-7 재확인
3. bash SaveWork/env_check.sh 실행 → 환경 검출 + GODOT_BIN/PROJECT_PATH/CSV_PATH export
4. §4-C 3단계 검증 명령 실행 → 통과 확인
5. 사용자 메시지 받기:
   a. 검증 결과 보고 → 새 이슈면 §9 표 매칭 → 수정
   b. 새 기능 요청 → 즉시 코드 → §I-7 검증 → 보고
   c. 의문점 → AskUserQuestion 또는 합리적 가정 (Auto mode)
6. 작업 종료 시 이 파일 §3 / §11 갱신 + 푸시
```

---

## 14. SaveWork 폴더 구조

```
SaveWork/
├── NEXT_SESSION.md       ← 이 파일 (인수인계)
└── env_check.sh          ← 환경 자동 검출 + 검증 명령 출력
```

다음 세션은 위 두 파일만 읽으면 어떤 환경에서든 5분 안에 작업 시작 가능.
