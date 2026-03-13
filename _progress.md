# 分析進度

## 功能域總覽

| 域 | 說明 | Spec 數 | 狀態 |
|---|---|---|---|
| A | 跟單系統（Follow Trading）| 5 | 進行中 |
| B | 期貨訂單（Order）| 3 | 待分析 |
| C | 錢包（Wallet）| 2 | 待分析 |
| D | WebSocket 推播 | 3 | 待分析 |
| E | Kafka 消費者 | 2 | 待分析 |
| F | Cache 層 | 2 | 待分析 |
| G | futures-server 核心 | 4 | 待分析 |
| H | REST API 層 | 3 | 待分析 |

---

## 詳細項目

### A — 跟單系統（Follow Trading）

- [ ] A-1: 帶單下單流程 `FollowService.add(PlaceLeadingOrderRequest)` → spec 檔：
- [ ] A-2: 跟單下單流程 `FollowService.add(PlaceFollowingOrderRequest)` → spec 檔：
- [ ] A-3: 金額驗證策略 `validator/` (ByAmountRang, ByFixedAmount, ByBalancePercentage) → spec 檔：
- [ ] A-4: Redis 狀態管理 `FollowRedisStateService` → spec 檔：
- [ ] A-5: 帳號權限與白名單 `FollowPermissionChecker, FollowService.addOrDelete()` → spec 檔：

### B — 期貨訂單（Order）

- [ ] B-1: 訂單 CRUD `FuturesOrderService` → spec 檔：
- [ ] B-2: 撤單流程 `FollowService.cancel()` → spec 檔：
- [ ] B-3: 訂單查詢與歷史 `FuturesOrderService.getFuturesOrders()` → spec 檔：

### C — 錢包（Wallet）

- [ ] C-1: 下單凍結 / 撤單解凍 `WalletService` → spec 檔：
- [ ] C-2: 錢包變更日誌 `WalletChangeLog` → spec 檔：

### D — WebSocket 推播

- [ ] D-1: 廣播服務 `BroadcastService` → spec 檔：
- [ ] D-2: 連線管理 `SocketConnectionRegistry, WebSocketClientCache` → spec 檔：
- [ ] D-3: 訊息處理 `DefaultWebsocketMessageHandler, interceptors` → spec 檔：

### E — Kafka 消費者

- [ ] E-1: Runner 結算通知 `FuturesRunnerSettledListener` → spec 檔：
- [ ] E-2: 設定 / 用戶等級刷新 `SettingRefreshListener, UserLevelCacheRefreshListener` → spec 檔：

### F — Cache 層（futures-api）

- [ ] F-1: 快取架構 `AbstractCacheOperations` + 各快取類 → spec 檔：
- [ ] F-2: 快取更新流程 `CacheUpdateService` → spec 檔：

### G — futures-server 核心

- [ ] G-1: Gameplay 引擎 `FuturesGameplayEntity`（755行，收益計算核心）→ spec 檔：
- [ ] G-2: Runner 生命週期 `FuturesRunner` 管理 → spec 檔：
- [ ] G-3: 結算流程 settlement logic → spec 檔：
- [ ] G-4: server Kafka 訊息處理 `message/` → spec 檔：

### H — REST API 層

- [ ] H-1: 跟單 Controller `FollowController, FollowInternalController` → spec 檔：
- [ ] H-2: 期貨 Controller `FutureController` → spec 檔：
- [ ] H-3: 錯誤處理 `ErrorHandler, advice/` → spec 檔：
