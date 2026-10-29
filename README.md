# hack

시간 제한이 있는 데이터·코드 과제를 코딩 에이전트(Codex)와 함께 할 때 쓰는 작업 규칙·문서 틀·스킬.
과제 답이나 과제별 코드는 들어 있지 않다.

## 에이전트에게 — 설치

"ihansam/hack 받아서 README대로 해줘"를 받았다면 **작업 폴더 루트에서** 아래만 실행한다.

```bash
git clone --depth 1 https://github.com/ihansam/hack /tmp/hack 2>/dev/null || git -C /tmp/hack pull -q
bash /tmp/hack/install.sh
```

- 작업 폴더 안에 clone하지 않는다(키트의 git 이력이 작업 이력에 섞이지 않게).
- `install.sh` 출력의 `[copy]`·`[append]`·`[skip]`·`[ok]`·`[fail]`·`[commit]` 줄을 그대로 보고하고, 마지막 **"사람이 할 일"**을 그대로 전달한다.
- 그 외에는 아무것도 하지 않는다. 과제 읽기·계획은 사람이 지시할 때 시작한다.

## install.sh가 하는 일

| 단계 | 내용 |
|---|---|
| 작업 규칙 | `AGENTS.md` 복사. 과제가 준 `AGENTS.md`가 있으면 덮어쓰지 않고 끝에 덧붙인다 |
| 문서 틀 | `STATUS.md`·`SPEC.md`·`DECISIONS.md` — 이미 있으면 건너뛴다 |
| 스킬 | `.agents/skills/walkthrough`·`.agents/skills/quiz` |
| uv | 없으면 설치(공식 설치 스크립트, 실패하면 pip) |
| commit | 이 스크립트가 추가한 파일만, 출처 URL과 함께 |

## 구성

| 경로 | 내용 |
|---|---|
| `AGENTS.md` | 문서 역할·읽는 법, ADR 한 줄 형식, 결정과 비준, commit 규칙, 처리 흐름 한 장, 순서와 체크포인트, 환경 규칙 |
| `templates/` | `STATUS.md`(30줄 이내 현재 상태) · `SPEC.md`(원문 위치 참조, 담당자 답 원문 인용, 용어) · `DECISIONS.md` |
| `skills/walkthrough` | 계획 전에 입력 한 건을 원문부터 결과까지 기준 문서로 따라가며 용어·산식을 푼다 |
| `skills/quiz` | 마감 전에 작업 기록을 근거로 확인 질문 2~3개 — 안다/모른다를 고르고 대조 |

## 설계 메모

- **문서는 작게, 읽는 범위는 구조로 제한한다.** 세션은 `STATUS.md`와 자기 Epic 파일만 읽는다. SPEC·DECISIONS는 `rg`로 필요한 줄만 읽는다.
- **결정과 비준을 나눈다.** 초반에는 에이전트가 되돌리기 쉬운 기본값으로 정하고 `[agent·잠정]`으로 남긴다. 사람은 문제를 이해한 뒤 첫 체크포인트에서 결과를 바꾸는 결정만 묶어서 비준한다.
- **이해는 마지막에 몰아 두지 않는다.** 초반에 입력 한 건 따라가기, 중간에 비준, 처리 흐름 한 장, 마감 전에 quiz.

## License

MIT
