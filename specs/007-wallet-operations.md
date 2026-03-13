---
id: SPEC-007
title: Wallet Operations
domain: futures-wallet
status: pending
priority: low
ticket: ""
target_service: com.xh.futures.service.WalletService
target_method: "payOrderFromFuturesWallet(), rollbackFuturesWalletForRevoke(), getRealBalance()"
---

## Context

`WalletService` 管理期貨錢包（`FuturesWallet`）的餘額讀寫。每次下單凍結金額、每次撤單解凍並退還，同時記錄 `WalletChangeLog` 流水。所有錢包操作在事務內執行，使用 `FOR UPDATE` 防止並發問題。

## Behavior

### getRealBalance

1. 通過 `accountId + coinId` 查詢餘額
2. 若錢包不存在（新帳號）→ 回傳 `BigDecimal.ZERO`（暫時行為，待未來完善）

### payOrderFromFuturesWallet（下單凍結）

1. `FOR UPDATE` 鎖定錢包記錄
2. 錢包不存在 → `WALLET_NOT_FUND`
3. 餘額不足 → `INSUFFICIENT_BALANCE`
4. 更新 DB：`balance -= amount`、`frozenBalance += amount`（`futuresWalletMapper.payAndFreeze`）
5. 寫入兩筆 `WalletChangeLog`：FREEZE（凍結記錄）、REAL（餘額扣除記錄）
6. changeType = `CREATE_ORDER`，remark = `ref orderId:{orderId}`
7. 回傳剩餘餘額

### rollbackFuturesWalletForRevoke（撤單解凍）

1. `FOR UPDATE` 鎖定錢包記錄
2. 錢包不存在 → 回傳 `BigDecimal.ZERO`（暫時行為）
3. 更新 DB：`balance += amount`、`frozenBalance -= amount`（`futuresWalletMapper.rollbackBalance`）
4. 寫入兩筆 `WalletChangeLog`：FREEZE（解凍記錄）、REAL（餘額返還記錄）
5. changeType = `CANCEL_ORDER`，remark = `ref orderId:{orderId}`
6. 回傳返還後餘額

### WalletChangeLog 欄位

- `id`：雪花 ID（`uidGenerator.getUID()`）
- `fundType`：REAL（正式）/ VIRTUAL（模擬）→ 依 `account.demoStatus`
- `walletType`：FUTURES
- `walletMode`：FREEZE / REAL
- `changeType`：CREATE_ORDER / CANCEL_ORDER

## Business Rules

1. 所有餘額操作在 `@Transactional` 事務內，DB 更新行數必須恰好為 1
2. `WalletChangeLog` 批量寫入，插入行數必須等於記錄數（否則 RuntimeException）
3. 模擬帳號（`DemoStatusType != NORMAL`）的 WalletChangeLog `fundType = VIRTUAL`
4. 撤單時若錢包不存在，暫時回傳 `BigDecimal.ZERO`（TODO 標記，未來處理）

## Test Cases

- [ ] `getRealBalance`：正常查詢 → 回傳餘額
- [ ] `getRealBalance`：錢包不存在（新帳號）→ 回傳 `0`
- [ ] `payOrderFromFuturesWallet`：正常下單 → balance 減少、frozenBalance 增加
- [ ] `payOrderFromFuturesWallet`：錢包不存在 → `WALLET_NOT_FUND`
- [ ] `payOrderFromFuturesWallet`：餘額不足（balance < amount）→ `INSUFFICIENT_BALANCE`
- [ ] `payOrderFromFuturesWallet`：WalletChangeLog 正確寫入（FREEZE + REAL 兩筆）
- [ ] `payOrderFromFuturesWallet`：remark 格式正確 `ref orderId:{id}`
- [ ] `payOrderFromFuturesWallet`：模擬帳號 → fundType = VIRTUAL
- [ ] `rollbackFuturesWalletForRevoke`：正常撤單 → balance 增加、frozenBalance 減少
- [ ] `rollbackFuturesWalletForRevoke`：錢包不存在 → 回傳 `0`
- [ ] `rollbackFuturesWalletForRevoke`：WalletChangeLog 正確寫入（CANCEL_ORDER）
- [ ] 並發場景：FOR UPDATE 確保同時操作同一錢包的原子性
