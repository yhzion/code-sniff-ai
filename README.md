
# code-sniff-ai

**code-sniff-ai**는 코드 변경 사항을 자동으로 리뷰해주는 스크립트입니다. 특정 파일 형식에 대해 git diff를 활용하여 변경된 내용을 추출하고, API를 통해 변경된 코드에 대한 리뷰를 제공합니다.

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

## 기여

기여를 원하시면 이 프로젝트를 포크하고, 새로운 브랜치를 생성하여 변경 사항을 반영한 후 풀 리퀘스트를 제출해주세요.

## 라이선스

이 프로젝트는 [MIT 라이선스](./LICENSE)로 라이선스가 부여되었습니다.

## 참고자료

- [Ollama 설치 안내 페이지](https://ollama.com/download)
