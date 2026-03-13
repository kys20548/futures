# Futures Go Rewrite — Agent Workflow

## 專案目標

將 Java 21 Spring Boot 的期貨交易平台（futures-api + futures-server）以架構師視角全面重構為 Go。
不是 copy-paste 翻譯，而是利用重構機會解決現有技術債，強化效能（尤其下單路徑的 cache 設計）並以 TDD 實作。

## 重要路徑

| 項目 | 路徑 |
|---|---|
| Java 原始碼 | `/Users/gaoweizhi/xh-workflow/firebit/workspace/futures/` |
| 本 repo | `/Users/gaoweizhi/xh-workflow/firebit/futures-specs/` |
| 進度追蹤 | `_progress.md` |
| Spec 文件 | `specs/*.md` |
| Go 實作 | `go/` |

## 三種工作模式

---

### 🔍 ANALYZE 模式

**觸發**：用戶說「分析」

**行為**：
1. 讀 `_progress.md`，找第一個 `[ ]` 狀態的分析項目
2. 以**架構師視角**分析對應的 Java 原始碼：
   - 現有實作有什麼問題？鎖粒度、快取設計、耦合度
   - Go 重構應該怎麼改？
   - Cache 策略：下單路徑如何做到低延遲
3. 寫 spec 文件到 `specs/`，格式見下方
4. 更新 `_progress.md`，將該項目標記為 `[x]`，填入 spec 文件路徑
5. `git add → commit → push`
6. 回報完成，並列出下一個待分析項目

**注意**：每次只分析一個項目，不要一次做多個。

---

### ⚙️ IMPLEMENT 模式

**觸發**：用戶說「實作」或「看有沒有新 spec」

**行為**：
1. `git pull` 拿最新 specs
2. 掃描 `specs/*.md`，找 `status: pending` 的 spec
   - 若無 pending spec，改查 GitHub open issues（`gh issue list`）
3. 選取一個 spec 或 issue，以 TDD 方式在 `go/` 實作：
   - 先寫 test（RED）
   - 寫最小實作（GREEN）
   - Refactor
4. 完成後：
   - 更新 spec `status: done`
   - commit + push
   - 若有對應 issue，`gh issue close`
5. 回報完成內容

---

### 📋 ISSUE 模式

**觸發**：用戶說「開 issue」或描述一個需求

**行為**：
1. 理解用戶需求
2. 整理成結構化的 GitHub issue：
   - **Title**：簡短描述
   - **Body**：背景、需求細節、驗收條件
   - **Labels**：`spec` / `enhancement` / `bug` 依情況
3. 執行 `gh issue create`，推到 GitHub
4. 回報 issue URL

---

## Spec 格式

```markdown
---
id: SPEC-XXX
title: 功能名稱
domain: follow-trading | order | wallet | websocket | kafka | cache | server
status: pending
priority: high | medium | low
java_source:
  - path/to/JavaFile.java
go_package: internal/follow
---

## 現有實作分析
描述 Java 現在怎麼做，不用面面俱到，重點在架構與流程。

## 問題 / 技術債
- 問題一（例：分散式鎖粒度過粗，影響並發下單吞吐）
- 問題二

## Go 重構設計
說明 Go 版本的架構決策，為什麼這樣設計。

## Cache 策略
Redis key 命名、TTL、失效時機、下單 hot path 優化方式。
（若此 spec 無 cache 需求可省略）

## Data Models
Go struct 定義（可用虛擬碼）。

## API Contracts
HTTP 端點或 internal interface 定義。

## TDD Test Cases
- [ ] unit: 描述
- [ ] unit: 描述
- [ ] integration: 描述
```

---

## 如何接續上一個工作狀態

每次 session 開始時：
1. 讀 `_progress.md` → 了解整體進度
2. 確認目前模式（用戶指令）
3. ANALYZE 模式：找第一個未完成的分析項目繼續
4. IMPLEMENT 模式：找最新 pending spec 或 open issue 繼續

---

## Go 模組資訊

```
module github.com/kys20548/futures
go 1.23
```

目錄結構（實作時逐步建立）：
```
go/
├── go.mod
├── go.sum
├── cmd/
│   ├── api/        ← futures-api 入口
│   └── server/     ← futures-server 入口
└── internal/
    ├── follow/     ← 跟單系統
    ├── order/      ← 訂單管理
    ├── wallet/     ← 錢包
    ├── broadcast/  ← WebSocket 推播
    ├── cache/      ← 快取層
    └── kafka/      ← Kafka 消費者
```
