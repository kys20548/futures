---
id: SPEC-002
title: Follow Order Placement
domain: follow-trading
status: pending
priority: high
ticket: ""
target_service: com.xh.service.FollowService
target_method: add(PlaceFollowingOrderRequest)
---

## Context

跟單（Following Order）是跟單者持有帶單邀請碼後決定跟進下注的操作。需通過多重驗證（Redis 狀態、帳號資格、自跟防護、重複下單防護、金額策略驗證），確認後凍結錢包並建立訂單，最後更新 Redis 計數。

## Behavior

1. 接收 `PlaceFollowingOrderRequest`（含 inviteCode、amount、coinId）
2. 從 SecurityContext 取得跟單者帳號 ID
3. 通過 inviteCode 查詢 Redis（`FollowRedisStateService.getState()`）取得帶單狀態
4. 驗證帶單狀態存在且有效
5. 查詢跟單者帳號，執行 `FollowPermissionChecker.requireAccountEligible()`
6. 執行 `FollowPermissionChecker.checkNotSelf()` 防止跟自己的帶單
7. 檢查 `FollowRedisStateService.getPlacedCodes()` 防止重複下單
8. 查詢 `FollowInfo` 和 `FollowInfoDetail`，選擇金額驗證策略（By_Amount_Rang / By_Fixed_Amount / By_Balance_Percentage）
9. 執行 `AmountLimitValidator.validate()`
10. 通過 `WalletService.payOrderFromFuturesWallet()` 凍結跟單金額
11. 建立 `FuturesOrder` 並呼叫 `FuturesOrderService.placeFuturesOrder()`
12. 呼叫 `FollowRedisStateService.recordFollowingOrder()` 更新 Redis 計數（人數+1、金額累加）
13. 回傳 `PlaceOrderResponse`

## API Contracts

### Request
```
POST /follow/place-following-order
Authorization: Bearer {token}

PlaceFollowingOrderRequest:
  - inviteCode: String (required, 8 字元帶單邀請碼)
  - amount: BigDecimal (required, > 0)
  - coinId: Long (required)
```

### Response
```json
{
  "code": 0,
  "data": {
    "orderId": 123456789
  }
}
```

## Business Rules

1. inviteCode 對應的帶單 Redis 狀態必須存在，否則提示帶單不存在或已過期
2. 跟單者不得是殭屍帳號，否則拋出 `NOW_ALLOW_ADD_ZOMBIE`
3. 跟單者不得跟自己的帶單，拋出 `NOT_ALLOWED_INVITE_SELF`
4. 同一跟單者對同一帶單只能下單一次（通過 Redis Set `FOLLOW_INVITED_PLACED:{accountId}` 防重）
5. 金額驗證依 `FollowAmountLimitType` 選擇策略：
   - `By_Amount_Rang`：金額需在 `[effectiveMin, effectiveMax]` 範圍內（含 gameplay/userLevel/marketingLevel 夾鉗）
   - `By_Fixed_Amount`：金額必須等於 `fixedAmount`（含夾鉗）
   - `By_Balance_Percentage`：金額需在餘額百分比計算結果範圍內，特殊邊界時拋出更精確錯誤
6. 跟單成功後 Redis 計數器遞增：跟單人數 +1、跟單總金額 + amount
7. TTL 比較：若 FOLLOW_INVITED_PLACED TTL < runner 剩餘秒數，則更新 TTL

## Test Cases

- [ ] 正常跟單：有效 inviteCode、合規金額、足夠餘額 → 成功回傳 orderId
- [ ] 無效 / 過期 inviteCode → 適當錯誤提示
- [ ] 跟自己的帶單 → 拋出 `NOT_ALLOWED_INVITE_SELF`
- [ ] 殭屍帳號嘗試跟單 → 拋出 `NOW_ALLOW_ADD_ZOMBIE`
- [ ] 重複跟同一帶單 → 拒絕
- [ ] By_Amount_Rang：金額 < effectiveMin → `AMOUNT_OUT_OF_RANGE`
- [ ] By_Amount_Rang：金額 > effectiveMax → `AMOUNT_OUT_OF_RANGE`
- [ ] By_Fixed_Amount：金額不符 → `AMOUNT_OUT_OF_RANGE`
- [ ] By_Balance_Percentage：userLimit 與 gameplay 完全不重疊（上方）→ `AMOUNT_EXCEEDS_MAX`
- [ ] By_Balance_Percentage：userLimit 與 gameplay 完全不重疊（下方）→ `AMOUNT_BELOW_MIN`
- [ ] 錢包餘額不足 → `INSUFFICIENT_BALANCE`
- [ ] 跟單成功後 Redis 計數正確遞增（人數、金額）
- [ ] 跟單成功後 inviteCode 加入 FOLLOW_INVITED_PLACED Set
- [ ] 跟單成功後 DB 記錄正確插入
