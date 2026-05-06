#!/usr/bin/env python3
"""
session_log.csv 분석기 — Day 7 KILL Criteria 자동 판정.

사용법:
    python analyze_csv.py <session1.csv> <session2.csv> ... <session5.csv>

또는 단일 파일:
    python analyze_csv.py session_log.csv

출력:
    - 동사 시퀀스 (3-그램)
    - 시퀀스 간 Levenshtein 거리
    - KILL 판정 (5회 중 4회 이상 동일 시퀀스 → KILL)

사양: DOC/dagger_marker_roadmap_supplement.md §B-2 (Day 7 KILL Criteria)
"""

import csv
import sys
from collections import Counter
from pathlib import Path


# 동사 시퀀스에 포함시킬 액션 (sim_marker / room_enter 등 메타는 제외)
VERB_ACTIONS = {
    "throw",
    "throw_charged",
    "plant",
    "teleport_start",
    "execute",
    "attack",
    "throw_blocked",
}


def levenshtein(a, b):
    """리스트 간 Levenshtein 거리."""
    if len(a) < len(b):
        return levenshtein(b, a)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        curr = [i]
        for j, cb in enumerate(b, 1):
            ins = prev[j] + 1
            dele = curr[j - 1] + 1
            sub = prev[j - 1] + (ca != cb)
            curr.append(min(ins, dele, sub))
        prev = curr
    return prev[-1]


def extract_verbs(csv_path):
    """csv 파일에서 동사 시퀀스 (3-그램 리스트) 반환."""
    actions = []
    with open(csv_path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            action = row.get("action", "").strip()
            if action in VERB_ACTIONS:
                actions.append(action)

    # 3-그램 리스트
    trigrams = []
    for i in range(len(actions) - 2):
        trigrams.append(tuple(actions[i:i + 3]))
    return actions, trigrams


def main():
    if len(sys.argv) < 2:
        print("Usage: analyze_csv.py <csv1> [csv2 ...]")
        sys.exit(1)

    files = [Path(p) for p in sys.argv[1:]]
    print(f"\n=== Analyzing {len(files)} session(s) ===\n")

    all_verb_lists = []
    for fp in files:
        if not fp.exists():
            print(f"  [SKIP] {fp} not found")
            continue
        verbs, trigrams = extract_verbs(fp)
        all_verb_lists.append((fp.name, verbs, trigrams))
        print(f"  {fp.name}: {len(verbs)} verbs, {len(trigrams)} 3-grams")

    if not all_verb_lists:
        print("No valid sessions.")
        return

    print("\n=== Top 3-grams per session ===")
    for name, _, trigrams in all_verb_lists:
        c = Counter(trigrams)
        top = c.most_common(3)
        print(f"\n  {name}:")
        for tg, cnt in top:
            print(f"    {' → '.join(tg)} : {cnt}x")

    if len(all_verb_lists) >= 2:
        print("\n=== Pairwise Levenshtein (verb lists) ===")
        for i in range(len(all_verb_lists)):
            for j in range(i + 1, len(all_verb_lists)):
                ni, vi, _ = all_verb_lists[i]
                nj, vj, _ = all_verb_lists[j]
                dist = levenshtein(vi, vj)
                print(f"  {ni} vs {nj}: dist = {dist}")

    if len(all_verb_lists) >= 5:
        print("\n=== KILL Criteria 판정 (Phase 1 Day 7) ===")
        n = len(all_verb_lists)
        identical_pairs = 0
        for i in range(n):
            for j in range(i + 1, n):
                vi = all_verb_lists[i][1]
                vj = all_verb_lists[j][1]
                if levenshtein(vi, vj) <= 1:
                    identical_pairs += 1
        threshold = 4
        if identical_pairs >= threshold:
            print(f"  KILL — {identical_pairs} 쌍이 동일 시퀀스 (>= {threshold} 임계)")
            print("  메커닉 표현력 부족. supplement §I-3 따라 PIVOT 검토.")
        else:
            print(f"  PASS — {identical_pairs} 쌍 동일 (< {threshold}). 다양성 충분.")
    else:
        print(f"\n(KILL 판정엔 5개 세션 필요. 현재 {len(all_verb_lists)}개.)")


if __name__ == "__main__":
    main()
