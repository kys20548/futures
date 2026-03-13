#!/usr/bin/env bash
# implement-spec.sh — 讀取一個 spec 文件，在 futures-api 上實作並開 PR
# Usage: implement-spec.sh <spec-file>
# Environment:
#   ANTHROPIC_API_KEY   - Claude API key
#   GITHUB_TOKEN        - GitHub token for PR creation
#   FUTURES_REPO_PATH   - path to cloned futures repo (default: /tmp/futures)

set -euo pipefail

SPEC_FILE="${1:?Usage: implement-spec.sh <spec-file>}"
FUTURES_REPO="${FUTURES_REPO_PATH:-/tmp/futures}"
LOG_DIR="/tmp/impl-logs"
mkdir -p "$LOG_DIR"

# --- 讀取 spec 元數據 ---
SPEC_ID=$(grep '^id:' "$SPEC_FILE" | sed 's/id: //' | tr -d '[:space:]"')
SPEC_TITLE=$(grep '^title:' "$SPEC_FILE" | sed 's/title: //' | tr -d '"')
SPEC_STATUS=$(grep '^status:' "$SPEC_FILE" | sed 's/status: //' | tr -d '[:space:]"')
TARGET_SERVICE=$(grep '^target_service:' "$SPEC_FILE" | sed 's/target_service: //' | tr -d '"')

echo "📋 Spec: $SPEC_ID - $SPEC_TITLE"
echo "   Status: $SPEC_STATUS"
echo "   Target: $TARGET_SERVICE"

# --- 跳過已完成的 spec ---
if [ "$SPEC_STATUS" = "done" ]; then
    echo "⏭️  Skipping $SPEC_ID (already done)"
    exit 0
fi

# --- 在 futures-api 上建立功能分支 ---
BRANCH="danny/feat/${SPEC_ID}"
cd "$FUTURES_REPO"
git fetch origin main
git checkout main
git pull origin main
git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# --- 組裝 Claude 提示 ---
SPEC_CONTENT=$(cat "$OLDPWD/$SPEC_FILE")
PROMPT=$(cat << PROMPT_EOF
You are implementing a Java Spring Boot feature for the futures-api service.

## Spec to Implement

$SPEC_CONTENT

## Repository Context

- Project: futures-api (Java 21, Spring Boot 3.3.3)
- Working directory: $FUTURES_REPO/futures-api
- Read CLAUDE.md for build commands and architecture details

## Implementation Instructions

1. **Locate the target service**: Find \`$TARGET_SERVICE\` in the codebase
2. **Follow TDD**: Write tests first (in src/test/), then implement
3. **Code style**: Follow existing patterns (Lombok, MyBatis Plus, @Transactional)
4. **Test location**: Mirror the source path under src/test/java/
5. **Minimal changes**: Only implement what the spec describes

## Output Requirements

- Write test file(s) first
- Write/modify implementation file(s)
- Commit message: short, ~10 Chinese characters (no Co-Authored-By)
- Do NOT push — the script will handle that

Start by reading the relevant source files, then implement step by step.
PROMPT_EOF
)

# --- 執行 Claude Code CLI ---
LOG_FILE="$LOG_DIR/${SPEC_ID}.log"
echo "🤖 Running Claude Code for $SPEC_ID..."

cd "$FUTURES_REPO/futures-api"
claude --print --allowedTools "Read,Write,Edit,Bash,Glob,Grep" \
    -p "$PROMPT" 2>&1 | tee "$LOG_FILE"

# --- 檢查是否有變更 ---
cd "$FUTURES_REPO"
if [ -z "$(git status --porcelain)" ]; then
    echo "⚠️  No changes made for $SPEC_ID"
    exit 0
fi

# --- Commit & Push ---
git add -A
git commit -m "實作 ${SPEC_ID}: ${SPEC_TITLE}"
git push origin "$BRANCH"

# --- 建立 PR (via gh CLI) ---
if command -v gh &> /dev/null; then
    gh pr create \
        --title "[${SPEC_ID}] ${SPEC_TITLE}" \
        --body "## Spec\n\nImplemented from \`${SPEC_FILE}\`\n\n## Changes\n\n- [ ] Tests written\n- [ ] Implementation complete\n- [ ] Build passes" \
        --base dev \
        --head "$BRANCH" \
        --repo firebit/backend/futures \
        2>/dev/null || echo "⚠️  PR creation skipped (may already exist)"
fi

# --- 更新 spec status 為 done ---
cd "$OLDPWD"
sed -i "s/^status: pending/status: done/" "$SPEC_FILE"
git add "$SPEC_FILE"
git commit -m "mark $SPEC_ID as done"
git push origin main

echo "✅ Done: $SPEC_ID"
