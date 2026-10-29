#!/usr/bin/env bash
# 작업 폴더 루트에서 실행한다: bash /tmp/hack/install.sh
# 기존 파일은 덮어쓰지 않는다. 이 스크립트가 추가한 파일만 commit한다.
set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$(pwd)"
if [ "$KIT" = "$DEST" ]; then echo "[stop] 키트 폴더가 아니라 작업 폴더 루트에서 실행하세요"; exit 1; fi

added=()
copy() { # copy <키트 안 경로> <작업 폴더 안 경로>
  if [ -e "$DEST/$2" ]; then echo "[skip] $2 (이미 있음)"; return; fi
  mkdir -p "$(dirname "$DEST/$2")" && cp "$KIT/$1" "$DEST/$2" && echo "[copy] $2" && added+=("$2")
}

# 1. 작업 규칙 — 과제가 준 AGENTS.md가 있으면 끝에 덧붙인다
if [ -f AGENTS.md ]; then
  if grep -q '<!-- hack:agents -->' AGENTS.md; then echo "[skip] AGENTS.md (이미 덧붙임)"
  else printf '\n' >> AGENTS.md && cat "$KIT/AGENTS.md" >> AGENTS.md && echo "[append] AGENTS.md" && added+=(AGENTS.md); fi
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
  else echo "[fail] uv 설치 실패 — $log 확인"; fi
fi

# 4. commit — 추가한 파일만
if [ ${#added[@]} -eq 0 ]; then echo "[skip] commit (추가한 파일 없음)"
elif ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then echo "[warn] git 저장소가 아님 — commit 생략"
else
  src="https://github.com/ihansam/hack"
  rev="$(git -C "$KIT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  git add -- "${added[@]}" && \
  git commit -q -m "chore: 작업 규칙·스킬 추가" -m "출처: $src ($rev)" -- "${added[@]}" && \
  echo "[commit] $(git log -1 --format='%h %s')" || echo "[warn] commit 실패 — git 사용자 설정을 확인하세요"
fi

cat <<'EOF'

== 사람이 할 일 ==
1. Codex를 다시 실행한다 (AGENTS.md·스킬은 새 세션에서 읽힌다)
2. /model 로 모델·effort를 고른다 (기본 effort가 낮을 수 있다) · 권한 auto · statusline에 context 사용량
3. $drill 입력 — 이후 할 일은 에이전트가 안내한다
EOF
