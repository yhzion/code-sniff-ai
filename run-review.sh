#!/bin/bash

# General settings
CURRENT_DIR=$(pwd)
TARGET_PROJECT_PATH=${TARGET_PROJECT_PATH:="./"}

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
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo " Done"
}

# 실행 함수
run() {
    local api_key="$API_KEY"
    local model="$MODEL"
    local endpoint="$ENDPOINT"
    local response_path="$RESPONSE_PATH"
    local headers=()

    max_tokens=${MAX_TOKENS:-4096}
    file_extensions=${FILE_EXTENSIONS:-".json$|.xml$|.ts$|.js$|.html$|.vue$|.sh$|.tsx$|.jsx$"}
    
    # 서비스 제공자에 따라 API 키 헤더 설정
    if [ "$service_provider" == "claude" ]; then
        headers+=("-H" "x-api-key: $API_KEY")
        headers+=("-H" "anthropic-version: $anthropic_version")
    elif [ "$service_provider" == "chatgpt" ] || [ "$service_provider" == "groq" ]; then
        headers+=("-H" "Authorization: Bearer $API_KEY")
    elif [ "$service_provider" == "gemini" ]; then
        # Gemini doesn't need any additional headers
        :
    fi

    echo -n "Reviewing code changes using $model on $service_provider"
    (
        # Move to target project path
        printf "\n리뷰를 위해 목표 프로젝트로 이동합니다.\n" 
        cd "$TARGET_PROJECT_PATH" || { printf "지정된 경로로 이동할 수 없습니다.: $TARGET_PROJECT_PATH"; exit 1;}
        printf "\n현재 디렉토리는 $TARGET_PROJECT_PATH 입니다.\n"

        # Move to the root directory of the project
        cd "$(git rev-parse --show-toplevel)"

        # Find modified files with specific extensions
        files=$(git diff --cached --name-only --diff-filter=ACM | grep -E "$file_extensions")

        # Exit process if files are not found
        if [ -z "$files" ]; then
          printf "리뷰할 대상이 존재하지 않습니다."
          exit 1
        fi

        for file in $files
        do
            printf "$file 파일을 리뷰 중 입니다."
            # Get the full content of the file
            full_content=$(cat "$file")
            
            # Get only the changed content
            changed_content=$(git diff --cached "$file" | grep '^[+-]' | grep -v '^[-+][-+][-+]' | sed 's/^[+-]//')
            
            if [ -n "$changed_content" ]; then
                # Create JSON payload to send to the API
                if [ "$service_provider" == "gemini" ]; then
                json_payload=$(jq -n \
                    --arg prompt "$PROMPT\n\nFull file content:\n$full_content\n\nChanged content:\n$changed_content" \
                    --arg max_tokens "$max_tokens" \
                    '{
                        "contents": [
                            {
                                "parts": [
                                    {
                                        "text": $prompt
                                    }
                                ]
                            }
                        ],
                        "generationConfig": {
                            "maxOutputTokens": ($max_tokens | tonumber)
                        }
                    }')
                else
                    json_payload=$(jq -n \
                        --arg model "$model" \
                        --arg full_content "$full_content" \
                        --arg changed_content "$changed_content" \
                        --arg prompt "$PROMPT" \
                        --arg max_tokens "$max_tokens" \
                        --arg role "user" \
                        --arg content "$PROMPT\n\nFull file content:\n$full_content\n\nChanged content:\n$changed_content" \
                        --argjson stream false \
                        '{
                            "model": $model,
                            "stream": false,
                            "max_tokens": ($max_tokens | tonumber),
                            "messages": [
                                {
                                    "role": $role,
                                    "content": $content
                                }
                            ]
                        }')
                fi

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

        # Move to current dir after review has done.
        cd "$CURRENT_DIR" || { printf "현재 위치로 복귀할 수 없습니다.: $CURRENT_DIR"; exit 1;}
        printf "\n현재 디렉토리는 $CURRENT_DIR 입니다.\n"
        printf "\n리뷰가 종료되었습니다.\n"

    ) & spinner
}

# 서비스 제공자에 따른 .env 파일 존재 여부 확인
if [ ! -f "./.env" ]; then
    echo "Error: .env file does not exist."
    exit 1
fi

# 실행
run
