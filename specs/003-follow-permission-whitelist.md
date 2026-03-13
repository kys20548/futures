---
id: SPEC-003
title: Follow Permission & Whitelist Management
domain: follow-trading
status: pending
priority: medium
ticket: ""
target_service: com.xh.service.FollowService
target_method: "addOrDelete(), permissionsTypeEdit()"
---

## Context

帶單者可以管理跟單白名單，也可以切換許可權型別（公開 vs 白名單限定）。`FollowPermissionChecker` 是從 `FollowService` 提取的獨立驗證元件，負責帳號資格驗證（存在性、殭屍帳號、型別）與自跟防護。

## Behavior

### addOrDelete（白名單新增/移除）

1. 驗證當前帳號為 RUNNER 型別
2. 查詢目標帳號，通過 `FollowPermissionChecker.requireAccountEligible()` 驗證
3. 根據 action（ADD / DELETE）執行 `FollowWhitelistMapper` 操作
4. 回傳操作結果

### permissionsTypeEdit（許可權型別變更）

1. 驗證當前帳號為 RUNNER 型別
2. 更新 `FollowInfo.permissionsType` 欄位
3. 回傳更新結果

### FollowPermissionChecker API

```java
// 帳號資格驗證：存在 + 非殭屍 + 型別符合
void requireAccountEligible(
    Supplier<Account> supplier,
    Supplier<? extends RuntimeException> notFoundEx,
    AccountType expectedType   // null = 不限型別
)

// 自跟防護
void checkNotSelf(Long followerId, Long leadingAccountId)
```

## API Contracts

### 白名單管理
```
POST /follow/whitelist
Authorization: Bearer {token}

{ "targetAccountId": 12345, "action": "ADD" }  // or "DELETE"
```

### 許可權型別變更
```
POST /follow/permissions-type
Authorization: Bearer {token}

{ "permissionsType": 1 }  // 0=UNIVERSAL, 1=WHITELIST
```

## Business Rules

1. 只有 RUNNER 型別帳號可以管理白名單和變更許可權型別
2. 白名單目標帳號不得是殭屍帳號（`AccountType.ZOMBIE`）
3. `PermissionsType.UNIVERSAL`：任何人均可跟單
4. `PermissionsType.WHITELIST`：僅白名單成員可跟單
5. 殭屍帳號判斷優先於型別判斷（ErrorCode 順序：`NOW_ALLOW_ADD_ZOMBIE` > `NOT_FOUND_RUNNER`）
6. `FollowPermissionChecker` 為無狀態 `@Component`，所有邏輯可獨立單元測試

## Test Cases

### FollowPermissionChecker 純單元測試（不需 Spring context）
- [ ] `requireAccountEligible`：帳號不存在 → notFoundEx 拋出
- [ ] `requireAccountEligible`：殭屍帳號 → `NOW_ALLOW_ADD_ZOMBIE`（優先於型別檢查）
- [ ] `requireAccountEligible`：型別不符（非 RUNNER）→ notFoundEx 拋出
- [ ] `requireAccountEligible`：正常 RUNNER 帳號 → 通過
- [ ] `requireAccountEligible`：expectedType=null → 只做存在性與殭屍檢查
- [ ] `checkNotSelf`：相同帳號 ID → `NOT_ALLOWED_INVITE_SELF`
- [ ] `checkNotSelf`：不同帳號 ID → 通過

### 白名單整合測試
- [ ] ADD：成功新增白名單成員
- [ ] DELETE：成功移除白名單成員
- [ ] 非 RUNNER 操作白名單 → 拒絕
- [ ] 目標為殭屍帳號 → 拒絕

### 許可權型別測試
- [ ] 切換為 WHITELIST → DB 更新成功
- [ ] 切換為 UNIVERSAL → DB 更新成功
- [ ] 非 RUNNER 嘗試切換 → 拒絕
