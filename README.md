<img width="1012" alt="image" src="https://github.com/user-attachments/assets/32f02c44-1fb3-416d-9327-40fdb42aaa89">

# code-sniff-ai

**code-sniff-ai**는 코드 변경 사항을 자동으로 리뷰해주는 쉘 스크립트입니다. 특정 파일 형식에 대해 git diff를 활용하여 변경된 내용을 추출하고, API를 통해 변경된 코드에 대한 리뷰를 제공합니다.

## 프로젝트 구조

```
code-sniff-ai
├── .env
├── .env.sample
├── .gitignore
├── README.md
├── example
│   ├── javascript
│   │   └── HelloWorld.js
│   └── python
│       └── hello_world.py
└── run-review.sh
```

## 설치 및 설정

### 1. .env 파일 설정

`.env.sample` 파일을 참고하여 `.env` 파일을 생성하고, 필요한 환경 변수들을 설정합니다.

### 2. 필수 의존성 설치

이 스크립트는 `jq`가 필요합니다. `jq`가 설치되어 있지 않다면 아래 명령어를 사용하여 설치할 수 있습니다.

- **Ubuntu/Linux**:

  ```bash
  sudo apt-get install jq
  ```

- **macOS**:

  ```bash
  brew install jq
  ```

- **Windows**:
  Windows에서는 [jq 공식 릴리즈 페이지](https://jqlang.github.io/jq/download/)에서 `jq.exe`를 다운로드하여 사용할 수 있습니다. 다운로드한 파일을 적절한 경로에 저장하고, 해당 경로를 시스템 PATH에 추가합니다.

## 사용법

### 코드 리뷰 실행

1. 코드를 수정한 후 변경 사항을 git에 스테이징합니다.

```bash
git add .
```

2. `run-review.sh` 스크립트를 실행하여 스테이징된 파일에 대한 코드 리뷰를 수행합니다.

```bash
./run-review.sh
```

이 스크립트는 git 저장소의 루트 디렉토리에서 실행되어야 하며, git에 스테이징된 변경 사항에 대해 리뷰를 수행합니다.

### 지원 파일 확장자

기본적으로 아래 확장자의 파일을 대상으로 리뷰를 수행합니다. 필요에 따라 환경 변수로 추가 설정할 수 있습니다.

- .json
- .xml
- .ts
- .js
- .html
- .vue
- .sh
- .tsx
- .jsx
- .py
- .css

## 예제

### JavaScript 예제

`example/javascript/HelloWorld.js` 파일에는 간단한 JavaScript 클래스 예제가 포함되어 있습니다.

```javascript
class HelloWorld {
  constructor() {
    this.message = "Hello, World!";
  }

  sayHello() {
    console.log(this.message);
  }
}
```

이 코드는 `sayHello` 메서드를 통해 "Hello, World!" 메시지를 콘솔에 출력하는 간단한 클래스입니다.

### Python 예제

`example/python/hello_world.py` 파일에는 간단한 Python 클래스 예제가 포함되어 있습니다.

```python
class HelloWorld:
    def __init__(self):
        self.message = 'Hello, World!'

    def say_hello(self):
        print(self.message)

if __name__ == "__main__":
    hello = HelloWorld()
    hello.say_hello()
```

이 코드는 `say_hello` 메서드를 통해 "Hello, World!" 메시지를 콘솔에 출력하는 간단한 클래스입니다.

## Ollama 모델 사전 다운로드

`Ollama`에서 사용하려는 모델은 미리 `ollama pull` 명령어를 이용해 다운로드되어 있어야 합니다. 예를 들어, `gemma2` 모델을 사용하려면 아래 명령어를 실행하여 모델을 다운로드하세요:

```bash
ollama pull gemma2
```

## 연구가 필요한 내용

### 1. Git Workflow 자동화

`code-sniff-ai`를 Git workflow에 통합하여 코드 리뷰 자동화를 더욱 효율적으로 만들 수 있는 방법을 연구 중입니다. 예를 들어, 특정 브랜치에 푸시할 때 자동으로 코드 리뷰가 트리거되도록 하거나, PR 생성 시 자동 리뷰를 실행하는 방법을 모색하고 있습니다. 이러한 통합은 CI/CD 파이프라인에 포함하여 개발 프로세스를 개선할 수 있습니다.

### 2. 프롬프트 엔지니어링을 통한 품질 개선

코드 리뷰의 정확성과 품질을 향상시키기 위해 프롬프트 엔지니어링을 적용할 수 있는 가능성을 연구하고 있습니다. AI 모델이 더욱 정교한 피드백을 제공할 수 있도록 다양한 프롬프트 구성 방안을 실험 중이며, 이를 통해 코드 리뷰 과정의 효율성을 극대화하고자 합니다.

## 기여

기여를 원하시면 이 프로젝트를 포크하고, 새로운 브랜치를 생성하여 변경 사항을 반영한 후 풀 리퀘스트를 제출해주세요.

## 라이선스

이 프로젝트는 [MIT 라이선스](./LICENSE)로 라이선스가 부여되었습니다.

## 참고자료

- [Ollama 설치 안내 페이지](https://ollama.com/download)

## 기원 (origin)
- [권도언님의 velog](https://velog.io/@kwonhl0211/) 에 포스팅되어있는 [Claude로 코드리뷰 경험 개선하기](https://velog.io/@kwonhl0211/Claude%EB%A1%9C-%EC%BD%94%EB%93%9C%EB%A6%AC%EB%B7%B0-%EA%B2%BD%ED%97%98-%EA%B0%9C%EC%84%A0%ED%95%98%EA%B8%B0) 내용의 fork 버전 입니다.
- 권도언님, 유레카 포인트를 제공해주셔서 감사합니다.😊

## 첨언
- 이 프로젝트 코드의 기반은 도언님의 코드이며, 이후 수정/생성된 대부분의 코드는 claude 3.5 sonnet, chat-gpt-4o 에 의해 생성된 것임을 밝힙니다.
