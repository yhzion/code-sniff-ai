#!/bin/bash

# Load environment variables from .env
if [ ! -f ./.env ]; then
    echo "Error: .env file does not exist."
    exit 1
fi

source ./.env

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "The jq program is not installed."
    echo "Please install jq and run the script again."
    exit 1
fi

# 기본 서비스 제공자를 .env 파일에서 로드
service_provider=${SERVICE_PROVIDER:-claude}
anthropic_version=${ANTHROPIC_VERSION:-2023-06-01}
response_path=${RESPONSE_PATH:-".data[0].content"}

# 스피너 함수 정의 (작업 진행 중에 회전하는 애니메이션 표시)
spinner() {
    local pid=$!  # 백그라운드에서 실행 중인 프로세스 ID 저장
    local delay=0.1  # 스피너 애니메이션의 딜레이 시간 설정
    local spinstr='|/-\'  # 스피너에 사용할 문자 설정
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do  # 백그라운드 프로세스가 실행 중일 때
        local temp=${spinstr#?}  # 첫 번째 문자 제거
        printf " [%c]  " "$spinstr"  # 스피너 출력
        spinstr=$temp${spinstr%"$temp"}  # 스피너 문자열 회전
        sleep $delay  # 딜레이 적용
        printf "\b\b\b\b\b\b"  # 이전 스피너 지우기
    done
    printf "    \b\b\b\b"  # 스피너 종료 시 마지막 공백 지우기
    echo " Done"  # 작업 완료 메시지 출력
}

# 실행 함수
run() {
    local model="$MODEL"
    local endpoint="$ENDPOINT"
    local response_path="$RESPONSE_PATH"
    local headers=()
    
    # 서비스 제공자에 따라 API 키 헤더 설정
    if [ "$service_provider" == "claude" ]; then
        headers+=("-H" "x-api-key: $API_KEY")
        headers+=("-H" "anthropic-version: $anthropic_version")
    elif [ "$service_provider" == "chatgpt" ]; then
        headers+=("-H" "Authorization: Bearer $API_KEY")
    fi

    echo -n "Reviewing code changes using $model on $service_provider"  # 리뷰 시작 메시지 출력
    (
        # Move to the root directory of the project
        cd "$(git rev-parse --show-toplevel)"

        max_tokens=${MAX_TOKENS:-4096}
        file_extensions=${FILE_EXTENSIONS:-".json$|.xml$|.ts$|.js$|.html$|.vue$|.sh$|.tsx$|.jsx$"}

        # Find modified files with specific extensions
        files=$(git diff --cached --name-only --diff-filter=ACM | grep -E "$file_extensions")

        for file in $files
        do
            # Get the full content of the file
            full_content=$(cat "$file")
            
            # Get only the changed content
            changed_content=$(git diff --cached "$file" | grep '^[+-]' | grep -v '^[-+][-+][-+]' | sed 's/^[+-]//')
            
            if [ -n "$changed_content" ]; then
                # Create JSON payload to send to the API
                json_payload=$(jq -n \
                    --arg model "$model" \
                    --arg full_content "$full_content" \
                    --arg changed_content "$changed_content" \
                    --arg prompt "$PROMPT" \
                    --arg max_tokens "$max_tokens" \
                    --arg role "user" \
                    --arg content "$PROMPT\n\nFull file content:\n$full_content\n\nChanged content:\n$changed_content" \
                    --argjson stream false \
                    --arg service_provider "$service_provider" \
                    '{
                        "model": $model,
                        "max_tokens": ($max_tokens | tonumber),
                        "messages": [
                            {
                                "role": $role,
                                "content": $content
                            }
                        ]
                    } 
                    + if $service_provider == "ollama" then {"stream": $stream} else {} end')

                # Make the API request
                response=$(curl -s -w "\n%{http_code}" "${headers[@]}" \
                    -H "Content-Type: application/json" \
                    -d "$json_payload" "$endpoint")

                # Separate the HTTP status code and the response body
                http_code=$(echo "$response" | tail -n1)
                body=$(echo "$response" | sed '$d')

                if [ "$http_code" -ne 200 ]; then
                    echo "Error: API returned status code $http_code"
                    echo "$body"
                    exit 1
                fi

                # Extract the review content from the JSON response
                review_content=$(echo "$body" | jq -r "$response_path")

                # Display the review content in plain text
                echo "Review for file $file using $model:"
                echo "$review_content"
            else
                echo "Error: The content of the file $file is empty"
                exit 1
            fi
        done

    ) & spinner  # 스피너 실행
}

# 서비스 제공자에 따른 .env 파일 존재 여부 확인
if [ ! -f "./.env" ]; then
    echo "Error: .env file does not exist."
    exit 1
fi

# 실행
run