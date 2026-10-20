# Security Policy / 보안 정책

## Supported Versions / 지원 버전

| Version | Supported |
| ------- | --------- |
| 0.1.x   | ✅        |

## Reporting a Vulnerability / 취약점 보고

**Security contact / 보안 담당자:**

- **Youngho Jeon (전영호)** — GitHub [@yhzion](https://github.com/yhzion)
- **Email:** [gplusit@gmail.com](mailto:gplusit@gmail.com)

Please report security vulnerabilities **privately by email** rather than through
public GitHub issues. 보안 취약점은 공개 이슈가 아닌 **이메일로 비공개 보고**해 주세요.

Include as much of the following as possible / 아래 내용을 포함해 주세요:

- Affected version and environment / 영향받는 버전과 환경
- Step-by-step reproduction or PoC / 재현 절차 또는 PoC
- Potential impact / 예상 영향

### Response targets / 응답 목표

- Acknowledgement within **72 hours** / 접수 후 72시간 이내 회신
- Fix or mitigation plan within **14 days** for confirmed issues / 확인된 취약점은 14일 이내 수정 계획
- Coordinated disclosure after a fix is released / 수정본 배포 후 조정된 공개(CVD) 진행

Reporters who follow this policy will be credited in the release notes
(unless anonymity is requested). 이 정책을 따른 보고자는 릴리스 노트에 크레딧을
제공합니다(익명 요청 시 제외).

## Scope / 범위

- This repository (`yhzion/code-sniff-ai`) and the published npm package `code-sniff-ai`
- 이 저장소와 npm 패키지 `code-sniff-ai`

## Handling your own API keys / API 키 관리 주의

`code-sniff-ai` sends your code to the LLM provider you configure. Never commit
`.env` files or API keys to version control. `.env` is already git-ignored.
`.env` 파일과 API 키는 절대 저장소에 커밋하지 마세요.
