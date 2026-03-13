---
id: SPEC-004
title: Follow Redis State Management
domain: follow-trading
status: pending
priority: medium
ticket: ""
target_service: com.xh.futures.follow.redis.FollowRedisStateService
target_method: "getState(), initLeadingOrderState(), recordFollowingOrder(), updateState(), getPlacedCodes()"
---

## Context

`FollowRedisStateService` 隔離跟單/帶單系統所有 Redis 讀寫操作，讓 `FollowService` 核心邏輯可在不依賴 Redis 的情況下測試。它管理三個 Redis key 群：帶單狀態 hash、跟單計數器、已下單 Set。

## Behavior

### Redis Key 設計

| Key | 型別 | 用途 |
|---|---|---|
| `FOLLOW_INVITE-{inviteCode}` | Hash | 帶單狀態（FollowRedisTemp 物件） |
| `FOLLOW_INVITE_AMOUNT-{inviteCode}` | String/Counter | 跟單總金額累加器 |
| `FOLLOW_INVITED_PLACED:{accountId}` | Set | 跟單者已下單的 inviteCode 集合 |

### 方法說明

- `getState(inviteCode)` → 取得帶單 Redis hash 狀態，不存在回傳 null
- `initLeadingOrderState(inviteCode, state, detailTtlSecs, runnerTtlSecs)` → 帶單建立時初始化 hash + 計數器 + TTL
- `recordFollowingOrder(followCode, accountId, amount, ttlSecs)` → 跟單後遞增計數、加入已下單 Set、比較更新 TTL
- `updateState(inviteCode, supplier)` → 帶分散式鎖更新帶單狀態（`@LockR(prefix = "Follow")`）
- `getPlacedCodes(accountId)` → 取得跟單者已下單的所有 inviteCode

## API Contracts（內部服務，無 HTTP 端點）

```java
FollowRedisTemp getState(String inviteCode)

void initLeadingOrderState(
    String inviteCode,
    FollowRedisTemp state,
    long detailTtlSecs,
    long runnerTtlSecs
)

void recordFollowingOrder(
    String followCode,
    Long accountId,
    BigDecimal amount,
    long ttlSecs
)

void updateState(String inviteCode, Supplier<FollowRedisTemp> supplier)

Set<String> getPlacedCodes(Long accountId)
```

## Business Rules

1. `initLeadingOrderState` 設定兩個 TTL：`runnerTtlSecs` 給 hash key，`detailTtlSecs` 給計數器 key
2. `recordFollowingOrder` TTL 比較：若 FOLLOW_INVITED_PLACED 現有 TTL < ttlSecs，則更新（防止 TTL 過早過期）
3. `updateState` 使用 `@LockR(prefix = "Follow")` 分散式鎖，確保並發跟單時帶單狀態更新的原子性
4. `getPlacedCodes` 回傳 Set<String>，空 Set 而非 null（若 key 不存在）

## Test Cases

- [ ] `getState`：存在的 inviteCode → 回傳正確 FollowRedisTemp 物件
- [ ] `getState`：不存在的 inviteCode → 回傳 null
- [ ] `initLeadingOrderState`：hash 寫入正確、計數器初始化為 0、兩個 TTL 正確設置
- [ ] `recordFollowingOrder`：人數計數器 +1
- [ ] `recordFollowingOrder`：金額計數器 + amount
- [ ] `recordFollowingOrder`：inviteCode 加入 Set
- [ ] `recordFollowingOrder`：現有 TTL < ttlSecs → 更新 TTL
- [ ] `recordFollowingOrder`：現有 TTL >= ttlSecs → 不更新 TTL
- [ ] `updateState`：狀態正確更新至 Redis hash
- [ ] `getPlacedCodes`：回傳所有已下單 inviteCode
- [ ] `getPlacedCodes`：空帳號（未下過單）→ 回傳空 Set
