---
id: SPEC-009
title: Kafka Message Handling
domain: kafka-listener
status: pending
priority: medium
ticket: ""
target_service: com.xh.listener
target_method: "FuturesRunnerSettledListener, SettingRefreshListener, UserLevelCacheRefreshListener"
---

## Context

`listener/` 套件包含 Kafka 消費者，監聽 futures-server 發出的事件並執行對應動作（WebSocket 廣播、快取刷新）。每個 listener 使用隨機 groupId 確保廣播語意（每個 futures-api 實例都收到消息）。

## Behavior

### FuturesRunnerSettledListener

- Topic: `FUTURES_RUNNER_SETTLED`
- 行為：收到 runnerId → 呼叫 `broadcastService.broadcastToAll(WALLET_AMOUNT_CHANGED, runnerId)`
- 目的：通知所有連線的客戶端，某個 runner 已結算，需更新錢包顯示

### SettingRefreshListener

- 監聽設定刷新事件
- 行為：觸發快取更新（`CacheUpdateService` 或直接清除快取）

### UserLevelCacheRefreshListener

- 監聽用戶等級變更事件
- 行為：刷新對應用戶的 `UserLevel` 快取

### GroupId 策略

```java
groupId = kafkaGroupIdHandler.generateRandomGroupId(topic)
// 確保每次啟動使用隨機 groupId，讓所有實例都消費到每條消息
```

## API Contracts（Kafka topics）

| Topic | Producer | Consumer | 用途 |
|---|---|---|---|
| `FUTURES_RUNNER_SETTLED` | futures-server | futures-api | runner 結算通知 |
| （其他設定刷新 topic） | manager-api | futures-api | 設定變更刷新 |

## Business Rules

1. 所有 listener 使用隨機 groupId，確保多實例廣播語意（每個 pod 都消費）
2. `FuturesRunnerSettledListener` 收到 runnerId 後，廣播給所有 WebSocket 連線
3. Listener 內部邏輯輕量，不做複雜計算，直接委託 service 處理
4. 消費失敗不重試（廣播語境下重複推送影響較小）

## Test Cases

### FuturesRunnerSettledListener
- [ ] 收到有效 runnerId → `broadcastToAll` 被呼叫，event = `WALLET_AMOUNT_CHANGED`
- [ ] 收到空字串 → 仍廣播（`Objects.toString(message, null)`）
- [ ] 廣播服務可 mock，驗證呼叫參數

### SettingRefreshListener
- [ ] 收到刷新事件 → 對應快取清除/更新
- [ ] 快取刷新後再次查詢返回最新設定

### UserLevelCacheRefreshListener
- [ ] 收到用戶等級變更 → 對應用戶快取失效
- [ ] 快取失效後下次查詢重新從 DB 載入

### 通用
- [ ] 隨機 groupId 確保多實例都消費（每個實例建立獨立 consumer group）
