# futures-specs

Spec-Driven Agent Pipeline for futures-api.

## 架構

```
新 Spec 推送到此 repo
        ↓
GitHub Action 觸發 implement-spec.yml
        ↓
implement-spec.sh 執行 Claude Code CLI
        ↓
在 futures-api 開分支 danny/feat/SPEC-xxx
        ↓
TDD 實作（tests first）→ commit → push → 開 PR
        ↓
Spec status 自動更新為 done
```

## Spec 格式

每個 `specs/*.md` 需包含 YAML frontmatter：

```yaml
---
id: SPEC-001
title: 功能名稱
domain: follow-trading
status: pending       # pending | in-progress | done
priority: high        # high | medium | low
ticket: ""            # 可選的 JIRA 單號
target_service: com.xh.service.FollowService
target_method: methodName()
---
```

然後包含以下節：
- `## Context` — 業務背景
- `## Behavior` — 詳細行為描述
- `## API Contracts` — 端點或方法簽名
- `## Business Rules` — 規則清單
- `## Test Cases` — 測試項目 checklist

## Specs 清單

| ID | 標題 | 複雜度 | 狀態 |
|---|---|---|---|
| SPEC-001 | Lead Order Placement | HIGH | pending |
| SPEC-002 | Follow Order Placement | HIGH | pending |
| SPEC-003 | Follow Permission & Whitelist | MEDIUM | pending |
| SPEC-004 | Follow Redis State Management | MEDIUM | pending |
| SPEC-005 | Amount Validation Pipeline | MEDIUM | pending |
| SPEC-006 | Order CRUD & History | LOW | pending |
| SPEC-007 | Wallet Operations | LOW | pending |
| SPEC-008 | WebSocket Broadcasting | MEDIUM | pending |
| SPEC-009 | Kafka Message Handling | MEDIUM | pending |
| SPEC-010 | Cache Management | LOW | pending |

## 手動觸發

在 GitHub Actions 頁面選擇 `Implement Spec` → `workflow_dispatch`，輸入 spec 文件路徑（如 `specs/001-lead-order-placement.md`）。

## 新增 Spec

1. 在 `specs/` 建立新 `.md` 文件，依照上方格式填寫
2. 設定 `status: pending`
3. Push → GitHub Action 自動觸發實作

## JIRA Ticket → Spec 整合

當有新 JIRA ticket 時：
1. 提供 ticket 號碼
2. Analyst 查詢 JIRA 內容 → 生成 spec 文件
3. Commit spec 到此 repo → GitHub Action 自動觸發實作
4. 每個 ticket 對應一個 spec，保留設計決策記錄

## GitHub Secrets 需求

| Secret | 用途 |
|---|---|
| `ANTHROPIC_API_KEY` | Claude Code CLI |
| `GITHUB_TOKEN` | 建立 PR（自動提供） |
| `FUTURES_API_DEPLOY_KEY` | Clone futures-api private repo |
