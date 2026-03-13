---
id: SPEC-005
title: Amount Validation Pipeline
domain: follow-trading
status: pending
priority: medium
ticket: ""
target_service: com.xh.futures.follow.validator
target_method: "ByAmountRangValidator, ByFixedAmountValidator, ByBalancePercentageValidator"
---

## Context

跟單金額驗證是一個策略模式（Strategy Pattern）實作。`AmountLimitValidator` 介面定義驗證契約，根據 `FollowAmountLimitType` 選擇對應的具體策略。所有策略共用 `AmountRangeUtils.applyCommonClamping()` 做 gameplay/userLevel/marketingLevel 夾鉗計算。

## Behavior

### 策略選擇

```
FollowAmountLimitType → 驗證策略
By_Amount_Rang        → ByAmountRangValidator
By_Fixed_Amount       → ByFixedAmountValidator
By_Balance_Percentage → ByBalancePercentageValidator
```

### AmountRangeUtils.applyCommonClamping()

套用共通夾鉗邏輯：
1. 與 `gameplay.quantityMin/quantityMax` 取交集
2. 與 `userLevel.minAmount/maxAmount` 取交集（若有）
3. 與 `marketingLevel.minAmount/maxAmount` 取交集（若有）
4. 對結果做 `setScale(2, DOWN)`

### ByAmountRangValidator

1. 取 `detail.minAmount` / `detail.maxAmount`
2. 套用 `applyCommonClamping()` 得 effectiveMin/effectiveMax
3. 若 amount 不在 `[effectiveMin, effectiveMax]` → `AMOUNT_OUT_OF_RANGE`

### ByFixedAmountValidator

1. 取 `detail.fixedAmount`，以 `(fixed, fixed)` 輸入 `applyCommonClamping()`
2. 若 amount 不在結果範圍 → `AMOUNT_OUT_OF_RANGE`

### ByBalancePercentageValidator

1. 計算 `userLimitMin = balance * minPercentage / 100`、`userLimitMax = balance * maxPercentage / 100`
2. 先做 gameplay 預夾鉗（與 gameplay min/max 取交集）
3. 再套用 `applyCommonClamping()`
4. 若超出範圍且 userLimit 與 gameplay 完全不重疊，觸發特殊邊界處理（更精確錯誤碼）
5. 否則 → `AMOUNT_OUT_OF_RANGE`

### 特殊邊界（ByBalancePercentageValidator）

| 情況 | 錯誤碼 |
|---|---|
| userLimit 完全在 gameplay max 上方，amount < gameplay.max | `AMOUNT_BELOW_MIN`（顯示 userLimitMin） |
| userLimit 完全在 gameplay max 上方，amount >= gameplay.max | `AMOUNT_EXCEEDS_MAX`（顯示 gameplay.max） |
| userLimit 完全在 gameplay min 下方，amount > gameplay.min | `AMOUNT_EXCEEDS_MAX`（顯示 userLimitMax） |
| userLimit 完全在 gameplay min 下方，amount <= gameplay.min | `AMOUNT_BELOW_MIN`（顯示 gameplay.min） |

## Business Rules

1. 所有驗證策略為純邏輯類（無 Spring 注入），可直接 `new` 實例化並單元測試
2. 錯誤訊息附帶數值參數（amount、effectiveMin、effectiveMax），格式化顯示去除多餘小數點
3. 夾鉗後 effectiveMin > effectiveMax 表示無合法金額區間（邊緣案例）

## Test Cases

### ByAmountRangValidator
- [ ] 金額在範圍內 → 通過
- [ ] 金額 < effectiveMin → `AMOUNT_OUT_OF_RANGE`
- [ ] 金額 > effectiveMax → `AMOUNT_OUT_OF_RANGE`
- [ ] gameplay 夾鉗縮小範圍後仍在範圍 → 通過
- [ ] userLevel 夾鉗縮小範圍後超出 → `AMOUNT_OUT_OF_RANGE`

### ByFixedAmountValidator
- [ ] 金額等於固定值 → 通過
- [ ] 金額不等於固定值 → `AMOUNT_OUT_OF_RANGE`
- [ ] 固定值被 gameplay 夾鉗後有效 → 通過

### ByBalancePercentageValidator
- [ ] 金額在餘額百分比範圍內 → 通過
- [ ] 金額超出範圍（一般情況）→ `AMOUNT_OUT_OF_RANGE`
- [ ] userLimit 完全在 gameplay max 上方，amount < gameplay.max → `AMOUNT_BELOW_MIN`
- [ ] userLimit 完全在 gameplay max 上方，amount >= gameplay.max → `AMOUNT_EXCEEDS_MAX`
- [ ] userLimit 完全在 gameplay min 下方，amount > gameplay.min → `AMOUNT_EXCEEDS_MAX`
- [ ] userLimit 完全在 gameplay min 下方，amount <= gameplay.min → `AMOUNT_BELOW_MIN`
