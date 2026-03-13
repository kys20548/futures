---
id: SPEC-006
title: Order CRUD & History
domain: futures-order
status: pending
priority: low
ticket: ""
target_service: com.xh.futures.service.FuturesOrderService
target_method: "placeFuturesOrder(), getFuturesOrders(), getFuturesOrderHistory(), getRevocableFuturesOrders(), changeFuturesOrderStatus()"
---

## Context

`FuturesOrderService` 管理期貨訂單的 CRUD 操作，包含下單、查詢現有訂單（PENDING/ACTIVE）、查詢歷史訂單、取消前置驗證、以及狀態變更。下單後透過 Kafka 發送累計金額事件。

## Behavior

### placeFuturesOrder

1. 呼叫 `futuresOrderMapper.insert(order)` 寫入 DB
2. 發送 Kafka 事件 `FUTURES_RUNNER_ACCUMULATE_AMOUNT`（金額取負值，表示資金流出）

### getFuturesOrders

1. 查詢狀態為 `PENDING | ACTIVE` 的訂單
2. 支援 `tradeType` 過濾、模擬帳號（simulatedId）
3. 回傳分頁結果 `PageVo<FuturesOrder>`

### getFuturesOrderHistory

1. 按時間範圍、tradeType 查詢歷史訂單
2. 支援模擬帳號（`@SimulationSupport`）
3. 回傳分頁結果 `PageVo<FuturesOrderHistory>`

### getRevocableFuturesOrders

1. 查詢 `accountId + orderId` 對應訂單
2. 若訂單不存在 → `IllegalArgumentException`
3. 若訂單狀態不是 `PENDING` → `ONLY_PENDING_STATUS_ALLOW_REVOKE`
4. 回傳可撤銷的 `FuturesOrder`

### changeFuturesOrderStatus

1. 更新訂單狀態（通過 accountId + orderId 確保帳號隔離）
2. 若更新行數不是 1 → `RuntimeException`（表示 DB 異常或並發衝突）

### getFuturesOrderById / getHistoryFuturesOrderById

- `@Cacheable(key = "#id")` 快取現有訂單查詢（cache name: `futures-api::follow-order`）

## API Contracts（內部服務方法）

```java
void placeFuturesOrder(FuturesOrder order)
PageVo<FuturesOrder> getFuturesOrders(Integer tradeType, Long accountId, Long simulatedId, Integer page, Integer size)
PageVo<FuturesOrderHistory> getFuturesOrderHistory(LocalDateTime start, LocalDateTime end, Integer tradeType, Long acctId, Long simulatedId, Integer page, Integer size)
FuturesOrder getRevocableFuturesOrders(Long acctId, Long orderId)
void changeFuturesOrderStatus(Long acctId, Long orderId, FuturesOrderStatusType statusType)
Optional<FuturesOrder> getFuturesOrderById(Long id)
```

## Business Rules

1. 只有 `PENDING` 狀態的訂單可以被撤銷
2. 狀態變更使用 `@Transactional`，DB 更新行數必須恰好為 1
3. 訂單查詢使用 read mapper（`FuturesOrderHistoryMapper`），下單使用 master mapper
4. Kafka 累計事件：`amount.negate()` 表示帶單 runner 的資金流出（負值）
5. 現有訂單快取：Redis cache，key 為訂單 ID

## Test Cases

- [ ] `placeFuturesOrder`：DB 寫入成功 + Kafka 事件發送（amount 為負值）
- [ ] `getFuturesOrders`：回傳 PENDING/ACTIVE 訂單，支援 tradeType 過濾
- [ ] `getFuturesOrderHistory`：按時間範圍正確過濾
- [ ] `getRevocableFuturesOrders`：正常 PENDING 訂單 → 回傳
- [ ] `getRevocableFuturesOrders`：訂單不存在 → IllegalArgumentException
- [ ] `getRevocableFuturesOrders`：訂單非 PENDING → `ONLY_PENDING_STATUS_ALLOW_REVOKE`
- [ ] `changeFuturesOrderStatus`：成功更新狀態（updAmount == 1）
- [ ] `changeFuturesOrderStatus`：並發衝突（updAmount != 1）→ RuntimeException
- [ ] `getFuturesOrderById`：快取命中（第二次查詢不走 DB）
