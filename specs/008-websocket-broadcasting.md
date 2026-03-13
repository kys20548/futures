---
id: SPEC-008
title: WebSocket Broadcasting
domain: websocket
status: pending
priority: medium
ticket: ""
target_service: com.xh.websocket.service.BroadcastService
target_method: "broadcast(), broadcastToAll(), broadcastToUser()"
---

## Context

`BroadcastService` 是 Socket.IO（netty-socketio）的廣播層，負責將後端事件（Kafka 消費結果、業務事件）推送給前端連線的 WebSocket 客戶端。採用生產者-消費者模式：事件進入有界佇列，單一 executor thread 消費並推送，避免阻塞業務線程。

## Behavior

### 架構

```
業務事件 → broadcast(data) → LinkedBlockingQueue(cap=1024)
                                        ↓
                         broadcastExecutor (Virtual Thread)
                                        ↓
                    hasFilters? → broadcastWithFiltering
                         NO   → broadcastToAll
```

### 核心方法

- `start()` / `stop()` → 控制 broadcastExecutor 生命週期
- `broadcast(data)` → 非阻塞加入佇列，佇列滿時丟棄並 `log.error`
- `broadcastToAll(data)` → 廣播所有連線（`socketIOServer.getBroadcastOperations().sendEvent`）
- `broadcastToUser(tokenId, data)` → 針對特定 token 的所有 socket 發送
- `broadcastWithFiltering(data)` → 依 `BroadcastFilter` 規則過濾後廣播

### 消息格式

所有消息包裝為 `WebSocketResponseResult.SUCCESS(event, data)`

### Virtual Thread 支援

依 `spring.threads.virtual.enabled` 選擇 `Thread.ofVirtual()` 或 `Thread.ofPlatform()`

## API Contracts（內部元件）

```java
void start()
void stop()
void broadcast(BroadcastData broadcastData)
void broadcastToAll(BroadcastData broadcastData)
void broadcastToUser(String tokenId, BroadcastData broadcastData)
```

`BroadcastData`:
- `event: String`（事件名稱）
- `data: Object`（任意 payload）

## Business Rules

1. 廣播佇列容量上限 1024，超出時丟棄訊息並記錄 error log（不阻塞業務線程）
2. broadcastExecutor 是 daemon-style 單線程，啟動/停止受 lifecycle 管理
3. 若無 `BroadcastFilter` 規則，走快速路徑 `broadcastToAll`
4. 有 filter 規則時，依 tokenId 匹配，只推送相關數據給對應客戶端
5. InterruptedException 中斷 executor 時設置 interrupt flag 並退出循環

## Test Cases

- [ ] `broadcast`：正常加入佇列 → executor 處理後發出 SocketIO 事件
- [ ] `broadcast`：佇列滿（1024 個未消費）→ 丟棄訊息、記錄 error log
- [ ] `broadcastToAll`：所有連線都收到事件，格式為 `WebSocketResponseResult.SUCCESS`
- [ ] `broadcastToUser`：只有指定 tokenId 的 socket 收到事件
- [ ] `broadcastToUser`：tokenId 不存在 → 不發送（無異常）
- [ ] 有 filter 規則時：符合條件的 tokenId 收到數據，不符合的不收到
- [ ] Virtual thread 模式：`broadcastExecutor` 使用 virtual thread
- [ ] Platform thread 模式：`broadcastExecutor` 使用 platform thread
- [ ] `stop()`：executor interrupt 後正確退出 while loop
