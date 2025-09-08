#!/bin/bash

# Test script to verify API communication
# Replace YOUR_API_KEY with your actual Claude API key

API_KEY="${ANTHROPIC_API_KEY:-YOUR_API_KEY}"

if [ "$API_KEY" = "YOUR_API_KEY" ]; then
    echo "Please set ANTHROPIC_API_KEY environment variable or edit this script"
    exit 1
fi

echo "Testing Claude API..."
echo

curl -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "messages": [
      {
        "role": "user",
        "content": "Hello"
      }
    ],
    "max_tokens": 1024
  }' | tee test_api_response.json | python3 -m json.tool

echo
echo "Response saved to test_api_response.json"