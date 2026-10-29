#!/usr/bin/env bash
# 작업 폴더 루트에서 실행한다: bash /tmp/hack/install.sh
# 기존 파일은 덮어쓰지 않는다. 이 스크립트가 추가한 파일만 commit한다. 다시 실행해도 된다.
# Codex 샌드박스는 .agents/·.git 쓰기를 막으므로 샌드박스 밖(승인 요청)에서 실행한다.
set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$(pwd)"
if [ "$KIT" = "$DEST" ]; then echo "[stop] 키트 폴더가 아니라 작업 폴더 루트에서 실행하세요"; exit 1; fi

added=() fails=()
fail() { echo "[fail] $1"; fails+=("$1"); }
pending() { [ -n "$(git status --porcelain -- "$1" 2>/dev/null)" ]; } # 이전 실행에서 commit 못 한 파일
copy() { # copy <키트 안 경로> <작업 폴더 안 경로>
  if [ -e "$DEST/$2" ]; then echo "[skip] $2 (이미 있음)"; pending "$2" && added+=("$2"); return; fi
  if err="$(mkdir -p "$(dirname "$DEST/$2")" 2>&1 && cp "$KIT/$1" "$DEST/$2" 2>&1)"; then
    echo "[copy] $2"; added+=("$2")
  else fail "$2 — $err"; fi
}

# 1. 작업 규칙 — 과제가 준 AGENTS.md가 있으면 끝에 덧붙인다
if [ -f AGENTS.md ]; then
  if grep -q '<!-- hack:agents -->' AGENTS.md; then echo "[skip] AGENTS.md (이미 덧붙임)"; pending AGENTS.md && added+=(AGENTS.md)
  elif { printf '\n' && cat "$KIT/AGENTS.md"; } >> AGENTS.md 2>/dev/null; then echo "[append] AGENTS.md"; added+=(AGENTS.md)
  else fail "AGENTS.md 덧붙이기"; fi
else copy AGENTS.md AGENTS.md; fi

# 2. 스킬
for s in drill quiz; do copy "skills/$s/SKILL.md" ".agents/skills/$s/SKILL.md"; done

# 3. uv
export PATH="$HOME/.local/bin:$PATH"
if command -v uv >/dev/null 2>&1; then echo "[ok] $(uv --version)"
else
  log=/tmp/hack-uv.log
  { curl -LsSf https://astral.sh/uv/install.sh | sh; } >"$log" 2>&1 || python3 -m pip install --user uv >>"$log" 2>&1
  if command -v uv >/dev/null 2>&1; then echo "[ok] uv 설치: $(uv --version) ($(command -v uv))"
  else fail "uv 설치 — $log 확인"; fi
fi

# 4. commit — 추가한 파일만
if [ ${#added[@]} -eq 0 ]; then echo "[skip] commit (추가한 파일 없음)"
elif ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then echo "[warn] git 저장소가 아님 — commit 생략"
else
  src="https://github.com/ihansam/hack"
  rev="$(git -C "$KIT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  if err="$(git add -- "${added[@]}" 2>&1 && git commit -q -m "chore: 작업 규칙·스킬 추가" -m "출처: $src ($rev)" -- "${added[@]}" 2>&1)"
  then echo "[commit] $(git log -1 --format='%h %s')"
  else fail "commit — $(printf '%s' "$err" | head -1)"; fi
fi

# 5. 지침 로드 점검 — Codex는 폴더마다 AGENTS.override.md를 AGENTS.md보다 먼저 읽고, 합산 32KiB에서 자른다
root="$(git rev-parse --show-toplevel 2>/dev/null)" || root=""
echo "[check] git 루트: ${root:-없음 (Codex는 현재 폴더의 지침만 읽는다)}"
total=0 seen=""
for f in "$HOME/.codex/AGENTS.override.md" "$HOME/.codex/AGENTS.md" "${root:-$DEST}"/AGENTS*.md "$DEST"/AGENTS*.md; do
  [ -f "$f" ] || continue
  case "$seen" in *"|$f|"*) continue;; esac; seen="$seen|$f|"
  n=$(wc -c <"$f" | tr -d ' '); total=$((total + n)); echo "[check] $f ${n}B"
  case "$f" in *AGENTS.override.md) echo "[warn] override가 있다 — 같은 폴더의 AGENTS.md는 읽히지 않는다";; esac
done
[ "$total" -gt 32768 ] && echo "[warn] 지침 합계 ${total}B > 32KiB — 끝에 덧붙인 작업 규칙이 잘릴 수 있다"

if [ ${#fails[@]} -gt 0 ]; then
  printf '\n== 설치 미완 (%d건) ==\n' "${#fails[@]}"; printf -- '- %s\n' "${fails[@]}"
  echo "샌드박스 밖(승인 요청)에서 이 스크립트를 다시 실행한다. 이미 설치된 것은 건너뛴다."
  exit 1
fi

cat <<'EOF'

== 사람이 할 일 ==
1. Codex를 다시 실행한다 (AGENTS.md·스킬은 새 세션에서 읽힌다)
2. /model 로 모델·effort를 고른다 (기본 effort가 낮을 수 있다) · 권한 auto · statusline에 context 사용량
3. $drill 입력 — 이후 할 일은 에이전트가 안내한다
EOF
