---
id: SPEC-001
title: Lead Order Placement
domain: follow-trading
status: pending
priority: high
ticket: ""
target_service: com.xh.service.FollowService
target_method: add(PlaceLeadingOrderRequest)
---

## Context

帶單（Leading Order）是跟單系統的核心功能。帶單者建立一筆訂單後，其他用戶（跟單者）可以跟隨這筆帶單下注。帶單建立時需要：驗證帶單者資格、凍結錢包餘額、初始化 Redis 狀態，並產生帶單邀請碼供跟單者使用。

## Behavior

1. 接收 `PlaceLeadingOrderRequest`，從 SecurityContext 取得當前帳號 ID
2. 查詢帶單者帳號，驗證帳號存在、非殭屍帳號、型別為 RUNNER
3. 查詢對應的 `FuturesGameplay`（通過 `gameplayId`），驗證有效
4. 查詢 `FollowInfo`（帶單設定），驗證存在
5. 通過 `FollowPermissionChecker.requireAccountEligible()` 做帳號資格驗證
6. 生成帶單邀請碼（`RandomStringUtils.randomAlphanumeric(8)`）
7. 通過 `WalletService.payOrderFromFuturesWallet()` 凍結帶單金額
8. 建立 `FuturesOrder` 實體並呼叫 `FuturesOrderService.placeFuturesOrder()`
9. 通過 `FollowRedisStateService.initLeadingOrderState()` 初始化 Redis 狀態（含 TTL）
10. 回傳 `PlaceOrderResponse`（含 orderId、inviteCode）

## API Contracts

### Request
```
POST /follow/place-leading-order
Authorization: Bearer {token}

PlaceLeadingOrderRequest:
  - gameplayId: Long (required)
  - amount: BigDecimal (required, > 0)
  - coinId: Long (required)
  - orderType: Integer (required)
```

### Response
```json
{
  "code": 0,
  "data": {
    "orderId": 123456789,
    "inviteCode": "ABC12345"
  }
}
```

## Business Rules

1. 帶單者帳號 `isSales` 必須是 RUNNER 型別，否則拋出 `NOT_FOUND_RUNNER` 錯誤
2. 帶單者帳號不得為殭屍帳號（`isSales == AccountType.ZOMBIE`），否則拋出 `NOW_ALLOW_ADD_ZOMBIE`
3. 錢包餘額不足時拋出 `INSUFFICIENT_BALANCE`
4. 錢包不存在時拋出 `WALLET_NOT_FUND`
5. 帶單成功後，Redis hash key = `FOLLOW_INVITE-{inviteCode}`，TTL 跟隨 runner 週期
6. 帶單成功後，發送 Kafka 事件 `FUTURES_RUNNER_ACCUMULATE_AMOUNT`（金額取負值）

## Test Cases

- [ ] 正常帶單：RUNNER 帳號、足夠餘額、有效 gameplay → 成功回傳 orderId + inviteCode
- [ ] 殭屍帳號嘗試帶單 → 拋出 `NOW_ALLOW_ADD_ZOMBIE`
- [ ] 非 RUNNER 型別帳號 → 拋出 `NOT_FOUND_RUNNER`
- [ ] 錢包餘額不足 → 拋出 `INSUFFICIENT_BALANCE`
- [ ] 錢包不存在 → 拋出 `WALLET_NOT_FUND`
- [ ] 無效的 gameplayId → 適當錯誤
- [ ] 帶單成功後 Redis 狀態正確初始化（inviteCode 存在、TTL 設置）
- [ ] 帶單成功後 FuturesOrder 記錄正確插入 DB
- [ ] 帶單成功後 Kafka 事件發送（amount 取負值）
