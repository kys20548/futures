---
id: SPEC-010
title: Cache Management
domain: futures-cache
status: pending
priority: low
ticket: ""
target_service: com.xh.futures.cache
target_method: "FuturesGameplayCache, FuturesRunnerCache, FuturesTradingPairCache, CoinCache, FutureOrderUplineCache"
---

## Context

`futures/cache/` 套件提供各類期貨業務數據的快取層，減少 DB 查詢壓力。所有快取繼承 `AbstractCacheOperations` 基類，統一快取操作介面。快取更新由 Kafka listener（`SettingRefreshListener`）或快取失效機制觸發。

## Behavior

### AbstractCacheOperations

基類定義快取 CRUD 介面：
- `findAll()` → 載入所有記錄（啟動時或快取失效後）
- `findById(id)` → 按 ID 查詢（先查快取，miss 時查 DB）
- `invalidate()` → 清除快取（觸發重新載入）

### 各快取實作

| 快取類 | 管理實體 | 快取策略 |
|---|---|---|
| `FuturesGameplayCache` | FuturesGameplay（期貨玩法設定）| ConcurrentHashMap + 啟動預熱 |
| `FuturesRunnerCache` | FuturesRunner（帶單玩家）| 依 gameplayId 分組 |
| `FuturesTradingPairCache` | 交易對設定 | 啟動預熱 |
| `CoinCache` | 幣種設定 | 啟動預熱 |
| `FutureOrderUplineCache` | 訂單上游關係 | 按需載入 |

### CacheUpdateService

`CacheUpdateService` 協調多個快取的刷新，供 Kafka listener 呼叫。

## API Contracts（內部快取介面）

```java
// AbstractCacheOperations<T, ID>
List<T> findAll()
Optional<T> findById(ID id)
void invalidate()
void refresh()  // invalidate + findAll
```

## Business Rules

1. 快取啟動時預熱（`@PostConstruct` 或 Spring lifecycle）
2. 快取使用 `ConcurrentHashMap` 存儲，線程安全
3. 快取 miss 時回退查詢 DB（讀 mapper）
4. 接收 Kafka 刷新事件後，透過 `CacheUpdateService` 批量刷新相關快取
5. 快取刷新為最終一致（refresh 期間仍可讀舊數據）

## Test Cases

- [ ] `findById`：快取命中 → 直接回傳，不查 DB
- [ ] `findById`：快取 miss → 查 DB 並回填快取
- [ ] `findAll`：回傳所有快取記錄
- [ ] `invalidate`：清除快取後下次查詢走 DB
- [ ] `FuturesGameplayCache`：gameplayId 正確對應 FuturesGameplay
- [ ] `FuturesRunnerCache`：按 gameplayId 分組查詢正確
- [ ] 快取線程安全：並發讀寫不拋出 ConcurrentModificationException
- [ ] 快取預熱：應用啟動後快取非空
- [ ] `CacheUpdateService`：刷新後所有相關快取更新為最新數據
